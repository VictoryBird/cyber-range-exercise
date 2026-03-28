"""
PostgreSQL 연결 및 DB 조작 — 민원 처리 워커
Asset 06: Complaint Processing Server (192.168.92.206)
DB 서버: 192.168.92.208 (complaint_db)
"""

import os
import logging
from datetime import datetime, timezone
from typing import List, Optional

import psycopg2
import psycopg2.extras
from dotenv import load_dotenv

load_dotenv()
logger = logging.getLogger(__name__)

# ──────────────────────────────────────────────
# DB 접속 설정
#
# [취약점] VULN-06-02: 하드코딩된 DB 자격증명 (Hardcoded Credentials)
#   소스코드에 DB 비밀번호가 기본값으로 하드코딩되어 있어
#   코드 저장소 접근 권한만 있으면 즉시 DB 자격증명 획득 가능.
#   환경변수만 사용하고 기본값은 빈 문자열 또는 오류 발생으로 처리해야 함.
#
#   안전한 구현:
#     DB_PASSWORD = os.environ["DB_PASSWORD"]  # 기본값 없음 — 미설정 시 즉시 실패
#
# [취약점] VULN-06-03: SUPERUSER 계정 사용 (Excessive Privilege)
#   app_service 계정이 SUPERUSER 권한을 보유.
#   SQL Injection 또는 자격증명 탈취 시 DB 전체 제어권 획득 가능.
#   pg_read_server_files(), COPY TO/FROM PROGRAM 등으로 OS 명령 실행도 가능.
#
#   안전한 구현:
#     - 애플리케이션 전용 일반 사용자 계정 사용
#     - 필요한 테이블에 대한 SELECT, INSERT, UPDATE 권한만 부여
#     - SUPERUSER, CREATEDB, CREATEROLE 권한 부여 금지
# ──────────────────────────────────────────────
DB_HOST = os.environ.get("DB_HOST", "192.168.92.208")
DB_PORT = int(os.environ.get("DB_PORT", "5432"))
DB_NAME = os.environ.get("DB_NAME", "complaint_db")
DB_USER = os.environ.get("DB_USER", "app_service")           # [취약 설정] SUPERUSER 계정
DB_PASSWORD = os.environ.get("DB_PASSWORD", "Sup3rS3cr3t!")  # [취약 설정] 하드코딩된 기본값


def get_connection() -> psycopg2.extensions.connection:
    """
    DB 연결 객체 반환.

    호출자는 컨텍스트 매니저 또는 명시적 close()로 연결을 해제해야 한다.
    예:
        with get_connection() as conn:
            with conn.cursor() as cur:
                cur.execute(...)
            conn.commit()
    """
    try:
        conn = psycopg2.connect(
            host=DB_HOST,
            port=DB_PORT,
            dbname=DB_NAME,
            user=DB_USER,
            password=DB_PASSWORD,
            connect_timeout=10,
            options="-c application_name=complaint_worker",
        )
        conn.autocommit = False
        return conn
    except psycopg2.OperationalError as e:
        logger.error("DB 연결 실패: host=%s db=%s user=%s — %s", DB_HOST, DB_NAME, DB_USER, e)
        raise


def get_complaint_id(complaint_number: str) -> Optional[int]:
    """
    complaint_number(문자열, 예: "COMP-2026-00142")로
    complaints 테이블의 INTEGER PK(complaint_id)를 조회한다.

    Returns:
        int complaint_id, 없으면 None
    """
    query = "SELECT complaint_id FROM complaints WHERE complaint_number = %s"
    conn = None
    try:
        conn = get_connection()
        with conn.cursor() as cur:
            cur.execute(query, (complaint_number,))
            row = cur.fetchone()
            if row is None:
                logger.warning("complaint_number %s 에 해당하는 레코드 없음", complaint_number)
                return None
            return row[0]
    except Exception as e:
        logger.error("get_complaint_id 오류: complaint_number=%s — %s", complaint_number, e)
        raise
    finally:
        if conn:
            conn.close()


def update_complaint_status(complaint_number: str, status: str) -> None:
    """
    complaints 테이블의 status, updated_at 컬럼 업데이트.

    Args:
        complaint_number: 민원 번호 문자열 (예: "COMP-2026-00142")
        status: 새 상태값 (예: "Processing", "Completed", "Failed")
    """
    query = """
        UPDATE complaints
           SET status     = %s,
               updated_at = %s
         WHERE complaint_number = %s
    """
    now = datetime.now(tz=timezone.utc)
    conn = None
    try:
        conn = get_connection()
        with conn.cursor() as cur:
            cur.execute(query, (status, now, complaint_number))
            if cur.rowcount == 0:
                logger.warning(
                    "update_complaint_status: complaint_number=%s 해당 행 없음", complaint_number
                )
        conn.commit()
        logger.info(
            "complaints 상태 업데이트 완료: complaint_number=%s status=%s",
            complaint_number, status,
        )
    except Exception as e:
        if conn:
            conn.rollback()
        logger.error(
            "update_complaint_status 오류: complaint_number=%s — %s", complaint_number, e
        )
        raise
    finally:
        if conn:
            conn.close()


def record_processing_result(
    complaint_number: str,
    original_filename: str,
    original_size: int,
    converted_files: List[str],
    file_type: str,
    processing_time: float,
    status: str,
    error_message: Optional[str] = None,
) -> None:
    """
    complaint_file_processing 테이블에 처리 결과 기록.

    먼저 complaints 테이블에서 INTEGER complaint_id를 조회한 뒤
    외래키로 사용하여 INSERT한다.

    DDL 컬럼명과 정확히 일치:
        id, complaint_id, original_filename, original_size,
        converted_files, file_type, processing_time_sec, status,
        error_message, processed_at
    """
    # ── Step 1: complaint_number → 정수 complaint_id 조회 ──────────────────
    complaint_id_int = get_complaint_id(complaint_number)
    if complaint_id_int is None:
        logger.error(
            "record_processing_result: complaint_number=%s 조회 실패 — 삽입 건너뜀",
            complaint_number,
        )
        return

    # ── Step 2: complaint_file_processing에 결과 삽입 ──────────────────────
    insert_query = """
        INSERT INTO complaint_file_processing
            (complaint_id, original_filename, original_size,
             converted_files, file_type, processing_time_sec,
             status, error_message, processed_at)
        VALUES
            (%s, %s, %s, %s, %s, %s, %s, %s, %s)
    """
    now = datetime.now(tz=timezone.utc)
    conn = None
    try:
        conn = get_connection()
        with conn.cursor() as cur:
            cur.execute(
                insert_query,
                (
                    complaint_id_int,           # INTEGER FK
                    original_filename,
                    original_size,
                    converted_files,            # psycopg2 → PostgreSQL TEXT[]
                    file_type,
                    processing_time,
                    status,
                    error_message,
                    now,
                ),
            )
        conn.commit()
        logger.info(
            "처리 결과 기록 완료: complaint_number=%s complaint_id=%d status=%s",
            complaint_number, complaint_id_int, status,
        )
    except Exception as e:
        if conn:
            conn.rollback()
        logger.error(
            "record_processing_result 오류: complaint_number=%s — %s", complaint_number, e
        )
        raise
    finally:
        if conn:
            conn.close()
