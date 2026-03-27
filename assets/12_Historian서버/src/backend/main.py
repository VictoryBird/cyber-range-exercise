"""
Historian 서버 — FastAPI REST API
OT 센서 태그 데이터(InfluxDB)의 조회/삽입/삭제를 위한 경량 API

[취약점] VULN-12-01: 전체 엔드포인트 인증 미구현
올바른 구현이라면 FastAPI 미들웨어 또는 Depends()로 인증을 강제해야 한다.
"""

import sys
import os

# src/backend 디렉토리를 모듈 경로에 추가
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from routers.api import router as api_router

app = FastAPI(
    title="Historian OT Data Server",
    description="OT 센서 태그 데이터 조회/삽입/삭제 REST API",
    version="1.0.0",
)

# CORS 허용 (모든 출처)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# [취약점] VULN-12-01: 인증 미들웨어 없이 라우터 등록
# 올바른 구현: app.add_middleware()로 JWT/Bearer 인증 미들웨어 추가
app.include_router(api_router)


@app.get("/")
async def root():
    return {
        "service": "Historian OT Data Server",
        "version": "1.0.0",
        "endpoints": [
            "/api/health",
            "/api/tags",
            "/api/query",
            "/api/write",
            "/api/data",
            "/api/config",
        ],
    }


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=8000)
