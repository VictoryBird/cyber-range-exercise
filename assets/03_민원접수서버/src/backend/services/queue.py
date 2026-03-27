"""
민원 접수 서버 — Redis 큐 서비스
민원 처리 서버(INT)에 파일 변환 작업을 전달한다.
"""

import json
import logging
import redis
from config import settings

logger = logging.getLogger("minwon")

_redis_client = None


def get_redis():
    global _redis_client
    if _redis_client is None:
        try:
            _redis_client = redis.Redis(
                host=settings.REDIS_HOST,
                port=settings.REDIS_PORT,
                decode_responses=True,
            )
            _redis_client.ping()
            logger.info(f"Redis 연결 성공: {settings.REDIS_HOST}:{settings.REDIS_PORT}")
        except redis.ConnectionError:
            logger.warning(f"Redis 연결 실패: {settings.REDIS_HOST}:{settings.REDIS_PORT} — 큐 비활성")
            _redis_client = None
    return _redis_client


def publish_task(complaint_id: str, file_key: str, original_name: str):
    """민원 처리 서버에 파일 변환 작업 전달"""
    client = get_redis()
    if client is None:
        logger.warning(f"Redis 미연결 — 작업 전달 스킵: {complaint_id}/{file_key}")
        return False

    message = json.dumps({
        "complaint_id": complaint_id,
        "file_key": file_key,
        "original_name": original_name,
        "action": "convert",
    })

    client.lpush(settings.REDIS_QUEUE, message)
    logger.info(f"처리 작업 전달: {complaint_id}/{original_name}")
    return True
