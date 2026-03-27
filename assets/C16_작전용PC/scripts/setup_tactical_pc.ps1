# ============================================================
# setup_tactical_pc.ps1 — C4I 작전용 PC 설정
# 대상: C4I-OPS-PC-{1~5} (192.168.130.21~25)
# 역할: COP 상황도 열람, AI 브리핑 확인 (전술 단말)
# 도메인: 미가입 (독립 운영)
# ============================================================
# 이 PC들은 직접적인 취약점이 없으며,
# 상위 서버(C13, C14, C15)의 데이터 오염에 의한 간접 피해를 받습니다.
# ============================================================

#Requires -RunAsAdministrator

param(
    # PC 번호 (1~5)
    [Parameter(Mandatory=$true)]
    [ValidateRange(1, 5)]
    [int]$PCNumber
)

$ErrorActionPreference = "Stop"

# PC별 설정
$pcConfigs = @{
    1 = @{ Hostname = "C4I-OPS-PC-1"; IP = "192.168.130.21"; Role = "작전과장 — 작전 현황 종합 모니터링" }
    2 = @{ Hostname = "C4I-OPS-PC-2"; IP = "192.168.130.22"; Role = "정보과장 — 적 동향 분석" }
    3 = @{ Hostname = "C4I-OPS-PC-3"; IP = "192.168.130.23"; Role = "화력과장 — 포병/화력 운용 현황" }
    4 = @{ Hostname = "C4I-OPS-PC-4"; IP = "192.168.130.24"; Role = "군수과장 — 보급/군수 현황" }
    5 = @{ Hostname = "C4I-OPS-PC-5"; IP = "192.168.130.25"; Role = "당직사관 — 상황 보고 종합" }
}

$config = $pcConfigs[$PCNumber]

Write-Host "============================================" -ForegroundColor Cyan
Write-Host " C4I 작전용 PC 설정" -ForegroundColor Cyan
Write-Host " 호스트: $($config.Hostname) ($($config.IP))" -ForegroundColor Cyan
Write-Host " 역할: $($config.Role)" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

# -------------------------------------------------------
# [1/7] 호스트명 설정
# -------------------------------------------------------
Write-Host "`n[1/7] 호스트명 설정..." -ForegroundColor Yellow

$currentName = $env:COMPUTERNAME
if ($currentName -ne $config.Hostname) {
    Rename-Computer -NewName $config.Hostname -Force
    Write-Host "  호스트명 변경: $currentName -> $($config.Hostname)" -ForegroundColor Green
} else {
    Write-Host "  호스트명 이미 $($config.Hostname)입니다." -ForegroundColor Green
}

# -------------------------------------------------------
# [2/7] 네트워크 설정 (고정 IP)
# -------------------------------------------------------
Write-Host "`n[2/7] 네트워크 설정..." -ForegroundColor Yellow

$adapter = Get-NetAdapter | Where-Object { $_.Status -eq "Up" } | Select-Object -First 1
$ifAlias = $adapter.Name

Remove-NetIPAddress -InterfaceAlias $ifAlias -Confirm:$false -ErrorAction SilentlyContinue
Remove-NetRoute -InterfaceAlias $ifAlias -Confirm:$false -ErrorAction SilentlyContinue

New-NetIPAddress -InterfaceAlias $ifAlias `
    -IPAddress $config.IP `
    -PrefixLength 24 `
    -DefaultGateway "192.168.130.1"

# DNS — C4I 존에는 별도 DNS 없으므로 게이트웨이 사용
Set-DnsClientServerAddress -InterfaceAlias $ifAlias `
    -ServerAddresses "192.168.130.1"

Write-Host "  IP: $($config.IP)/24, GW: 192.168.130.1, DNS: 192.168.130.1" -ForegroundColor Green

# -------------------------------------------------------
# [3/7] hosts 파일 설정 (C4I 내부 서버 해석)
# -------------------------------------------------------
Write-Host "`n[3/7] hosts 파일 설정..." -ForegroundColor Yellow

$hostsFile = "C:\Windows\System32\drivers\etc\hosts"

# C4I 내부 서버 호스트 엔트리
$hostsEntries = @(
    "192.168.130.10  relay.c4i.local",
    "192.168.130.11  cop.c4i.local",
    "192.168.130.12  data.c4i.local",
    "192.168.130.13  summary.c4i.local"
)

