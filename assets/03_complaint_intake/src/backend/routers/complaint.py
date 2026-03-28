import hashlib
import uuid
from datetime import datetime, timezone

import psycopg2
import psycopg2.extras
from fastapi import APIRouter, Depends, File, Form, HTTPException, Request, UploadFile
from fastapi.responses import RedirectResponse

import config
from models.complaint import ComplaintResponse, ComplaintSubmit, FileUploadResponse
from services import queue as queue_svc
from services import storage as storage_svc

router = APIRouter(prefix="/api")


# ---------------------------------------------------------------------------
# DB 헬퍼
# ---------------------------------------------------------------------------

def get_db():
    """psycopg2 동기 DB 연결을 반환한다."""
    conn = psycopg2.connect(
        host=config.DB_HOST,
        port=config.DB_PORT,
        dbname=config.DB_NAME,
        user=config.DB_USER,
        password=config.DB_PASSWORD,
        cursor_factory=psycopg2.extras.RealDictCursor,
    )
    try:
        yield conn
    finally:
        conn.close()


# ---------------------------------------------------------------------------
# POST /api/complaint/submit
# ---------------------------------------------------------------------------

@router.post("/complaint/submit", status_code=201)
def submit_complaint(body: ComplaintSubmit, conn=Depends(get_db)):
    """민원을 접수하고 민원번호를 반환한다."""
    with conn.cursor() as cur:
        # 1단계: 민원 삽입 (complaint_number는 임시값으로 채운 뒤 UPDATE)
        cur.execute(
            """
            INSERT INTO complaints (
                complaint_number,
                applicant_name,
                applicant_email,
                applicant_phone,
                applicant_addr,
                category,
                title,
                content,
                status,
                priority
            ) VALUES (
                %s, %s, %s, %s, %s,
                %s, %s, %s,
                'Received', 'Normal'
            )
            RETURNING complaint_id
            """,
            (
                "TEMP",
                body.applicant_name,
                body.applicant_email,
                body.applicant_phone,
                body.applicant_addr,
                body.category,
                body.title,
                body.content,
            ),
        )
        row = cur.fetchone()
        complaint_id: int = row["complaint_id"]

        # 2단계: complaint_number 생성 및 UPDATE
        year = datetime.now(timezone.utc).year
        complaint_number = f"COMP-{year}-{complaint_id:05d}"
        cur.execute(
            "UPDATE complaints SET complaint_number = %s WHERE complaint_id = %s",
            (complaint_number, complaint_id),
        )

    conn.commit()
    return {"complaint_number": complaint_number, "complaint_id": complaint_id}


# ---------------------------------------------------------------------------
# POST /api/complaint/upload
# ---------------------------------------------------------------------------

@router.post("/complaint/upload", response_model=FileUploadResponse)
async def upload_attachment(
    complaint_number: str = Form(...),
    content_type: str = Form("application/octet-stream"),
    file: UploadFile = File(...),
    conn=Depends(get_db),
):
    """민원 첨부파일을 업로드한다.

    [취약점] 파일 확장자 검사: 허용 확장자 문자열이 파일명 어딘가에 포함되어 있으면 통과한다.
    예) 'shell.pdf.py' 는 '.pdf' 가 포함되므로 허용됨 → 악성 스크립트 업로드 가능.
    올바른 구현: os.path.splitext(filename)[-1].lower() in ALLOWED_EXTENSIONS 로 최종 확장자만 검사해야 한다.
    """
    filename = file.filename or ""

    # [취약점] 확장자 포함 여부만 확인 — 최종 확장자 검사 아님
    allowed = False
    for ext in config.ALLOWED_EXTENSIONS:
        if ext in filename.lower():
            allowed = True
            break

    if not allowed:
        raise HTTPException(status_code=400, detail=f"허용되지 않는 파일 형식입니다: {filename}")

    data = await file.read()
    file_size = len(data)

    if file_size > config.MAX_UPLOAD_SIZE:
        raise HTTPException(status_code=413, detail="파일 크기가 허용 한도를 초과합니다.")

    # 무결성 체크섬
    checksum = hashlib.sha256(data).hexdigest()

    # MinIO 저장 경로
    unique_key = f"{complaint_number}/{uuid.uuid4().hex}_{filename}"

    # [취약점] 클라이언트 제공 content_type 그대로 사용 (storage.upload 참조)
    storage_svc.upload(
        bucket=config.MINIO_BUCKET,
        key=unique_key,
        data=data,
        content_type=content_type,
    )

    # DB: complaint_id 조회
    with conn.cursor() as cur:
        cur.execute(
            "SELECT complaint_id FROM complaints WHERE complaint_number = %s",
            (complaint_number,),
        )
        row = cur.fetchone()
        if not row:
            raise HTTPException(status_code=404, detail="민원번호를 찾을 수 없습니다.")
        complaint_id = row["complaint_id"]

        # DB: attachments 삽입
        cur.execute(
            """
            INSERT INTO attachments (
                complaint_id,
                original_name,
                stored_path,
                file_size,
                mime_type,
                checksum_sha256
            ) VALUES (%s, %s, %s, %s, %s, %s)
            RETURNING attachment_id
            """,
            (
                complaint_id,
                filename,
                unique_key,
                file_size,
                content_type,
                checksum,
            ),
        )
        att_row = cur.fetchone()
        attachment_id = att_row["attachment_id"]

    conn.commit()

    # Redis 업로드 이벤트 발행
    event = {
        "complaint_id": complaint_number,
        "file_key": unique_key,
        "filename": filename,
        "content_type": content_type,
        "action": "file_uploaded",
        "timestamp": datetime.now(timezone.utc).isoformat(),
    }
    try:
        queue_svc.publish(config.REDIS_QUEUE, event)
        queue_svc.log_upload_event(event)
    except Exception:
        # Redis 실패는 무시 — 파일 업로드 자체는 성공으로 처리
        pass

    return FileUploadResponse(
        attachment_id=attachment_id,
        complaint_number=complaint_number,
        original_name=filename,
        stored_path=unique_key,
        file_size=file_size,
        mime_type=content_type,
    )


