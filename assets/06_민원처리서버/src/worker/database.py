"""
민원 처리 서버 — PostgreSQL 데이터베이스 연결 관리.

처리 결과를 DB에 기록하고, 민원 상태를 업데이트한다.

[취약점] VULN-06-04: DB 자격증명이 환경변수(.env 파일)에 하드코딩되어 있으며,
  기본값에도 비밀번호가 포함되어 .env 파일 없이도 DB 접근 가능.
  올바른 구현: HashiCorp Vault 등 시크릿 관리 시스템에서 런타임 로딩
"""

import os
import logging
from datetime import datetime
from typing import List, Optional

import psycopg2
from psycopg2.extras import RealDictCursor

logger = logging.getLogger("complaint_worker.db")

# [취약점] VULN-06-04: 자격증명을 환경변수에서 직접 로딩, 기본값에도 비밀번호 하드코딩
# 올바른 구현: 기본값을 제공하지 않고, 환경변수 미설정 시 명시적 에러 발생
DB_CONFIG = {
    "host": os.getenv("DB_HOST", "192.168.100.20"),
    "port": int(os.getenv("DB_PORT", "5432")),
    "dbname": os.getenv("DB_NAME", "complaints"),
    "user": os.getenv("DB_USER", "app_service"),
    "password": os.getenv("DB_PASSWORD", "Sup3rS3cr3t!"),  # [취약점] VULN-06-04: 기본값에 비밀번호
}


def get_connection():
    """DB 연결을 반환한다."""
    return psycopg2.connect(**DB_CONFIG)


def update_complaint_status(complaint_id: str, status: str):
    """민원 처리 상태를 업데이트한다."""
    conn = get_connection()
    try:
        with conn.cursor() as cur:
            cur.execute(
                "UPDATE complaints SET status = %s, updated_at = %s WHERE id = %s",
                (status, datetime.utcnow(), complaint_id),
            )
        conn.commit()
        logger.info(f"[{complaint_id}] 상태 업데이트: {status}")
    except Exception as e:
        logger.error(f"DB 상태 업데이트 실패: {e}")
        conn.rollback()
    finally:
        conn.close()


def record_processing_result(
    complaint_id: str,
    original_filename: str,
    original_size: int,
    converted_files: List[str],
    file_type: str,
    processing_time: float,
    status: str,
    error_message: Optional[str] = None,
):
    """파일 처리 결과를 DB에 기록한다."""
    conn = get_connection()
    try:
        with conn.cursor() as cur:
            cur.execute(
                """
                INSERT INTO complaint_file_processing
                    (complaint_id, original_filename, original_size,
                     converted_files, file_type, processing_time_sec,
                     status, error_message, processed_at)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
                """,
                (
                    complaint_id,
                    original_filename,
                    original_size,
                    converted_files,
                    file_type,
                    processing_time,
                    status,
                    error_message,
                    datetime.utcnow(),
                ),
            )
        conn.commit()
        logger.info(f"[{complaint_id}] 처리 결과 기록 완료: {status}")
    except Exception as e:
        logger.error(f"DB 처리 결과 기록 실패: {e}")
        conn.rollback()
    finally:
        conn.close()
