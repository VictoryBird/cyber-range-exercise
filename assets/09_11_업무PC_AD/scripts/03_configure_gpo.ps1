# ============================================================
# 03_configure_gpo.ps1 — 그룹 정책(GPO) 구성 (의도적 약화)
# 대상: DC01 (192.168.100.50)
# 도메인: corp.mois.local
# ============================================================
# 이 스크립트는 훈련 시나리오를 위해 의도적으로 약한 GPO를 설정합니다.
# 각 취약점에는 [취약점] 태그와 올바른 설정 방법을 주석으로 명시합니다.
# ============================================================

#Requires -RunAsAdministrator

$ErrorActionPreference = "Stop"
Import-Module GroupPolicy
Import-Module ActiveDirectory

$domainDN = "DC=corp,DC=mois,DC=local"

Write-Host "============================================" -ForegroundColor Cyan
Write-Host " GPO 설정 시작 (의도적 약화)" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

# -------------------------------------------------------
# [1/7] 비밀번호 정책 약화 (Default Domain Policy)
# -------------------------------------------------------
Write-Host "`n[1/7] 비밀번호 정책 약화..." -ForegroundColor Yellow

# [취약점] 약한 비밀번호 정책 — 최소 길이 8자, 복잡성 없음, 잠금 없음
# 올바른 설정: 최소 12자, 복잡성 사용, 잠금 임계값 5회, 비밀번호 기록 24개
$tempDir = "C:\temp"
if (-not (Test-Path $tempDir)) { New-Item -Path $tempDir -ItemType Directory -Force | Out-Null }

$secTemplate = @"
[Unicode]
Unicode=yes
[System Access]
MinimumPasswordLength = 8
PasswordComplexity = 0
MinimumPasswordAge = 0
MaximumPasswordAge = 0
PasswordHistorySize = 0
LockoutBadCount = 0
ClearTextPassword = 0
"@

# [취약점] 최소 비밀번호 길이 8자 — 권장: 12자 이상
# [취약점] 비밀번호 복잡성 미적용 — 권장: PasswordComplexity = 1
# [취약점] 비밀번호 기록 0개 — 권장: PasswordHistorySize = 24
# [취약점] 계정 잠금 없음 (LockoutBadCount = 0) — 권장: 5회 잠금
# [취약점] 비밀번호 만료 없음 (MaximumPasswordAge = 0) — 권장: 90일

$secTemplate | Out-File -FilePath "$tempDir\weak_password_policy.inf" -Encoding Unicode
secedit /configure /db "$tempDir\secedit.sdb" /cfg "$tempDir\weak_password_policy.inf" /areas SECURITYPOLICY /quiet

Write-Host "  [취약점] 비밀번호 최소 길이: 8자 (권장: 12자)" -ForegroundColor Red
Write-Host "  [취약점] 비밀번호 복잡성: 사용 안 함 (권장: 사용)" -ForegroundColor Red
Write-Host "  [취약점] 계정 잠금: 없음 (권장: 5회)" -ForegroundColor Red
Write-Host "  [취약점] 비밀번호 만료: 없음 (권장: 90일)" -ForegroundColor Red

# -------------------------------------------------------
# [2/7] PC-보안설정 GPO 생성 (워크스테이션 보안 약화)
# -------------------------------------------------------
Write-Host "`n[2/7] PC-보안설정 GPO 생성..." -ForegroundColor Yellow

$gpoSecurity = "PC-보안설정"
try {
    New-GPO -Name $gpoSecurity -Comment "워크스테이션 보안 설정 (훈련용 의도적 약화)" | Out-Null
} catch {
    Write-Host "  GPO '$gpoSecurity' 이미 존재합니다." -ForegroundColor DarkYellow
}

# [취약점] WDigest 활성화 — 평문 비밀번호가 메모리에 저장됨 (Mimikatz로 추출 가능)
# 올바른 설정: UseLogonCredential = 0 (Windows 8.1/2012 R2 이후 기본값)
Set-GPRegistryValue -Name $gpoSecurity `
    -Key "HKLM\SYSTEM\CurrentControlSet\Control\SecurityProviders\WDigest" `
    -ValueName "UseLogonCredential" -Type DWord -Value 1
Write-Host "  [취약점] WDigest 활성화 (평문 PW 메모리 노출)" -ForegroundColor Red

# [취약점] Credential Guard 비활성화 — Mimikatz가 LSASS에서 자격증명 추출 가능
# 올바른 설정: EnableVirtualizationBasedSecurity = 1, LsaCfgFlags = 1
Set-GPRegistryValue -Name $gpoSecurity `
    -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard" `
    -ValueName "EnableVirtualizationBasedSecurity" -Type DWord -Value 0
Set-GPRegistryValue -Name $gpoSecurity `
    -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard" `
    -ValueName "LsaCfgFlags" -Type DWord -Value 0
Write-Host "  [취약점] Credential Guard 비활성화 (Mimikatz 허용)" -ForegroundColor Red