$currentHosts = Get-Content $hostsFile -ErrorAction SilentlyContinue
foreach ($entry in $hostsEntries) {
    $hostname = ($entry -split '\s+')[1]
    if ($currentHosts -notmatch [regex]::Escape($hostname)) {
        Add-Content -Path $hostsFile -Value $entry
        Write-Host "  [추가] $entry" -ForegroundColor Green
    } else {
        Write-Host "  [존재] $hostname" -ForegroundColor DarkYellow
    }
}

# -------------------------------------------------------
# [4/7] 로컬 사용자 계정 생성
# -------------------------------------------------------
Write-Host "`n[4/7] 로컬 사용자 계정 설정..." -ForegroundColor Yellow

# 운영자 계정
$opUser = Get-LocalUser -Name "operator" -ErrorAction SilentlyContinue
if (-not $opUser) {
    $opPassword = ConvertTo-SecureString "Op3rator!C4I" -AsPlainText -Force
    New-LocalUser -Name "operator" -Password $opPassword `
        -FullName "C4I Operator" `
        -Description "작전용 PC 운영자 계정" `
        -PasswordNeverExpires
    Add-LocalGroupMember -Group "Users" -Member "operator"
    Write-Host "  [생성] operator 계정 (Op3rator!C4I)" -ForegroundColor Green
} else {
    Write-Host "  [존재] operator 계정" -ForegroundColor DarkYellow
}

# 관리자 계정
$adminUser = Get-LocalUser -Name "c4i-admin" -ErrorAction SilentlyContinue
if (-not $adminUser) {
    $adminPassword = ConvertTo-SecureString "C4I!Admin#2024" -AsPlainText -Force
    New-LocalUser -Name "c4i-admin" -Password $adminPassword `
        -FullName "C4I Administrator" `
        -Description "작전용 PC 관리자 계정" `
        -PasswordNeverExpires
    Add-LocalGroupMember -Group "Administrators" -Member "c4i-admin"
    Write-Host "  [생성] c4i-admin 계정 (C4I!Admin#2024)" -ForegroundColor Green
} else {
    Write-Host "  [존재] c4i-admin 계정" -ForegroundColor DarkYellow
}

# -------------------------------------------------------
# [5/7] 브라우저 북마크 및 홈페이지 설정
# -------------------------------------------------------
Write-Host "`n[5/7] 브라우저 북마크 설정..." -ForegroundColor Yellow

# Chrome 북마크 설정 (레지스트리 기반 관리 북마크)
$chromePolPath = "HKLM:\SOFTWARE\Policies\Google\Chrome"
$bookmarkPath = "$chromePolPath\ManagedBookmarks"

# Chrome 정책 디렉토리 생성
if (-not (Test-Path $chromePolPath)) {
    New-Item -Path $chromePolPath -Force | Out-Null
}

# 홈페이지 설정 — COP 상황도
New-ItemProperty -Path $chromePolPath -Name "HomepageLocation" `
    -Value "http://cop.c4i.local:8080/map.jsp" -PropertyType String -Force | Out-Null
New-ItemProperty -Path $chromePolPath -Name "HomepageIsNewTabPage" `
    -Value 0 -PropertyType DWord -Force | Out-Null
New-ItemProperty -Path $chromePolPath -Name "RestoreOnStartup" `
    -Value 4 -PropertyType DWord -Force | Out-Null

# 시작 페이지 설정
$startupPath = "$chromePolPath\RestoreOnStartupURLs"
if (-not (Test-Path $startupPath)) {
    New-Item -Path $startupPath -Force | Out-Null
}
New-ItemProperty -Path $startupPath -Name "1" `
    -Value "http://cop.c4i.local:8080/map.jsp" -PropertyType String -Force | Out-Null

# 관리 북마크 설정 (JSON 형식)
$bookmarks = '[{"toplevel_name": "C4I"}, ' +
    '{"name": "COP 상황도", "url": "http://cop.c4i.local:8080/map.jsp"}, ' +
    '{"name": "AI 브리핑", "url": "http://summary.c4i.local:8001/api/summary/latest"}, ' +
    '{"name": "이벤트 현황", "url": "http://data.c4i.local:8000/api/stats"}]'
New-ItemProperty -Path $chromePolPath -Name "ManagedBookmarks" `
    -Value $bookmarks -PropertyType String -Force | Out-Null

Write-Host "  홈페이지: http://cop.c4i.local:8080/map.jsp" -ForegroundColor Green
Write-Host "  북마크: COP 상황도, AI 브리핑, 이벤트 현황" -ForegroundColor Green

# -------------------------------------------------------
# [6/7] Windows 방화벽 설정
# -------------------------------------------------------
Write-Host "`n[6/7] Windows 방화벽 설정..." -ForegroundColor Yellow

