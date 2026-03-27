"""
외부 포털 서버 — 공지사항 API
공지사항 목록 조회, 상세 조회 기능을 제공한다.
"""

from fastapi import APIRouter, Query, Depends, HTTPException
from database import get_db

router = APIRouter(prefix="/api", tags=["notices"])


@router.get("/notices")
async def list_notices(
    page: int = Query(1, ge=1),
    size: int = Query(20, ge=1, le=100),
    category: str = Query(None),
    db=Depends(get_db),
):
    """공지사항 목록 조회 (인증 불필요)"""
    offset = (page - 1) * size

    if category:
        count_query = "SELECT COUNT(*) FROM notices WHERE is_public = true AND category = :category"
        data_query = """
            SELECT id, title, category, created_at, view_count
            FROM notices WHERE is_public = true AND category = :category
            ORDER BY created_at DESC LIMIT :limit OFFSET :offset
        """
        values = {"category": category, "limit": size, "offset": offset}
    else:
        count_query = "SELECT COUNT(*) FROM notices WHERE is_public = true"
        data_query = """
            SELECT id, title, category, created_at, view_count
            FROM notices WHERE is_public = true
            ORDER BY created_at DESC LIMIT :limit OFFSET :offset
        """
        values = {"limit": size, "offset": offset}

    count_values = {k: v for k, v in values.items() if k not in ("limit", "offset")}
    total = await db.fetch_val(count_query, count_values)
    items = await db.fetch_all(data_query, values)

    return {
        "total": total or 0,
        "page": page,
        "size": size,
        "items": [dict(r) for r in items],
    }


@router.get("/notices/{notice_id}")
async def get_notice(notice_id: int, db=Depends(get_db)):
    """공지사항 상세 조회 (인증 불필요)"""
    query = """
        SELECT id, title, category, content, author, created_at, view_count
        FROM notices WHERE id = :id AND is_public = true
    """
    notice = await db.fetch_one(query, {"id": notice_id})
    if not notice:
        raise HTTPException(status_code=404, detail="공지사항을 찾을 수 없습니다")

    await db.execute("UPDATE notices SET view_count = view_count + 1 WHERE id = :id", {"id": notice_id})
    return dict(notice)
