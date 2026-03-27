"""
파일 라우트
[취약점] VULN-I8-02: /api/files/list -- 인증 없이 접근 가능
  - 정상 구현: get_current_user_required 의존성 추가
[취약점] VULN-I8-01: /api/download -- Path Traversal (../../ 경로 미검증)
  - 정상 구현: os.path.realpath()로 경로 검증 후 UPLOAD_DIR 범위 내인지 확인
[취약점] VULN-I8-03: JWT 검증이 Optional -- 인증 없이도 다운로드 가능
  - 정상 구현: get_current_user_required 사용
"""

import os
from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, Query, UploadFile, File, Request
from fastapi.responses import FileResponse
from sqlalchemy.orm import Session

from config import settings
from database import get_db
from models import Document, AuditLog, User
from auth import get_current_user_optional, get_current_user_required

router = APIRouter()


@router.get("/files/list")
def list_files(
    category: Optional[str] = None,
    db: Session = Depends(get_db)
    # [취약점] VULN-I8-02: 인증 의존성 누락 -- 누구나 접근 가능
    #   정상 구현: user: User = Depends(get_current_user_required) 추가
):
    """
    전체 문서 목록 반환
    [취약점] VULN-I8-02: 인증 없이 모든 문서 메타데이터 노출
    """
    query = db.query(Document)

    if category:
        query = query.filter(Document.category == category)

    documents = query.order_by(Document.uploaded_at.desc()).all()

    return {
        "files": [
            {
                "id": doc.id,
                "filename": doc.original_filename,
                "category": doc.category,
                "classification": doc.classification,
                "size": doc.file_size,
                "uploaded_by": doc.uploaded_by,
                "uploaded_at": str(doc.uploaded_at),
                "description": doc.description,
            }
            for doc in documents
        ],
        "total": len(documents),
    }


@router.get("/download")
def download_file(
    file: str = Query(..., description="다운로드할 파일명"),
    request: Request = None,
    user: Optional[User] = Depends(get_current_user_optional),
    db: Session = Depends(get_db),
):
    """
    파일 다운로드
    [취약점] VULN-I8-01: Path Traversal -- 파일명에 ../../ 포함 시 시스템 파일 접근 가능
      공격 예시: GET /api/download?file=../../etc/passwd
      공격 예시: GET /api/download?file=../../../opt/docstorage/.env
    [취약점] VULN-I8-03: JWT 검증이 Optional이므로 인증 없이도 다운로드 가능
    """
    # [취약점] VULN-I8-01: os.path.join은 상대 경로를 해석하지만,
    # 사용자 입력의 ../ 를 정규화하여 상위 디렉토리 접근 허용
    file_path = os.path.join(settings.UPLOAD_DIR, file)

    # [취약점] VULN-I8-01: os.path.realpath() 또는 경로 검증 없음
    # 정상 코드라면 다음과 같이 검증해야 함:
    #   real_path = os.path.realpath(file_path)
    #   if not real_path.startswith(os.path.realpath(settings.UPLOAD_DIR)):
    #       raise HTTPException(status_code=403, detail="접근 거부")

    if not os.path.exists(file_path):
        raise HTTPException(status_code=404, detail="파일을 찾을 수 없습니다")

    if not os.path.isfile(file_path):
        raise HTTPException(status_code=400, detail="유효한 파일이 아닙니다")

    # 감사 로그 (사용자 정보 없이도 기록)
    db.add(AuditLog(
        action="download",
        username=user.username if user else "anonymous",
        target=file,
        ip_address=request.client.host if request else "unknown",
        details=f"파일 다운로드: {file}"
    ))
    db.commit()

    return FileResponse(
        path=file_path,
        filename=os.path.basename(file),
        media_type="application/octet-stream",
    )


@router.post("/upload")
def upload_file(
    file: UploadFile = File(...),
    category: str = Query("일반행정"),
    classification: str = Query("일반"),
    description: str = Query(""),
    user: User = Depends(get_current_user_required),
    db: Session = Depends(get_db),
):
    """파일 업로드 (인증 필요)"""
    # 카테고리별 디렉토리 생성
    category_dir = os.path.join(settings.UPLOAD_DIR, category)
    os.makedirs(category_dir, exist_ok=True)

    # 파일 저장
    save_path = os.path.join(category_dir, file.filename)

    with open(save_path, "wb") as f:
        content = file.file.read()
        if len(content) > settings.MAX_UPLOAD_SIZE:
            raise HTTPException(status_code=413, detail="파일 크기 초과")
        f.write(content)

    # DB에 메타데이터 저장
    doc = Document(
        filename=file.filename,
        original_filename=file.filename,
        file_path=save_path,
        file_size=len(content),
        category=category,
        classification=classification,
        description=description,
        uploaded_by=user.username,
    )
    db.add(doc)

    # 감사 로그
    db.add(AuditLog(
        action="upload",
        username=user.username,
        target=file.filename,
        details=f"파일 업로드: {file.filename} ({category}/{classification})"
    ))
    db.commit()

    return {
        "status": "success",
        "file": {
            "id": doc.id,
            "filename": doc.original_filename,
            "size": doc.file_size,
            "category": doc.category,
        }
    }


@router.get("/files/{file_id}")
def get_file_info(
    file_id: int,
    user: User = Depends(get_current_user_required),
    db: Session = Depends(get_db),
):
    """파일 메타데이터 조회"""
    doc = db.query(Document).filter(Document.id == file_id).first()
    if not doc:
        raise HTTPException(status_code=404, detail="문서를 찾을 수 없습니다")

    return {
        "id": doc.id,
        "filename": doc.original_filename,
        "category": doc.category,
        "classification": doc.classification,
        "size": doc.file_size,
        "uploaded_by": doc.uploaded_by,
        "uploaded_at": str(doc.uploaded_at),
        "description": doc.description,
    }


@router.delete("/files/{file_id}")
def delete_file(
    file_id: int,
    user: User = Depends(get_current_user_required),
    db: Session = Depends(get_db),
):
    """파일 삭제 (인증 필요)"""
    doc = db.query(Document).filter(Document.id == file_id).first()
    if not doc:
        raise HTTPException(status_code=404, detail="문서를 찾을 수 없습니다")

    # 파일 시스템에서 삭제
    if os.path.exists(doc.file_path):
        os.remove(doc.file_path)

    # DB에서 삭제
    db.delete(doc)
    db.add(AuditLog(
        action="delete",
        username=user.username,
        target=doc.original_filename,
        details=f"파일 삭제: {doc.original_filename}"
    ))
    db.commit()

    return {"status": "deleted", "filename": doc.original_filename}
