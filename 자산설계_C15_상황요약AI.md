# 자산 설계서 #C15 — 상황 요약 AI 서버

| 항목 | 내용 |
|------|------|
| 자산 ID | C15 |
| IP | 192.168.130.13 |
| OS | Ubuntu 22.04 LTS |
| 도메인 | summary.c4i.local |
| 역할 | LLaMA 기반 전장 상황 자동 요약 |
| 작성일 | 2026-03-26 |

---

## 1. 개요

### 1.1 자산 목적

C15 상황 요약 AI 서버는 C4I 존의 인공지능 기반 상황 분석 시스템이다. C14 데이터 수집 서버에서 작전 이벤트를 주기적으로 수집하고, LLaMA 3 8B 모델을 활용하여 한국어 전장 상황 요약 브리핑을 자동 생성한다. 생성된 브리핑은 API를 통해 작전용 PC에 제공된다.

주요 기능:
- **자동 데이터 수집**: C14 API에서 15분 주기로 이벤트 수집
- **상황 분석**: 이벤트 유형별 집계, 위협 수준 평가
- **AI 브리핑 생성**: LLaMA 기반 자연어 상황 요약
- **브리핑 이력 관리**: 과거 브리핑 저장 및 조회

### 1.2 훈련에서의 역할

이 자산은 **간접 피해 대상**이다. C15 자체에는 직접적인 취약점이 없으나, C14의 데이터가 변조되면 AI가 허위 데이터를 기반으로 잘못된 상황 요약을 생성한다. 이는 "가비지 인, 가비지 아웃(Garbage In, Garbage Out)" 원리의 전형적인 사례이다.

> 공격자가 직접 C15를 공격할 필요가 없다. C14 데이터를 변조하면 15분 이내에 C15가 자동으로 허위 브리핑을 생성한다.

### 1.3 정상 브리핑 vs 오염 브리핑 비교

**정상 상태의 AI 브리핑:**

```
═══════════════════════════════════════════
   전장 상황 요약 브리핑
   생성 시각: 2026-03-26 14:30 KST
   데이터 기반: 최근 24시간 이벤트 35건
═══════════════════════════════════════════

1. 전체 상황 평가: 안정 (STABLE)

2. 아군 현황:
   - 보병 부대: 정상 운용 중 (이동 완료 12건)
   - 기갑 부대: 전개 위치 도착, 대기 상태
   - 포병 부대: 사격 진지 전환 완료
   - 특수전 부대: 정찰 임무 귀환 완료

3. 적 동향:
   - 적 전초 활동 소폭 증가 (5건 탐지)
   - 적 기갑부대 야간 이동 포착 (주의 필요)
   - 적 장사정포 진지 이동 감지 (경계 강화)

4. 위협 평가:
   - 전반적 위협 수준: 보통 (MODERATE)
   - 주요 위협: 적 장사정포 진지 변경 (사격 준비 가능성)
   - 권고: 대포병 감시 강화, 대비 태세 유지

5. 권고 사항:
   - 현 방어 태세 유지
   - 적 장사정포 동향 집중 감시
   - 정기 정찰 일정 유지
═══════════════════════════════════════════
```

**변조 후 AI 브리핑 (C14 데이터 오염 상태):**

```
═══════════════════════════════════════════
   전장 상황 요약 브리핑
   생성 시각: 2026-03-26 14:45 KST
   데이터 기반: 최근 24시간 이벤트 68건
═══════════════════════════════════════════

1. 전체 상황 평가: ★★★ 긴급 (CRITICAL) ★★★

2. 아군 현황:
   - ★ 아군 이동/배치 정보 부재 (0건) — 통신 두절 가능성
   - 아군 부대 현재 위치 확인 불가
   - 즉각 통신 상태 점검 필요

3. 적 동향:
   - ★★★ 적 대규모 남하 전진 감지 (55건) ★★★
   - 적 기계화보병 50개 대대급 부대 동시 남하
   - 전진 구간: 파주~연천~철원 전 전방 축선
   - 서울 근교까지 적 특수부대 침투 확인

4. 위협 평가:
   - 전반적 위협 수준: ★ 최고 (MAXIMUM) ★
   - 적 전면 공격 징후 — 전쟁 개시 가능성 극히 높음
   - 모든 전방 축선에서 동시 적 전진
   - 아군 통신 두절은 적 전자전 가능성

5. 긴급 권고 사항:
   - ★ 즉각 전투 준비 태세 발령 권고 ★
   - 전 부대 방어 진지 점령 명령
   - 예비대 즉각 투입 준비
   - 합참 긴급 보고 필요
   - 공군 출격 준비 요청
═══════════════════════════════════════════
```

---

## 2. 기술 스택

