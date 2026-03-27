# 자산 #09~#11: 공공기관 업무용 PC + AD (corp.mois.local)

## 개요

| 항목 | 내용 |
|------|------|
| 자산 | 업무용 PC 5대 + 관리자 PC 1대 + AD/DC 1대 |
| IP 대역 | 192.168.100.31~35 (업무용), .40 (관리자), .50 (DC) |
| OS | Windows 10/11 Pro (PC), Windows Server 2022 (DC) |
| AD 도메인 | corp.mois.local |
| 훈련 단계 | STEP 2-4 ~ 2-6: 피싱 감염 → 자격증명 탈취 → 측면 이동 → 도메인 장악 |

## 배포 순서

### 1단계: DC 구성 (192.168.100.50 — Windows Server 2022)

```powershell
# 1. AD DS 프로모션
.\scripts\01_setup_dc.ps1

# 2. OU 및 사용자 생성
.\scripts\02_create_ou_users.ps1

# 3. GPO 구성 (의도적 약화)
.\scripts\03_configure_gpo.ps1

# 4. Sysmon 설치 (블루팀용)
.\scripts\05_install_sysmon.ps1
```

### 2단계: 업무용 PC 도메인 가입 (192.168.100.31~35, .40)

```powershell
# 각 PC에서 실행 (호스트명, IP를 PC에 맞게 수정)
.\scripts\04_join_domain.ps1

# Sysmon 설치
.\scripts\05_install_sysmon.ps1
```

### 3단계: 검증

```powershell
.\scripts\verify.ps1
```

## 주요 사용자 계정

| 사용자 | 비밀번호 | 부서 | PC |
|--------|----------|------|-----|
| admin_kim | P@ssw0rd2024! | IT운영팀 (Domain Admin) | WS-ADMIN01 |
| sysadmin | AdminP@ss! | IT운영팀 (Domain Admin) | DC01 |
| user_lee | Seoyeon123! | 민원처리과 (피싱 대상) | WS-PC01 |
| user_choi | Donghyun1! | 정보보안과 | WS-PC02 |
| user_jung | Haeun2024! | 총무과 | WS-PC03 |
| user_han | Jiwoo2024! | 정보화기획과 | WS-PC04 |
| user_park | Minjun2024! | 대외협력과 | WS-PC05 |

## 의도적 취약점 목록

- 비밀번호 복잡성 미적용, 최소 8자
- 계정 잠금 없음 (브루트포스 가능)
- WDigest 활성화 (평문 비밀번호 메모리 노출)
- Credential Guard 비활성화 (Mimikatz 허용)
- SMB 서명 미적용 (NTLM 릴레이 가능)
- PowerShell 실행 정책 Unrestricted
- LAPS 미적용 (로컬 Admin 비밀번호 동일: LocalAdmin1!)
- RDP/WinRM 전체 허용