# ---------------------------------------------------------------------------
# GET /api/complaint/{complaint_number}
# ---------------------------------------------------------------------------

@router.get("/complaint/{complaint_number}", response_model=ComplaintResponse)
def get_complaint(complaint_number: str, conn=Depends(get_db)):
    """민원 상세 정보를 반환한다.

    [취약점] IDOR (Insecure Direct Object Reference):
    인증 없이 민원번호만 알면 누구든 타인의 민원 내용을 조회할 수 있다.
    올바른 구현: 요청자의 세션/토큰에서 신원을 확인하고, 본인 또는 담당자만 조회 가능하도록 한다.
    """
    with conn.cursor() as cur:
        cur.execute(
            """
            SELECT
                complaint_id,
                complaint_number,
                applicant_name,
                applicant_email,
                applicant_phone,
                applicant_addr,
                category,
                title,
                content,
                status,
                priority,
                assigned_dept,
                assigned_to,
                response,
                responded_at,
                created_at,
                updated_at
            FROM complaints
            WHERE complaint_number = %s
            """,
            (complaint_number,),
        )
        row = cur.fetchone()

    if not row:
        raise HTTPException(status_code=404, detail="민원을 찾을 수 없습니다.")

    return ComplaintResponse(**dict(row))


# ---------------------------------------------------------------------------
# GET /api/complaint/{complaint_number}/download
# ---------------------------------------------------------------------------

@router.get("/complaint/{complaint_number}/download")
def download_attachment(complaint_number: str, attachment_id: int, conn=Depends(get_db)):
    """첨부파일의 Presigned URL로 리다이렉트한다.

    [취약점] IDOR: 민원번호와 attachment_id만 알면 인증 없이 첨부파일을 내려받을 수 있다.
    올바른 구현: 요청자가 해당 민원의 소유자인지 검증 후 URL을 발급해야 한다.
    """
    with conn.cursor() as cur:
        # 민원번호 → complaint_id 확인
        cur.execute(
            "SELECT complaint_id FROM complaints WHERE complaint_number = %s",
            (complaint_number,),
        )
        comp_row = cur.fetchone()
        if not comp_row:
            raise HTTPException(status_code=404, detail="민원을 찾을 수 없습니다.")

        # attachment 조회 (complaint_id 와 매칭 확인은 하지만 소유권 검증 없음)
        cur.execute(
            """
            SELECT stored_path
            FROM attachments
            WHERE attachment_id = %s AND complaint_id = %s
            """,
            (attachment_id, comp_row["complaint_id"]),
        )
        att_row = cur.fetchone()

    if not att_row:
        raise HTTPException(status_code=404, detail="첨부파일을 찾을 수 없습니다.")

    presigned_url = storage_svc.generate_presigned_url(att_row["stored_path"])
    return RedirectResponse(url=presigned_url, status_code=302)


# ---------------------------------------------------------------------------
# GET /api/complaints  (관리자 전용)
# ---------------------------------------------------------------------------

@router.get("/complaints")
def list_complaints(
    request: Request,
    page: int = 1,
    size: int = 20,
    status: str = None,
    conn=Depends(get_db),
):
    """민원 목록을 반환한다 (관리자 전용).

    [취약점] 하드코딩된 관리자 토큰:
    Authorization 헤더의 Bearer 토큰을 소스코드에 직접 박힌 값과 비교한다.
    소스코드 유출 시 즉시 권한 탈취 가능.
    올바른 구현: 환경변수로 토큰을 관리하고, 가능하면 JWT/OAuth2 같은 표준 인증 체계를 사용한다.
    """
    # [취약점] 하드코딩된 관리자 토큰 비교
    auth_header = request.headers.get("Authorization", "")
    token = auth_header.removeprefix("Bearer ").strip()
    if token != "admin-token-mois-2026":  # [취약 설정] 하드코딩 토큰
        raise HTTPException(status_code=401, detail="인증 실패")

    offset = (page - 1) * size

    conditions = []
    params: list = []

    if status:
        conditions.append("status = %s")
        params.append(status)

    where_clause = "WHERE " + " AND ".join(conditions) if conditions else ""

    with conn.cursor() as cur:
        # 전체 건수
        cur.execute(f"SELECT COUNT(*) AS cnt FROM complaints {where_clause}", params)
        total = cur.fetchone()["cnt"]

        # 페이지 데이터
        params_data = params + [size, offset]
        cur.execute(
            f"""
            SELECT
                complaint_id,
                complaint_number,
                applicant_name,
                applicant_email,
                applicant_phone,
                category,
                title,
                status,
                priority,
                assigned_dept,
                created_at,
                updated_at
            FROM complaints
            {where_clause}
            ORDER BY created_at DESC
            LIMIT %s OFFSET %s
            """,
            params_data,
        )
        rows = cur.fetchall()

    return {
        "total": total,
        "page": page,
        "size": size,
        "items": [dict(r) for r in rows],
    }
