"""
Historian REST API 라우터

[취약점] VULN-12-01: 모든 엔드포인트에 인증 미구현
[취약점] VULN-12-02: /api/config에서 InfluxDB 토큰 노출
[취약점] VULN-12-03: DELETE 인가 없이 허용
[취약점] VULN-12-04: write/delete에 rate limiting 없음

올바른 구현이라면:
- fastapi.security.HTTPBearer 등으로 인증 미들웨어 적용
- /api/config 엔드포인트 제거 또는 민감 정보 마스킹
- DELETE에 관리자 인가 요구
- slowapi 등으로 rate limiting 적용
"""

import time
from datetime import datetime, timezone

from fastapi import APIRouter, Query, Request
from influxdb_client import InfluxDBClient, Point
from influxdb_client.client.write_api import SYNCHRONOUS

from config import settings

router = APIRouter(prefix="/api")

# InfluxDB 클라이언트
client = InfluxDBClient(
    url=settings.INFLUXDB_URL,
    token=settings.INFLUXDB_TOKEN,
    org=settings.INFLUXDB_ORG,
)

# 서버 시작 시각 (uptime 계산용)
_start_time = time.time()

# 태그 메타데이터
TAG_METADATA = [
    {
        "name": "temperature",
        "description": "온도 센서 (°C)",
        "unit": "°C",
        "min": 20.0,
        "max": 30.0,
    },
    {
        "name": "pressure",
        "description": "압력 센서 (bar)",
        "unit": "bar",
        "min": 90.0,
        "max": 110.0,
    },
    {
        "name": "flow_rate",
        "description": "유량 센서 (L/min)",
        "unit": "L/min",
        "min": 100.0,
        "max": 200.0,
    },
    {
        "name": "power",
        "description": "전력 센서 (V)",
        "unit": "V",
        "min": 220.0,
        "max": 240.0,
    },
]

# 태그명→단위 매핑
TAG_UNITS = {t["name"]: t["unit"] for t in TAG_METADATA}


# ---------------------------------------------------------------------------
# GET /api/health
# ---------------------------------------------------------------------------
@router.get("/health")
async def health():
    """서버 상태 확인 (헬스체크)"""
    try:
        health_result = client.health()
        influx_status = "connected" if health_result.status == "pass" else "disconnected"
    except Exception:
        influx_status = "disconnected"

    return {
        "status": "healthy",
        "influxdb": influx_status,
        "uptime_seconds": int(time.time() - _start_time),
        "version": "1.0.0",
    }


# ---------------------------------------------------------------------------
# GET /api/tags
# [취약점] VULN-12-01: 인증 없이 태그 목록 노출
# 올바른 구현: HTTPBearer 인증 미들웨어 적용 필요
# ---------------------------------------------------------------------------
@router.get("/tags")
async def get_tags():
    """전체 태그 목록 조회 — 인증 없이 접근 가능"""
    return {"tags": TAG_METADATA}


# ---------------------------------------------------------------------------
# GET /api/query
# [취약점] VULN-12-01: 인증 없이 센서 데이터 전량 조회 가능
# 올바른 구현: HTTPBearer 인증 미들웨어 적용 필요
# ---------------------------------------------------------------------------
@router.get("/query")
async def query_data(
    tag: str,
    from_time: str = Query(default="-1h", alias="from"),
    to_time: str = Query(default="now()", alias="to"),
    limit: int = Query(default=1000),
):
    """태그 데이터 조회 — 인증 없이 접근 가능"""
    query_api = client.query_api()

    # Flux 쿼리 구성
    flux_query = f"""
from(bucket: "{settings.INFLUXDB_BUCKET}")
  |> range(start: {from_time}, stop: {to_time})
  |> filter(fn: (r) => r["_measurement"] == "{tag}")
  |> filter(fn: (r) => r["_field"] == "value")
  |> sort(columns: ["_time"])
  |> limit(n: {limit})
"""

    tables = query_api.query(flux_query, org=settings.INFLUXDB_ORG)

    data = []
    for table in tables:
        for record in table.records:
            data.append(
                {
                    "time": record.get_time().isoformat().replace("+00:00", "Z"),
                    "value": record.get_value(),
                    "unit": TAG_UNITS.get(tag, ""),
                }
            )

    return {
        "tag": tag,
        "count": len(data),
        "data": data,
    }


