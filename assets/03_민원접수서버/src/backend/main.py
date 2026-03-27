"""
민원 접수 서버 — FastAPI 메인 엔트리포인트
발도리아 행정안전부 민원 접수 포털 API

핵심 침투 벡터: 파일 업로드 → MinIO → Redis → INT 민원처리서버에서 RCE 발생
"""

import logging
import sys
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from config import settings
from routers.complaint import router as complaint_router, init_db
from services.storage import ensure_bucket

logging.basicConfig(
    level=getattr(logging, settings.API_LOG_LEVEL.upper()),
    format='{"time":"%(asctime)s","level":"%(levelname)s","logger":"%(name)s","message":"%(message)s"}',
    handlers=[logging.StreamHandler(sys.stdout)],
)
logger = logging.getLogger("minwon")


@asynccontextmanager
async def lifespan(app: FastAPI):
    logger.info("민원 접수 서버 시작")
    init_db()
    try:
        ensure_bucket()
        logger.info("MinIO 버킷 확인 완료")
    except Exception as e:
        logger.warning(f"MinIO 연결 실패 (나중에 재시도): {e}")
    yield
    logger.info("민원 접수 서버 종료")


app = FastAPI(
    title="민원 접수 API",
    description="발도리아 행정안전부 민원 접수 포털",
    version="1.0.0",
    docs_url=None,
    redoc_url=None,
    openapi_url=None,
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(complaint_router)


@app.get("/api/health")
async def health():
    return {"status": "ok", "service": "minwon-intake"}
