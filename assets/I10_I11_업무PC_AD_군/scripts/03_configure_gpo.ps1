# ============================================================
# 03_configure_gpo.ps1 — 군 GPO 구성 (의도적 약화)
# 대상: MIL-DC01 (192.168.110.50)
# 도메인: corp.mnd.local
# ============================================================
# 공공기관(corp.mois.local)과 동일한 취약 GPO 구조를 적용합니다.
# ============================================================

#Requires -RunAsAdministrator

$ErrorActionPreference = "Stop"
Import-Module GroupPolicy
Import-Module ActiveDirectory

$domainDN = "DC=corp,DC=mnd,DC=local"

Write-Host "============================================" -ForegroundColor Cyan
Write-Host " 군 GPO 설정 시작 (의도적 약화)" -ForegroundColor Cyan
Write-Host " 도메인: corp.mnd.local" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

# -------------------------------------------------------
# [1/5] 비밀번호 정책 약화
# -------------------------------------------------------
Write-Host "`n[1/5] 비밀번호 정책 약화..." -ForegroundColor Yellow

$tempDir = "C:\temp"
if (-not (Test-Path $tempDir)) { New-Item -Path $tempDir -ItemType Directory -Force | Out-Null }

# [취약점] 약한 비밀번호 정책
# 올바른 설정: 최소 12자, 복잡성 사용, 잠금 5회, 비밀번호 기록 24개
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

$secTemplate | Out-File -FilePath "$tempDir\weak_password_policy.inf" -Encoding Unicode
secedit /configure /db "$tempDir\secedit.sdb" /cfg "$tempDir\weak_password_policy.inf" /areas SECURITYPOLICY /quiet

Write-Host "  [취약점] 비밀번호 최소 8자, 복잡성 없음, 잠금 없음" -ForegroundColor Red

# -------------------------------------------------------
# [2/5] MIL-PC-보안설정 GPO 생성
# -------------------------------------------------------
Write-Host "`n[2/5] MIL-PC-보안설정 GPO 생성..." -ForegroundColor Yellow

$gpoName = "MIL-PC-보안설정"
try {
    New-GPO -Name $gpoName -Comment "군 워크스테이션 보안 설정 (훈련용 의도적 약화)" | Out-Null
} catch {
    Write-Host "  GPO '$gpoName' 이미 존재합니다." -ForegroundColor DarkYellow
}

# [취약점] WDigest 활성화 — 평문 비밀번호 메모리 저장
# 올바른 설정: UseLogonCredential = 0
Set-GPRegistryValue -Name $gpoName `
    -Key "HKLM\SYSTEM\CurrentControlSet\Control\SecurityProviders\WDigest" `
    -ValueName "UseLogonCredential" -Type DWord -Value 1
Write-Host "  [취약점] WDigest 활성화 (평문 PW 메모리 노출)" -ForegroundColor Red

# [취약점] Credential Guard 비활성화
# 올바른 설정: EnableVirtualizationBasedSecurity = 1, LsaCfgFlags = 1
Set-GPRegistryValue -Name $gpoName `
    -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard" `
    -ValueName "EnableVirtualizationBasedSecurity" -Type DWord -Value 0
Set-GPRegistryValue -Name $gpoName `
    -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard" `
    -ValueName "LsaCfgFlags" -Type DWord -Value 0
Write-Host "  [취약점] Credential Guard 비활성화 (Mimikatz 허용)" -ForegroundColor Red

# [취약점] PowerShell 실행 정책 Unrestricted
# 올바른 설정: AllSigned 또는 RemoteSigned
Set-GPRegistryValue -Name $gpoName `
    -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\PowerShell" `
    -ValueName "EnableScripts" -Type DWord -Value 1
Set-GPRegistryValue -Name $gpoName `
    -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\PowerShell" `
    -ValueName "ExecutionPolicy" -Type String -Value "Unrestricted"
Write-Host "  [취약점] PowerShell Unrestricted (권장: AllSigned)" -ForegroundColor Red

# [취약점] SMB 서명 미적용 — NTLM 릴레이 공격 가능
# 올바른 설정: RequireSecuritySignature = 1
Set-GPRegistryValue -Name $gpoName `
    -Key "HKLM\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" `
    -ValueName "RequireSecuritySignature" -Type DWord -Value 0
Set-GPRegistryValue -Name $gpoName `
    -Key "HKLM\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters" `
    -ValueName "RequireSecuritySignature" -Type DWord -Value 0
Write-Host "  [취약점] SMB 서명 미적용 (NTLM 릴레이 가능)" -ForegroundColor Red

# GPO 연결
New-GPLink -Name $gpoName -Target "OU=워크스테이션,$domainDN" -ErrorAction SilentlyContinue
Write-Host "  GPO 연결: OU=워크스테이션" -ForegroundColor Green

