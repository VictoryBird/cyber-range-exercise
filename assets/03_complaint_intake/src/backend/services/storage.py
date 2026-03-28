import boto3
from botocore.client import Config
import config


def _get_client():
    protocol = "https" if config.MINIO_SECURE else "http"
    return boto3.client(
        "s3",
        endpoint_url=f"{protocol}://{config.MINIO_ENDPOINT}",
        aws_access_key_id=config.MINIO_ACCESS_KEY,
        aws_secret_access_key=config.MINIO_SECRET_KEY,
        config=Config(signature_version="s3v4"),
        region_name="us-east-1",
    )


def upload(bucket: str, key: str, data: bytes, content_type: str) -> None:
    """MinIO에 파일을 업로드한다.

    [취약점] content_type을 클라이언트가 제공한 값 그대로 사용한다.
    Content-Type 스푸핑 가능: 악성 파일을 image/png 등 허용된 타입으로 위장 가능.
    올바른 구현: python-magic 등으로 실제 파일 시그니처를 검사해 Content-Type을 서버에서 결정한다.
    """
    client = _get_client()
    client.put_object(
        Bucket=bucket,
        Key=key,
        Body=data,
        ContentType=content_type,  # [취약 설정] 클라이언트 제공 Content-Type 그대로 저장
    )


def generate_presigned_url(key: str, expires: int = 3600) -> str:
    """지정된 오브젝트에 대한 Presigned URL을 생성한다."""
    client = _get_client()
    url = client.generate_presigned_url(
        "get_object",
        Params={"Bucket": config.MINIO_BUCKET, "Key": key},
        ExpiresIn=expires,
    )
    return url
