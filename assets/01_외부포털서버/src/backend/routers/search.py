"""
외부 포털 서버 — 통합 검색 API

[취약점 #3] SQL Injection
사용자 입력(q)을 파라미터 바인딩 없이 직접 SQL 문자열에 삽입한다.
에러 발생 시 SQL 오류 상세 정보가 응답에 포함된다.

공격 예시:
  GET /api/search?q=' UNION SELECT 1,2,version(),4--
  GET /api/search?q=' UNION SELECT id,'user',username,password FROM users--
"""

import logging
from fastapi import APIRouter, Query, Depends
from database import get_db

logger = logging.getLogger("mois-portal")
router = APIRouter(prefix="/api", tags=["search"])


@router.get("/search")
async def search(
    q: str = Query(..., description="검색어"),
    type: str = Query(None, description="검색 유형: notice 또는 inquiry"),
    page: int = Query(1, ge=1),
    size: int = Query(20, ge=1, le=100),
    db=Depends(get_db),
):
    """
    통합 검색

    [취약점] 사용자 입력(q)이 SQL 문자열에 직접 삽입됨 — SQL Injection 가능
    올바른 구현: 파라미터 바인딩 ($1, $2) 사용
    """
    offset = (page - 1) * size

    # [취약점 #3] 사용자 입력을 직접 SQL 문자열에 삽입
    # 올바른 구현: WHERE title ILIKE $1, [f"%{q}%"]
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
            WHERE title ILIKE '%{q}%' OR content ILIKE '%{q}%'
        """

    count_query = f"SELECT COUNT(*) FROM ({base_query}) as sub"
    data_query = f"{base_query} ORDER BY id DESC LIMIT {size} OFFSET {offset}"

    try:
        total = await db.fetch_val(count_query)
        items = await db.fetch_all(data_query)
        logger.info(f"Search query executed: q={q}, results={total}")
        return {
            "total": total or 0,
            "query": q,
            "items": [dict(r) for r in items],
        }
    except Exception as e:
        # [취약점] 에러 메시지에 SQL 오류 상세 정보 노출
        logger.error(f"Search error: {str(e)}, query={q}")
        return {"error": f"검색 중 오류가 발생했습니다: {str(e)}"}
