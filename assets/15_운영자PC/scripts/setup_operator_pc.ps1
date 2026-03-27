# ============================================================
# setup_operator_pc.ps1 — OT 운영자 PC 설정
# 대상: OT-OP-PC01 (192.168.201.21), OT-OP-PC02 (192.168.201.22)
# 역할: SCADA-LTS HMI 모니터링 단말
# ============================================================

#Requires -RunAsAdministrator

param(
    # PC 번호 (1 또는 2)
    [Parameter(Mandatory=$true)]
    [ValidateSet("1", "2")]
    [string]$PCNumber
)

$ErrorActionPreference = "Stop"

# PC별 설정
$pcConfig = @{
    "1" = @{ Hostname = "OT-OP-PC01"; IP = "192.168.201.21"; OperatorUser = "operator1"; Description = "주 운영자 PC (Windows 10)" }
    "2" = @{ Hostname = "OT-OP-PC02"; IP = "192.168.201.22"; OperatorUser = "operator2"; Description = "부 운영자 PC (Windows 11)" }
}

$config = $pcConfig[$PCNumber]
$scadaUrl = "http://192.168.201.10:8080/ScadaLTS/"

Write-Host "============================================" -ForegroundColor Cyan
Write-Host " OT 운영자 PC 설정" -ForegroundColor Cyan
Write-Host " 호스트: $($config.Hostname) ($($config.IP))" -ForegroundColor Cyan
Write-Host " 역할: $($config.Description)" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

# -------------------------------------------------------
# [1/6] 호스트명 설정
# -------------------------------------------------------
Write-Host "`n[1/6] 호스트명 설정..." -ForegroundColor Yellow

$currentName = $env:COMPUTERNAME
if ($currentName -ne $config.Hostname) {
    Rename-Computer -NewName $config.Hostname -Force
    Write-Host "  호스트명 변경: $currentName -> $($config.Hostname)" -ForegroundColor Green
} else {
    Write-Host "  호스트명 이미 $($config.Hostname)입니다." -ForegroundColor Green
}

# -------------------------------------------------------
# [2/6] 네트워크 설정 (고정 IP)
# -------------------------------------------------------
Write-Host "`n[2/6] 네트워크 설정..." -ForegroundColor Yellow

$adapter = Get-NetAdapter | Where-Object { $_.Status -eq "Up" } | Select-Object -First 1
$ifAlias = $adapter.Name

# 기존 설정 제거
Remove-NetIPAddress -InterfaceAlias $ifAlias -Confirm:$false -ErrorAction SilentlyContinue
Remove-NetRoute -InterfaceAlias $ifAlias -Confirm:$false -ErrorAction SilentlyContinue

# 고정 IP 설정
New-NetIPAddress -InterfaceAlias $ifAlias `
    -IPAddress $config.IP `
    -PrefixLength 24 `
    -DefaultGateway "192.168.201.1"

# DNS 설정 — OT 존에는 별도 DNS 없으므로 게이트웨이 사용
Set-DnsClientServerAddress -InterfaceAlias $ifAlias `
    -ServerAddresses "192.168.201.1"

Write-Host "  IP: $($config.IP)/24, GW: 192.168.201.1, DNS: 192.168.201.1" -ForegroundColor Green

# -------------------------------------------------------
# [3/6] hosts 파일 설정
# -------------------------------------------------------
Write-Host "`n[3/6] hosts 파일 설정..." -ForegroundColor Yellow

$hostsFile = "C:\Windows\System32\drivers\etc\hosts"
$hostsEntries = @(
    "192.168.201.10    scada-server",
    "192.168.201.11    plc-simulator"
)

$currentHosts = Get-Content $hostsFile -ErrorAction SilentlyContinue
foreach ($entry in $hostsEntries) {
    $hostname = ($entry -split '\s+')[1]
    if ($currentHosts -notmatch [regex]::Escape($hostname)) {
        Add-Content -Path $hostsFile -Value $entry
        Write-Host "  [추가] $entry" -ForegroundColor Green
    } else {
        Write-Host "  [존재] $hostname (이미 등록됨)" -ForegroundColor DarkYellow
    }
}

# -------------------------------------------------------
# [4/6] 브라우저 키오스크 자동 실행 설정
# -------------------------------------------------------
Write-Host "`n[4/6] 브라우저 키오스크 자동 실행 설정..." -ForegroundColor Yellow

# 시작프로그램 디렉토리에 배치 파일 생성
$startupDir = "C:\Users\$($config.OperatorUser)\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup"

# 사용자 폴더가 없을 수 있으므로 공용 시작프로그램에도 배치
$publicStartupDir = "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup"

