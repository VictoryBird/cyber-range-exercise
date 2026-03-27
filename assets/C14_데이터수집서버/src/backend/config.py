"""
C14 데이터 수집·관리 서버 — 설정 모듈
파일 경로: /opt/datacollector/app/config.py
"""

import os
from urllib.parse import quote_plus

# 데이터베이스 설정
DB_HOST = os.getenv("DB_HOST", "localhost")
DB_PORT = int(os.getenv("DB_PORT", "5432"))
DB_NAME = os.getenv("DB_NAME", "events_db")
DB_USER = os.getenv("DB_USER", "events_user")
DB_PASS = os.getenv("DB_PASS", "Ev3nts!C4I#2024")

DATABASE_URL = f"postgresql://{DB_USER}:{quote_plus(DB_PASS)}@{DB_HOST}:{DB_PORT}/{DB_NAME}"

# API 키
API_KEY = os.getenv("API_KEY", "dev-key-12345")
ADMIN_KEY = os.getenv("ADMIN_KEY", "admin-key-99999")
