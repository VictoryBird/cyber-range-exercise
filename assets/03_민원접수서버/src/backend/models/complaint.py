"""
민원 접수 서버 — 민원 데이터 모델
SQLite 기반 로컬 저장 (경량 구현)
"""

from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime


class ComplaintCreate(BaseModel):
    title: str
    category: str
    content: str
    submitter_name: str
    submitter_phone: Optional[str] = None
    submitter_email: Optional[str] = None


class FileInfo(BaseModel):
    file_id: str
    filename: str
    download_url: str


class ComplaintResponse(BaseModel):
    complaint_id: str
    title: str
    category: str
    content: str
    status: str
    submitter_name: str
    submitter_phone: Optional[str] = None
    submitter_email: Optional[str] = None
    files: List[FileInfo] = []
    created_at: str
    updated_at: str
