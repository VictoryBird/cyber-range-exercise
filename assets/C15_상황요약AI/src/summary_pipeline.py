#!/usr/bin/env python3
"""
C4I 상황 요약 AI 파이프라인
파일 경로: /opt/summary-ai/scripts/summary_pipeline.py

C14 데이터 수집 서버에서 이벤트를 수집하고,
LLaMA를 통해 전장 상황 요약 브리핑을 생성한다.

실행: systemd timer (15분 주기) 또는 API 호출로 수동 실행

※ 이 자산에는 직접적인 취약점이 없음.
   간접 오염: C14 데이터가 변조되면 허위 브리핑이 자동 생성됨.
"""

import json
import logging
import os
import sys
from datetime import datetime, timezone, timedelta
from pathlib import Path

import requests

# ============================================================
# 설정
# ============================================================
C4I_API_URL = os.getenv("C4I_API_URL", "http://192.168.130.12:8000")
C4I_API_KEY = os.getenv("C4I_API_KEY", "dev-key-12345")
OLLAMA_URL = os.getenv("SUMMARY_OLLAMA_URL", "http://localhost:11434")
OLLAMA_MODEL = os.getenv("OLLAMA_MODEL", "llama3:8b")

BRIEFING_DIR = Path(os.getenv("BRIEFING_DIR", "/opt/summary-ai/data/briefings"))
LOG_FILE = os.getenv("LOG_FILE", "/opt/summary-ai/logs/pipeline.log")

BRIEFING_DIR.mkdir(parents=True, exist_ok=True)
os.makedirs(os.path.dirname(LOG_FILE), exist_ok=True)

# ============================================================
# 로깅
# ============================================================
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    handlers=[
        logging.FileHandler(LOG_FILE),
        logging.StreamHandler(sys.stdout),
    ],
)
logger = logging.getLogger("summary-pipeline")


# ============================================================
# 데이터 수집
# ============================================================
def fetch_events(hours: int = 24) -> dict:
    """C14에서 최근 이벤트를 수집한다."""
    since = (datetime.now(timezone.utc) - timedelta(hours=hours)).isoformat()
    try:
        resp = requests.get(
            f"{C4I_API_URL}/api/events",
            params={"since": since, "limit": 500},
            headers={"X-API-Key": C4I_API_KEY},
            timeout=30,
        )
        resp.raise_for_status()
        data = resp.json()
        logger.info(f"C14에서 {data['total']}건 이벤트 수집 완료")
        return data
    except requests.RequestException as e:
        logger.error(f"C14 이벤트 수집 실패: {e}")
        return {"total": 0, "events": []}


def fetch_stats() -> dict:
    """C14에서 이벤트 통계를 조회한다."""
    try:
        resp = requests.get(
            f"{C4I_API_URL}/api/stats",
            headers={"X-API-Key": C4I_API_KEY},
            timeout=30,
        )
        resp.raise_for_status()
        return resp.json()
    except requests.RequestException as e:
        logger.error(f"C14 통계 조회 실패: {e}")
        return {}


# ============================================================
# 데이터 집계
# ============================================================
def aggregate_events(events_data: dict) -> dict:
    """이벤트를 유형별로 집계하고 구조화한다."""
    events = events_data.get("events", [])

    summary = {
        "total_events": len(events),
        "by_type": {},
        "by_priority": {},
        "friendly_events": [],
        "enemy_events": [],
        "critical_events": [],
        "recent_events": events[:10],
    }

    for evt in events:
        etype = evt.get("type", "unknown")
        priority = evt.get("priority", "low")

        summary["by_type"][etype] = summary["by_type"].get(etype, 0) + 1
        summary["by_priority"][priority] = summary["by_priority"].get(priority, 0) + 1

        if etype.startswith("friendly"):
            summary["friendly_events"].append(evt)
        elif etype.startswith("enemy"):
            summary["enemy_events"].append(evt)

        if priority in ("high", "critical"):
            summary["critical_events"].append(evt)

    return summary


