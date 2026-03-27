# ============================================================
# 06_setup_update_checker.ps1 — 패치 서버 자동 업데이트 클라이언트
# 참조 스크립트: 군 업무용 PC(I10-I11)에서 사용하는 업데이트 체커
# 이 스크립트는 공공기관 PC에서는 사용하지 않으며, 참조용으로 포함됨
# ============================================================
# [취약점] 공급망 공격 벡터 — HTTP 평문 통신, 무서명 실행
# 군 PC(I10-I11)에서 사용되며, 패치 서버가 침해되면
# 악성 업데이트가 자동으로 다운로드/실행됩니다.
# ============================================================

#Requires -RunAsAdministrator

param(
    # 패치 서버 URL (기본값: 군 패치 서버)
    [string]$PatchServerUrl = "http://update.mnd.local/updates/manifest.json",

    # 업데이트 확인 주기 (분)
    [int]$IntervalMinutes = 30,

    # 설치 디렉토리
    [string]$InstallDir = "C:\ProgramData\MND\UpdateService"
)

$ErrorActionPreference = "Stop"

Write-Host "============================================" -ForegroundColor Cyan
Write-Host " 패치 자동 업데이트 클라이언트 설정" -ForegroundColor Cyan
Write-Host " 패치 서버: $PatchServerUrl" -ForegroundColor Cyan
Write-Host " 확인 주기: ${IntervalMinutes}분" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

# -------------------------------------------------------
# [1/3] 디렉토리 및 업데이트 스크립트 생성
# -------------------------------------------------------
Write-Host "`n[1/3] 업데이트 스크립트 생성..." -ForegroundColor Yellow

# 설치 디렉토리 생성
$downloadDir = "$InstallDir\downloads"
$logFile = "$InstallDir\update.log"

New-Item -Path $InstallDir -ItemType Directory -Force | Out-Null
New-Item -Path $downloadDir -ItemType Directory -Force | Out-Null

# 업데이트 확인 스크립트 생성
# [취약점] HTTP 평문 통신 — MITM 공격으로 매니페스트 변조 가능
# 올바른 설정: HTTPS + 인증서 피닝 사용
# [취약점] 다운로드 파일 서명 미검증 — 악성 파일 실행 가능
# 올바른 설정: 코드 서명 인증서로 파일 서명 검증 (Authenticode)

$updateScript = @'
# update-checker.ps1 — 패치 서버 자동 업데이트 클라이언트
# [취약점] 이 스크립트는 공급망 공격의 핵심 벡터입니다.
# 패치 서버가 침해되면 악성 업데이트가 자동으로 설치됩니다.

param(
    [string]$ManifestUrl = "MANIFEST_URL_PLACEHOLDER",
    [string]$DownloadDir = "DOWNLOAD_DIR_PLACEHOLDER",
    [string]$LogFile = "LOG_FILE_PLACEHOLDER"
)

function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - $Message" | Out-File -FilePath $LogFile -Append -Encoding UTF8
    Write-Host "[$timestamp] $Message"
}

try {
    Write-Log "업데이트 확인 시작: $ManifestUrl"

    # [취약점] HTTP 평문 통신 — 올바른 설정: HTTPS 사용
    $manifest = Invoke-WebRequest -Uri $ManifestUrl -UseBasicParsing -TimeoutSec 30 |
        ConvertFrom-Json

    Write-Log "매니페스트 수신: 버전=$($manifest.version), 패치 수=$($manifest.patches.Count)"

    foreach ($patch in $manifest.patches) {
        $patchFile = Join-Path $DownloadDir $patch.filename
        $patchUrl = $patch.url

        # 이미 설치된 패치인지 확인
        $installedFile = "$DownloadDir\$($patch.kb_id).installed"
        if (Test-Path $installedFile) {
            Write-Log "  이미 설치됨: $($patch.kb_id) ($($patch.filename))"
            continue
        }

        Write-Log "  다운로드 중: $($patch.filename) ($($patch.size_mb)MB)"

        # [취약점] HTTP 다운로드 — MITM 공격으로 파일 교체 가능
        Invoke-WebRequest -Uri $patchUrl -OutFile $patchFile -UseBasicParsing

        # [취약점] 파일 해시/서명 검증 없음 — 악성 파일 실행 가능
        # 올바른 설정:
        #   $expectedHash = $patch.sha256
        #   $actualHash = (Get-FileHash $patchFile -Algorithm SHA256).Hash
        #   if ($actualHash -ne $expectedHash) { Remove-Item $patchFile; continue }
        #   또한 Authenticode 서명 검증: Get-AuthenticodeSignature $patchFile

        Write-Log "  실행 중: $($patch.filename)"

        # [취약점] 다운로드된 파일을 검증 없이 즉시 실행
        Start-Process -FilePath $patchFile -ArgumentList "/quiet /norestart" -Wait

        # 설치 완료 마커 생성
        New-Item -Path $installedFile -ItemType File -Force | Out-Null
        Write-Log "  설치 완료: $($patch.kb_id)"
    }

    Write-Log "업데이트 확인 완료"

} catch {
    Write-Log "오류 발생: $_"
}
'@