| 계층 | 기술 | 버전 | 용도 |
|------|------|------|------|
| OS | Ubuntu | 22.04 LTS | 기반 운영체제 |
| Runtime | Python | 3.11 | 파이프라인 실행 |
| LLM 서버 | Ollama | 최신 | LLaMA 모델 호스팅 |
| LLM 모델 | LLaMA 3 | 8B | 상황 요약 생성 |
| 프레임워크 | FastAPI | 0.109.x | 브리핑 API 제공 |
| ASGI 서버 | Uvicorn | 0.27.x | HTTP 서버 |
| HTTP 클라이언트 | requests | 2.31.x | C14 API 및 Ollama 호출 |
| 스케줄링 | systemd timer | - | 15분 주기 브리핑 생성 |

---

## 3. 요약 파이프라인 소스 코드

### 3.1 summary_pipeline.py (브리핑 생성 파이프라인)

```python
#!/usr/bin/env python3
"""
C4I 상황 요약 AI 파이프라인
파일 경로: /opt/summary-ai/scripts/summary_pipeline.py

C14 데이터 수집 서버에서 이벤트를 수집하고,
LLaMA를 통해 전장 상황 요약 브리핑을 생성한다.

실행: systemd timer (15분 주기) 또는 API 호출로 수동 실행
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

BRIEFING_DIR = Path("/opt/summary-ai/data/briefings")
LOG_FILE = "/opt/summary-ai/logs/pipeline.log"

BRIEFING_DIR.mkdir(parents=True, exist_ok=True)

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

    prompt = f"""당신은 대한민국 합동참모본부 소속 군사 정보 분석관입니다.
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
```

### 3.2 summary_api.py (브리핑 API 서버)

```python
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

BRIEFING_DIR = Path("/opt/summary-ai/data/briefings")

import sys
sys.path.insert(0, "/opt/summary-ai/scripts")
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
```

---

## 4. systemd 서비스

### 4.1 Ollama 서비스 (LLM 호스팅)

```ini
# /etc/systemd/system/ollama.service
[Unit]
Description=Ollama LLM Server
After=network-online.target

[Service]
Type=simple
ExecStart=/usr/local/bin/ollama serve
Restart=always
RestartSec=3
Environment=OLLAMA_HOST=0.0.0.0:11434

[Install]
WantedBy=multi-user.target
```

### 4.2 요약 API 서비스

```ini
# /etc/systemd/system/summary-api.service
[Unit]
Description=C4I Summary AI API Server
After=network-online.target ollama.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/summary-ai/app
ExecStart=/opt/summary-ai/venv/bin/uvicorn summary_api:app --host 0.0.0.0 --port 8001 --log-level info
Restart=always
RestartSec=5
Environment=PYTHONUNBUFFERED=1
Environment=C4I_API_URL=http://192.168.130.12:8000
Environment=C4I_API_KEY=dev-key-12345
Environment=SUMMARY_OLLAMA_URL=http://localhost:11434

[Install]
WantedBy=multi-user.target
```

### 4.3 브리핑 생성 타이머

```ini
# /etc/systemd/system/summary-gen.service
[Unit]
Description=C4I Summary Generation Service
After=network-online.target ollama.service

[Service]
Type=oneshot
User=root
WorkingDirectory=/opt/summary-ai/scripts
ExecStart=/opt/summary-ai/venv/bin/python /opt/summary-ai/scripts/summary_pipeline.py
Environment=PYTHONUNBUFFERED=1
Environment=C4I_API_URL=http://192.168.130.12:8000
Environment=C4I_API_KEY=dev-key-12345
Environment=SUMMARY_OLLAMA_URL=http://localhost:11434
```

```ini
# /etc/systemd/system/summary-gen.timer
[Unit]
Description=C4I Summary Generation Timer (15min)

[Timer]
OnBootSec=2min
OnUnitActiveSec=15min
AccuracySec=30s

[Install]
WantedBy=timers.target
```

---

## 5. 설치 스크립트

```bash
#!/bin/bash
# /opt/summary-ai/setup.sh — C15 상황 요약 AI 서버 설치

set -e

echo "=========================================="
echo "C15 상황 요약 AI 서버 설치 시작"
echo "호스트: summary.c4i.local (192.168.130.13)"
echo "=========================================="

# 1. 시스템 업데이트
apt-get update && apt-get upgrade -y

# 2. Python 설치
apt-get install -y python3 python3-pip python3-venv curl

# 3. Ollama 설치
curl -fsSL https://ollama.com/install.sh | sh

# 4. Ollama 서비스 시작 및 모델 다운로드
systemctl enable ollama
systemctl start ollama

# LLaMA 3 8B 모델 다운로드
ollama pull llama3:8b

# 5. 디렉토리 구조 생성
mkdir -p /opt/summary-ai/{app,scripts,data/briefings,logs,config}

# 6. Python 가상 환경
python3 -m venv /opt/summary-ai/venv
source /opt/summary-ai/venv/bin/activate
pip install fastapi uvicorn requests python-dotenv

# 7. 소스 배포
cp /opt/summary-ai/src/summary_pipeline.py /opt/summary-ai/scripts/
cp /opt/summary-ai/src/summary_api.py /opt/summary-ai/app/

# 8. systemd 서비스 등록

# 9. 서비스 활성화
systemctl daemon-reload
systemctl enable summary-api
systemctl start summary-api
systemctl enable summary-gen.timer
systemctl start summary-gen.timer

# 10. 호스트명 설정
hostnamectl set-hostname summary-c4i

# 11. 초기 브리핑 생성
/opt/summary-ai/venv/bin/python /opt/summary-ai/scripts/summary_pipeline.py

echo "=========================================="
echo "C15 상황 요약 AI 서버 설치 완료"
echo "API: http://summary.c4i.local:8001"
echo "Ollama: http://summary.c4i.local:11434"
echo "=========================================="
```

