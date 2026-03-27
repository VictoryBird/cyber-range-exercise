"""
외부 포털 서버 — 내부 설정 API

[취약점 #2] 인증 미적용 내부 API
/api/internal/config 엔드포인트에서 DB 크리덴셜, JWT 시크릿 등
민감 정보가 인증 없이 노출된다.
"""

from fastapi import APIRouter, Depends
from datetime import datetime
from database import get_db, database
from config import settings

router = APIRouter(prefix="/api/internal", tags=["internal"])

_start_time = datetime.utcnow()


@router.get("/config")
async def get_config():
    """
    내부 설정 정보 조회

    [취약점] 인증 없이 접근 가능
    [취약점] DB 크리덴셜, JWT 시크릿 키가 평문으로 노출됨

    레드팀 활용: 이 엔드포인트에서 DB 접속 정보를 획득하여
    192.168.100.20:5432에 직접 접속 시도
    """
    return {
        "app_name": settings.APP_NAME,
        "version": settings.VERSION,
        "environment": settings.ENVIRONMENT,
        "database": {
            "host": settings.DB_HOST,
            "port": settings.DB_PORT,
            "name": settings.DB_NAME,
            "user": settings.DB_USER,
            "password": settings.DB_PASSWORD,  # [취약점] 비밀번호 평문 노출
        },
        "jwt_secret": settings.JWT_SECRET,  # [취약점] JWT 시크릿 키 노출
        "debug_mode": settings.DEBUG,
        "allowed_origins": settings.ALLOWED_ORIGINS,
    }


@router.get("/health")
async def health_detail(db=Depends(get_db)):
    """
    상세 헬스체크 — DB 연결 상태, 서버 업타임 포함

    [취약점] 내부 인프라 정보 노출
    """
    db_connected = False
    try:
        await database.fetch_val("SELECT 1")
        db_connected = True
    except Exception:
        pass

    uptime = (datetime.utcnow() - _start_time).total_seconds()

    return {
        "status": "ok" if db_connected else "degraded",
        "uptime_seconds": int(uptime),
        "database": {
            "connected": db_connected,
            "host": settings.DB_HOST,
            "port": settings.DB_PORT,
            "name": settings.DB_NAME,
        },
        "server": {
            "environment": settings.ENVIRONMENT,
            "python_version": "3.11",
            "framework": "FastAPI 0.104.1",
        },
    }
