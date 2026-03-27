"""
민원 접수 서버 — 민원 API 라우터

[취약점 #1] 파일 업로드 확장자 우회 — 이중 확장자 허용
[취약점 #2] Content-Type 신뢰 — 클라이언트 제공 MIME 타입 무검증
[취약점 #3] IDOR — complaint_id로 타인 민원 조회/다운로드 가능
[취약점 #4] 하드코딩 관리자 토큰
"""

import os
import json
import uuid
import logging
import sqlite3
from datetime import datetime, timezone

from fastapi import APIRouter, UploadFile, File, Form, Query, Header, HTTPException
from fastapi.responses import RedirectResponse
from typing import Optional

from config import settings
from services.storage import upload_file, generate_presigned_url, ensure_bucket
from services.queue import publish_task

logger = logging.getLogger("minwon")
router = APIRouter(prefix="/api")

DB_PATH = "/opt/minwon/data/complaints.db"


def get_db():
    """SQLite 연결"""
    db_dir = os.path.dirname(DB_PATH)
    os.makedirs(db_dir, exist_ok=True)
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn


def init_db():
    """테이블 초기화"""
    conn = get_db()
    conn.executescript("""
        CREATE TABLE IF NOT EXISTS complaints (
            complaint_id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            category TEXT NOT NULL,
            content TEXT NOT NULL,
            status TEXT DEFAULT 'received',
            submitter_name TEXT NOT NULL,
            submitter_phone TEXT,
            submitter_email TEXT,
            created_at TEXT,
            updated_at TEXT
        );
        CREATE TABLE IF NOT EXISTS files (
            file_id TEXT PRIMARY KEY,
            complaint_id TEXT NOT NULL,
            filename TEXT NOT NULL,
            file_key TEXT NOT NULL,
            file_size INTEGER,
            content_type TEXT,
            uploaded_at TEXT,
            FOREIGN KEY (complaint_id) REFERENCES complaints(complaint_id)
        );
    """)
    conn.close()


def _next_complaint_id(conn) -> str:
    """순차적 민원 번호 생성 — [취약점 #3] 예측 가능한 ID"""
    row = conn.execute("SELECT COUNT(*) as cnt FROM complaints").fetchone()
    num = (row["cnt"] or 0) + 1
    return f"COMP-2026-{num:05d}"


# ===== 민원 접수 =====
@router.post("/complaint/submit", status_code=201)
async def submit_complaint(
    title: str = Form(...),
    category: str = Form(...),
    content: str = Form(...),
    submitter_name: str = Form(...),
    submitter_phone: Optional[str] = Form(None),
    submitter_email: Optional[str] = Form(None),
):
    """새 민원 접수"""
    conn = get_db()
    now = datetime.now(timezone.utc).isoformat()
    complaint_id = _next_complaint_id(conn)

    conn.execute(
        """INSERT INTO complaints
           (complaint_id, title, category, content, status, submitter_name, submitter_phone, submitter_email, created_at, updated_at)
           VALUES (?, ?, ?, ?, 'received', ?, ?, ?, ?, ?)""",
        (complaint_id, title, category, content, submitter_name, submitter_phone, submitter_email, now, now),
    )
    conn.commit()
    conn.close()

    logger.info(f"민원 접수: {complaint_id} — {title}")
    return {
        "complaint_id": complaint_id,
        "status": "received",
        "created_at": now,
        "message": "민원이 정상적으로 접수되었습니다.",
    }


# ===== 파일 업로드 =====
@router.post("/complaint/upload")
async def upload_complaint_file(
    complaint_id: str = Form(...),
    file: UploadFile = File(...),
):
    """
    민원 첨부파일 업로드

    [취약점 #1] 파일 확장자 검증이 불완전 — 이중 확장자(shell.pdf.py) 우회 가능
    올바른 구현: os.path.splitext()의 결과만 확인하고, 매직 바이트 검증 수행

    [취약점 #2] Content-Type을 클라이언트 제공 값 그대로 신뢰
    올바른 구현: python-magic으로 실제 파일 내용 기반 MIME 타입 판별
    """
    filename = file.filename

    # [취약점 #1] 허용 확장자 중 하나가 파일명에 "포함"되어 있는지만 확인
    # shell.pdf.py → ".pdf"가 포함되어 있으므로 통과
    # 올바른 구현: ext = os.path.splitext(filename)[1].lower(); if ext not in ALLOWED
    allowed = False
    for ext in settings.allowed_ext_list:
        if ext in filename.lower():
            allowed = True
            break

    if not allowed:
        raise HTTPException(status_code=400, detail="허용되지 않는 파일 형식입니다.")

    # 파일 읽기 및 크기 검증
    contents = await file.read()
    if len(contents) > settings.MAX_UPLOAD_SIZE:
        raise HTTPException(status_code=413, detail="파일 크기가 50MB를 초과합니다.")

    # [취약점 #2] Content-Type을 클라이언트 제공 값 그대로 사용
    # 올바른 구현: import magic; mime = magic.from_buffer(contents, mime=True)
    content_type = file.content_type or "application/octet-stream"

    # MinIO에 저장
    file_id = str(uuid.uuid4())
    file_key = f"{complaint_id}/{filename}"

    try:
        ensure_bucket()
        upload_file(file_key, contents, content_type)
    except Exception as e:
        logger.error(f"MinIO 업로드 실패: {e}")
        raise HTTPException(status_code=500, detail="파일 저장 중 오류가 발생했습니다.")

    # DB에 파일 정보 저장
    conn = get_db()
    now = datetime.now(timezone.utc).isoformat()
    conn.execute(
        "INSERT INTO files (file_id, complaint_id, filename, file_key, file_size, content_type, uploaded_at) VALUES (?, ?, ?, ?, ?, ?, ?)",
        (file_id, complaint_id, filename, file_key, len(contents), content_type, now),
    )
    conn.commit()
    conn.close()

    # Redis 큐에 처리 요청 전달
    publish_task(complaint_id, file_key, filename)

    logger.info(f"파일 업로드: {complaint_id}/{filename} ({len(contents)} bytes, type={content_type})")
    return {
        "file_id": file_id,
        "filename": filename,
        "size": len(contents),
        "upload_time": now,
        "status": "uploaded",
    }