# 기본 정책: 인바운드 차단, 아웃바운드 허용
netsh advfirewall set allprofiles firewallpolicy blockinbound,allowoutbound

# C4I 서버 접근 허용 (아웃바운드)
$fwRules = @(
    @{ Name = "C4I-COP";     RemoteIP = "192.168.130.11"; Port = "8080"; Desc = "COP 상황도 서버" },
    @{ Name = "C4I-Data";    RemoteIP = "192.168.130.12"; Port = "8000"; Desc = "데이터 수집 서버" },
    @{ Name = "C4I-Summary"; RemoteIP = "192.168.130.13"; Port = "8001"; Desc = "AI 요약 서버" }
)

foreach ($rule in $fwRules) {
    netsh advfirewall firewall add rule `
        name="$($rule.Name)" `
        dir=out action=allow `
        remoteip=$($rule.RemoteIP) `
        remoteport=$($rule.Port) `
        protocol=tcp 2>$null

    Write-Host "  [허용] $($rule.Desc) ($($rule.RemoteIP):$($rule.Port))" -ForegroundColor Green
}

# ICMP 인바운드 허용 (ping)
netsh advfirewall firewall add rule `
    name="C4I-ICMP" dir=in action=allow protocol=icmpv4 2>$null

Write-Host "  [허용] ICMP 인바운드 (ping)" -ForegroundColor Green
Write-Host "  [정책] 인바운드 차단(ping 제외), 아웃바운드: C4I 서버만 허용" -ForegroundColor Green

# -------------------------------------------------------
# [7/7] 바탕화면 바로가기 생성
# -------------------------------------------------------
Write-Host "`n[7/7] 바탕화면 바로가기 생성..." -ForegroundColor Yellow

$publicDesktop = "C:\Users\Public\Desktop"

# COP 상황도 바로가기
$copShortcut = "$publicDesktop\COP 상황도.url"
@"
[InternetShortcut]
URL=http://cop.c4i.local:8080/map.jsp
IconIndex=0
"@ | Out-File -FilePath $copShortcut -Encoding ASCII
Write-Host "  [생성] COP 상황도 바로가기" -ForegroundColor Green

# AI 브리핑 바로가기
$aiShortcut = "$publicDesktop\AI 브리핑.url"
@"
[InternetShortcut]
URL=http://summary.c4i.local:8001/api/summary/latest
IconIndex=0
"@ | Out-File -FilePath $aiShortcut -Encoding ASCII
Write-Host "  [생성] AI 브리핑 바로가기" -ForegroundColor Green

# 이벤트 현황 바로가기
$eventShortcut = "$publicDesktop\이벤트 현황.url"
@"
[InternetShortcut]
URL=http://data.c4i.local:8000/api/stats
IconIndex=0
"@ | Out-File -FilePath $eventShortcut -Encoding ASCII
Write-Host "  [생성] 이벤트 현황 바로가기" -ForegroundColor Green

# -------------------------------------------------------
# 완료 안내
# -------------------------------------------------------
Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host " C4I 작전용 PC 설정 완료" -ForegroundColor Cyan
Write-Host " 호스트: $($config.Hostname) ($($config.IP))" -ForegroundColor Cyan
Write-Host " 역할: $($config.Role)" -ForegroundColor Cyan
Write-Host "" -ForegroundColor Cyan
Write-Host " 계정 정보:" -ForegroundColor White
Write-Host "   운영자: operator / Op3rator!C4I" -ForegroundColor White
Write-Host "   관리자: c4i-admin / C4I!Admin#2024" -ForegroundColor White
Write-Host "" -ForegroundColor Cyan
Write-Host " 접속 URL:" -ForegroundColor White
Write-Host "   COP 상황도: http://cop.c4i.local:8080/map.jsp" -ForegroundColor White
Write-Host "   AI 브리핑:  http://summary.c4i.local:8001/api/summary/latest" -ForegroundColor White
Write-Host "   이벤트:     http://data.c4i.local:8000/api/stats" -ForegroundColor White
Write-Host "" -ForegroundColor Cyan
Write-Host " 재부팅 후 호스트명이 적용됩니다." -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

$reboot = Read-Host "지금 재부팅하시겠습니까? (Y/N)"
if ($reboot -eq "Y" -or $reboot -eq "y") {
    Restart-Computer -Force
}
