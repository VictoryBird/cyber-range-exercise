"""
관리자 라우트
[취약점] VULN-I8-02 / VULN-I8-03: 인증 미적용 -- 모든 사용자가 관리자 API 접근 가능
  - 정상 구현: 모든 엔드포인트에 get_current_user_required 의존성 추가
  - 정상 구현: 관리자 역할 검증 (role == "admin") 추가
"""

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from sqlalchemy import func

from database import get_db
from models import User, Document, AuditLog

router = APIRouter()


@router.get("/users")
def list_users(db: Session = Depends(get_db)):
    """
    전체 사용자 목록
    [취약점] VULN-I8-02: 인증 없이 모든 사용자 정보 노출 (이메일, 부서, 역할 포함)
      정상 구현: user: User = Depends(get_current_user_required) 추가 및 role 검증
    """
    users = db.query(User).all()

    return {
        "users": [
            {
                "id": u.id,
                "username": u.username,
                "name": u.name,
                "email": u.email,
                "department": u.department,
                "role": u.role,
                "last_login": str(u.last_login) if u.last_login else None,
                "created_at": str(u.created_at),
            }
            for u in users
        ]
    }


@router.get("/stats")
def system_stats(db: Session = Depends(get_db)):
    """
    시스템 통계
    [취약점] VULN-I8-02: 인증 없이 접근 가능
    """
    total_users = db.query(func.count(User.id)).scalar()
    total_docs = db.query(func.count(Document.id)).scalar()
    total_size = db.query(func.sum(Document.file_size)).scalar() or 0

    recent_uploads = db.query(Document)\
        .order_by(Document.uploaded_at.desc())\
        .limit(10).all()

    recent_logins = db.query(AuditLog)\
        .filter(AuditLog.action == "login")\
        .order_by(AuditLog.timestamp.desc())\
        .limit(10).all()

    return {
        "total_users": total_users,
        "total_documents": total_docs,
        "total_storage_bytes": total_size,
        "recent_uploads": [
            {"filename": d.original_filename, "by": d.uploaded_by, "at": str(d.uploaded_at)}
            for d in recent_uploads
        ],
        "recent_logins": [
            {"username": l.username, "at": str(l.timestamp), "ip": l.ip_address}
            for l in recent_logins
        ],
    }
