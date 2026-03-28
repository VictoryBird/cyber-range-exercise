"""
Internal API Router
Asset 01: External Portal Server (192.168.92.201)

[취약점] VULN-01-02: No authentication on internal endpoints.
The /config endpoint exposes database credentials in plaintext.
올바른 구현: remove this endpoint entirely, or require
admin authentication AND never expose raw credentials.
"""

from fastapi import APIRouter, Depends
from config import settings
from database import get_pool
import time

router = APIRouter(prefix="/api/internal", tags=["internal"])

_start_time = time.time()


@router.get("/config")
async def get_config():
    """
    [취약점] VULN-01-02: Internal configuration with DB credentials exposed.
    No authentication required. Password shown in plaintext.
    This is the key vulnerability that allows attackers to obtain DB credentials
    and pivot to the internal database server (192.168.92.208).

    올바른 구현: remove this endpoint entirely, or at minimum:
        1. Require admin authentication: Depends(get_current_admin_user)
        2. Never return raw passwords
        3. Mask sensitive values: "password": "****"
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
            "password": settings.DB_PASSWORD,  # [취약점] Plaintext password exposure
        },
        "jwt_secret": settings.JWT_SECRET,  # [취약점] JWT secret exposed
        "debug_mode": settings.DEBUG,
        "allowed_origins": settings.ALLOWED_ORIGINS,
    }


@router.get("/health")
async def health_check():
    """Service health check with internal details."""
    uptime = time.time() - _start_time
    db_status = "unknown"
    try:
        pool = await get_pool()
        async with pool.acquire() as conn:
            await conn.fetchval("SELECT 1")
            db_status = "connected"
    except Exception as e:
        db_status = f"error: {str(e)}"

    return {
        "status": "healthy",
        "uptime_seconds": round(uptime, 2),
        "database": db_status,
        "version": settings.VERSION,
        "environment": settings.ENVIRONMENT,
    }
