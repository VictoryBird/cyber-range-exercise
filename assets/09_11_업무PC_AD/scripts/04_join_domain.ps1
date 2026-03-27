# ============================================================
# 04_join_domain.ps1 — 업무용 PC 도메인 가입 스크립트
# 대상: 업무용 PC 1~5 (192.168.100.31~35), 관리자 PC (192.168.100.40)
# 도메인: corp.mois.local
# ============================================================
# 실행 전: 각 PC에 맞게 $pcConfig의 호스트명/IP를 선택하세요.
# ============================================================

#Requires -RunAsAdministrator

$ErrorActionPreference = "Stop"

Write-Host "============================================" -ForegroundColor Cyan
Write-Host " 도메인 가입 스크립트 (corp.mois.local)" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

# -------------------------------------------------------
# PC별 설정 — 해당 PC에 맞는 인덱스를 선택하세요
# -------------------------------------------------------
$pcConfigs = @(
    @{ Hostname = "WS-PC01";    IP = "192.168.100.31"; User = "user_lee";   Description = "업무용 PC-1 (피싱 대상)" },
    @{ Hostname = "WS-PC02";    IP = "192.168.100.32"; User = "user_choi";  Description = "업무용 PC-2" },
    @{ Hostname = "WS-PC03";    IP = "192.168.100.33"; User = "user_jung";  Description = "업무용 PC-3" },
    @{ Hostname = "WS-PC04";    IP = "192.168.100.34"; User = "user_han";   Description = "업무용 PC-4" },
    @{ Hostname = "WS-PC05";    IP = "192.168.100.35"; User = "user_park";  Description = "업무용 PC-5" },
    @{ Hostname = "WS-ADMIN01"; IP = "192.168.100.40"; User = "admin_kim";  Description = "관리자 PC" }
)

# 현재 PC에 해당하는 설정 선택 (실행 시 수정)
# 예: $pcIndex = 0 → WS-PC01
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
# [2/4] 네트워크 설정 (고정 IP, DNS → DC)
# -------------------------------------------------------
Write-Host "`n[2/4] 네트워크 설정..." -ForegroundColor Yellow

$adapter = Get-NetAdapter | Where-Object { $_.Status -eq "Up" } | Select-Object -First 1
$ifAlias = $adapter.Name

# 기존 설정 제거
Remove-NetIPAddress -InterfaceAlias $ifAlias -Confirm:$false -ErrorAction SilentlyContinue
Remove-NetRoute -InterfaceAlias $ifAlias -Confirm:$false -ErrorAction SilentlyContinue

# 고정 IP 설정
New-NetIPAddress -InterfaceAlias $ifAlias `
    -IPAddress $config.IP `
    -PrefixLength 24 `
    -DefaultGateway "192.168.100.1"

# DNS를 DC(192.168.100.50)로 설정 — AD 도메인 해석을 위해 필수
Set-DnsClientServerAddress -InterfaceAlias $ifAlias `
    -ServerAddresses "192.168.100.50"

Write-Host "  IP: $($config.IP)/24, GW: 192.168.100.1, DNS: 192.168.100.50" -ForegroundColor Green

# -------------------------------------------------------
# [3/4] 도메인 가입
# -------------------------------------------------------
Write-Host "`n[3/4] 도메인 가입 (corp.mois.local)..." -ForegroundColor Yellow

# DC 연결 확인
Write-Host "  DC 연결 확인 중..." -ForegroundColor Gray
$dcReachable = Test-Connection -ComputerName "192.168.100.50" -Count 2 -Quiet
if (-not $dcReachable) {
    Write-Host "  [오류] DC(192.168.100.50)에 연결할 수 없습니다!" -ForegroundColor Red
    Write-Host "  네트워크 설정을 확인하세요." -ForegroundColor Red
    exit 1
}
Write-Host "  DC 연결 확인 완료" -ForegroundColor Green

# 도메인 가입 자격증명 입력
$domainCred = Get-Credential -Message "도메인 관리자 자격증명 입력 (예: CORP\admin_kim)"

# OU 지정 — 호스트명에 따라 업무용PC 또는 관리자PC OU에 배치
if ($config.Hostname -like "*ADMIN*") {
    $ouPath = "OU=관리자PC,OU=워크스테이션,DC=corp,DC=mois,DC=local"
} else {
    $ouPath = "OU=업무용PC,OU=워크스테이션,DC=corp,DC=mois,DC=local"
}

Add-Computer -DomainName "corp.mois.local" `
    -Credential $domainCred `
    -OUPath $ouPath `
    -Force

Write-Host "  도메인 가입 완료 (OU: $ouPath)" -ForegroundColor Green

# -------------------------------------------------------
# [4/4] 로컬 Administrator 비밀번호 설정
# -------------------------------------------------------
Write-Host "`n[4/4] 로컬 Administrator 비밀번호 설정..." -ForegroundColor Yellow

# [취약점] 모든 PC에 동일한 로컬 Admin 비밀번호 설정 — LAPS 미적용
# 올바른 설정: LAPS를 통해 각 PC마다 고유한 랜덤 비밀번호 할당
$localAdminPW = ConvertTo-SecureString "LocalAdmin1!" -AsPlainText -Force
Set-LocalUser -Name "Administrator" -Password $localAdminPW
Enable-LocalUser -Name "Administrator"
Write-Host "  [취약점] 로컬 Administrator 비밀번호: LocalAdmin1! (모든 PC 동일)" -ForegroundColor Red

# WinRM 활성화 (GPO로도 배포되지만 즉시 적용)
Enable-PSRemoting -Force -SkipNetworkProfileCheck
Write-Host "  WinRM 활성화 완료" -ForegroundColor Green

# -------------------------------------------------------
# 재부팅 안내
# -------------------------------------------------------
Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host " 도메인 가입 완료 — 재부팅이 필요합니다" -ForegroundColor Cyan
Write-Host " 호스트명: $($config.Hostname)" -ForegroundColor Cyan
Write-Host " 주 사용자: $($config.User)" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

$reboot = Read-Host "지금 재부팅하시겠습니까? (Y/N)"
if ($reboot -eq "Y" -or $reboot -eq "y") {
    Restart-Computer -Force
}