# 플레이스홀더 치환
$updateScript = $updateScript.Replace("MANIFEST_URL_PLACEHOLDER", $PatchServerUrl)
$updateScript = $updateScript.Replace("DOWNLOAD_DIR_PLACEHOLDER", $downloadDir)
$updateScript = $updateScript.Replace("LOG_FILE_PLACEHOLDER", $logFile)

$scriptPath = "$InstallDir\update-checker.ps1"
$updateScript | Out-File -FilePath $scriptPath -Encoding UTF8

Write-Host "  스크립트 생성: $scriptPath" -ForegroundColor Green

# -------------------------------------------------------
# [2/3] 예약 작업 등록
# -------------------------------------------------------
Write-Host "`n[2/3] 예약 작업 등록 (${IntervalMinutes}분 간격)..." -ForegroundColor Yellow

$taskName = "MND-UpdateChecker"

# 기존 작업 제거
Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue

# 새 예약 작업 생성
$action = New-ScheduledTaskAction `
    -Execute "powershell.exe" `
    -Argument "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$scriptPath`""

$trigger = New-ScheduledTaskTrigger `
    -Once -At (Get-Date) `
    -RepetitionInterval (New-TimeSpan -Minutes $IntervalMinutes) `
    -RepetitionDuration (New-TimeSpan -Days 365)

$principal = New-ScheduledTaskPrincipal `
    -UserId "SYSTEM" `
    -LogonType ServiceAccount `
    -RunLevel Highest

$settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -StartWhenAvailable `
    -RestartCount 3 `
    -RestartInterval (New-TimeSpan -Minutes 5)

Register-ScheduledTask `
    -TaskName $taskName `
    -Action $action `
    -Trigger $trigger `
    -Principal $principal `
    -Settings $settings `
    -Description "군 패치 관리 서버 자동 업데이트 확인 (${IntervalMinutes}분 간격)"

Write-Host "  예약 작업 등록: $taskName (SYSTEM 권한)" -ForegroundColor Green

# -------------------------------------------------------
# [3/3] 초기 실행 테스트
# -------------------------------------------------------
Write-Host "`n[3/3] 초기 업데이트 확인 실행..." -ForegroundColor Yellow

# 첫 번째 실행 (패치 서버 연결 테스트)
try {
    & powershell.exe -ExecutionPolicy Bypass -File $scriptPath
    Write-Host "  초기 실행 완료 (로그: $logFile)" -ForegroundColor Green
} catch {
    Write-Host "  [경고] 초기 실행 실패 — 패치 서버($PatchServerUrl) 연결을 확인하세요." -ForegroundColor Yellow
}

Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host " 자동 업데이트 클라이언트 설정 완료" -ForegroundColor Cyan
Write-Host " [취약점] 공급망 공격 벡터:" -ForegroundColor Red
Write-Host "  - HTTP 평문 통신 (MITM 가능)" -ForegroundColor Red
Write-Host "  - 파일 서명/해시 미검증" -ForegroundColor Red
Write-Host "  - 다운로드 즉시 SYSTEM 권한 실행" -ForegroundColor Red
Write-Host "============================================" -ForegroundColor Cyan
