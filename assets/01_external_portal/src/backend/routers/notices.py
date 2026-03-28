"""
Notice Board API Router
Asset 01: External Portal Server (192.168.92.201)
"""

from fastapi import APIRouter, Query, Depends, HTTPException
from database import get_db

router = APIRouter(prefix="/api", tags=["notices"])


@router.get("/notices")
async def list_notices(
    page: int = Query(1, ge=1),
    size: int = Query(20, ge=1, le=100),
    category: str = Query(None),
    conn=Depends(get_db),
):
    """List public notices with pagination."""
    offset = (page - 1) * size

    # Build query
    where_clause = "WHERE is_public = true"
    params = []
    param_idx = 1

    if category:
        where_clause += f" AND LOWER(category) = LOWER(${param_idx})"
        params.append(category)
        param_idx += 1

    # Count query (no LIMIT/OFFSET per CLAUDE.md)
    count_query = f"SELECT COUNT(*) FROM notices {where_clause}"
    total = await conn.fetchval(count_query, *params)

    # Data query
    data_query = f"""
        SELECT id, title, category, author, view_count, created_at
        FROM notices
        {where_clause}
        ORDER BY created_at DESC
        LIMIT ${param_idx} OFFSET ${param_idx + 1}
    """
    params.extend([size, offset])
    rows = await conn.fetch(data_query, *params)

    return {
        "total": total,
        "page": page,
        "size": size,
        "items": [dict(r) for r in rows],
    }


@router.get("/notices/{notice_id}")
async def get_notice(notice_id: int, conn=Depends(get_db)):
    """Get notice detail and increment view count."""
    row = await conn.fetchrow(
        """SELECT id, title, content, category, author, is_public,
                  view_count, created_at, updated_at
           FROM notices WHERE id = $1""",
        notice_id,
    )
    if not row:
        raise HTTPException(status_code=404, detail="Notice not found")

    if not row["is_public"]:
        raise HTTPException(status_code=404, detail="Notice not found")

    # Increment view count
    await conn.execute(
        "UPDATE notices SET view_count = view_count + 1 WHERE id = $1",
        notice_id,
    )

    result = dict(row)
    result["view_count"] += 1
    return result