# -------------------------------------------------------
# [3/5] 방화벽 정책 GPO
# -------------------------------------------------------
Write-Host "`n[3/5] MIL-PC-방화벽정책 GPO..." -ForegroundColor Yellow

$gpoFW = "MIL-PC-방화벽정책"
try { New-GPO -Name $gpoFW -Comment "군 워크스테이션 방화벽 (훈련용 과도한 허용)" | Out-Null } catch {}

# 방화벽 스크립트를 SYSVOL에 배포
$fwScript = @'
# 군 워크스테이션 방화벽 규칙

# [취약점] RDP 전체 허용
New-NetFirewallRule -DisplayName "Allow RDP" -Direction Inbound -Protocol TCP -LocalPort 3389 -Action Allow -Profile Domain -ErrorAction SilentlyContinue

# [취약점] SMB 전체 허용
New-NetFirewallRule -DisplayName "Allow SMB" -Direction Inbound -Protocol TCP -LocalPort 445 -Action Allow -Profile Domain -ErrorAction SilentlyContinue

# [취약점] WinRM 전체 허용
New-NetFirewallRule -DisplayName "Allow WinRM" -Direction Inbound -Protocol TCP -LocalPort 5985 -Action Allow -Profile Domain -ErrorAction SilentlyContinue

# ICMP 허용
New-NetFirewallRule -DisplayName "Allow ICMP" -Direction Inbound -Protocol ICMPv4 -Action Allow -Profile Domain -ErrorAction SilentlyContinue

# 패치 서버 아웃바운드 허용 (HTTP)
New-NetFirewallRule -DisplayName "Allow PatchServer" -Direction Outbound -Protocol TCP -RemotePort 80 -RemoteAddress 192.168.120.10 -Action Allow -ErrorAction SilentlyContinue
'@

$sysvolScriptsDir = "C:\Windows\SYSVOL\sysvol\corp.mnd.local\scripts"
if (-not (Test-Path $sysvolScriptsDir)) { New-Item -Path $sysvolScriptsDir -ItemType Directory -Force | Out-Null }
$fwScript | Out-File -FilePath "$sysvolScriptsDir\setup_firewall.ps1" -Encoding UTF8

Write-Host "  방화벽 스크립트 배포 완료" -ForegroundColor Green

# -------------------------------------------------------
# [4/5] PowerShell 로깅 GPO (블루팀용)
# -------------------------------------------------------
Write-Host "`n[4/5] PowerShell 로깅 GPO (블루팀용)..." -ForegroundColor Yellow

$gpoPSLog = "MIL-PowerShell-로깅"
try { New-GPO -Name $gpoPSLog -Comment "PowerShell 스크립트 블록 로깅 (블루팀)" | Out-Null } catch {}

Set-GPRegistryValue -Name $gpoPSLog `
    -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging" `
    -ValueName "EnableScriptBlockLogging" -Type DWord -Value 1
Set-GPRegistryValue -Name $gpoPSLog `
    -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging" `
    -ValueName "EnableScriptBlockInvocationLogging" -Type DWord -Value 1

New-GPLink -Name $gpoPSLog -Target $domainDN -ErrorAction SilentlyContinue
Write-Host "  PowerShell 스크립트 블록 로깅 활성화" -ForegroundColor Green

# -------------------------------------------------------
# [5/5] 감사 정책 + LAPS 미적용
# -------------------------------------------------------
Write-Host "`n[5/5] 감사 정책 및 LAPS 미적용..." -ForegroundColor Yellow

# 감사 정책 활성화 (블루팀용)
auditpol /set /category:"Logon/Logoff" /success:enable /failure:enable
auditpol /set /category:"Account Logon" /success:enable /failure:enable
auditpol /set /category:"Account Management" /success:enable /failure:enable
auditpol /set /category:"DS Access" /success:enable /failure:enable
auditpol /set /category:"Object Access" /success:enable /failure:enable
auditpol /set /category:"Privilege Use" /success:enable /failure:enable
auditpol /set /category:"Process Tracking" /success:enable /failure:enable
Write-Host "  감사 정책 활성화 완료 (블루팀용)" -ForegroundColor Green

# [취약점] LAPS 미적용 — 모든 PC 로컬 Admin 비밀번호 동일 (LocalAdmin1!)
# 올바른 설정: LAPS 설치로 각 PC 로컬 Admin PW 랜덤화
Write-Host "  [취약점] LAPS 미적용 — 로컬 Admin PW 동일 (LocalAdmin1!)" -ForegroundColor Red

# GPO 강제 업데이트
gpupdate /force

Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host " 군 GPO 설정 완료" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
