"""
외부 포털 서버 — 설정 모듈
.env 파일에서 환경변수를 로드하여 애플리케이션 전역에서 사용한다.

[취약 설정] DB 크리덴셜이 .env 파일에 평문 저장됨
[취약 설정] JWT 시크릿 키가 추측 가능한 문자열
"""

from pydantic_settings import BaseSettings
from typing import List


class Settings(BaseSettings):
    # 서버 기본 설정
    APP_NAME: str = "MOIS Portal"
    VERSION: str = "1.2.0"
    ENVIRONMENT: str = "production"
    DEBUG: bool = False
    HOST: str = "0.0.0.0"
    PORT: int = 8000

    # 도메인 설정
    DOMAIN: str = "www.mois.valdoria.gov"
    ALLOWED_ORIGINS: List[str] = [
        "https://www.mois.valdoria.gov",
        "http://203.238.140.10",
    ]

    # 데이터베이스 설정
    # [취약 설정] 하드코딩된 크리덴셜 — 민원처리서버 침해 시 설정파일 탈취로 DB 직접 접속 가능
    DB_HOST: str = "192.168.100.20"
    DB_PORT: int = 5432
    DB_NAME: str = "mois_portal"
    DB_USER: str = "portal_app"
    DB_PASSWORD: str = "P0rtal#DB@2026!"

    # JWT 인증 설정
    # [취약 설정] 추측 가능한 시크릿 키
    JWT_SECRET: str = "valdoria-mois-jwt-secret-key-2026"
    JWT_ALGORITHM: str = "HS256"
    JWT_EXPIRE_MINUTES: int = 60

    # 로깅 설정
    LOG_LEVEL: str = "INFO"
    LOG_FILE: str = "/var/log/mois-portal/app.log"

    @property
    def database_url(self) -> str:
        from urllib.parse import quote_plus
        password = quote_plus(self.DB_PASSWORD)
        return f"postgresql+asyncpg://{self.DB_USER}:{password}@{self.DB_HOST}:{self.DB_PORT}/{self.DB_NAME}"

    @property
    def database_url_sync(self) -> str:
        return f"postgresql://{self.DB_USER}:{self.DB_PASSWORD}@{self.DB_HOST}:{self.DB_PORT}/{self.DB_NAME}"

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"


settings = Settings()