# [취약점] PowerShell 실행 정책 Unrestricted — 서명되지 않은 스크립트 무제한 실행
# 올바른 설정: ExecutionPolicy = "AllSigned" 또는 "RemoteSigned"
Set-GPRegistryValue -Name $gpoSecurity `
    -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\PowerShell" `
    -ValueName "EnableScripts" -Type DWord -Value 1
Set-GPRegistryValue -Name $gpoSecurity `
    -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\PowerShell" `
    -ValueName "ExecutionPolicy" -Type String -Value "Unrestricted"
Write-Host "  [취약점] PowerShell 실행 정책: Unrestricted (권장: AllSigned)" -ForegroundColor Red

# [취약점] SMB 서명 미적용 — NTLM 릴레이 공격 가능
# 올바른 설정: RequireSecuritySignature = 1 (서버 및 클라이언트 모두)
Set-GPRegistryValue -Name $gpoSecurity `
    -Key "HKLM\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" `
    -ValueName "RequireSecuritySignature" -Type DWord -Value 0
Set-GPRegistryValue -Name $gpoSecurity `
    -Key "HKLM\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters" `
    -ValueName "RequireSecuritySignature" -Type DWord -Value 0
Write-Host "  [취약점] SMB 서명 미적용 (NTLM 릴레이 가능)" -ForegroundColor Red

# GPO 연결: 워크스테이션 OU
New-GPLink -Name $gpoSecurity -Target "OU=워크스테이션,$domainDN" -ErrorAction SilentlyContinue
Write-Host "  GPO 연결: OU=워크스테이션" -ForegroundColor Green

# -------------------------------------------------------
# [3/7] PC-방화벽정책 GPO (과도한 허용)
# -------------------------------------------------------
Write-Host "`n[3/7] PC-방화벽정책 GPO 생성..." -ForegroundColor Yellow

$gpoFirewall = "PC-방화벽정책"
try {
    New-GPO -Name $gpoFirewall -Comment "워크스테이션 방화벽 정책 (훈련용 과도한 허용)" | Out-Null
} catch {
    Write-Host "  GPO '$gpoFirewall' 이미 존재합니다." -ForegroundColor DarkYellow
}

# 방화벽 규칙은 GPO 스타트업 스크립트로 배포
$fwScript = @'
# 워크스테이션 방화벽 규칙 배포 스크립트 (GPO 스타트업)

# [취약점] RDP 전체 허용 — 관리자만 허용해야 하나 전체 허용
# 올바른 설정: -RemoteAddress를 관리자 PC IP(192.168.100.40)로 제한
New-NetFirewallRule -DisplayName "Allow RDP" `
    -Direction Inbound -Protocol TCP -LocalPort 3389 `
    -Action Allow -Profile Domain -ErrorAction SilentlyContinue

# [취약점] SMB 전체 허용
# 올바른 설정: 필요한 서버 IP만 허용
New-NetFirewallRule -DisplayName "Allow SMB" `
    -Direction Inbound -Protocol TCP -LocalPort 445 `
    -Action Allow -Profile Domain -ErrorAction SilentlyContinue

# [취약점] WinRM 전체 허용 — PowerShell 원격 실행 가능
# 올바른 설정: -RemoteAddress를 관리자 PC IP로 제한
New-NetFirewallRule -DisplayName "Allow WinRM" `
    -Direction Inbound -Protocol TCP -LocalPort 5985 `
    -Action Allow -Profile Domain -ErrorAction SilentlyContinue

# ICMP 허용 (정상)
New-NetFirewallRule -DisplayName "Allow ICMP" `
    -Direction Inbound -Protocol ICMPv4 `
    -Action Allow -Profile Domain -ErrorAction SilentlyContinue
'@

$fwScriptPath = "\\$env:COMPUTERNAME\SYSVOL\corp.mois.local\scripts\setup_firewall.ps1"
$sysvolScriptsDir = "C:\Windows\SYSVOL\sysvol\corp.mois.local\scripts"
if (-not (Test-Path $sysvolScriptsDir)) { New-Item -Path $sysvolScriptsDir -ItemType Directory -Force | Out-Null }
$fwScript | Out-File -FilePath "$sysvolScriptsDir\setup_firewall.ps1" -Encoding UTF8

Write-Host "  방화벽 스크립트 배포: $sysvolScriptsDir\setup_firewall.ps1" -ForegroundColor Green

# -------------------------------------------------------
# [4/7] LAPS 미적용 확인 (의도적)
# -------------------------------------------------------
Write-Host "`n[4/7] LAPS 미적용 (의도적)..." -ForegroundColor Yellow

# [취약점] LAPS(Local Administrator Password Solution) 미적용
# 모든 PC의 로컬 Administrator 비밀번호가 동일: LocalAdmin1!
# → Pass-the-Hash로 모든 PC 접근 가능
# 올바른 설정: LAPS를 설치하여 각 PC 로컬 Admin 비밀번호를 랜덤화
Write-Host "  [취약점] LAPS 미적용 — 모든 PC 로컬 Admin 비밀번호 동일 (LocalAdmin1!)" -ForegroundColor Red
Write-Host "  [권장] LAPS 설치: Install-Module -Name LAPS" -ForegroundColor DarkYellow

