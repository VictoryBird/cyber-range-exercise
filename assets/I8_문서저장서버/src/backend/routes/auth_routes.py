"""인증 라우트"""

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy.orm import Session
from datetime import datetime

from database import get_db
from models import User, AuditLog
from auth import verify_password, create_access_token

router = APIRouter()


class LoginRequest(BaseModel):
    username: str
    password: str


class LoginResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: dict


@router.post("/login", response_model=LoginResponse)
def login(req: LoginRequest, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.username == req.username).first()

    if not user or not verify_password(req.password, user.password_hash):
        # 감사 로그 기록
        db.add(AuditLog(
            action="login_failed",
            username=req.username,
            ip_address="(from request)",
            details=f"로그인 실패: {req.username}"
        ))
        db.commit()
        raise HTTPException(status_code=401, detail="사용자명 또는 비밀번호가 올바르지 않습니다")

    # 마지막 로그인 시간 업데이트
    user.last_login = datetime.utcnow()
    db.add(AuditLog(
        action="login",
        username=user.username,
        details="로그인 성공"
    ))
    db.commit()

    token = create_access_token({"sub": user.username, "role": user.role})

    return LoginResponse(
        access_token=token,
        user={
            "id": user.id,
            "username": user.username,
            "name": user.name,
            "department": user.department,
            "role": user.role,
        }
    )
