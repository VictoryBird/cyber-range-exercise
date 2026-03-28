"""
MinIO S3 클라이언트 — 민원 파일 저장소
Asset 06: Complaint Processing Server (192.168.92.206)
MinIO 서버: 192.168.92.203:9000
"""

import os
import logging
from pathlib import Path

import boto3
from botocore.client import Config
from botocore.exceptions import ClientError
from dotenv import load_dotenv

load_dotenv()
logger = logging.getLogger(__name__)

# ──────────────────────────────────────────────
# MinIO 접속 설정 (환경변수 우선, 기본값은 훈련 환경값)
# ──────────────────────────────────────────────
MINIO_ENDPOINT  = os.environ.get("MINIO_ENDPOINT",   "http://192.168.92.203:9000")
MINIO_ACCESS_KEY = os.environ.get("MINIO_ACCESS_KEY", "minioadmin")
MINIO_SECRET_KEY = os.environ.get("MINIO_SECRET_KEY", "minioadmin123")
MINIO_BUCKET    = os.environ.get("MINIO_BUCKET",      "complaints")
MINIO_REGION    = os.environ.get("MINIO_REGION",      "us-east-1")  # MinIO는 리전 불필요하지만 boto3 필수


class MinIOClient:
    """
    boto3 기반 MinIO S3 클라이언트.

    MinIO는 S3 호환 API를 제공하므로 boto3의 s3 클라이언트를 그대로 사용한다.
    endpoint_url을 MinIO 주소로 지정하고 path-style 접근을 활성화한다.
    """

    def __init__(
        self,
        endpoint: str = MINIO_ENDPOINT,
        access_key: str = MINIO_ACCESS_KEY,
        secret_key: str = MINIO_SECRET_KEY,
        bucket: str = MINIO_BUCKET,
        region: str = MINIO_REGION,
    ) -> None:
        self.bucket = bucket
        self._client = boto3.client(
            "s3",
            endpoint_url=endpoint,
            aws_access_key_id=access_key,
            aws_secret_access_key=secret_key,
            region_name=region,
            config=Config(
                signature_version="s3v4",
                s3={"addressing_style": "path"},  # MinIO는 path-style 필수
                retries={"max_attempts": 3, "mode": "standard"},
            ),
        )
        logger.debug("MinIOClient 초기화: endpoint=%s bucket=%s", endpoint, bucket)

    # ──────────────────────────────────────────────────────────────────────
    # 파일 다운로드
    # ──────────────────────────────────────────────────────────────────────
    def download_file(self, s3_key: str, local_path: str | Path) -> None:
        """
        MinIO에서 파일을 로컬 경로로 다운로드한다.

        Args:
            s3_key:     S3 오브젝트 키 (예: "uploads/COMP-2026-00142/document.docx")
            local_path: 저장할 로컬 파일 경로
        """
        local_path = Path(local_path)
        local_path.parent.mkdir(parents=True, exist_ok=True)

        logger.info("MinIO 다운로드: s3://%s/%s → %s", self.bucket, s3_key, local_path)
        try:
            self._client.download_file(
                Bucket=self.bucket,
                Key=s3_key,
                Filename=str(local_path),
            )
            size = local_path.stat().st_size
            logger.info("다운로드 완료: %s (%d bytes)", local_path.name, size)
        except ClientError as e:
            error_code = e.response["Error"]["Code"]
            logger.error(
                "MinIO 다운로드 실패: key=%s code=%s message=%s",
                s3_key, error_code, e.response["Error"]["Message"],
            )
            raise

    # ──────────────────────────────────────────────────────────────────────
    # 파일 업로드
    # ──────────────────────────────────────────────────────────────────────
    def upload_file(self, local_path: str | Path, s3_key: str) -> None:
        """
        로컬 파일을 MinIO에 업로드한다.

        Args:
            local_path: 업로드할 로컬 파일 경로
            s3_key:     저장할 S3 오브젝트 키 (예: "processed/COMP-2026-00142/document.pdf")
        """
        local_path = Path(local_path)
        if not local_path.exists():
            raise FileNotFoundError(f"업로드 대상 파일 없음: {local_path}")

        size = local_path.stat().st_size
        logger.info(
            "MinIO 업로드: %s (%d bytes) → s3://%s/%s",
            local_path.name, size, self.bucket, s3_key,
        )
        try:
            self._client.upload_file(
                Filename=str(local_path),
                Bucket=self.bucket,
                Key=s3_key,
            )
            logger.info("업로드 완료: s3://%s/%s", self.bucket, s3_key)
        except ClientError as e:
            error_code = e.response["Error"]["Code"]
            logger.error(
                "MinIO 업로드 실패: local=%s key=%s code=%s message=%s",
                local_path, s3_key, error_code, e.response["Error"]["Message"],
            )
            raise

    # ──────────────────────────────────────────────────────────────────────
    # 헬퍼
    # ──────────────────────────────────────────────────────────────────────
    def object_exists(self, s3_key: str) -> bool:
        """오브젝트 존재 여부 확인 (head_object 사용)."""
        try:
            self._client.head_object(Bucket=self.bucket, Key=s3_key)
            return True
        except ClientError as e:
            if e.response["Error"]["Code"] in ("404", "NoSuchKey"):
                return False
            raise

    def ensure_bucket(self) -> None:
        """버킷이 없으면 생성한다 (초기화용)."""
        try:
            self._client.head_bucket(Bucket=self.bucket)
        except ClientError:
            self._client.create_bucket(Bucket=self.bucket)
            logger.info("버킷 생성 완료: %s", self.bucket)