# -------------------------------------------------------
# [5/7] PowerShell 스크립트 블록 로깅 (블루팀용)
# -------------------------------------------------------
Write-Host "`n[5/7] PowerShell 로깅 GPO (블루팀용)..." -ForegroundColor Yellow

$gpoPSLog = "PowerShell-로깅"
try {
    New-GPO -Name $gpoPSLog -Comment "PowerShell 스크립트 블록 로깅 (블루팀 탐지용)" | Out-Null
} catch {
    Write-Host "  GPO '$gpoPSLog' 이미 존재합니다." -ForegroundColor DarkYellow
}

# PowerShell 스크립트 블록 로깅 활성화 (블루팀 탐지용 — 정상 설정)
Set-GPRegistryValue -Name $gpoPSLog `
    -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging" `
    -ValueName "EnableScriptBlockLogging" -Type DWord -Value 1
Set-GPRegistryValue -Name $gpoPSLog `
    -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging" `
    -ValueName "EnableScriptBlockInvocationLogging" -Type DWord -Value 1

# 도메인 루트에 연결
New-GPLink -Name $gpoPSLog -Target $domainDN -ErrorAction SilentlyContinue
Write-Host "  PowerShell 스크립트 블록 로깅 활성화 (블루팀용)" -ForegroundColor Green

# -------------------------------------------------------
# [6/7] DC 감사 정책 (블루팀용)
# -------------------------------------------------------
Write-Host "`n[6/7] DC 감사 정책 (블루팀용)..." -ForegroundColor Yellow

$gpoAudit = "DC-감사정책"
try {
    New-GPO -Name $gpoAudit -Comment "DC 감사 로그 설정 (블루팀 탐지용)" | Out-Null
} catch {
    Write-Host "  GPO '$gpoAudit' 이미 존재합니다." -ForegroundColor DarkYellow
}

# 감사 정책 — 성공/실패 모두 기록 (블루팀 탐지를 위한 정상 설정)
$auditTemplate = @"
[Unicode]
Unicode=yes
[Event Audit]
AuditSystemEvents = 3
AuditLogonEvents = 3
AuditObjectAccess = 3
AuditPrivilegeUse = 3
AuditPolicyChange = 3
AuditAccountManage = 3
AuditProcessTracking = 3
AuditDSAccess = 3
AuditAccountLogon = 3
"@

$auditTemplate | Out-File -FilePath "$tempDir\audit_policy.inf" -Encoding Unicode
# 감사 정책은 DC에 직접 적용
auditpol /set /category:"Logon/Logoff" /success:enable /failure:enable
auditpol /set /category:"Account Logon" /success:enable /failure:enable
auditpol /set /category:"Account Management" /success:enable /failure:enable
auditpol /set /category:"DS Access" /success:enable /failure:enable
auditpol /set /category:"Object Access" /success:enable /failure:enable
auditpol /set /category:"Privilege Use" /success:enable /failure:enable
auditpol /set /category:"Process Tracking" /success:enable /failure:enable

Write-Host "  감사 정책 활성화 (전체 카테고리, 성공/실패)" -ForegroundColor Green

# -------------------------------------------------------
# [7/7] Sysmon 배포 GPO
# -------------------------------------------------------
Write-Host "`n[7/7] Sysmon 배포 GPO..." -ForegroundColor Yellow

$gpoSysmon = "Sysmon-배포"
try {
    New-GPO -Name $gpoSysmon -Comment "Sysmon 설치/구성 배포 (블루팀용)" | Out-Null
} catch {
    Write-Host "  GPO '$gpoSysmon' 이미 존재합니다." -ForegroundColor DarkYellow
}

# Sysmon 배포 스크립트는 별도 (05_install_sysmon.ps1)
New-GPLink -Name $gpoSysmon -Target $domainDN -ErrorAction SilentlyContinue
Write-Host "  Sysmon 배포 GPO 생성 완료 (스크립트는 05_install_sysmon.ps1 참조)" -ForegroundColor Green

# -------------------------------------------------------
# GPO 강제 업데이트
# -------------------------------------------------------
Write-Host "`n GPO 강제 업데이트 중..." -ForegroundColor Yellow
gpupdate /force

Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host " GPO 설정 완료" -ForegroundColor Cyan
Write-Host " 취약점 요약:" -ForegroundColor Red
Write-Host "  - 비밀번호 정책 약화 (8자, 복잡성 없음, 잠금 없음)" -ForegroundColor Red
Write-Host "  - WDigest 활성화 (평문 PW 노출)" -ForegroundColor Red
Write-Host "  - Credential Guard 비활성화 (Mimikatz 허용)" -ForegroundColor Red
Write-Host "  - SMB 서명 미적용 (NTLM 릴레이)" -ForegroundColor Red
Write-Host "  - PowerShell Unrestricted (악성 스크립트)" -ForegroundColor Red
Write-Host "  - LAPS 미적용 (로컬 Admin PW 동일)" -ForegroundColor Red
Write-Host "  - RDP/WinRM 전체 허용" -ForegroundColor Red
Write-Host "============================================" -ForegroundColor Cyan
