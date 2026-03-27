"""
민원 처리 서버 — Celery 애플리케이션 설정.

Redis를 브로커/결과 백엔드로 사용하는 Celery 워커를 구성한다.
"""

import os
from celery import Celery
from dotenv import load_dotenv

load_dotenv()

# Celery 앱 생성
app = Celery("complaint_worker")

# --- 브로커 및 결과 백엔드 ---
# [취약점] VULN-06-03: Redis 무인증 URL — 인증 토큰 없음
# 올바른 구현: redis://:StrongPassword@host:6379/0
app.conf.broker_url = os.getenv(
    "CELERY_BROKER_URL", "redis://192.168.100.12:6379/0"
)
app.conf.result_backend = os.getenv(
    "CELERY_RESULT_BACKEND", "redis://192.168.100.12:6379/1"
)

# --- 직렬화 설정 ---
app.conf.task_serializer = "json"
app.conf.result_serializer = "json"
# [취약점] pickle 직렬화 허용 — 역직렬화 공격 가능
# 올바른 구현: accept_content = ["json"]
app.conf.accept_content = ["json", "pickle"]

# --- 워커 설정 ---
app.conf.worker_concurrency = int(os.getenv("WORKER_CONCURRENCY", "3"))
app.conf.worker_prefetch_multiplier = 1
app.conf.task_acks_late = True

# --- 작업 큐 설정 ---
app.conf.task_queues = {
    "file_convert": {
        "exchange": "file_convert",
        "routing_key": "file_convert",
    },
}
app.conf.task_default_queue = "file_convert"

# --- 작업 제한 시간 ---
app.conf.task_soft_time_limit = 300   # 5분
app.conf.task_time_limit = 600        # 10분 (하드 리밋)

# --- 로깅 ---
app.conf.worker_hijack_root_logger = False
app.conf.worker_log_format = (
    "[%(asctime)s: %(levelname)s/%(processName)s] %(message)s"
)

# 태스크 모듈 자동 검색
app.autodiscover_tasks(["worker"], related_name="tasks")
