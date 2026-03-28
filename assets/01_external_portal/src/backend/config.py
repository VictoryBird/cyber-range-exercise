"""
Application Configuration
Asset 01: External Portal Server (192.168.92.201)
"""

import os
from urllib.parse import quote_plus
from dotenv import load_dotenv

load_dotenv()


class Settings:
    APP_NAME: str = os.getenv("APP_NAME", "MOIS Portal")
    VERSION: str = os.getenv("APP_VERSION", "1.2.0")
    ENVIRONMENT: str = os.getenv("ENVIRONMENT", "production")
    DEBUG: bool = os.getenv("DEBUG", "false").lower() == "true"

    # Database
    DB_HOST: str = os.getenv("DB_HOST", "192.168.92.208")
    DB_PORT: int = int(os.getenv("DB_PORT", "5432"))
    DB_NAME: str = os.getenv("DB_NAME", "mois_portal")
    DB_USER: str = os.getenv("DB_USER", "portal_app")
    DB_PASSWORD: str = os.getenv("DB_PASSWORD", "P0rtal#DB@2026!")

    # JWT
    JWT_SECRET: str = os.getenv("JWT_SECRET", "valdoria-mois-jwt-secret-key-2026")
    JWT_ALGORITHM: str = os.getenv("JWT_ALGORITHM", "HS256")
    JWT_EXPIRE_MINUTES: int = int(os.getenv("JWT_EXPIRE_MINUTES", "60"))

    # CORS
    # CLAUDE.md: ALLOWED_ORIGINS as JSON array format in .env
    ALLOWED_ORIGINS: list = ["https://www.mois.valdoria.gov"]

    # Logging
    LOG_LEVEL: str = os.getenv("LOG_LEVEL", "INFO")
    LOG_FILE: str = os.getenv("LOG_FILE", "/var/log/mois-portal/app.log")

    @property
    def DATABASE_URL(self) -> str:
        # CLAUDE.md: URL-encode password with quote_plus() — password contains # and !
        password = quote_plus(self.DB_PASSWORD)
        return f"postgresql+asyncpg://{self.DB_USER}:{password}@{self.DB_HOST}:{self.DB_PORT}/{self.DB_NAME}"


settings = Settings()
