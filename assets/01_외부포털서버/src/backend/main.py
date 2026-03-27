"""
외부 포털 서버 — FastAPI 메인 엔트리포인트
Valdoria 행정안전부(MOIS) 대표 홈페이지 API 서버

[취약 설정] Swagger UI, ReDoc, OpenAPI 스펙이 프로덕션에서 활성화됨
[취약 설정] /api/admin/*, /api/internal/* 라우터에 인증 미적용
"""

import logging
import sys
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from config import settings
from database import connect_db, disconnect_db
from routers import notices, search, inquiry, admin, internal

# 로깅 설정
logging.basicConfig(
    level=getattr(logging, settings.LOG_LEVEL),
    format='{"time":"%(asctime)s","level":"%(levelname)s","logger":"%(name)s","message":"%(message)s"}',
    handlers=[
        logging.StreamHandler(sys.stdout),
        logging.FileHandler(settings.LOG_FILE, encoding="utf-8")
        if settings.LOG_FILE != "/var/log/mois-portal/app.log"
        else logging.StreamHandler(sys.stdout),
    ],
)
logger = logging.getLogger("mois-portal")


@asynccontextmanager
async def lifespan(app: FastAPI):
    """애플리케이션 시작/종료 이벤트"""
    logger.info("MOIS Portal API 서버 시작")
    await connect_db()
    yield
    await disconnect_db()
    logger.info("MOIS Portal API 서버 종료")


# [취약 설정] docs_url, redoc_url, openapi_url을 비활성화하지 않음
# 프로덕션에서는 docs_url=None, redoc_url=None으로 설정해야 함
app = FastAPI(
    title="MOIS Portal API",
    description="Valdoria 행정안전부 대표 홈페이지 API",
    version=settings.VERSION,
    docs_url="/docs",
    redoc_url="/redoc",
    openapi_url="/openapi.json",
    lifespan=lifespan,
)

# CORS 설정
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 정상 라우터 등록
app.include_router(notices.router)
app.include_router(search.router)
app.include_router(inquiry.router)

# [취약 설정] 관리자/내부 라우터에 인증 의존성 미적용
# 올바른 구현: dependencies=[Depends(get_current_admin_user)]
app.include_router(admin.router)
app.include_router(internal.router)


@app.get("/api/health")
async def health_check():
    return {"status": "ok", "service": "mois-portal", "version": settings.VERSION}
