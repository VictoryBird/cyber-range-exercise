"""
유틸리티 함수 — 민원 처리 워커
Asset 06: Complaint Processing Server (192.168.92.206)
"""

import hashlib
import logging
import re
from pathlib import Path

logger = logging.getLogger(__name__)

# ──────────────────────────────────────────────
# 파일명 관련
# ──────────────────────────────────────────────

def sanitize_filename(filename: str) -> str:
    """
    파일명에서 경로 순회 및 shell 메타문자를 제거하여 안전한 파일명을 반환한다.

    Note: FileProcessor의 취약점(VULN-06-05, VULN-06-07)은 의도적으로
    이 함수를 사용하지 않아 발생한다.

    Args:
        filename: 원본 파일명 (경로 포함 가능)

    Returns:
        안전한 파일명 (디렉토리 부분 제거, 메타문자 치환)
    """
    # 경로 순회 제거: 디렉토리 부분만 잘라냄
    name = Path(filename).name

    # Null byte 제거
    name = name.replace("\x00", "")

    # shell 메타문자 및 공백을 밑줄로 치환
    name = re.sub(r'[^\w.\-]', '_', name)

    # 연속 밑줄 정리
    name = re.sub(r'_+', '_', name)

    # 앞뒤 밑줄 및 점 정리
    name = name.strip('_.')

    if not name:
        name = "unnamed_file"

    return name


def compute_sha256(file_path: str | Path) -> str:
    """
    파일의 SHA-256 해시를 계산한다.

    Args:
        file_path: 해시를 계산할 파일 경로

    Returns:
        16진수 SHA-256 문자열
    """
    sha256 = hashlib.sha256()
    file_path = Path(file_path)
    with file_path.open("rb") as f:
        for chunk in iter(lambda: f.read(65536), b""):
            sha256.update(chunk)
    return sha256.hexdigest()


def build_s3_key(prefix: str, complaint_number: str, filename: str) -> str:
    """
    MinIO S3 오브젝트 키를 구성한다.

    Args:
        prefix:           버킷 내 디렉토리 접두사 (예: "uploads", "processed")
        complaint_number: 민원 번호 (예: "COMP-2026-00142")
        filename:         파일명

    Returns:
        S3 오브젝트 키 (예: "uploads/COMP-2026-00142/document.docx")
    """
    safe_filename = sanitize_filename(filename)
    return f"{prefix.strip('/')}/{complaint_number}/{safe_filename}"


def human_readable_size(size_bytes: int) -> str:
    """
    바이트 수를 사람이 읽기 쉬운 문자열로 변환한다.

    Args:
        size_bytes: 바이트 크기

    Returns:
        예: "1.5 MB", "320 KB"
    """
    if size_bytes < 1024:
        return f"{size_bytes} B"
    elif size_bytes < 1024 ** 2:
        return f"{size_bytes / 1024:.1f} KB"
    elif size_bytes < 1024 ** 3:
        return f"{size_bytes / (1024 ** 2):.1f} MB"
    else:
        return f"{size_bytes / (1024 ** 3):.1f} GB"


def is_valid_complaint_number(complaint_number: str) -> bool:
    """
    민원 번호 형식 검증 (예: COMP-2026-00142).

    Args:
        complaint_number: 검증할 민원 번호 문자열

    Returns:
        형식이 올바르면 True
    """
    pattern = r'^COMP-\d{4}-\d{5}$'
    return bool(re.match(pattern, complaint_number))
