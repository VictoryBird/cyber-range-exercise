"""
Admin API Router
Asset 01: External Portal Server (192.168.92.201)

[취약점] VULN-01-02: Missing authentication on admin endpoints.
All endpoints in this router are accessible without any authentication.
올바른 구현:
    from auth import get_current_admin_user
    router = APIRouter(
        prefix="/api/admin",
        dependencies=[Depends(get_current_admin_user)]
    )
"""

from fastapi import APIRouter, Query, Depends, HTTPException
from database import get_db
from pydantic import BaseModel
from typing import Optional
from datetime import datetime

router = APIRouter(prefix="/api/admin", tags=["admin"])


class NoticeCreate(BaseModel):
    title: str
    content: str
    category: str = "General"
    is_public: bool = True


class NoticeUpdate(BaseModel):
    title: Optional[str] = None
    content: Optional[str] = None
    category: Optional[str] = None
    is_public: Optional[bool] = None


@router.get("/users")
async def list_users(conn=Depends(get_db)):
    """
    [취약점] VULN-01-02: Admin user list -- NO authentication check.
    Returns all registered portal users including emails and roles.
    올바른 구현: require admin JWT token via Depends(get_current_admin_user)
    """
    rows = await conn.fetch(
        "SELECT id, username, email, role, last_login, created_at FROM users ORDER BY id"
    )
    return {"users": [dict(r) for r in rows]}


@router.get("/notices")
async def admin_list_notices(
    page: int = Query(1, ge=1),
    size: int = Query(20, ge=1, le=100),
    conn=Depends(get_db),
):
    """
    [취약점] VULN-01-02: Admin notice list -- includes non-public notices, NO auth.
    올바른 구현: require admin JWT token via Depends(get_current_admin_user)
    """
    offset = (page - 1) * size
    total = await conn.fetchval("SELECT COUNT(*) FROM notices")
    rows = await conn.fetch(
        """SELECT id, title, category, author, is_public, view_count, created_at
           FROM notices ORDER BY created_at DESC
           LIMIT $1 OFFSET $2""",
        size,
        offset,
    )
    return {
        "total": total,
        "page": page,
        "size": size,
        "items": [dict(r) for r in rows],
    }


@router.post("/notices")
async def create_notice(notice: NoticeCreate, conn=Depends(get_db)):
    """
    [취약점] VULN-01-02: Create notice -- NO authentication required.
    Anyone can publish notices.
    올바른 구현: require admin JWT token via Depends(get_current_admin_user)
    """
    row = await conn.fetchrow(
        """INSERT INTO notices (title, content, category, is_public, author)
           VALUES ($1, $2, $3, $4, 'Anonymous')
           RETURNING id, title, created_at""",
        notice.title,
        notice.content,
        notice.category,
        notice.is_public,
    )
    return {"message": "Notice created", "notice": dict(row)}


@router.put("/notices/{notice_id}")
async def update_notice(notice_id: int, notice: NoticeUpdate, conn=Depends(get_db)):
    """
    [취약점] VULN-01-02: Update notice -- NO authentication required.
    Anyone can modify existing notices.
    올바른 구현: require admin JWT token via Depends(get_current_admin_user)
    """
    # Check existence
    existing = await conn.fetchrow("SELECT id FROM notices WHERE id = $1", notice_id)
    if not existing:
        raise HTTPException(status_code=404, detail="Notice not found")

    # Build dynamic update query
    fields = []
    params = []
    param_idx = 1

    if notice.title is not None:
        fields.append(f"title = ${param_idx}")
        params.append(notice.title)
        param_idx += 1
    if notice.content is not None:
        fields.append(f"content = ${param_idx}")
        params.append(notice.content)
        param_idx += 1
    if notice.category is not None:
        fields.append(f"category = ${param_idx}")
        params.append(notice.category)
        param_idx += 1
    if notice.is_public is not None:
        fields.append(f"is_public = ${param_idx}")
        params.append(notice.is_public)
        param_idx += 1

    if not fields:
        raise HTTPException(status_code=400, detail="No fields to update")

    fields.append(f"updated_at = ${param_idx}")
    params.append(datetime.utcnow())
    param_idx += 1

    params.append(notice_id)
    set_clause = ", ".join(fields)
    query = f"UPDATE notices SET {set_clause} WHERE id = ${param_idx} RETURNING id, title, updated_at"

    row = await conn.fetchrow(query, *params)
    return {"message": "Notice updated", "notice": dict(row)}


@router.delete("/notices/{notice_id}")
async def delete_notice(notice_id: int, conn=Depends(get_db)):
    """
    [취약점] VULN-01-02: Delete notice -- NO authentication required.
    Anyone can delete notices.
    올바른 구현: require admin JWT token via Depends(get_current_admin_user)
    """
    result = await conn.execute("DELETE FROM notices WHERE id = $1", notice_id)
    if result == "DELETE 0":
        raise HTTPException(status_code=404, detail="Notice not found")
    return {"message": "Notice deleted", "id": notice_id}