---

## 6. 공통 참조 정보

### 6.1 OPNSense-7 방화벽 규칙

| # | 방향 | 출발지 | 도착지 | 포트 | 프로토콜 | 동작 | 설명 |
|---|------|--------|--------|------|----------|------|------|
| 1 | WAN→LAN | 192.168.110.40 (관리자 PC) | 192.168.130.10 | 22 | TCP | ALLOW | SSH 관리 접근 |
| 2 | WAN→LAN | 192.168.110.10 (INT 포털) | 192.168.130.10 | 443 | TCP | ALLOW | INT→릴레이 |
| 3 | LAN→LAN | 192.168.130.0/24 | 192.168.130.0/24 | * | * | ALLOW | C4I 내부 전체 허용 |
| 4 | LAN→WAN | 192.168.130.10 | 192.168.110.10 | 8080 | TCP | ALLOW | 릴레이→INT |
| 5 | WAN→LAN | * | * | * | * | **DENY** | 기본 거부 |
| 6 | LAN→WAN | * | * | * | * | **DENY** | C4I→외부 기본 거부 |

### 6.2 DNS 설정 (C4I 내부)

```bash
192.168.130.1   gw.c4i.local
192.168.130.10  relay.c4i.local
192.168.130.11  cop.c4i.local
192.168.130.12  data.c4i.local
192.168.130.13  summary.c4i.local
192.168.130.21  ops-pc-1.c4i.local
192.168.130.22  ops-pc-2.c4i.local
192.168.130.23  ops-pc-3.c4i.local
192.168.130.24  ops-pc-4.c4i.local
192.168.130.25  ops-pc-5.c4i.local
```

### 6.3 블루팀 탐지 요약 (C15 관련)

| 자산 | 탐지 항목 | 심각도 | 탐지 방법 |
|------|-----------|--------|-----------|
| C15 | 브리핑 위협수준 급변 (STABLE→CRITICAL) | HIGH | 브리핑 이력 비교 |
| C15 | 아군 이벤트 0건 기반 브리핑 생성 | CRITICAL | 파이프라인 로그 |

### 6.4 크리덴셜 참조

| 자산 | 서비스 | 계정 | 비밀번호 | 용도 |
|------|--------|------|----------|------|
| C15 | Ollama | (없음) | (없음) | LLM API (인증 없음) |
| C15 | API | (없음) | (없음) | 브리핑 API (인증 없음) |

### 6.5 네트워크 포트

| 자산 | IP | 포트 | 프로토콜 | 서비스 |
|------|-----|------|----------|--------|
| C15 | 192.168.130.13 | 8001 | TCP | FastAPI (브리핑 API) |
| C15 | 192.168.130.13 | 11434 | TCP | Ollama (LLM API) |

### 6.6 네트워크 토폴로지

```
                    ┌──────────────────────────────────────────────────┐
                    │              C4I 존 (192.168.130.0/24)            │
                    │                                                    │
    ┌───────────┐   │   ┌──────────┐    ┌──────────┐    ┌──────────┐   │
    │ 군 INT    │───┼──▶│ C12 망연동│───▶│ C14 데이터│◀──▶│ C13 COP  │   │
    │ 이벤트    │   │   │ 서버     │    │ 수집 서버 │    │ 상황도   │   │
    │ 192.168.  │   │   │ .130.10  │    │ .130.12  │    │ .130.11  │   │
    │ 110.10    │   │   └──────────┘    └────┬─────┘    └────┬─────┘   │
    └───────────┘   │                        │               │         │
                    │                        ▼               │         │
        OPNSense-7  │                   ┌──────────┐         │         │
        (방화벽)     │                   │ C15 AI   │         │         │
                    │                   │ 요약 서버 │         │         │
                    │                   │ .130.13  │         │         │
                    │                   └────┬─────┘         │         │
                    │                        │               │         │
                    │                        ▼               ▼         │
                    │              ┌──────────────────────────────┐     │
                    │              │   C16 작전용 PC 1~5          │     │
                    │              │   .130.21 ~ .130.25          │     │
                    │              │   COP 지도 + AI 브리핑 열람   │     │
                    │              └──────────────────────────────┘     │
                    └──────────────────────────────────────────────────┘
```

---

> **문서 끝** — 이 문서는 사이버 훈련 환경 구축을 위한 기술 설계서이며, 실제 군사 시스템과 무관하다. 모든 IP, 크리덴셜, 도메인은 가상 환경 전용이다.