# ============================================================
# 프롬프트 생성
# ============================================================
def build_prompt(aggregated: dict) -> str:
    """LLaMA에 전달할 프롬프트를 생성한다."""
    # 프롬프트 템플릿 파일이 있으면 사용
    template_path = Path(__file__).parent / "prompt_template.txt"
    if template_path.exists():
        with open(template_path, "r", encoding="utf-8") as f:
            base_prompt = f.read()
    else:
        base_prompt = """당신은 대한민국 합동참모본부 소속 군사 정보 분석관입니다.
다음 작전 이벤트 데이터를 기반으로 현재 전장 상황을 요약하세요.

{event_summary}

다음 형식으로 한국어 브리핑을 작성하세요:

1. 전체 상황 평가 (한 줄 요약 + 위협 수준: STABLE/ELEVATED/HIGH/CRITICAL)
2. 아군 현황 요약 (부대 이동, 배치 상황)
3. 적 동향 분석 (적 부대 활동, 위치, 이동 방향)
4. 위협 평가 (위협 수준, 주요 위협 요소, 예상 적 의도)
5. 권고 사항 (지휘관 의사결정을 위한 구체적 행동 권고)

분석 시 유의사항:
- 아군 이동 정보가 0건이면 통신 두절 또는 보고 체계 장애 가능성을 언급하세요
- 적 이벤트 비율이 비정상적으로 높으면 (80% 이상) 대규모 공세 가능성을 평가하세요
- 각 항목은 간결하되 구체적 수치를 포함하세요
- 위협 수준에 따라 긴급도를 명확히 표시하세요"""

    event_summary = f"""
[이벤트 집계 데이터]
- 전체 이벤트 수: {aggregated['total_events']}건
- 유형별 분포: {json.dumps(aggregated['by_type'], ensure_ascii=False)}
- 우선순위별 분포: {json.dumps(aggregated['by_priority'], ensure_ascii=False)}
- 아군 관련 이벤트: {len(aggregated['friendly_events'])}건
- 적군 관련 이벤트: {len(aggregated['enemy_events'])}건
- 긴급(high/critical) 이벤트: {len(aggregated['critical_events'])}건

[최근 주요 이벤트 (최신순)]
"""

    for evt in aggregated["recent_events"]:
        loc = evt.get("location", {})
        lat = loc.get("lat", "N/A")
        lng = loc.get("lng", "N/A")
        event_summary += f"- [{evt.get('priority','?').upper()}] {evt.get('type','?')}: {evt.get('description','정보 없음')} "
        event_summary += f"(부대: {evt.get('unit','불명')}, 좌표: {lat}, {lng})\n"

    if aggregated["critical_events"]:
        event_summary += "\n[긴급 이벤트 상세]\n"
        for evt in aggregated["critical_events"][:5]:
            event_summary += f"- ★ {evt.get('description', '상세 없음')} ({evt.get('unit', '불명')})\n"

    prompt = base_prompt.replace("{event_summary}", event_summary)
    return prompt


# ============================================================
# LLaMA 호출
# ============================================================
def generate_summary(prompt: str) -> str:
    """Ollama를 통해 LLaMA에 프롬프트를 전달하고 요약을 생성한다."""
    try:
        resp = requests.post(
            f"{OLLAMA_URL}/api/generate",
            json={
                "model": OLLAMA_MODEL,
                "prompt": prompt,
                "stream": False,
                "options": {
                    "temperature": 0.3,
                    "top_p": 0.9,
                    "num_predict": 1500,
                },
            },
            timeout=120,
        )
        resp.raise_for_status()
        result = resp.json()
        summary = result.get("response", "요약 생성 실패")
        logger.info(f"LLaMA 요약 생성 완료 ({len(summary)}자)")
        return summary
    except requests.RequestException as e:
        logger.error(f"Ollama 호출 실패: {e}")
        return f"[오류] AI 요약 생성 실패: {e}"


# ============================================================
# 브리핑 저장
# ============================================================
def save_briefing(summary: str, aggregated: dict) -> str:
    """생성된 브리핑을 파일로 저장한다."""
    now = datetime.now(timezone.utc)
    filename = f"briefing_{now.strftime('%Y%m%d_%H%M%S')}.json"
    filepath = BRIEFING_DIR / filename

    briefing = {
        "generated_at": now.isoformat(),
        "data_source": C4I_API_URL,
        "total_events_analyzed": aggregated["total_events"],
        "event_distribution": aggregated["by_type"],
        "priority_distribution": aggregated["by_priority"],
        "friendly_event_count": len(aggregated["friendly_events"]),
        "enemy_event_count": len(aggregated["enemy_events"]),
        "critical_event_count": len(aggregated["critical_events"]),
        "summary_text": summary,
    }

    with open(filepath, "w", encoding="utf-8") as f:
        json.dump(briefing, f, ensure_ascii=False, indent=2)

    latest = BRIEFING_DIR / "latest.json"
    if latest.exists():
        latest.unlink()
    latest.symlink_to(filepath)

    logger.info(f"브리핑 저장: {filepath}")
    return str(filepath)


# ============================================================
# 메인 파이프라인
# ============================================================
def run_pipeline():
    """전체 요약 파이프라인을 실행한다."""
    logger.info("=" * 60)
    logger.info("C4I 상황 요약 파이프라인 시작")
    logger.info("=" * 60)

    events_data = fetch_events(hours=24)
    if events_data["total"] == 0:
        logger.warning("수집된 이벤트 없음, 파이프라인 종료")
        return None

    aggregated = aggregate_events(events_data)
    logger.info(f"집계 완료: 전체 {aggregated['total_events']}건, "
                f"아군 {len(aggregated['friendly_events'])}건, "
                f"적군 {len(aggregated['enemy_events'])}건, "
                f"긴급 {len(aggregated['critical_events'])}건")

    prompt = build_prompt(aggregated)
    summary = generate_summary(prompt)
    filepath = save_briefing(summary, aggregated)

    logger.info("파이프라인 완료")
    return filepath


if __name__ == "__main__":
    run_pipeline()
