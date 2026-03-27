"""
외부 포털 서버 — 민원 조회 API
민원 접수번호(tracking_number) 기반으로 처리 상태를 조회한다.
"""

from fastapi import APIRouter, Depends, HTTPException
from database import get_db

router = APIRouter(prefix="/api", tags=["inquiry"])


@router.get("/inquiry/{tracking_number}")
async def get_inquiry(tracking_number: str, db=Depends(get_db)):
    """민원 처리 상태 조회 (인증 불필요)"""
    query = """
        SELECT tracking_number, subject, status, submitted_at, department
        FROM inquiries WHERE tracking_number = :tn
    """
    result = await db.fetch_one(query, {"tn": tracking_number})
    if not result:
        raise HTTPException(status_code=404, detail="해당 접수번호의 민원을 찾을 수 없습니다")
    return dict(result)
