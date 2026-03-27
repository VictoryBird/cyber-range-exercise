# ============================================================
# 01_setup_dc.ps1 — 군 AD 도메인 컨트롤러 프로모션
# 대상: 192.168.110.50 (MIL-DC01) — Windows Server 2022
# 도메인: corp.mnd.local
# ============================================================

#Requires -RunAsAdministrator

$ErrorActionPreference = "Stop"

Write-Host "============================================" -ForegroundColor Cyan
Write-Host " 군 AD DS 도메인 컨트롤러 설정 시작" -ForegroundColor Cyan
Write-Host " 도메인: corp.mnd.local" -ForegroundColor Cyan
Write-Host " 호스트: MIL-DC01 (192.168.110.50)" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

# -------------------------------------------------------
# [1/5] 호스트명 설정
# -------------------------------------------------------
Write-Host "`n[1/5] 호스트명 설정..." -ForegroundColor Yellow

$currentName = $env:COMPUTERNAME
if ($currentName -ne "MIL-DC01") {
    Rename-Computer -NewName "MIL-DC01" -Force
    Write-Host "  호스트명 변경: $currentName -> MIL-DC01" -ForegroundColor Green
} else {
    Write-Host "  호스트명 이미 MIL-DC01입니다." -ForegroundColor Green
}

# -------------------------------------------------------
# [2/5] 네트워크 설정 (고정 IP)
# -------------------------------------------------------
Write-Host "`n[2/5] 네트워크 설정..." -ForegroundColor Yellow

$adapter = Get-NetAdapter | Where-Object { $_.Status -eq "Up" } | Select-Object -First 1
$ifAlias = $adapter.Name

Remove-NetIPAddress -InterfaceAlias $ifAlias -Confirm:$false -ErrorAction SilentlyContinue
Remove-NetRoute -InterfaceAlias $ifAlias -Confirm:$false -ErrorAction SilentlyContinue

New-NetIPAddress -InterfaceAlias $ifAlias `
    -IPAddress "192.168.110.50" `
    -PrefixLength 24 `
    -DefaultGateway "192.168.110.1"

# DNS는 자기 자신(루프백) — AD 통합 DNS 역할
Set-DnsClientServerAddress -InterfaceAlias $ifAlias `
    -ServerAddresses "127.0.0.1"

Write-Host "  IP: 192.168.110.50/24, GW: 192.168.110.1, DNS: 127.0.0.1" -ForegroundColor Green

# -------------------------------------------------------
# [3/5] AD DS 역할 설치
# -------------------------------------------------------
Write-Host "`n[3/5] AD DS 역할 설치 중..." -ForegroundColor Yellow

Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools
Install-WindowsFeature -Name DNS -IncludeManagementTools
Install-WindowsFeature -Name GPMC

Write-Host "  AD DS, DNS, GPMC 역할 설치 완료" -ForegroundColor Green

# -------------------------------------------------------
# [4/5] AD DS 포리스트 프로모션
# -------------------------------------------------------
Write-Host "`n[4/5] AD DS 포리스트 생성 (corp.mnd.local)..." -ForegroundColor Yellow

$dsrmPassword = ConvertTo-SecureString "MilDsrm2026!" -AsPlainText -Force

Install-ADDSForest `
    -DomainName "corp.mnd.local" `
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
# [5/5] 완료 안내 (재부팅 후 02_create_users.ps1 실행)
# -------------------------------------------------------
Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host " 군 AD DS 프로모션 완료 — 서버가 재부팅됩니다" -ForegroundColor Cyan
Write-Host " 재부팅 후 02_create_users.ps1 실행" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
