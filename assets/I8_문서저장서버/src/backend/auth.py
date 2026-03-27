"""
인증 모듈
[취약점] VULN-I8-03: JWT 검증이 선택적(Optional)으로 구현됨
  - 정상 구현: 모든 보호 엔드포인트에서 get_current_user_required() 사용
  - 현재 구현: 일부 엔드포인트에서 get_current_user_optional()만 사용하여 인증 우회 가능
"""

import jwt
from datetime import datetime, timedelta
from typing import Optional
from fastapi import Depends, HTTPException, Header
from passlib.context import CryptContext
from sqlalchemy.orm import Session

from config import settings
from database import get_db
from models import User

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


def hash_password(password: str) -> str:
    return pwd_context.hash(password)


def verify_password(plain: str, hashed: str) -> bool:
    return pwd_context.verify(plain, hashed)


def create_access_token(data: dict) -> str:
    to_encode = data.copy()
    expire = datetime.utcnow() + timedelta(seconds=settings.JWT_EXPIRATION)
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, settings.JWT_SECRET, algorithm=settings.JWT_ALGORITHM)


def get_current_user_optional(
    authorization: Optional[str] = Header(None),
    db: Session = Depends(get_db)
) -> Optional[User]:
    """
    [취약점] VULN-I8-03: JWT가 없으면 None을 반환하지만, API에서 None 검사를 하지 않음
      - 정상 구현: 인증 실패 시 HTTPException(401)을 raise해야 함
      - 현재 구현: None을 반환하여 무인증 접근 허용
    """
    if not authorization:
        return None  # [취약점] 인증 없이 통과

    try:
        scheme, token = authorization.split(" ", 1)
        if scheme.lower() != "bearer":
            return None

        payload = jwt.decode(token, settings.JWT_SECRET, algorithms=[settings.JWT_ALGORITHM])
        username = payload.get("sub")
        if not username:
            return None

        user = db.query(User).filter(User.username == username).first()
        return user
    except (jwt.PyJWTError, ValueError):
        return None  # [취약점] 토큰 오류 시에도 None 반환 (401이 아님)


def get_current_user_required(
    authorization: Optional[str] = Header(None),
    db: Session = Depends(get_db)
) -> User:
    """인증 필수 -- 이 함수를 사용해야 하지만 일부 엔드포인트에서 누락됨"""
    user = get_current_user_optional(authorization, db)
    if not user:
        raise HTTPException(status_code=401, detail="인증이 필요합니다")
    return user
