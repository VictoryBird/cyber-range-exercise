import json
import redis
import config


def _get_client() -> redis.Redis:
    return redis.Redis(
        host=config.REDIS_HOST,
        port=config.REDIS_PORT,
        decode_responses=True,
    )


def publish(queue_name: str, message: dict) -> None:
    """Redis 큐에 메시지를 LPUSH 한다."""
    r = _get_client()
    r.lpush(queue_name, json.dumps(message))


def log_upload_event(event: dict) -> None:
    """파일 업로드 이벤트를 upload_events 리스트에 기록한다."""
    r = _get_client()
    r.lpush("upload_events", json.dumps(event))