# ---------------------------------------------------------------------------
# POST /api/write
# [취약점] VULN-12-01: 인증 없이 데이터 삽입 가능
# [취약점] VULN-12-04: rate limiting 미적용 — 대량 허위 데이터 삽입 가능
# 올바른 구현:
#   - HTTPBearer 인증 + Pydantic 모델로 태그명/값 범위/타임스탬프 검증
#   - slowapi 등으로 분당 요청 수 제한
# ---------------------------------------------------------------------------
@router.post("/write", status_code=201)
async def write_data(payload: dict):
    """데이터 삽입 — 인증/검증 없음"""
    # [취약점] VULN-12-04: 입력 검증 없음 — 임의 태그명, 범위 외 값, 타임스탬프 조작 가능
    tag = payload.get("tag")  # [취약점] 태그명 검증 없음
    value = payload.get("value")  # [취약점] 값 범위 검증 없음 (음수, 극단값 허용)
    timestamp = payload.get("timestamp")  # [취약점] 타임스탬프 검증 없음

    point = Point(tag).field("value", float(value))
    if timestamp:
        point = point.time(timestamp)

    write_api = client.write_api(write_options=SYNCHRONOUS)
    write_api.write(
        bucket=settings.INFLUXDB_BUCKET,
        org=settings.INFLUXDB_ORG,
        record=point,
    )

    return {
        "status": "written",
        "tag": tag,
        "value": value,
        "timestamp": timestamp or datetime.now(timezone.utc).isoformat(),
    }


# ---------------------------------------------------------------------------
# DELETE /api/data
# [취약점] VULN-12-03: 인증/인가 없이 데이터 삭제 허용 — 사고 은폐에 활용 가능
# [취약점] VULN-12-04: rate limiting 미적용 — 전체 이력 일괄 삭제 가능
# 올바른 구현:
#   - 관리자 권한 인가 필수 (RBAC)
#   - 삭제 작업 감사 로깅 (audit log)
#   - rate limiting 적용
# ---------------------------------------------------------------------------
@router.delete("/data")
async def delete_data(
    tag: str,
    from_time: str = Query(alias="from"),
    to_time: str = Query(alias="to"),
):
    """데이터 삭제 — 인증/인가 없음, 감사 로깅 미흡"""
    delete_api = client.delete_api()
    delete_api.delete(
        start=from_time,
        stop=to_time,
        predicate=f'_measurement="{tag}"',
        bucket=settings.INFLUXDB_BUCKET,
        org=settings.INFLUXDB_ORG,
    )

    return {
        "status": "deleted",
        "tag": tag,
        "from": from_time,
        "to": to_time,
    }


# ---------------------------------------------------------------------------
# GET /api/config
# [취약점] VULN-12-02: InfluxDB 토큰, 내부 네트워크 정보(SCADA IP) 평문 노출
# 올바른 구현:
#   - 이 엔드포인트를 제거하거나, 민감 정보 마스킹
#   - 최소한 인증 필수 + 토큰 마스킹 (예: "hist****2024")
# ---------------------------------------------------------------------------
@router.get("/config")
async def get_config():
    """시스템 설정 조회 — 민감 정보 포함"""
    return {
        "influxdb_url": settings.INFLUXDB_URL,
        "influxdb_org": settings.INFLUXDB_ORG,
        "influxdb_bucket": settings.INFLUXDB_BUCKET,
        "influxdb_token": settings.INFLUXDB_TOKEN,  # [취약점] VULN-12-02: 토큰 평문 노출
        "api_version": "1.0.0",
        "scada_endpoint": settings.SCADA_HOST,  # [취약점] VULN-12-02: OT 네트워크 정보 노출
    }
