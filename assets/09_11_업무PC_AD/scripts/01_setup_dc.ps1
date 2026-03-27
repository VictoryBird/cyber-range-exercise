# ============================================================
# 01_setup_dc.ps1 — Active Directory 도메인 컨트롤러 프로모션
# 대상: 192.168.100.50 (DC01) — Windows Server 2022
# 도메인: corp.mois.local
# ============================================================
# 실행 전 요구사항:
#   - Windows Server 2022 Standard/Datacenter 설치 완료
#   - 관리자(Administrator) 권한으로 실행
#   - 네트워크 설정 완료 (고정 IP: 192.168.100.50)
# ============================================================

#Requires -RunAsAdministrator

$ErrorActionPreference = "Stop"

Write-Host "============================================" -ForegroundColor Cyan
Write-Host " AD DS 도메인 컨트롤러 설정 시작" -ForegroundColor Cyan
Write-Host " 도메인: corp.mois.local" -ForegroundColor Cyan
Write-Host " 호스트: DC01 (192.168.100.50)" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

# -------------------------------------------------------
# [1/5] 호스트명 설정
# -------------------------------------------------------
Write-Host "`n[1/5] 호스트명 설정..." -ForegroundColor Yellow

$currentName = $env:COMPUTERNAME
if ($currentName -ne "DC01") {
    Rename-Computer -NewName "DC01" -Force
    Write-Host "  호스트명 변경: $currentName -> DC01" -ForegroundColor Green
    Write-Host "  (재부팅 후 적용됩니다)" -ForegroundColor DarkYellow
} else {
    Write-Host "  호스트명 이미 DC01입니다." -ForegroundColor Green
}

# -------------------------------------------------------
# [2/5] 네트워크 설정 (고정 IP, DNS)
# -------------------------------------------------------
Write-Host "`n[2/5] 네트워크 설정..." -ForegroundColor Yellow

# 기존 IP 설정 제거 후 고정 IP 할당
$adapter = Get-NetAdapter | Where-Object { $_.Status -eq "Up" } | Select-Object -First 1
$ifAlias = $adapter.Name

# 기존 IP 제거
Remove-NetIPAddress -InterfaceAlias $ifAlias -Confirm:$false -ErrorAction SilentlyContinue
Remove-NetRoute -InterfaceAlias $ifAlias -Confirm:$false -ErrorAction SilentlyContinue

# 고정 IP 설정
New-NetIPAddress -InterfaceAlias $ifAlias `
    -IPAddress "192.168.100.50" `
    -PrefixLength 24 `
    -DefaultGateway "192.168.100.1"

# DNS는 자기 자신(루프백)으로 설정 — AD 통합 DNS 역할 수행
Set-DnsClientServerAddress -InterfaceAlias $ifAlias `
    -ServerAddresses "127.0.0.1"

Write-Host "  IP: 192.168.100.50/24, GW: 192.168.100.1, DNS: 127.0.0.1" -ForegroundColor Green

# -------------------------------------------------------
# [3/5] AD DS 역할 설치
# -------------------------------------------------------
Write-Host "`n[3/5] AD DS 역할 설치 중..." -ForegroundColor Yellow

Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools
Install-WindowsFeature -Name DNS -IncludeManagementTools
Install-WindowsFeature -Name GPMC  # 그룹 정책 관리 콘솔

Write-Host "  AD DS, DNS, GPMC 역할 설치 완료" -ForegroundColor Green

# -------------------------------------------------------
# [4/5] AD DS 포리스트 프로모션
# -------------------------------------------------------
Write-Host "`n[4/5] AD DS 포리스트 생성 (corp.mois.local)..." -ForegroundColor Yellow

# DSRM(디렉터리 서비스 복원 모드) 비밀번호 설정
$dsrmPassword = ConvertTo-SecureString "DsrmP@ss2024!" -AsPlainText -Force

# 새 포리스트 생성 — 단일 DC 환경
Install-ADDSForest `
    -DomainName "corp.mois.local" `
    -DomainNetbiosName "CORP" `
    -ForestMode "WinThreshold" `
    -DomainMode "WinThreshold" `
    -InstallDns:$true `
    -DatabasePath "C:\Windows\NTDS" `
    -LogPath "C:\Windows\NTDS" `
    -SysvolPath "C:\Windows\SYSVOL" `
    -SafeModeAdministratorPassword $dsrmPassword `
    -NoRebootOnCompletion:$false `
    -Force:$true

# -------------------------------------------------------
# [5/5] 완료 안내
# -------------------------------------------------------
# 주의: Install-ADDSForest는 자동으로 재부팅됩니다.
# 재부팅 후 02_create_ou_users.ps1을 실행하세요.
Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host " AD DS 프로모션 완료 — 서버가 재부팅됩니다" -ForegroundColor Cyan
Write-Host " 재부팅 후 02_create_ou_users.ps1 실행" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
