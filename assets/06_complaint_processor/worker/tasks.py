"""
Celery 태스크 정의 — 민원 파일 처리
Asset 06: Complaint Processing Server (192.168.92.206)

취약점 목록:
  VULN-06-09: 파일 내용 검증 없이 처리 (No Content Validation)
  VULN-06-10: 내부 경로 노출 (Information Disclosure via Error)
"""

import logging
import os
import shutil
import tempfile
from pathlib import Path

import structlog
from celery import Celery, Task
from celery.exceptions import MaxRetriesExceededError

from db import record_processing_result, update_complaint_status
from file_processor import FileProcessor
from storage import MinIOClient

# ──────────────────────────────────────────────
# Celery 앱 초기화
# ──────────────────────────────────────────────
app = Celery("complaint_worker")
app.config_from_object("celeryconfig")

# ──────────────────────────────────────────────
# 로거 설정
# ──────────────────────────────────────────────
structlog.configure(
    processors=[
        structlog.stdlib.add_log_level,
        structlog.stdlib.add_logger_name,
        structlog.processors.TimeStamper(fmt="iso"),
        structlog.processors.StackInfoRenderer(),
        structlog.processors.format_exc_info,
        structlog.processors.JSONRenderer(),
    ],
    wrapper_class=structlog.stdlib.BoundLogger,
    logger_factory=structlog.stdlib.LoggerFactory(),
)
logger = structlog.get_logger(__name__)

# ──────────────────────────────────────────────
# 상수
# ──────────────────────────────────────────────
MINIO_INPUT_PREFIX  = os.environ.get("MINIO_INPUT_PREFIX",  "uploads")
MINIO_OUTPUT_PREFIX = os.environ.get("MINIO_OUTPUT_PREFIX", "processed")


class BaseTask(Task):
    """공통 기반 태스크: 싱글턴 클라이언트 보관."""
    _storage: MinIOClient | None  = None
    _processor: FileProcessor | None = None

    @property
    def storage(self) -> MinIOClient:
        if self._storage is None:
            self._storage = MinIOClient()
        return self._storage

    @property
    def processor(self) -> FileProcessor:
        if self._processor is None:
            self._processor = FileProcessor()
        return self._processor


