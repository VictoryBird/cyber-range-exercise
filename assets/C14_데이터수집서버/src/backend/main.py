#!/usr/bin/env python3
"""
C4I 데이터 수집·관리 서버 — FastAPI 애플리케이션
파일 경로: /opt/datacollector/app/main.py

★★★ 이 코드에는 의도적인 보안 취약점이 포함되어 있습니다 ★★★
- VULN-C14-01: API 키 하드코딩 및 /api/config 노출
- VULN-C14-02: DELETE/UPDATE 인증 미흡
- VULN-C14-03: 레이트 리밋 없음
- VULN-C14-04: 입력 검증 없음
"""

from datetime import datetime, timezone

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from routers.events import router as events_router

# ============================================================
# FastAPI 앱 초기화
# ============================================================
app = FastAPI(
    title="C4I 데이터 수집·관리 API",
    description="작전 이벤트 수집, 조회, 관리 API",
    version="1.0.0",
)

# CORS 설정 (★ 과도하게 허용)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 라우터 등록
app.include_router(events_router)


@app.get("/health")
def health_check():
    """헬스 체크 (인증 없음)"""
    return {
        "status": "ok",
        "service": "C4I Data Collector",
        "timestamp": datetime.now(timezone.utc).isoformat(),
    }


# ============================================================
# 앱 실행
# ============================================================
if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8000,
        reload=False,
        log_level="info",
    )
