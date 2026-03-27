"""
외부 포털 서버 — 데이터베이스 연결 모듈
databases 라이브러리로 비동기 PostgreSQL 연결을 관리한다.
"""

import databases
from config import settings

# 비동기 DB 연결 인스턴스
database = databases.Database(settings.database_url)


async def get_db():
    """FastAPI 의존성 주입용 DB 세션 제공"""
    return database


async def connect_db():
    """애플리케이션 시작 시 DB 연결"""
    await database.connect()


async def disconnect_db():
    """애플리케이션 종료 시 DB 연결 해제"""
    await database.disconnect()
