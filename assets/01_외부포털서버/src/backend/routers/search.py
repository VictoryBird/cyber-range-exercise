"""
Search API Router
Asset 01: External Portal Server (192.168.92.201)

[취약점] VULN-01-03: SQL Injection in search endpoint
The user input 'q' is directly interpolated into the SQL query using f-string.
Correct implementation: use parameterized queries ($1, $2) with asyncpg.
"""

from fastapi import APIRouter, Query, Depends
from database import get_db
import logging

logger = logging.getLogger("mois-portal")
router = APIRouter(prefix="/api", tags=["search"])


@router.get("/search")
async def search(
    q: str = Query(..., description="Search keyword"),
    type: str = Query(None, description="Search type: notice or inquiry"),
    page: int = Query(1, ge=1),
    size: int = Query(20, ge=1, le=100),
    conn=Depends(get_db),
):
    """
    Integrated search endpoint.

    [취약점] VULN-01-03: SQL Injection
    User input 'q' is directly embedded in SQL via f-string.
    올바른 구현:
        await conn.fetch(
            "SELECT ... WHERE title ILIKE $1", f"%{q}%"
        )
    """
    offset = (page - 1) * size

    # [취약점] VULN-01-03: Raw f-string SQL injection — user input 'q' is NOT parameterized
    # 올바른 구현: use asyncpg parameterized queries ($1, $2) instead of f-string interpolation
    if type == "inquiry":
        base_query = f"""
            SELECT id, 'inquiry' as type, subject as title,
                   SUBSTRING(description, 1, 200) as snippet
            FROM inquiries
            WHERE subject ILIKE '%{q}%' OR tracking_number ILIKE '%{q}%'
        """
    else:
        base_query = f"""
            SELECT id, 'notice' as type, title,
                   SUBSTRING(content, 1, 200) as snippet
            FROM notices
            WHERE (title ILIKE '%{q}%' OR content ILIKE '%{q}%')
              AND is_public = true
        """

    count_query = f"SELECT COUNT(*) FROM ({base_query}) as sub"
    data_query = f"{base_query} ORDER BY id DESC LIMIT {size} OFFSET {offset}"

    try:
        total = await conn.fetchval(count_query)
        rows = await conn.fetch(data_query)
        logger.info(f"Search query executed: q={q}, results={total}")
        return {
            "total": total,
            "query": q,
            "items": [dict(r) for r in rows],
        }
    except Exception as e:
        # [취약점] VULN-01-03: SQL error details exposed in response
        # 올바른 구현: return generic error message, do not expose internal SQL errors
        #   e.g., return {"error": "An internal error occurred"}
        logger.error(f"Search error: {str(e)}, query={q}")
        return {"error": f"Search error occurred: {str(e)}"}
