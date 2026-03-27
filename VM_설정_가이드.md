# VM 설정 가이드 — 호스트명 + 일반 사용자 계정

> vSphere에서 VM 생성 시 아래 표를 참고하여 호스트명과 일반 사용자를 설정한다.
> root 비밀번호는 모든 Linux VM 공통: `Vald0ria!Root`
> Windows Administrator 비밀번호는 공통: `Vald0ria!Admin`

---

## 공공기관 DMZ (203.238.140.0/24)

| # | 자산명 | IP | OS | VM 호스트명 | 일반 사용자 | 비밀번호 |
|---|--------|----|----|-----------|-----------|---------|
| 1 | 외부 포털 서버 | 203.238.140.10 | Ubuntu 22.04 | `pub-portal` | `portaladm` | `Portal@dmin2026` |
| 2 | 메일 포털 게이트 | 203.238.140.11 | Ubuntu 22.04 | `mail-gateway` | `mailadm` | `M@ilGw2026!` |
| 3 | 민원 접수 서버 | 203.238.140.12 | Ubuntu 22.04 | `minwon-intake` | `minwon` | `Minw0n@2026!` |

## 공공기관 INT (192.168.100.0/24)

| # | 자산명 | IP | OS | VM 호스트명 | 일반 사용자 | 비밀번호 |
|---|--------|----|----|-----------|-----------|---------|
| 4 | 내부 업무 포털 | 192.168.100.10 | Ubuntu 22.04 | `intranet` | `intraadm` | `Intr@n3t2026!` |
| 5 | 웹메일 | 192.168.100.11 | Debian 12 | `webmail` | `mailadm` | `W3bMail2026!` |
| 6 | 민원 처리 서버 | 192.168.100.12 | Ubuntu 22.04 | `minwon-worker` | `worker` | `W0rker@2026!` |
| 7 | AI Assistant | 192.168.100.13 | Ubuntu 22.04 | `ai-assistant` | `aiadm` | `AiAsst2026!` |
| 8 | DB 서버 | 192.168.100.20 | Ubuntu 22.04 | `db-server` | `dbadm` | `DbAdm!n2026` |
| 9 | 업무용 PC-1 | 192.168.100.31 | Windows 10/11 | `WS-PC01` | `user_lee` | `Seoyeon123!` |
| 9 | 업무용 PC-2 | 192.168.100.32 | Windows 10/11 | `WS-PC02` | `user_choi` | `Donghyun1!` |
| 9 | 업무용 PC-3 | 192.168.100.33 | Windows 10/11 | `WS-PC03` | `user_jung` | `Haeun2024!` |
| 9 | 업무용 PC-4 | 192.168.100.34 | Windows 10/11 | `WS-PC04` | `user_han` | `Jiwoo2024!` |
| 9 | 업무용 PC-5 | 192.168.100.35 | Windows 10/11 | `WS-PC05` | `user_park` | `Minjun2024!` |
| 10 | 관리자 PC | 192.168.100.40 | Windows 10/11 | `WS-ADMIN01` | `admin_kim` | `P@ssw0rd2024!` |
| 11 | 인증 서버 (AD/DC) | 192.168.100.50 | Win Server 2022 | `DC01` | `sysadmin` | `AdminP@ss!` |

## Industrial DMZ (192.168.200.0/24)

| # | 자산명 | IP | OS | VM 호스트명 | 일반 사용자 | 비밀번호 |
|---|--------|----|----|-----------|-----------|---------|
| 12 | Historian 서버 | 192.168.200.10 | Ubuntu 22.04 | `historian` | `histadm` | `Hist0r!an2026` |

## OT (192.168.201.0/24)

| # | 자산명 | IP | OS | VM 호스트명 | 일반 사용자 | 비밀번호 |
|---|--------|----|----|-----------|-----------|---------|
| 13 | SCADA 서버 | 192.168.201.10 | Rocky Linux 9 | `scada-server` | `scadaadm` | `Sc@da2026!` |
| 14 | PLC 시뮬레이터 | 192.168.201.11 | Ubuntu 22.04 | `plc-simulator` | `plcadm` | `PlcS!m2026` |
| 15 | 운영자 PC-1 | 192.168.201.21 | Windows 10/11 | `OT-PC01` | `operator1` | `Oper@tor1!` |
| 15 | 운영자 PC-2 | 192.168.201.22 | Windows 10/11 | `OT-PC02` | `operator2` | `Oper@tor2!` |

## 군 DMZ (211.57.64.0/24)

| # | 자산명 | IP | OS | VM 호스트명 | 일반 사용자 | 비밀번호 |
|---|--------|----|----|-----------|-----------|---------|
| D1 | 외부 포털 서버 | 211.57.64.10 | Rocky Linux 9 | `mil-ext-portal` | `miladm` | `M!lPortal2026` |
| D2 | VPN 게이트웨이 | 211.57.64.11 | Ubuntu 22.04 | `vpn-gateway` | `vpnadm` | `VpnGw@2026!` |
| D3 | 자료교환체계 | 211.57.64.12 | Ubuntu 22.04 | `file-exchange` | `ncadm` | `Nextcl0ud2026!` |
| D4 | 허니팟 SSH | 211.57.64.13 | Ubuntu 22.04 | `hp-ssh` | `hpadm` | `H0neyP0t2026!` |
| D5 | 허니팟 Web | 211.57.64.14 | Ubuntu 22.04 | `hp-web` | `hpadm` | `H0neyP0t2026!` |

## 군 INT (192.168.110.0/24)

