"""
C14 데이터 수집·관리 서버 — 이벤트 라우터
파일 경로: /opt/datacollector/app/routers/events.py

★★★ 이 코드에는 의도적인 보안 취약점이 포함되어 있습니다 ★★★
- VULN-C14-01: /api/config에서 API 키 및 DB 정보 노출
- VULN-C14-02: DELETE 인증 없음
- VULN-C14-03: 레이트 리밋 없음
- VULN-C14-04: 입력 검증 없음
"""

from datetime import datetime, timezone
from typing import Optional

import sqlalchemy as sa
from fastapi import APIRouter, Header, HTTPException, Query
from pydantic import BaseModel

from database import SessionLocal, events_table
from config import API_KEY, ADMIN_KEY, DB_HOST, DB_PORT, DB_NAME, DB_USER, DB_PASS

router = APIRouter()


# ============================================================
# Pydantic 모델
# ============================================================
class EventCreate(BaseModel):
    type: str
    unit: Optional[str] = None
    location: Optional[dict] = None  # {"lat": float, "lng": float}
    timestamp: Optional[str] = None
    priority: Optional[str] = "medium"
    source: Optional[str] = "relay"
    verified: Optional[bool] = False
    description: Optional[str] = None
    metadata: Optional[dict] = {}


class EventUpdate(BaseModel):
    type: Optional[str] = None
    unit: Optional[str] = None
    location: Optional[dict] = None
    timestamp: Optional[str] = None
    priority: Optional[str] = None
    source: Optional[str] = None
    verified: Optional[bool] = None
    description: Optional[str] = None
    metadata: Optional[dict] = None


# ============================================================
# 인증 헬퍼
# ============================================================
def verify_api_key(x_api_key: Optional[str] = Header(None)):
    """API 키 검증 (★ 하드코딩된 키와 비교)"""
    if x_api_key != API_KEY and x_api_key != ADMIN_KEY:
        raise HTTPException(status_code=401, detail="유효하지 않은 API 키")
    return x_api_key


# ============================================================
# 엔드포인트
# ============================================================

@router.get("/api/config")
def get_config():
    """
    시스템 설정 조회

    [취약점] VULN-C14-01: 인증 없이 접근 가능, API 키 및 DB 정보 노출 (CWE-798, CWE-200)
    [올바른 구현] 인증 필수 + 민감 정보(API 키, DB 비밀번호) 응답에서 제외
    """
    return {
        "service": "C4I Data Collector",
        "version": "1.0.0",
        "api_key": API_KEY,                    # ★ API 키 노출
        "admin_key": ADMIN_KEY,                # ★ 관리자 키 노출
        "database": {
            "host": DB_HOST,
            "port": DB_PORT,
            "name": DB_NAME,
            "user": DB_USER,
            "password": DB_PASS,               # ★ DB 비밀번호 노출
        },
        "endpoints": {
            "events": "/api/events",
            "stats": "/api/stats",
            "config": "/api/config",
        },
        "environment": "development",          # ★ 개발 모드 정보
        "debug": True,
    }


@router.get("/api/events")
def list_events(
    x_api_key: Optional[str] = Header(None),
    type: Optional[str] = Query(None, description="이벤트 유형 필터"),
    priority: Optional[str] = Query(None, description="우선순위 필터"),
    source: Optional[str] = Query(None, description="소스 필터"),
    since: Optional[str] = Query(None, description="이 시각 이후 이벤트 (ISO 8601)"),
    limit: int = Query(100, description="최대 조회 건수"),
    offset: int = Query(0, description="건너뛸 건수"),
):
    """이벤트 목록 조회 (API 키 필요)"""
    verify_api_key(x_api_key)

    with SessionLocal() as session:
        query = sa.select(events_table).order_by(events_table.c.timestamp.desc())

        if type:
            query = query.where(events_table.c.type == type)
        if priority:
            query = query.where(events_table.c.priority == priority)
        if source:
            query = query.where(events_table.c.source == source)
        if since:
            try:
                since_dt = datetime.fromisoformat(since.replace("Z", "+00:00"))
                query = query.where(events_table.c.timestamp > since_dt)
            except ValueError:
                pass

        query = query.offset(offset).limit(limit)
        result = session.execute(query)
        rows = result.fetchall()

        events = []
        for row in rows:
            events.append({
                "id": row.id,
                "type": row.type,
                "unit": row.unit,
                "location": {"lat": row.location_lat, "lng": row.location_lng},
                "timestamp": row.timestamp.isoformat() if row.timestamp else None,
                "priority": row.priority,
                "source": row.source,
                "verified": row.verified,
                "description": row.description,
            })

        return {"total": len(events), "events": events}


@router.get("/api/events/{event_id}")
def get_event(
    event_id: int,
    x_api_key: Optional[str] = Header(None),
):
    """이벤트 상세 조회"""
    verify_api_key(x_api_key)

    with SessionLocal() as session:
        query = sa.select(events_table).where(events_table.c.id == event_id)
        result = session.execute(query)
        row = result.fetchone()

        if not row:
            raise HTTPException(status_code=404, detail="이벤트를 찾을 수 없습니다")

        return {
            "id": row.id,
            "type": row.type,
            "unit": row.unit,
            "location": {"lat": row.location_lat, "lng": row.location_lng},
            "timestamp": row.timestamp.isoformat() if row.timestamp else None,
            "priority": row.priority,
            "source": row.source,
            "verified": row.verified,
            "description": row.description,
        }


