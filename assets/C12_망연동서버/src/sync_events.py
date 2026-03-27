#!/usr/bin/env python3
"""
C4I 망 연동 서버 — 이벤트 동기화 스크립트
INT 존 이벤트 소스에서 신규 작전 이벤트를 수집하여 C4I 데이터 수집 서버로 전달한다.

실행 방식: systemd timer (30초 주기)
실행 권한: root (★ VULN-C12-02: 불필요한 root 권한)

파일 경로: /opt/relay/scripts/sync_events.py
"""

import json
import logging
import os
import sys
from datetime import datetime, timedelta, timezone

import requests

# ============================================================
# 설정 (★ VULN-C12-01: 크리덴셜 및 API 키 하드코딩)
# [취약점] VULN-C12-01: SSH 크리덴셜과 API 키가 소스 코드에 하드코딩됨
# [올바른 구현] 환경변수 또는 시크릿 관리 도구(Vault 등)에서 읽어와야 함
# ============================================================
INT_EVENT_SOURCE = "http://192.168.110.10:8080/api/events"
C4I_DATA_API = "http://192.168.130.12:8000/api/events"
C4I_API_KEY = "dev-key-12345"  # ★ 하드코딩된 API 키

# [취약점] VULN-C12-01: SSH 크리덴셜 하드코딩 (원격 점검용으로 남겨진 잔여 코드)
# [올바른 구현] SSH 키 기반 인증을 사용하고, 크리덴셜은 코드에 포함하지 않아야 함
SSH_USER = "relay-admin"
SSH_PASS = "R3lay!Sync#2024"
SSH_HOST = "192.168.110.10"

LAST_SYNC_FILE = "/opt/relay/data/last_sync.txt"
LOG_FILE = "/opt/relay/logs/sync.log"

# ============================================================
# 로깅 설정
# ============================================================
os.makedirs(os.path.dirname(LOG_FILE), exist_ok=True)

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    handlers=[
        logging.FileHandler(LOG_FILE),
        logging.StreamHandler(sys.stdout),
    ],
)
logger = logging.getLogger("relay-sync")


def get_last_sync_time():
    """마지막 동기화 시각을 파일에서 읽어온다."""
    try:
        with open(LAST_SYNC_FILE, "r") as f:
            ts = f.read().strip()
            return ts
    except FileNotFoundError:
        # 파일이 없으면 24시간 전부터 수집
        default = (datetime.now(timezone.utc) - timedelta(hours=24)).isoformat()
        logger.info(f"last_sync 파일 없음, 기본값 사용: {default}")
        return default


def save_last_sync_time(ts):
    """마지막 동기화 시각을 파일에 기록한다."""
    os.makedirs(os.path.dirname(LAST_SYNC_FILE), exist_ok=True)
    with open(LAST_SYNC_FILE, "w") as f:
        f.write(ts)


def fetch_events_from_int(since):
    """
    INT 존 이벤트 소스에서 신규 이벤트를 조회한다.

    Args:
        since: ISO 8601 형식 타임스탬프 (이 시각 이후 이벤트만 조회)

    Returns:
        list: 이벤트 목록
    """
    try:
        resp = requests.get(
            INT_EVENT_SOURCE,
            params={"since": since, "limit": 500},
            timeout=30,
        )
        resp.raise_for_status()
        events = resp.json()
        logger.info(f"INT에서 {len(events)}건 이벤트 수신")
        return events
    except requests.RequestException as e:
        logger.error(f"INT 이벤트 조회 실패: {e}")
        return []


def transform_event(raw_event):
    """
    INT 포맷 이벤트를 C4I 표준 포맷으로 변환한다.

    INT 포맷:
        {
            "event_id": "EVT-001",
            "event_type": "friendly_move",
            "unit_name": "제1보병대대",
            "lat": 37.5665, "lng": 126.978,
            "event_time": "2026-03-26T10:00:00Z",
            "priority_level": "medium"
        }

    C4I 포맷:
        {
            "type": "friendly_move",
            "unit": "제1보병대대",
            "location": {"lat": 37.5665, "lng": 126.978},
            "timestamp": "2026-03-26T10:00:00Z",
            "priority": "medium",
            "source": "relay",
            "verified": false
        }
    """
    try:
        c4i_event = {
            "type": raw_event.get("event_type", "unknown"),
            "unit": raw_event.get("unit_name", "불명"),
            "location": {
                "lat": float(raw_event.get("lat", 0)),
                "lng": float(raw_event.get("lng", 0)),
            },
            "timestamp": raw_event.get("event_time", datetime.now(timezone.utc).isoformat()),
            "priority": raw_event.get("priority_level", "low"),
            "source": "relay",
            "verified": False,
        }
        return c4i_event
    except (ValueError, TypeError) as e:
        logger.warning(f"이벤트 변환 실패: {e}, 원본: {raw_event}")
        return None


# ============================================================
# [취약점] VULN-C12-03: 무결성 검증 부재
# [올바른 구현] 스크립트 파일의 SHA-256 해시를 사전에 기록해두고,
#              실행 시마다 해시를 비교하여 변조 여부를 확인해야 함.
#              예: hashlib.sha256(open(__file__,'rb').read()).hexdigest()를
#              /opt/relay/config/integrity.hash 파일의 값과 비교
# ============================================================


def send_to_data_collector(events):
    """
    변환된 이벤트를 C14 데이터 수집 API로 전송한다.

    Args:
        events: C4I 포맷 이벤트 목록

    Returns:
        int: 성공적으로 전송된 이벤트 수
    """
    success_count = 0
    for event in events:
        try:
            resp = requests.post(
                C4I_DATA_API,
                json=event,
                headers={
                    "X-API-Key": C4I_API_KEY,
                    "Content-Type": "application/json",
                },
                timeout=10,
            )
            if resp.status_code in (200, 201):
                success_count += 1
            else:
                logger.warning(
                    f"이벤트 전송 실패 (HTTP {resp.status_code}): {resp.text}"
                )
        except requests.RequestException as e:
            logger.error(f"이벤트 전송 오류: {e}")
    return success_count


def main():
    """메인 동기화 루프"""
    logger.info("=" * 60)
    logger.info("C4I 망 연동 동기화 시작")
    logger.info("=" * 60)

    # 1. 마지막 동기화 시각 확인
    last_sync = get_last_sync_time()
    logger.info(f"마지막 동기화: {last_sync}")

    # 2. INT에서 신규 이벤트 조회
    raw_events = fetch_events_from_int(last_sync)
    if not raw_events:
        logger.info("동기화할 신규 이벤트 없음")
        return

    # 3. 이벤트 변환
    transformed = []
    for raw in raw_events:
        event = transform_event(raw)
        if event:
            transformed.append(event)

    logger.info(f"변환 완료: {len(transformed)}/{len(raw_events)}건")

    # 4. C14로 전송
    sent = send_to_data_collector(transformed)
    logger.info(f"전송 완료: {sent}/{len(transformed)}건")

    # 5. 동기화 시각 갱신
    now = datetime.now(timezone.utc).isoformat()
    save_last_sync_time(now)
    logger.info(f"동기화 완료, 다음 동기화 기준: {now}")


if __name__ == "__main__":
    main()
