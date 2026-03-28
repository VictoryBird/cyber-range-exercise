"""
Database Connection (asyncpg direct, no databases library)
Asset 01: External Portal Server (192.168.92.201)
"""

import asyncpg
from config import settings
from urllib.parse import quote_plus


_pool: asyncpg.Pool = None


async def get_pool() -> asyncpg.Pool:
    global _pool
    if _pool is None:
        # CLAUDE.md: URL-encode password with quote_plus() — password contains # and !
        password = quote_plus(settings.DB_PASSWORD)
        dsn = f"postgresql://{settings.DB_USER}:{password}@{settings.DB_HOST}:{settings.DB_PORT}/{settings.DB_NAME}"
        _pool = await asyncpg.create_pool(
            dsn=dsn,
            min_size=2,
            max_size=10,
        )
    return _pool


async def close_pool():
    global _pool
    if _pool is not None:
        await _pool.close()
        _pool = None


async def get_db():
    """Dependency: yields an asyncpg connection from the pool."""
    pool = await get_pool()
    async with pool.acquire() as conn:
        yield conn