@app.task(
    bind=True,
    base=BaseTask,
    name="complaint_worker.process_file",
    queue="file_convert",
    max_retries=3,
    default_retry_delay=10,
    acks_late=True,
)
def process_file(self, complaint_id: str, filename: str) -> dict:
    """
    민원 첨부파일을 MinIO에서 내려받아 변환한 뒤 결과를 다시 업로드하고
    DB에 처리 결과를 기록한다.

    NOTE: complaint_id 파라미터는 실제로는 complaint_number 문자열이다.
          예) "COMP-2026-00142"
          DB에서는 complaint_number 컬럼으로 조회하며 INTEGER PK는
          db.get_complaint_id()로 별도 조회한다.

    [취약점] VULN-06-09: 파일 내용 검증 없이 처리 (No Content Validation Before Processing)
      MinIO에서 내려받은 파일의 크기, 파일 타입, 악성 여부를 전혀 검사하지 않고
      바로 FileProcessor로 전달한다.
      공격자가 조작된 파일(예: zip bomb, 악성 매크로가 포함된 .docx)을 업로드하면
      워커 프로세스가 파일을 그대로 처리하게 됨.

      안전한 구현:
        # 크기 제한
        if local_path.stat().st_size > 50 * 1024 * 1024:  # 50MB
            raise ValueError("파일 크기 초과")
        # MIME 타입 화이트리스트 검사
        allowed_mimes = {"application/pdf", "image/jpeg", ...}
        if magic.from_file(str(local_path), mime=True) not in allowed_mimes:
            raise ValueError("허용되지 않는 파일 타입")
        # 바이러스 검사 (ClamAV 연동)
        scan_result = clamd.scan_file(str(local_path))
        if scan_result and "FOUND" in str(scan_result):
            raise ValueError("악성 파일 탐지")

    [취약점] VULN-06-10: 오류 메시지에 내부 경로 노출 (Information Disclosure via Error)
      예외 발생 시 str(e) 전체를 DB의 error_message 컬럼과 태스크 응답에 포함시켜
      서버 내부 디렉토리 구조, 파일명, 설정 정보 등이 외부에 노출될 수 있음.

      안전한 구현:
        error_msg = "파일 처리 중 오류가 발생했습니다."
        logger.exception("내부 오류", complaint_number=complaint_id, filename=filename)
        # 내부 상세 오류는 로그에만 기록

    Args:
        complaint_id: 실제로는 complaint_number 문자열 (예: "COMP-2026-00142")
        filename:     MinIO에 저장된 원본 파일명 (오브젝트 키의 마지막 부분)
    """
    complaint_number = complaint_id  # 의미 명확화를 위한 별칭

    log = logger.bind(complaint_number=complaint_number, filename=filename, task_id=self.request.id)
    log.info("파일 처리 태스크 시작")

    # MinIO 오브젝트 키 구성
    s3_input_key = f"{MINIO_INPUT_PREFIX}/{complaint_number}/{filename}"

    work_dir = None
    try:
        # ── 1. 상태 업데이트: Processing ──────────────────────────────────
        update_complaint_status(complaint_number, "Processing")

        # ── 2. 임시 작업 디렉토리 생성 ─────────────────────────────────────
        work_dir = Path(tempfile.mkdtemp(prefix=f"complaint_{complaint_number}_"))
        local_input = work_dir / filename
        log.debug("임시 디렉토리 생성: %s", work_dir)

        # ── 3. MinIO에서 원본 파일 다운로드 ───────────────────────────────
        self.storage.download_file(s3_input_key, local_input)
        original_size = local_input.stat().st_size
        log.info("다운로드 완료: %d bytes", original_size)

        # ── 4. 파일 처리 (변환 파이프라인) ────────────────────────────────
        # [취약 설정] 내용 검증 없이 바로 처리 — VULN-06-09
        result = self.processor.process(local_input, work_dir)
        log.info(
            "파일 처리 완료: status=%s file_type=%s converted=%d개",
            result["status"], result["file_type"], len(result["converted_files"]),
        )

        # ── 5. 변환 결과물 MinIO 업로드 ───────────────────────────────────
        uploaded_keys: list[str] = []
        for converted_path_str in result["converted_files"]:
            converted_path = Path(converted_path_str)
            if not converted_path.exists():
                log.warning("변환 파일 없음 — 건너뜀: %s", converted_path)
                continue
            s3_out_key = f"{MINIO_OUTPUT_PREFIX}/{complaint_number}/{converted_path.name}"
            self.storage.upload_file(converted_path, s3_out_key)
            uploaded_keys.append(s3_out_key)
            log.debug("업로드 완료: %s", s3_out_key)

        # ── 6. 민원 상태 업데이트 ─────────────────────────────────────────
        final_status = "Completed" if result["status"] == "success" else "Failed"
        update_complaint_status(complaint_number, final_status)

        # ── 7. DB에 처리 결과 기록 ────────────────────────────────────────
        record_processing_result(
            complaint_number=complaint_number,
            original_filename=filename,
            original_size=original_size,
            converted_files=uploaded_keys,
            file_type=result["file_type"],
            processing_time=result["processing_time_sec"],
            status=result["status"],
            error_message=result.get("error"),  # [취약 설정] 내부 경로 포함 가능 — VULN-06-10
        )

        log.info("태스크 완료: complaint_number=%s status=%s", complaint_number, final_status)
        return {
            "complaint_number": complaint_number,
            "status": final_status,
            "uploaded_files": uploaded_keys,
            "file_type": result["file_type"],
            "processing_time_sec": result["processing_time_sec"],
        }

    except Exception as exc:
        # ──────────────────────────────────────────────────────────────────
        # [취약 설정] str(exc)를 응답/DB에 직접 포함 — VULN-06-10
        #   안전한 구현: 범용 오류 메시지만 반환하고 상세 내용은 로그에만 기록
        # ──────────────────────────────────────────────────────────────────
        error_msg = str(exc)  # [취약 설정] 내부 경로 등 민감 정보 노출 가능
        log.error("태스크 오류: %s", error_msg, exc_info=True)

        # 재시도 가능한 경우 재시도 (최대 3회)
        try:
            # DB 상태를 Retrying으로 업데이트 후 재시도
            update_complaint_status(complaint_number, "Retrying")
            raise self.retry(exc=exc, countdown=10 * (self.request.retries + 1))
        except MaxRetriesExceededError:
            log.error("최대 재시도 초과: complaint_number=%s", complaint_number)
            # 최종 실패 처리
            try:
                update_complaint_status(complaint_number, "Failed")
                record_processing_result(
                    complaint_number=complaint_number,
                    original_filename=filename,
                    original_size=0,
                    converted_files=[],
                    file_type="unknown",
                    processing_time=0.0,
                    status="failed",
                    error_message=error_msg,  # [취약 설정]
                )
            except Exception as db_exc:
                log.error("실패 기록 중 추가 오류: %s", db_exc)
            raise

    finally:
        # 임시 작업 디렉토리 정리
        if work_dir and work_dir.exists():
            try:
                shutil.rmtree(work_dir)
                log.debug("임시 디렉토리 정리 완료: %s", work_dir)
            except Exception as cleanup_exc:
                log.warning("임시 디렉토리 정리 실패: %s — %s", work_dir, cleanup_exc)
