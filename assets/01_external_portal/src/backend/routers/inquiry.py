"""
Inquiry Status API Router
Asset 01: External Portal Server (192.168.92.201)
"""

from fastapi import APIRouter, Depends, HTTPException
from database import get_db

router = APIRouter(prefix="/api", tags=["inquiry"])


@router.get("/inquiry/{tracking_number}")
async def get_inquiry_status(tracking_number: str, conn=Depends(get_db)):
    """Look up inquiry status by tracking number."""
    row = await conn.fetchrow(
        """SELECT tracking_number, subject, status, department,
                  submitter_name, submitted_at, updated_at
           FROM inquiries WHERE tracking_number = $1""",
        tracking_number,
    )
    if not row:
        raise HTTPException(
            status_code=404,
            detail="No inquiry found with the provided tracking number",
        )
    return dict(row)
