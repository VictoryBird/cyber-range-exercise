# 자산 설계서 #C16 — 작전용 PC 1-5

| 항목 | 내용 |
|------|------|
| 자산 ID | C16 (PC-1 ~ PC-5) |
| IP | (테스트 미할당) ~ 192.168.92.236 |
| OS | Windows 10/11 Pro |
| 도메인 | (도메인 미가입) |
| 역할 | 전술 운용자 단말 — COP 상황도 열람 + AI 브리핑 확인 |
| 작성일 | 2026-03-26 |

---

## 1. 개요

### 1.1 자산 목적

C16 작전용 PC는 C4I 존에서 작전 요원 및 지휘관이 사용하는 전술 단말이다. 독립 운영 PC(도메인 미가입)로, 주요 역할은 COP 상황도 열람과 AI 브리핑 확인이다.

| PC | IP | 사용자 | 역할 |
|----|----|--------|------|
| PC-1 | (테스트 미할당) | 작전과장 | 작전 현황 종합 모니터링 |
| PC-2 | (테스트 미할당) | 정보과장 | 적 동향 분석 |
| PC-3 | (테스트 미할당) | 화력과장 | 포병/화력 운용 현황 |
| PC-4 | (테스트 미할당) | 군수과장 | 보급/군수 현황 |
| PC-5 | 192.168.92.236 | 당직사관 | 상황 보고 종합 |

### 1.2 훈련에서의 역할

이 PC들은 **최종 피해 대상**이다. C14 데이터 변조와 C13 COP 지도 조작의 결과가 이 PC에서 표시되어, 작전 요원이 허위 정보를 기반으로 보고서를 작성하고 지휘관이 잘못된 의사결정을 내리게 된다.

> 직접적인 취약점은 없으며, 상위 서버(C13, C14, C15)의 데이터 오염에 의한 간접 피해를 받는다.

---

## 2. 시스템 설정

### 2.1 기본 구성

```
운영체제: Windows 10/11 Pro (도메인 미가입)
호스트명: C4I-OPS-PC-{1~5}
로컬 계정: operator / Op3rator!C4I
관리자 계정: c4i-admin / C4I!Admin#2024

네트워크:
  IP: 192.168.92.236{21~25}
  서브넷: 255.255.255.0
  게이트웨이: 192.168.92.236
  DNS: 192.168.92.236

브라우저 홈페이지: http://cop.c4i.local:8080/map.jsp
북마크:
  - COP 상황도: http://cop.c4i.local:8080/map.jsp
  - AI 브리핑: http://summary.c4i.local:8001/api/summary/latest
  - 이벤트 현황: http://data.c4i.local:8000/api/stats
```

### 2.2 hosts 파일 설정

```
# C:\Windows\System32\drivers\etc\hosts
192.168.92.236  relay.c4i.local
192.168.92.236  cop.c4i.local
192.168.92.236  data.c4i.local
192.168.92.236  summary.c4i.local
```

### 2.3 방화벽 설정

```powershell
# 아웃바운드만 허용 (C4I 내부 서버로만)
# 인바운드 모두 차단 (ping 제외)

# Windows 방화벽 규칙
netsh advfirewall set allprofiles firewallpolicy blockinbound,allowoutbound

# C4I 서버 접근 허용
netsh advfirewall firewall add rule name="C4I-COP" dir=out action=allow remoteip=192.168.92.236 remoteport=8080 protocol=tcp
netsh advfirewall firewall add rule name="C4I-Data" dir=out action=allow remoteip=192.168.92.236 remoteport=8000 protocol=tcp
netsh advfirewall firewall add rule name="C4I-Summary" dir=out action=allow remoteip=192.168.92.236 remoteport=8001 protocol=tcp

# ICMP 허용
netsh advfirewall firewall add rule name="C4I-ICMP" dir=in action=allow protocol=icmpv4
```

---

## 3. 공통 참조 정보

### 3.1 OPNSense-7 방화벽 규칙

#### 인터페이스 구성

```
WAN: 192.168.92.1/24 (군 INT 측)
LAN: 192.168.92.236/24 (C4I 측)
관리: 192.168.1.17/24 (OOB 관리)
```

#### 방화벽 규칙

| # | 방향 | 출발지 | 도착지 | 포트 | 프로토콜 | 동작 | 설명 |
|---|------|--------|--------|------|----------|------|------|
| 1 | WAN→LAN | 192.168.92.254 (관리자 PC) | 192.168.92.236 | 22 | TCP | ALLOW | SSH 관리 접근 |
| 2 | WAN→LAN | 192.168.92.236 (INT 포털) | 192.168.92.236 | 443 | TCP | ALLOW | INT→릴레이 |
| 3 | LAN→LAN | 192.168.92.0/24 | 192.168.92.0/24 | * | * | ALLOW | C4I 내부 전체 허용 |
| 4 | LAN→WAN | 192.168.92.236 | 192.168.92.236 | 8080 | TCP | ALLOW | 릴레이→INT |
| 5 | WAN→LAN | * | * | * | * | **DENY** | 기본 거부 |
| 6 | LAN→WAN | * | * | * | * | **DENY** | C4I→외부 기본 거부 |

