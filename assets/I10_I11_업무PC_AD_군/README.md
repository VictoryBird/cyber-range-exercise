# 자산 #I10~#I11: 군 업무용 PC + AD (corp.mnd.local)

## 개요

| 항목 | 내용 |
|------|------|
| 자산 | 업무용 PC 5대 + 관리자 PC 1대 + AD/DC 1대 |
| IP 대역 | 192.168.110.31~35 (업무용), .40 (관리자), .50 (DC) |
| OS | Windows 10/11 Pro (PC), Windows Server 2022 (DC) |
| AD 도메인 | corp.mnd.local |
| 훈련 단계 | STEP 4-2: 공급망 공격(패치 서버) → 감염 → 자격증명 탈취 → 도메인 장악 |

## 배포 순서

### 1단계: DC 구성 (192.168.110.50 — MIL-DC01)

```powershell
.\scripts\01_setup_dc.ps1
# 재부팅 후:
.\scripts\02_create_users.ps1
.\scripts\03_configure_gpo.ps1
```

### 2단계: PC 도메인 가입 (192.168.110.31~35, .40)

```powershell
.\scripts\04_join_domain.ps1
```

### 3단계: 자동 업데이트 클라이언트 설치 (핵심 -- 공급망 공격 벡터)

```powershell
.\scripts\05_update_checker.ps1
```

## 주요 사용자 계정

| 사용자 | 비밀번호 | 부서 | PC |
|--------|----------|------|-----|
| mil_admin | MilAdmin2026! | 정보통신과 (Domain Admin) | MIL-ADMIN01 |
| mil_kim | Jungsu2026! | 작전지원과 | MIL-PC01 |
| mil_lee | Hyunwoo123! | 정보보호과 | MIL-PC02 |
| mil_park | Seojun2026! | 군수지원과 | MIL-PC03 |
| mil_choi | Minseo2026! | 통신운영과 | MIL-PC04 |
| mil_jung | Yujin2026! | 인사과 | MIL-PC05 |
| mil_han | Dohyun2026! | 전산과 | MIL-PC01 (보조) |

## 핵심 취약점: 공급망 공격 벡터

`05_update_checker.ps1`가 설치하는 자동 업데이트 클라이언트는 30분 간격으로 패치 서버(http://192.168.120.10)에서 매니페스트를 확인하고, 신규 패치를 다운로드하여 SYSTEM 권한으로 실행합니다.

- HTTP 평문 통신 (MITM 가능)
- 파일 서명/해시 미검증
- 다운로드 즉시 SYSTEM 권한 실행
