"""
민원 처리 서버 — 환경변수 로딩 모듈.

모든 설정값을 환경변수에서 로딩하며, 기본값을 제공한다.
"""

import os
from dotenv import load_dotenv

load_dotenv()


class Config:
    """애플리케이션 설정."""

    # Redis / Celery
    REDIS_URL: str = os.getenv("REDIS_URL", "redis://192.168.100.12:6379/0")
    CELERY_BROKER_URL: str = os.getenv("CELERY_BROKER_URL", "redis://192.168.100.12:6379/0")
    CELERY_RESULT_BACKEND: str = os.getenv("CELERY_RESULT_BACKEND", "redis://192.168.100.12:6379/1")

    # MinIO
    MINIO_ENDPOINT: str = os.getenv("MINIO_ENDPOINT", "203.238.140.12:9000")
    MINIO_ACCESS_KEY: str = os.getenv("MINIO_ACCESS_KEY", "minio_complaint_svc")
    MINIO_SECRET_KEY: str = os.getenv("MINIO_SECRET_KEY", "minio_S3cr3tK3y_2026!")
    MINIO_BUCKET: str = os.getenv("MINIO_BUCKET", "complaints")
    MINIO_USE_SSL: bool = os.getenv("MINIO_USE_SSL", "false").lower() == "true"

    # PostgreSQL
    # [취약점] VULN-06-04: DB 자격증명이 기본값에도 하드코딩
    # 올바른 구현: 기본값을 제공하지 않고, 환경변수 미설정 시 에러 발생
    DB_HOST: str = os.getenv("DB_HOST", "192.168.100.20")
    DB_PORT: int = int(os.getenv("DB_PORT", "5432"))
    DB_NAME: str = os.getenv("DB_NAME", "complaints")
    DB_USER: str = os.getenv("DB_USER", "app_service")
    DB_PASSWORD: str = os.getenv("DB_PASSWORD", "Sup3rS3cr3t!")  # [취약점] VULN-06-04

    # Worker
    WORKER_CONCURRENCY: int = int(os.getenv("WORKER_CONCURRENCY", "3"))
    PROCESSING_TEMP_DIR: str = os.getenv("PROCESSING_TEMP_DIR", "/tmp/processing")
    LIBREOFFICE_PATH: str = os.getenv("LIBREOFFICE_PATH", "/usr/bin/soffice")
    LOG_LEVEL: str = os.getenv("LOG_LEVEL", "INFO")

    # Sentry
    SENTRY_DSN: str = os.getenv("SENTRY_DSN", "")


config = Config()
