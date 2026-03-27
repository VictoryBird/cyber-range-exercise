# ============================================================
# 04_join_domain.ps1 — 군 업무용 PC 도메인 가입
# 대상: MIL-PC01~05 (192.168.110.31~35), MIL-ADMIN01 (192.168.110.40)
# 도메인: corp.mnd.local
# ============================================================

#Requires -RunAsAdministrator

$ErrorActionPreference = "Stop"

Write-Host "============================================" -ForegroundColor Cyan
Write-Host " 군 도메인 가입 스크립트 (corp.mnd.local)" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

# PC별 설정
$pcConfigs = @(
    @{ Hostname = "MIL-PC01";    IP = "192.168.110.31"; User = "mil_kim";   Description = "업무용 PC-1 (작전지원과)" },
    @{ Hostname = "MIL-PC02";    IP = "192.168.110.32"; User = "mil_lee";   Description = "업무용 PC-2 (정보보호과)" },
    @{ Hostname = "MIL-PC03";    IP = "192.168.110.33"; User = "mil_park";  Description = "업무용 PC-3 (군수지원과)" },
    @{ Hostname = "MIL-PC04";    IP = "192.168.110.34"; User = "mil_choi";  Description = "업무용 PC-4 (통신운영과)" },
    @{ Hostname = "MIL-PC05";    IP = "192.168.110.35"; User = "mil_jung";  Description = "업무용 PC-5 (인사과)" },
    @{ Hostname = "MIL-ADMIN01"; IP = "192.168.110.40"; User = "mil_admin"; Description = "관리자 PC (정보통신과)" }
)

# PC 선택
Write-Host "`nPC 목록:" -ForegroundColor Yellow
for ($i = 0; $i -lt $pcConfigs.Count; $i++) {
    Write-Host "  [$i] $($pcConfigs[$i].Hostname) ($($pcConfigs[$i].IP)) - $($pcConfigs[$i].Description)"
}

$pcIndex = Read-Host "`n이 PC에 해당하는 번호를 입력하세요 (0-5)"
$config = $pcConfigs[[int]$pcIndex]

Write-Host "`n선택: $($config.Hostname) ($($config.IP))" -ForegroundColor Green

# -------------------------------------------------------
# [1/4] 호스트명 설정
# -------------------------------------------------------
Write-Host "`n[1/4] 호스트명 설정..." -ForegroundColor Yellow

$currentName = $env:COMPUTERNAME
if ($currentName -ne $config.Hostname) {
    Rename-Computer -NewName $config.Hostname -Force
    Write-Host "  호스트명 변경: $currentName -> $($config.Hostname)" -ForegroundColor Green
} else {
    Write-Host "  호스트명 이미 $($config.Hostname)입니다." -ForegroundColor Green
}

# -------------------------------------------------------
# [2/4] 네트워크 설정
# -------------------------------------------------------
Write-Host "`n[2/4] 네트워크 설정..." -ForegroundColor Yellow

$adapter = Get-NetAdapter | Where-Object { $_.Status -eq "Up" } | Select-Object -First 1
$ifAlias = $adapter.Name

Remove-NetIPAddress -InterfaceAlias $ifAlias -Confirm:$false -ErrorAction SilentlyContinue
Remove-NetRoute -InterfaceAlias $ifAlias -Confirm:$false -ErrorAction SilentlyContinue

New-NetIPAddress -InterfaceAlias $ifAlias `
    -IPAddress $config.IP `
    -PrefixLength 24 `
    -DefaultGateway "192.168.110.1"

# DNS를 DC(192.168.110.50)로 설정
Set-DnsClientServerAddress -InterfaceAlias $ifAlias `
    -ServerAddresses "192.168.110.50"

Write-Host "  IP: $($config.IP)/24, GW: 192.168.110.1, DNS: 192.168.110.50" -ForegroundColor Green

# -------------------------------------------------------
# [3/4] 도메인 가입
# -------------------------------------------------------
Write-Host "`n[3/4] 도메인 가입 (corp.mnd.local)..." -ForegroundColor Yellow

# DC 연결 확인
$dcReachable = Test-Connection -ComputerName "192.168.110.50" -Count 2 -Quiet
if (-not $dcReachable) {
    Write-Host "  [오류] DC(192.168.110.50)에 연결할 수 없습니다!" -ForegroundColor Red
    exit 1
}
Write-Host "  DC 연결 확인 완료" -ForegroundColor Green

$domainCred = Get-Credential -Message "도메인 관리자 자격증명 입력 (예: CORP\mil_admin)"

if ($config.Hostname -like "*ADMIN*") {
    $ouPath = "OU=관리자PC,OU=워크스테이션,DC=corp,DC=mnd,DC=local"
} else {
    $ouPath = "OU=업무용PC,OU=워크스테이션,DC=corp,DC=mnd,DC=local"
}

Add-Computer -DomainName "corp.mnd.local" `
    -Credential $domainCred `
    -OUPath $ouPath `
    -Force

Write-Host "  도메인 가입 완료 (OU: $ouPath)" -ForegroundColor Green

# -------------------------------------------------------
# [4/4] 로컬 Administrator 비밀번호 설정
# -------------------------------------------------------
Write-Host "`n[4/4] 로컬 Administrator 비밀번호 설정..." -ForegroundColor Yellow

# [취약점] 모든 PC 동일 로컬 Admin 비밀번호 — LAPS 미적용
# 올바른 설정: LAPS로 각 PC마다 랜덤 비밀번호 할당
$localAdminPW = ConvertTo-SecureString "LocalAdmin1!" -AsPlainText -Force
Set-LocalUser -Name "Administrator" -Password $localAdminPW
Enable-LocalUser -Name "Administrator"
Write-Host "  [취약점] 로컬 Administrator 비밀번호: LocalAdmin1! (모든 PC 동일)" -ForegroundColor Red

# WinRM 활성화
Enable-PSRemoting -Force -SkipNetworkProfileCheck
Write-Host "  WinRM 활성화 완료" -ForegroundColor Green

Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host " 도메인 가입 완료 — 재부팅이 필요합니다" -ForegroundColor Cyan
Write-Host " 재부팅 후 05_update_checker.ps1 실행" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

$reboot = Read-Host "지금 재부팅하시겠습니까? (Y/N)"
if ($reboot -eq "Y" -or $reboot -eq "y") {
    Restart-Computer -Force
}
