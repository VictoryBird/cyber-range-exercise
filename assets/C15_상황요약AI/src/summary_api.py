#!/usr/bin/env python3
"""
C4I 상황 요약 API 서버
파일 경로: /opt/summary-ai/app/summary_api.py

생성된 브리핑을 제공하는 REST API
"""

import json
import os
from datetime import datetime, timezone
from pathlib import Path
from typing import Optional

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware

BRIEFING_DIR = Path(os.getenv("BRIEFING_DIR", "/opt/summary-ai/data/briefings"))

import sys
sys.path.insert(0, os.getenv("PIPELINE_DIR", "/opt/summary-ai/scripts"))
from summary_pipeline import run_pipeline

app = FastAPI(
    title="C4I 상황 요약 AI API",
    description="LLaMA 기반 전장 상황 요약 브리핑 제공",
    version="1.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/health")
def health_check():
    return {"status": "ok", "service": "C4I Summary AI"}


@app.get("/api/summary/latest")
def get_latest_summary():
    """최신 브리핑 조회"""
    latest = BRIEFING_DIR / "latest.json"
    if not latest.exists():
        raise HTTPException(status_code=404, detail="아직 생성된 브리핑이 없습니다")

    with open(latest, "r", encoding="utf-8") as f:
        return json.load(f)


@app.get("/api/summary/history")
def get_summary_history(limit: int = 10):
    """과거 브리핑 이력 조회"""
    briefings = sorted(BRIEFING_DIR.glob("briefing_*.json"), reverse=True)[:limit]
    history = []
    for bp in briefings:
        with open(bp, "r", encoding="utf-8") as f:
            data = json.load(f)
            history.append({
                "filename": bp.name,
                "generated_at": data.get("generated_at"),
                "total_events": data.get("total_events_analyzed"),
                "enemy_events": data.get("enemy_event_count"),
                "friendly_events": data.get("friendly_event_count"),
            })
    return {"total": len(history), "briefings": history}


@app.post("/api/summary/generate")
def force_generate():
    """수동 브리핑 생성 (즉시 실행)"""
    try:
        filepath = run_pipeline()
        if filepath:
            with open(filepath, "r", encoding="utf-8") as f:
                return json.load(f)
        else:
            raise HTTPException(status_code=500, detail="브리핑 생성 실패 (이벤트 없음)")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"브리핑 생성 오류: {str(e)}")


if __name__ == "__main__":
    import uvicorn
    uvicorn.run("summary_api:app", host="0.0.0.0", port=8001, log_level="info")
