# 구현 진행 상황

> 마지막 업데이트: 2026-03-28

## 전체 요약

| 항목 | 값 |
|------|-----|
| 전체 자산 수 | 27개 (논리 자산 기준) |
| 구현 완료 | 4개 |
| 미구현 | 23개 |
| 현재 작업 | Group 1 완료, Group 2 대기 |

---

## 구현 그룹 (공격 체인 PHASE 순서)

### Group 1 — PHASE 1: 공공기관 DMZ 침투
| 자산 | 이름 | IP | 스택 | 상태 |
|------|------|-----|------|------|
| 01 | 외부 포털 서버 | 192.168.92.201 | Next.js 15.0.3 + FastAPI + Nginx | ✅ 완료 |
| 03 | 민원 접수 서버 | 192.168.92.203 | React(Vite) + FastAPI + MinIO + Nginx | ✅ 완료 |
| 06 | 민원 처리 서버 | 192.168.92.206 | Celery + Redis + LibreOffice + Pillow | ✅ 완료 |
| 08 | DB 서버 | 192.168.92.208 | PostgreSQL | ✅ 완료 |

### Group 2 — PHASE 2: 공공기관 INT 확산
| 자산 | 이름 | IP | 스택 | 상태 |
|------|------|-----|------|------|
| 04 | 내부 업무 포털 | 192.168.92.204 | Nginx + Django/Spring Boot + PostgreSQL | ⬜ 미구현 |
| 05 | 웹메일 서버 | 192.168.92.205 | Postfix + Dovecot + Roundcube | ⬜ 미구현 |
| 09 | 업무 PC (5대) | 192.168.92.209 | Windows 10/11 | ⬜ 미구현 |
| 10 | 관리자 PC | 192.168.92.210 | Windows 10/11 | ⬜ 미구현 |
| 11 | 인증 서버 (DC) | 192.168.92.211 | Windows Server 2022 + AD | ⬜ 미구현 |

### Group 3 — PHASE 2→3: 공공→군 피벗
| 자산 | 이름 | IP | 스택 | 상태 |
|------|------|-----|------|------|
| 02 | 메일 포털 게이트 | 192.168.92.202 | Nginx | ⬜ 미구현 |
| 07 | AI 어시스턴트 | 192.168.92.207 | Ollama + OpenWebUI (Docker) | ⬜ 미구현 |

### Group 4 — PHASE 3: OT 침투
| 자산 | 이름 | IP | 스택 | 상태 |
|------|------|-----|------|------|
| 12 | Historian 서버 | 192.168.92.212 | InfluxDB + Python API | ⬜ 미구현 |
| 13 | SCADA 서버 | 192.168.92.213 | scada-lts + Java + Node-RED | ⬜ 미구현 |
| 14 | PLC 시뮬레이터 | 192.168.92.214 | Python simulator | ⬜ 미구현 |
| 15 | 운영자 PC (2대) | 192.168.92.215 | Windows 10/11 | ⬜ 미구현 |

### Group 5 — PHASE 4: 군 DMZ 침투
| 자산 | 이름 | IP | 스택 | 상태 |
|------|------|-----|------|------|
| D1 | 군 외부 포털 | 192.168.92.240 | eGovframework + Apache Tomcat | ⬜ 미구현 |
| D2 | VPN 게이트웨이 | 192.168.92.241 | OpenVPN Access Server | ⬜ 미구현 |
| D3 | 자료교환체계 | 192.168.92.242 | Nextcloud | ⬜ 미구현 |
| D4-D5 | 허니팟 | 192.168.92.243-244 | Cowrie + SNARE (Docker) | ⬜ 미구현 |

### Group 6 — PHASE 4: 군 INT 침투
| 자산 | 이름 | IP | 스택 | 상태 |
|------|------|-----|------|------|
| I6 | 군 업무 포털 | 192.168.92.245 | eGovframework + Spring Boot + PostgreSQL | ⬜ 미구현 |
| I7 | 군 웹메일 | 192.168.92.246 | Postfix + Dovecot + Roundcube | ⬜ 미구현 |
| I8 | 문서 저장 서버 | 192.168.92.247 | FastAPI + Nginx + PostgreSQL | ⬜ 미구현 |
| I9 | 패치 관리 서버 | 192.168.92.248 | Nginx/Apache HTTP Repo | ⬜ 미구현 |
| I10 | 군 업무 PC (5대) | 192.168.92.249 | Windows 10/11 | ⬜ 미구현 |
| I11 | 군 관리자 PC | 192.168.92.250 | Windows 10/11 + AD | ⬜ 미구현 |

### Group 7 — PHASE 5: C4I 데이터 조작
| 자산 | 이름 | IP | 스택 | 상태 |
|------|------|-----|------|------|
| C12 | 망 연동 서버 | 192.168.92.251 | Python API script | ⬜ 미구현 |
| C13 | 작전 상황도 서버 | 192.168.92.252 | Apache Tomcat + JSP + OpenLayers | ⬜ 미구현 |
| C14 | 데이터 수집 서버 | 192.168.92.253 | PostgreSQL + FastAPI | ⬜ 미구현 |
| C15 | 상황 요약 AI | 192.168.92.254 | LLaMA + Python pipeline | ⬜ 미구현 |
| C16 | 작전용 PC (5대) | 192.168.92.255 | Windows 10/11 | ⬜ 미구현 |

---

## 완료 이력

| 날짜 | 자산 | 내용 |
|------|------|------|
| 2026-03-28 | 08 DB 서버 | setup.sh + SQL 스키마/시드 + 취약점 구현 완료, VM 테스트 통과 |
| 2026-03-28 | 01 외부 포털 | FastAPI + Next.js + Nginx 구현 완료, Playwright 테스트 통과 |
| 2026-03-28 | 03 민원 접수 | React(Vite) + FastAPI + MinIO + Nginx, 4단계 접수폼, 취약점 4종 (확장자우회/Content-Type/IDOR/하드코딩토큰) |
| 2026-03-28 | 06 민원 처리 | Celery + Redis + LibreOffice/Pillow 파이프라인, 취약점 7종 (RCE/무인증Redis/하드코딩DB/SUPERUSER 등) |
