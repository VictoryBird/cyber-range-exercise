"""
Celery 설정 — 민원 파일 처리 워커
Asset 06: Complaint Processing Server (192.168.92.206)
"""

import os
from dotenv import load_dotenv

load_dotenv()

# ──────────────────────────────────────────────
# 브로커 및 결과 백엔드
# ──────────────────────────────────────────────
broker_url = os.environ.get("CELERY_BROKER_URL", "redis://192.168.92.206:6379/0")
result_backend = os.environ.get("CELERY_RESULT_BACKEND", "redis://192.168.92.206:6379/1")

# ──────────────────────────────────────────────
# 직렬화 설정
#
# [취약점] VULN-06-01: Pickle 역직렬화 공격 (Insecure Deserialization)
#   accept_content에 "pickle"을 포함하면 공격자가 조작된 pickle 페이로드를
#   브로커(Redis)에 주입하여 워커 프로세스에서 임의 코드 실행(RCE) 가능.
#   Redis가 인증 없이 열려 있거나 네트워크 접근이 가능한 경우 즉시 악용 가능.
#
#   안전한 구현:
#     task_serializer = "json"
#     result_serializer = "json"
#     accept_content = ["json"]
#
#   참고: https://docs.celeryq.dev/en/stable/userguide/security.html
# ──────────────────────────────────────────────
task_serializer = "pickle"          # [취약 설정] json으로 교체해야 함
result_serializer = "pickle"        # [취약 설정] json으로 교체해야 함
accept_content = ["pickle", "json"] # [취약 설정] ["json"]만 허용해야 함

# ──────────────────────────────────────────────
# 큐 설정
# ──────────────────────────────────────────────
task_default_queue = "file_convert"
task_queues = {
    "file_convert": {
        "exchange": "file_convert",
        "routing_key": "file_convert",
    }
}

# ──────────────────────────────────────────────
# 태스크 실행 설정
# ──────────────────────────────────────────────
task_acks_late = True               # 태스크 완료 후 ACK (재처리 보장)
worker_prefetch_multiplier = 1      # 파일 처리는 무거우므로 1개씩 가져옴
task_track_started = True
task_time_limit = 600               # 10분 하드 타임아웃
task_soft_time_limit = 540          # 9분 소프트 타임아웃

# ──────────────────────────────────────────────
# 재시도 설정 (태스크 레벨에서 개별 제어하지만 기본값 설정)
# ──────────────────────────────────────────────
task_max_retries = 3
task_default_retry_delay = 10       # 10초 후 재시도

# ──────────────────────────────────────────────
# 로깅
# ──────────────────────────────────────────────
worker_log_format = "[%(asctime)s: %(levelname)s/%(processName)s] %(message)s"
worker_task_log_format = "[%(asctime)s: %(levelname)s/%(processName)s][%(task_name)s(%(task_id)s)] %(message)s"

# ──────────────────────────────────────────────
# 결과 만료
# ──────────────────────────────────────────────
result_expires = 3600               # 1시간 후 결과 삭제

# ──────────────────────────────────────────────
# 타임존
# ──────────────────────────────────────────────
timezone = "Asia/Seoul"
enable_utc = True
