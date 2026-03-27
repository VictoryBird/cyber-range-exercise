#!/usr/bin/env python3
"""
군 문서 저장 서버 -- FastAPI 메인 애플리케이션
자산 I8 (192.168.110.12)
"""

from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates
from contextlib import asynccontextmanager

from config import settings
from database import engine, Base
from routes.auth_routes import router as auth_router
from routes.file_routes import router as file_router
from routes.admin_routes import router as admin_router


@asynccontextmanager
async def lifespan(app: FastAPI):
    # 시작 시 DB 테이블 생성
    Base.metadata.create_all(bind=engine)
    yield


app = FastAPI(
    title="국방부 문서 저장 시스템",
    description="군 내부 문서 관리 서비스",
    version="1.0.0",
    lifespan=lifespan,
    # [취약점] API 문서 공개 (운영 환경에서는 비활성화해야 함)
    docs_url="/docs" if settings.DEBUG else None,
    redoc_url="/redoc" if settings.DEBUG else None,
)

# 정적 파일 및 템플릿
app.mount("/static", StaticFiles(directory="static"), name="static")
templates = Jinja2Templates(directory="templates")

# 라우터 등록
app.include_router(auth_router, prefix="/api/auth", tags=["인증"])
app.include_router(file_router, prefix="/api", tags=["파일"])
app.include_router(admin_router, prefix="/api/admin", tags=["관리자"])


@app.get("/")
async def index(request):
    """파일 브라우저 UI"""
    from fastapi.responses import HTMLResponse
    from starlette.requests import Request
    return templates.TemplateResponse("index.html", {"request": request})


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "main:app",
        host=settings.APP_HOST,
        port=settings.APP_PORT,
        reload=settings.DEBUG,
    )
