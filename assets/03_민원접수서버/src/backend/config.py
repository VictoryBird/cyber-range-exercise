"""
민원 접수 서버 — 설정 모듈
"""

from pydantic_settings import BaseSettings
from typing import List


class Settings(BaseSettings):
    API_HOST: str = "0.0.0.0"
    API_PORT: int = 8000
    API_LOG_LEVEL: str = "info"
    ADMIN_TOKEN: str = "admin-token-mois-2026"

    MINIO_ENDPOINT: str = "203.238.140.12:9000"
    MINIO_ACCESS_KEY: str = "minio_access"
    MINIO_SECRET_KEY: str = "minio_secret123"
    MINIO_BUCKET: str = "complaints"
    MINIO_SECURE: bool = False

    REDIS_HOST: str = "192.168.100.10"
    REDIS_PORT: int = 6379
    REDIS_QUEUE: str = "complaint_processing"

    ALLOWED_EXTENSIONS: str = ".pdf,.jpg,.jpeg,.png,.docx,.xlsx"
    MAX_UPLOAD_SIZE: int = 52428800

    LOG_DIR: str = "/var/log/minwon"

    @property
    def allowed_ext_list(self) -> List[str]:
        return [e.strip() for e in self.ALLOWED_EXTENSIONS.split(",")]

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"


settings = Settings()