| # | 자산명 | IP | OS | VM 호스트명 | 일반 사용자 | 비밀번호 |
|---|--------|----|----|-----------|-----------|---------|
| I6 | 내부 업무 포털 | 192.168.110.10 | Rocky Linux 9 | `mil-intranet` | `milintra` | `M!lIntra2026` |
| I7 | 웹메일 서버 | 192.168.110.11 | Debian 12 | `mil-webmail` | `milmail` | `M!lMail2026!` |
| I8 | 문서 저장 서버 | 192.168.110.12 | Ubuntu 22.04 | `mil-docstorage` | `docadm` | `D0cSt0r2026!` |
| I9 | 패치 관리 서버 | 192.168.120.10 | Debian 12 | `mil-patch` | `patchadm` | `P@tchMgr2026!` |
| I10 | 업무용 PC-1 | 192.168.110.31 | Windows 10/11 | `MIL-PC01` | `mil_user01` | `M!lUser01@` |
| I10 | 업무용 PC-2 | 192.168.110.32 | Windows 10/11 | `MIL-PC02` | `mil_user02` | `M!lUser02@` |
| I10 | 업무용 PC-3 | 192.168.110.33 | Windows 10/11 | `MIL-PC03` | `mil_user03` | `M!lUser03@` |
| I10 | 업무용 PC-4 | 192.168.110.34 | Windows 10/11 | `MIL-PC04` | `mil_user04` | `M!lUser04@` |
| I10 | 업무용 PC-5 | 192.168.110.35 | Windows 10/11 | `MIL-PC05` | `mil_user05` | `M!lUser05@` |
| I11 | 관리자 PC | 192.168.110.40 | Windows 10/11 | `MIL-ADMIN01` | `mil_admin` | `M!lAdm!n2026` |

## 군 INT — AD/DC

| # | 자산명 | IP | OS | VM 호스트명 | 일반 사용자 | 비밀번호 |
|---|--------|----|----|-----------|-----------|---------|
| — | 군 인증 서버 | 192.168.110.50 | Win Server 2022 | `MIL-DC01` | `mil_sysadmin` | `M!lSysAdm2026!` |

## C4I (192.168.130.0/24)

| # | 자산명 | IP | OS | VM 호스트명 | 일반 사용자 | 비밀번호 |
|---|--------|----|----|-----------|-----------|---------|
| C12 | 망 연동 서버 | 192.168.130.10 | Ubuntu 22.04 | `c4i-relay` | `relayadm` | `R3lay@2026!` |
| C13 | 작전 상황도 서버 | 192.168.130.11 | Rocky Linux 9 | `c4i-cop` | `copadm` | `C0pMap2026!` |
| C14 | 데이터 수집 서버 | 192.168.130.12 | Ubuntu 22.04 | `c4i-datacollect` | `dataadm` | `D@taC0ll2026!` |
| C15 | 상황 요약 AI | 192.168.130.13 | Ubuntu 22.04 | `c4i-summary-ai` | `aiadm` | `SumAi2026!` |
| C16 | 작전용 PC-1 | 192.168.130.21 | Windows 10/11 | `C4I-PC01` | `ops_user01` | `0psUser01!` |
| C16 | 작전용 PC-2 | 192.168.130.22 | Windows 10/11 | `C4I-PC02` | `ops_user02` | `0psUser02!` |
| C16 | 작전용 PC-3 | 192.168.130.23 | Windows 10/11 | `C4I-PC03` | `ops_user03` | `0psUser03!` |
| C16 | 작전용 PC-4 | 192.168.130.24 | Windows 10/11 | `C4I-PC04` | `ops_user04` | `0psUser04!` |
| C16 | 작전용 PC-5 | 192.168.130.25 | Windows 10/11 | `C4I-PC05` | `ops_user05` | `0psUser05!` |

## OPNSense 방화벽 (192.168.1.0/24 관리망)

| # | 자산명 | 관리 IP | VM 호스트명 | 관리자 | 비밀번호 |
|---|--------|---------|-----------|--------|---------|
| FW1 | OPNSense-1 | 192.168.1.11 | `fw-opnsense1` | `root` | `opnsense` |
| FW2 | OPNSense-2 | 192.168.1.12 | `fw-opnsense2` | `root` | `opnsense` |
| FW3 | OPNSense-3 | 192.168.1.13 | `fw-opnsense3` | `root` | `opnsense` |
| FW4 | OPNSense-4 | 192.168.1.14 | `fw-opnsense4` | `root` | `opnsense` |
| FW5 | OPNSense-5 | 192.168.1.15 | `fw-opnsense5` | `root` | `opnsense` |
| FW6 | OPNSense-6 | 192.168.1.16 | `fw-opnsense6` | `root` | `opnsense` |
| FW7 | OPNSense-7 | 192.168.1.17 | `fw-opnsense7` | `root` | `opnsense` |

---

## 비밀번호 규칙

- **Linux root**: `Vald0ria!Root` (전체 공통)
- **Windows Administrator**: `Vald0ria!Admin` (전체 공통)
- **일반 사용자**: 자산별 고유 (위 표 참조)
- **AD 도메인 사용자**: 설계 문서 및 시드 데이터 참조
- **OPNSense**: 설치 후 즉시 변경 권장

## VM 총 수

| 구분 | Linux VM | Windows VM | OPNSense | 합계 |
|------|----------|-----------|----------|------|
| 공공기관 | 6 | 7 | 2 | 15 |
| Industrial/OT | 2 | 2 | 2 | 6 |
| 군 | 7 | 7 | 2 | 16 |
| C4I | 3 | 5 | 1 | 9 |
| **합계** | **18** | **21** | **7** | **46** |
