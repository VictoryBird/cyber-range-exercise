from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime


class ComplaintSubmit(BaseModel):
    title: str
    category: str
    content: str
    applicant_name: str = Field(alias="submitter_name")
    applicant_phone: Optional[str] = Field(None, alias="submitter_phone")
    applicant_email: Optional[str] = Field(None, alias="submitter_email")
    applicant_addr: Optional[str] = Field(None, alias="submitter_addr")

    model_config = {"populate_by_name": True}


class ComplaintResponse(BaseModel):
    complaint_id: int
    complaint_number: str
    applicant_name: str
    applicant_email: Optional[str] = None
    applicant_phone: Optional[str] = None
    applicant_addr: Optional[str] = None
    category: str
    title: str
    content: str
    status: str
    priority: Optional[str] = None
    assigned_dept: Optional[str] = None
    assigned_to: Optional[str] = None
    response: Optional[str] = None
    responded_at: Optional[datetime] = None
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None


class FileUploadResponse(BaseModel):
    attachment_id: int
    complaint_number: str
    original_name: str
    stored_path: str
    file_size: int
    mime_type: str