@router.post("/api/events", status_code=201)
def create_event(
    event: EventCreate,
    x_api_key: Optional[str] = Header(None),
):
    """
    이벤트 생성

    [취약점] VULN-C14-03: 레이트 리밋 없음 — 스크립트로 수백 건 연속 주입 가능 (CWE-770)
    [올바른 구현] slowapi 등 레이트 리밋 미들웨어 적용 (예: 분당 10건 제한)

    [취약점] VULN-C14-04: 입력 검증 없음 — 임의 type, 비현실적 좌표 등 모두 허용 (CWE-20)
    [올바른 구현] type은 허용 목록(enum) 검증, 좌표는 한반도 범위(33~43N, 124~132E) 검증
    """
    verify_api_key(x_api_key)

    lat = event.location.get("lat") if event.location else None
    lng = event.location.get("lng") if event.location else None
    ts = event.timestamp
    if ts:
        try:
            ts = datetime.fromisoformat(ts.replace("Z", "+00:00"))
        except ValueError:
            ts = datetime.now(timezone.utc)
    else:
        ts = datetime.now(timezone.utc)

    with SessionLocal() as session:
        ins = events_table.insert().values(
            type=event.type,
            unit=event.unit,
            location_lat=lat,
            location_lng=lng,
            timestamp=ts,
            priority=event.priority,
            source=event.source,
            verified=event.verified,
            description=event.description,
            metadata=event.metadata or {},
            created_at=datetime.now(timezone.utc),
            updated_at=datetime.now(timezone.utc),
        )
        result = session.execute(ins)
        session.commit()

        return {
            "success": True,
            "id": result.inserted_primary_key[0],
            "message": "이벤트 생성 완료",
        }


@router.put("/api/events/{event_id}")
def update_event(
    event_id: int,
    event: EventUpdate,
    x_api_key: Optional[str] = Header(None),
):
    """
    이벤트 수정

    [취약점] VULN-C14-02: API 키만 확인하고 소유권/권한은 확인하지 않음 (CWE-862)
    [올바른 구현] 이벤트 생성자(source)와 요청자를 비교하여 소유권 검증
    """
    verify_api_key(x_api_key)

    update_data = {}
    if event.type is not None:
        update_data["type"] = event.type
    if event.unit is not None:
        update_data["unit"] = event.unit
    if event.location is not None:
        update_data["location_lat"] = event.location.get("lat")
        update_data["location_lng"] = event.location.get("lng")
    if event.timestamp is not None:
        try:
            update_data["timestamp"] = datetime.fromisoformat(event.timestamp.replace("Z", "+00:00"))
        except ValueError:
            pass
    if event.priority is not None:
        update_data["priority"] = event.priority
    if event.source is not None:
        update_data["source"] = event.source
    if event.verified is not None:
        update_data["verified"] = event.verified
    if event.description is not None:
        update_data["description"] = event.description

    update_data["updated_at"] = datetime.now(timezone.utc)

    with SessionLocal() as session:
        upd = (
            events_table.update()
            .where(events_table.c.id == event_id)
            .values(**update_data)
        )
        result = session.execute(upd)
        session.commit()

        if result.rowcount == 0:
            raise HTTPException(status_code=404, detail="이벤트를 찾을 수 없습니다")

        return {"success": True, "message": f"이벤트 {event_id} 수정 완료"}


@router.delete("/api/events")
def delete_events(
    type: Optional[str] = Query(None, description="삭제할 이벤트 유형"),
    since: Optional[str] = Query(None, description="이 시각 이후 이벤트 삭제"),
    before: Optional[str] = Query(None, description="이 시각 이전 이벤트 삭제"),
    # [취약점] VULN-C14-02: 인증 헤더를 아예 확인하지 않음 (CWE-862)
    # [올바른 구현] verify_api_key 호출 + 관리자 권한 검증 + 삭제 사유 로깅
):
    """
    이벤트 대량 삭제

    [취약점] VULN-C14-02: 인증 없이 대량 삭제 가능
    [올바른 구현] 관리자 API 키 검증 필수, 삭제 로그 기록
    """
    with SessionLocal() as session:
        query = events_table.delete()

        if type:
            query = query.where(events_table.c.type == type)
        if since:
            try:
                since_dt = datetime.fromisoformat(since.replace("Z", "+00:00"))
                query = query.where(events_table.c.timestamp > since_dt)
            except ValueError:
                pass
        if before:
            try:
                before_dt = datetime.fromisoformat(before.replace("Z", "+00:00"))
                query = query.where(events_table.c.timestamp < before_dt)
            except ValueError:
                pass

        result = session.execute(query)
        session.commit()

        return {
            "success": True,
            "deleted_count": result.rowcount,
            "message": f"{result.rowcount}건 이벤트 삭제 완료",
        }


@router.get("/api/stats")
def get_stats(
    x_api_key: Optional[str] = Header(None),
):
    """이벤트 통계"""
    verify_api_key(x_api_key)

    with SessionLocal() as session:
        total = session.execute(sa.select(sa.func.count()).select_from(events_table)).scalar()

        type_counts = session.execute(
            sa.select(events_table.c.type, sa.func.count().label("count"))
            .group_by(events_table.c.type)
            .order_by(sa.desc("count"))
        ).fetchall()

        priority_counts = session.execute(
            sa.select(events_table.c.priority, sa.func.count().label("count"))
            .group_by(events_table.c.priority)
        ).fetchall()

        source_counts = session.execute(
            sa.select(events_table.c.source, sa.func.count().label("count"))
            .group_by(events_table.c.source)
        ).fetchall()

        return {
            "total_events": total,
            "by_type": {row.type: row.count for row in type_counts},
            "by_priority": {row.priority: row.count for row in priority_counts},
            "by_source": {row.source: row.count for row in source_counts},
            "generated_at": datetime.now(timezone.utc).isoformat(),
        }
