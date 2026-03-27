"""
민원 처리 서버 — MinIO S3 호환 스토리지 클라이언트.

DMZ의 MinIO(203.238.140.12:9000)에서 민원 첨부파일을 다운로드하고,
처리 결과를 업로드한다.
"""

import os
import logging

import boto3
from botocore.config import Config as BotoConfig

logger = logging.getLogger("complaint_worker.storage")


class MinIOClient:
    """MinIO S3 API 클라이언트."""

    def __init__(self):
        self.endpoint = os.getenv("MINIO_ENDPOINT", "203.238.140.12:9000")
        self.access_key = os.getenv("MINIO_ACCESS_KEY")
        self.secret_key = os.getenv("MINIO_SECRET_KEY")
        self.bucket = os.getenv("MINIO_BUCKET", "complaints")
        self.use_ssl = os.getenv("MINIO_USE_SSL", "false").lower() == "true"

        protocol = "https" if self.use_ssl else "http"

        self.s3 = boto3.client(
            "s3",
            endpoint_url=f"{protocol}://{self.endpoint}",
            aws_access_key_id=self.access_key,
            aws_secret_access_key=self.secret_key,
            config=BotoConfig(signature_version="s3v4"),
            region_name="us-east-1",  # MinIO 기본값
        )

    def download_file(self, s3_key: str, local_path: str):
        """S3에서 파일을 다운로드한다."""
        os.makedirs(os.path.dirname(local_path), exist_ok=True)
        logger.info(f"S3 다운로드: s3://{self.bucket}/{s3_key} -> {local_path}")
        self.s3.download_file(self.bucket, s3_key, local_path)

    def upload_file(self, local_path: str, s3_key: str):
        """파일을 S3에 업로드한다."""
        logger.info(f"S3 업로드: {local_path} -> s3://{self.bucket}/{s3_key}")
        self.s3.upload_file(local_path, self.bucket, s3_key)
