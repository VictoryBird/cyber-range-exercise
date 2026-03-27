"""설정 관리"""

import os
from urllib.parse import quote_plus
from dotenv import load_dotenv

load_dotenv()

_DB_PASSWORD = os.getenv("DB_PASSWORD", "DocStore2026!")
_DB_USER = os.getenv("DB_USER", "docstorage")
_DB_HOST = os.getenv("DB_HOST", "localhost")
_DB_PORT = os.getenv("DB_PORT", "5432")
_DB_NAME = os.getenv("DB_NAME", "mil_docstorage")
_DEFAULT_DB_URL = f"postgresql://{_DB_USER}:{quote_plus(_DB_PASSWORD)}@{_DB_HOST}:{_DB_PORT}/{_DB_NAME}"


class Settings:
    APP_HOST: str = os.getenv("APP_HOST", "0.0.0.0")
    APP_PORT: int = int(os.getenv("APP_PORT", "8000"))
    DATABASE_URL: str = os.getenv("DATABASE_URL", _DEFAULT_DB_URL)

    # JWT 설정
    JWT_SECRET: str = os.getenv("JWT_SECRET", "mil_docstorage_jwt_secret_key_2026")
    JWT_ALGORITHM: str = os.getenv("JWT_ALGORITHM", "HS256")
    JWT_EXPIRATION: int = int(os.getenv("JWT_EXPIRATION", "3600"))

    # 파일 설정
    UPLOAD_DIR: str = os.getenv("UPLOAD_DIR", "/opt/docstorage/files")
    MAX_UPLOAD_SIZE: int = int(os.getenv("MAX_UPLOAD_SIZE", "52428800"))

    # 디버그 모드
    DEBUG: bool = os.getenv("DEBUG", "true").lower() == "true"


settings = Settings()