$hmiScript = @"
@echo off
REM ============================================================
REM OT 운영자 PC - SCADA HMI 자동 실행 (키오스크 모드)
REM 대상: $($config.Hostname) ($($config.IP))
REM ============================================================

REM 부팅 시 네트워크 안정화 대기
timeout /t 30 /nobreak

REM SCADA-LTS HMI를 Chrome 키오스크 모드로 실행
start "" "C:\Program Files\Google\Chrome\Application\chrome.exe" ^
    --kiosk ^
    --no-first-run ^
    --disable-session-crashed-bubble ^
    --disable-infobars ^
    "$scadaUrl"

REM Node-RED 대시보드 (보조 모니터용, 필요시 주석 해제)
REM start "" "C:\Program Files\Google\Chrome\Application\chrome.exe" ^
REM     "http://192.168.201.10:1880/ui"
"@

# 공용 시작프로그램에 배치
$hmiScript | Out-File -FilePath "$publicStartupDir\startup_hmi.bat" -Encoding ASCII
Write-Host "  키오스크 스크립트: $publicStartupDir\startup_hmi.bat" -ForegroundColor Green

# 사용자별 시작프로그램에도 배치 (존재하는 경우)
if (Test-Path (Split-Path $startupDir -Parent)) {
    if (-not (Test-Path $startupDir)) { New-Item -Path $startupDir -ItemType Directory -Force | Out-Null }
    $hmiScript | Out-File -FilePath "$startupDir\startup_hmi.bat" -Encoding ASCII
    Write-Host "  사용자 시작프로그램에도 배치: $startupDir" -ForegroundColor Green
}

# -------------------------------------------------------
# [5/6] Windows 방화벽 설정
# -------------------------------------------------------
Write-Host "`n[5/6] Windows 방화벽 설정..." -ForegroundColor Yellow

# 아웃바운드: SCADA 서버만 허용
New-NetFirewallRule -DisplayName "OT-Allow-SCADA-HTTP" `
    -Direction Outbound -Action Allow -Protocol TCP `
    -RemotePort 8080 -RemoteAddress "192.168.201.10" `
    -ErrorAction SilentlyContinue

New-NetFirewallRule -DisplayName "OT-Allow-SCADA-NodeRED" `
    -Direction Outbound -Action Allow -Protocol TCP `
    -RemotePort 1880 -RemoteAddress "192.168.201.10" `
    -ErrorAction SilentlyContinue

# ICMP 허용 (ping)
New-NetFirewallRule -DisplayName "OT-Allow-ICMP" `
    -Direction Inbound -Action Allow -Protocol ICMPv4 `
    -ErrorAction SilentlyContinue

Write-Host "  방화벽: SCADA 서버(8080, 1880)만 아웃바운드 허용" -ForegroundColor Green

# -------------------------------------------------------
# [6/6] 로컬 사용자 계정 확인
# -------------------------------------------------------
Write-Host "`n[6/6] 로컬 사용자 계정 확인..." -ForegroundColor Yellow

# 운영자 계정이 없으면 생성
$localUser = Get-LocalUser -Name $config.OperatorUser -ErrorAction SilentlyContinue
if (-not $localUser) {
    $opPassword = ConvertTo-SecureString $config.OperatorUser -AsPlainText -Force
    New-LocalUser -Name $config.OperatorUser -Password $opPassword `
        -FullName "OT Operator $PCNumber" `
        -Description "SCADA HMI 운영자 계정" `
        -PasswordNeverExpires
    Add-LocalGroupMember -Group "Users" -Member $config.OperatorUser
    Write-Host "  [생성] $($config.OperatorUser) 계정 생성" -ForegroundColor Green
} else {
    Write-Host "  [존재] $($config.OperatorUser) 계정 확인" -ForegroundColor Green
}

# 자동 로그인 설정 (운영자 PC 특성 — 항상 로그인 상태 유지)
$regPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
Set-ItemProperty -Path $regPath -Name "AutoAdminLogon" -Value "1"
Set-ItemProperty -Path $regPath -Name "DefaultUserName" -Value $config.OperatorUser
Set-ItemProperty -Path $regPath -Name "DefaultPassword" -Value $config.OperatorUser
Write-Host "  자동 로그인 설정: $($config.OperatorUser)" -ForegroundColor Green

Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host " OT 운영자 PC 설정 완료" -ForegroundColor Cyan
Write-Host " 호스트: $($config.Hostname)" -ForegroundColor Cyan
Write-Host " SCADA URL: $scadaUrl" -ForegroundColor Cyan
Write-Host " 재부팅 후 자동으로 HMI 화면이 표시됩니다." -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

$reboot = Read-Host "지금 재부팅하시겠습니까? (Y/N)"
if ($reboot -eq "Y" -or $reboot -eq "y") {
    Restart-Computer -Force
}
