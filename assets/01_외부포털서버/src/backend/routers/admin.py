"""
외부 포털 서버 — 관리자 API

[취약점 #2] 인증 미적용 관리자 API
이 라우터의 모든 엔드포인트는 인증/인가 확인 없이 응답한다.
"""

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from typing import Optional
from database import get_db

# [취약점] 인증 의존성 미적용
router = APIRouter(prefix="/api/admin", tags=["admin"])


class NoticeCreate(BaseModel):
    title: str
    content: str
    category: str = "일반"
    is_public: bool = True


class NoticeUpdate(BaseModel):
    title: Optional[str] = None
    content: Optional[str] = None
    category: Optional[str] = None
    is_public: Optional[bool] = None


@router.get("/users")
async def list_users(db=Depends(get_db)):
    """관리자 사용자 목록 — [취약점] 인증 체크 누락"""
    query = "SELECT id, username, email, role, last_login FROM users ORDER BY id"
    result = await db.fetch_all(query)
    return {"users": [dict(r) for r in result]}


@router.get("/notices")
async def admin_list_notices(db=Depends(get_db)):
    """관리자용 공지사항 목록 (비공개 포함) — [취약점] 인증 체크 누락"""
    query = """
        SELECT id, title, category, is_public, author, created_at, view_count
        FROM notices ORDER BY created_at DESC
    """
    result = await db.fetch_all(query)
    return {"notices": [dict(r) for r in result]}


@router.post("/notices")
async def create_notice(notice: NoticeCreate, db=Depends(get_db)):
    """공지사항 작성 — [취약점] 인증 체크 누락"""
    query = """
        INSERT INTO notices (title, content, category, is_public, author)
        VALUES (:title, :content, :category, :is_public, '관리자')
        RETURNING id
    """
    notice_id = await db.fetch_val(query, {
        "title": notice.title,
        "content": notice.content,
        "category": notice.category,
        "is_public": notice.is_public,
    })
    return {"id": notice_id, "message": "공지사항이 작성되었습니다"}


@router.put("/notices/{notice_id}")
async def update_notice(notice_id: int, notice: NoticeUpdate, db=Depends(get_db)):
    """공지사항 수정 — [취약점] 인증 체크 누락"""
    updates = []
    values = {"id": notice_id}

    for field in ["title", "content", "category", "is_public"]:
        value = getattr(notice, field)
        if value is not None:
            updates.append(f"{field} = :{field}")
            values[field] = value

    if not updates:
        raise HTTPException(status_code=400, detail="수정할 항목이 없습니다")

    query = f"UPDATE notices SET {', '.join(updates)} WHERE id = :id"
    await db.execute(query, values)
    return {"message": "공지사항이 수정되었습니다"}


@router.delete("/notices/{notice_id}")
async def delete_notice(notice_id: int, db=Depends(get_db)):
    """공지사항 삭제 — [취약점] 인증 체크 누락"""
    await db.execute("DELETE FROM notices WHERE id = :id", {"id": notice_id})
    return {"message": "공지사항이 삭제되었습니다"}