### 3.2 DNS 설정 (C4I 내부)

```bash
192.168.92.236   gw.c4i.local
192.168.92.236  relay.c4i.local
192.168.92.236  cop.c4i.local
192.168.92.236  data.c4i.local
192.168.92.236  summary.c4i.local
(테스트 미할당)  ops-pc-1.c4i.local
(테스트 미할당)  ops-pc-2.c4i.local
(테스트 미할당)  ops-pc-3.c4i.local
(테스트 미할당)  ops-pc-4.c4i.local
192.168.92.236  ops-pc-5.c4i.local
```

### 3.3 네트워크 토폴로지

```
                    ┌──────────────────────────────────────────────────┐
                    │              C4I 존 (192.168.92.0/24)            │
                    │                                                    │
    ┌───────────┐   │   ┌──────────┐    ┌──────────┐    ┌──────────┐   │
    │ 군 INT    │───┼──▶│ C12 망연동│───▶│ C14 데이터│◀──▶│ C13 COP  │   │
    │ 이벤트    │   │   │ 서버     │    │ 수집 서버 │    │ 상황도   │   │
    │ 192.168.  │   │   │ .130.10  │    │ .130.12  │    │ .130.11  │   │
    │ 110.10    │   │   └──────────┘    └────┬─────┘    └────┬─────┘   │
    └───────────┘   │                        │               │         │
                    │                        ▼               │         │
        OPNSense-7  │                   ┌──────────┐         │         │
        (방화벽)     │                   │ C15 AI   │         │         │
                    │                   │ 요약 서버 │         │         │
                    │                   │ .130.13  │         │         │
                    │                   └────┬─────┘         │         │
                    │                        │               │         │
                    │                        ▼               ▼         │
                    │              ┌──────────────────────────────┐     │
                    │              │   C16 작전용 PC 1~5          │     │
                    │              │   .130.21 ~ .130.25          │     │
                    │              │   COP 지도 + AI 브리핑 열람   │     │
                    │              └──────────────────────────────┘     │
                    └──────────────────────────────────────────────────┘
```

### 3.4 크리덴셜 참조

| 자산 | 서비스 | 계정 | 비밀번호 | 용도 |
|------|--------|------|----------|------|
| C16 | Windows 로컬 | operator | Op3rator!C4I | 일반 사용자 |
| C16 | Windows 관리자 | c4i-admin | C4I!Admin#2024 | 로컬 관리자 |

### 3.5 네트워크 포트

| 자산 | IP | 포트 | 프로토콜 | 서비스 |
|------|-----|------|----------|--------|
| C16 | (테스트 미할당)~25 | - | - | 아웃바운드만 |

### 3.6 블루팀 탐지 요약 (전체 탐지 체인)

```
[탐지 체인 — 데이터 변조 공격]

1차 경보: C12 비정상 SSH 로그인
├─ 탐지: /var/log/auth.log에 relay-admin 로그인
├─ 심각도: HIGH
└─ 후속: sync_events.py 해시 검증

2차 경보: C12 스크립트 무결성 실패
├─ 탐지: sha256sum 불일치
├─ 심각도: CRITICAL
└─ 후속: 스크립트 diff 분석, 원본 복구

3차 경보: C14 friendly 이벤트 소멸
├─ 탐지: /api/stats에서 friendly_move = 0
├─ 심각도: CRITICAL
└─ 후속: C12 릴레이 로그 확인

4차 경보: C14 대량 DELETE/POST
├─ 탐지: API 로그에서 DELETE 후 대량 POST 패턴
├─ 심각도: CRITICAL
└─ 후속: 이벤트 백업에서 복구

5차 경보: C13 SQL Injection 시도
├─ 탐지: Tomcat access_log UNION/INSERT 패턴
├─ 심각도: HIGH
└─ 후속: getUnit.jsp 접근 차단, WAF 적용

6차 경보: C15 브리핑 이상
├─ 탐지: 위협 수준 STABLE → CRITICAL 급변
├─ 심각도: HIGH
└─ 후속: C14 데이터 검증, 브리핑 폐기
```

---

> **문서 끝** — 이 문서는 사이버 훈련 환경 구축을 위한 기술 설계서이며, 실제 군사 시스템과 무관하다. 모든 IP, 크리덴셜, 도메인은 가상 환경 전용이다.
