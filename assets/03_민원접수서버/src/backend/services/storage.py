"""
민원 접수 서버 — MinIO 스토리지 서비스
S3 호환 오브젝트 스토리지에 파일을 저장하고 presigned URL을 생성한다.
"""

import boto3
from botocore.client import Config as BotoConfig
from config import settings

_s3_client = None


def get_s3_client():
    global _s3_client
    if _s3_client is None:
        _s3_client = boto3.client(
            "s3",
            endpoint_url=f"http{'s' if settings.MINIO_SECURE else ''}://{settings.MINIO_ENDPOINT}",
            aws_access_key_id=settings.MINIO_ACCESS_KEY,
            aws_secret_access_key=settings.MINIO_SECRET_KEY,
            config=BotoConfig(signature_version="s3v4"),
            region_name="us-east-1",
        )
    return _s3_client


def ensure_bucket():
    """complaints 버킷이 없으면 생성"""
    client = get_s3_client()
    try:
        client.head_bucket(Bucket=settings.MINIO_BUCKET)
    except Exception:
        client.create_bucket(Bucket=settings.MINIO_BUCKET)


def upload_file(file_key: str, file_data: bytes, content_type: str) -> str:
    """파일을 MinIO에 업로드하고 키를 반환"""
    client = get_s3_client()
    client.put_object(
        Bucket=settings.MINIO_BUCKET,
        Key=file_key,
        Body=file_data,
        ContentType=content_type,
    )
    return file_key


def generate_presigned_url(file_key: str, expires: int = 3600) -> str:
    """
    presigned URL 생성

    [취약점 #3] 요청자와 민원 소유자의 일치 여부를 검증하지 않음
    complaint_id와 file_key만 알면 누구나 파일 다운로드 가능
    """
    client = get_s3_client()
    return client.generate_presigned_url(
        "get_object",
        Params={"Bucket": settings.MINIO_BUCKET, "Key": file_key},
        ExpiresIn=expires,
    )