# ===== 민원 조회 =====
@router.get("/complaint/{complaint_id}")
async def get_complaint(complaint_id: str):
    """
    민원 상태 조회

    [취약점 #3] complaint_id가 순차적(COMP-2026-XXXXX)이므로
    다른 사용자의 민원 정보(이름, 전화번호 포함)를 열람 가능 (IDOR)
    올바른 구현: 접수 시 발급한 비밀 토큰으로 인증
    """
    conn = get_db()
    complaint = conn.execute(
        "SELECT * FROM complaints WHERE complaint_id = ?", (complaint_id,)
    ).fetchone()

    if not complaint:
        conn.close()
        raise HTTPException(status_code=404, detail="해당 민원을 찾을 수 없습니다.")

    files = conn.execute(
        "SELECT file_id, filename FROM files WHERE complaint_id = ?", (complaint_id,)
    ).fetchall()
    conn.close()

    file_list = [
        {
            "file_id": f["file_id"],
            "filename": f["filename"],
            "download_url": f"/api/complaint/{complaint_id}/download?file_id={f['file_id']}",
        }
        for f in files
    ]

    return {
        "complaint_id": complaint["complaint_id"],
        "title": complaint["title"],
        "category": complaint["category"],
        "content": complaint["content"],
        "status": complaint["status"],
        "submitter_name": complaint["submitter_name"],
        "submitter_phone": complaint["submitter_phone"],
        "submitter_email": complaint["submitter_email"],
        "files": file_list,
        "created_at": complaint["created_at"],
        "updated_at": complaint["updated_at"],
    }


# ===== 파일 다운로드 =====
@router.get("/complaint/{complaint_id}/download")
async def download_file(complaint_id: str, file_id: str = Query(...)):
    """
    첨부파일 다운로드 (MinIO presigned URL 리다이렉트)

    [취약점 #3] 요청자와 민원 소유자의 일치 여부를 검증하지 않음
    complaint_id와 file_id만 알면 누구나 다운로드 가능
    """
    conn = get_db()
    file_row = conn.execute(
        "SELECT file_key FROM files WHERE file_id = ? AND complaint_id = ?",
        (file_id, complaint_id),
    ).fetchone()
    conn.close()

    if not file_row:
        raise HTTPException(status_code=404, detail="파일을 찾을 수 없습니다.")

    url = generate_presigned_url(file_row["file_key"])
    return RedirectResponse(url=url, status_code=302)


# ===== 민원 목록 (관리용) =====
@router.get("/complaints")
async def list_complaints(
    page: int = Query(1, ge=1),
    per_page: int = Query(20, ge=1, le=100),
    status: Optional[str] = Query(None),
    x_admin_token: Optional[str] = Header(None),
):
    """
    민원 목록 조회

    [취약점 #4] 관리자 토큰이 소스코드에 하드코딩 (admin-token-mois-2026)
    토큰 없이도 기본 필드가 반환됨
    """
    conn = get_db()
    offset = (page - 1) * per_page

    where = ""
    params = []
    if status:
        where = "WHERE status = ?"
        params.append(status)

    total = conn.execute(f"SELECT COUNT(*) as cnt FROM complaints {where}", params).fetchone()["cnt"]

    params.extend([per_page, offset])
    rows = conn.execute(
        f"SELECT complaint_id, title, category, status, submitter_name, created_at FROM complaints {where} ORDER BY created_at DESC LIMIT ? OFFSET ?",
        params,
    ).fetchall()
    conn.close()

    # [취약점 #4] 토큰이 없어도 기본 정보 반환, 토큰이 있으면 추가 필드 포함
    is_admin = x_admin_token == settings.ADMIN_TOKEN
    complaints = []
    for r in rows:
        item = {
            "complaint_id": r["complaint_id"],
            "title": r["title"],
            "status": r["status"],
            "created_at": r["created_at"],
        }
        if is_admin:
            item["submitter_name"] = r["submitter_name"]
            item["category"] = r["category"]
        complaints.append(item)

    return {"total": total, "page": page, "per_page": per_page, "complaints": complaints}
