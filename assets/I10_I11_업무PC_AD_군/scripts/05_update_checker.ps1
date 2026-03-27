# ============================================================
# 05_update_checker.ps1 — 군 패치 서버 자동 업데이트 클라이언트
# 대상: MIL-PC01~05, MIL-ADMIN01
# 패치 서버: http://192.168.120.10 (군 패치 관리 서버)
# ============================================================
# [취약점] 이 스크립트는 공급망 공격(STEP 4-2)의 핵심 벡터입니다.
# 패치 서버가 침해되면 악성 업데이트(SecurityPatch_KB2024001.exe)가
# 자동으로 다운로드/실행되어 Havoc C2 Demon이 설치됩니다.
#
# 취약점 목록:
#   [취약점] HTTP 평문 통신 — MITM 공격으로 매니페스트/파일 변조 가능
#   [취약점] 파일 서명/해시 미검증 — 임의 실행 파일 실행 가능
#   [취약점] SYSTEM 권한 자동 실행 — 최고 권한으로 악성코드 실행
#
# 올바른 설정:
#   - HTTPS + 인증서 피닝 사용
#   - 파일 SHA-256 해시 및 Authenticode 서명 검증
#   - 최소 권한 원칙 적용 (전용 서비스 계정)
#   - 다운로드 후 관리자 승인 절차 추가
# ============================================================

#Requires -RunAsAdministrator

param(
    # 패치 서버 매니페스트 URL
    [string]$ManifestUrl = "http://192.168.120.10/updates/manifest.json",

    # 업데이트 확인 주기 (분)
    [int]$IntervalMinutes = 30,

    # 설치 디렉토리
    [string]$InstallDir = "C:\ProgramData\MND\UpdateService"
)

$ErrorActionPreference = "Stop"

Write-Host "============================================" -ForegroundColor Cyan
Write-Host " 군 패치 자동 업데이트 클라이언트 설정" -ForegroundColor Cyan
Write-Host " 패치 서버: $ManifestUrl" -ForegroundColor Cyan
Write-Host " 확인 주기: ${IntervalMinutes}분" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

# -------------------------------------------------------
# [1/3] 디렉토리 및 업데이트 스크립트 생성
# -------------------------------------------------------
Write-Host "`n[1/3] 업데이트 스크립트 생성..." -ForegroundColor Yellow

$downloadDir = "$InstallDir\downloads"
$logFile = "$InstallDir\update.log"

New-Item -Path $InstallDir -ItemType Directory -Force | Out-Null
New-Item -Path $downloadDir -ItemType Directory -Force | Out-Null

# 자동 업데이트 확인 스크립트
$updateScript = @"
# ============================================================
# update-checker.ps1 — 군 패치 서버 자동 업데이트 클라이언트
# [취약점] 공급망 공격(Supply Chain Attack) 벡터
# 이 스크립트는 SYSTEM 권한의 예약 작업으로 30분마다 실행됩니다.
# ============================================================

`$ManifestUrl = "$ManifestUrl"
`$DownloadDir = "$downloadDir"
`$LogFile = "$logFile"

function Write-Log {
    param([string]`$Message)
    `$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "`$timestamp - `$Message" | Out-File -FilePath `$LogFile -Append -Encoding UTF8
}

try {
    Write-Log "===== 업데이트 확인 시작 ====="
    Write-Log "매니페스트 URL: `$ManifestUrl"
    Write-Log "호스트명: `$env:COMPUTERNAME"

    # [취약점] HTTP 평문 통신 — 네트워크 스니핑/MITM으로 변조 가능
    # 올바른 설정: HTTPS 사용 + 인증서 검증
    `$response = Invoke-WebRequest -Uri `$ManifestUrl -UseBasicParsing -TimeoutSec 30
    `$manifest = `$response.Content | ConvertFrom-Json

    Write-Log "매니페스트 수신: 버전=`$(`$manifest.version), 패치 수=`$(`$manifest.patches.Count)"

    foreach (`$patch in `$manifest.patches) {
        `$patchFile = Join-Path `$DownloadDir `$patch.filename
        `$installedMarker = Join-Path `$DownloadDir "`$(`$patch.kb_id).installed"

        # 이미 설치된 패치 건너뛰기
        if (Test-Path `$installedMarker) {
            Write-Log "  [건너뜀] `$(`$patch.kb_id) (이미 설치됨)"
            continue
        }

        Write-Log "  [다운로드] `$(`$patch.filename) (`$(`$patch.size_mb)MB)"
        Write-Log "  URL: `$(`$patch.url)"

        # [취약점] HTTP 다운로드 — 전송 중 파일 교체 가능
        Invoke-WebRequest -Uri `$patch.url -OutFile `$patchFile -UseBasicParsing

        # [취약점] 파일 해시/서명 검증 없음
        # 올바른 설정:
        #   `$expectedHash = `$patch.sha256
        #   `$actualHash = (Get-FileHash `$patchFile -Algorithm SHA256).Hash
        #   if (`$actualHash -ne `$expectedHash) {
        #       Write-Log "  [거부] 해시 불일치: 예상=`$expectedHash, 실제=`$actualHash"
        #       Remove-Item `$patchFile -Force
        #       continue
        #   }
        #   `$sig = Get-AuthenticodeSignature `$patchFile
        #   if (`$sig.Status -ne "Valid") {
        #       Write-Log "  [거부] 서명 미유효: `$(`$sig.Status)"
        #       Remove-Item `$patchFile -Force
        #       continue
        #   }

        Write-Log "  [실행] `$(`$patch.filename) — SYSTEM 권한으로 실행"

        # [취약점] 검증 없이 SYSTEM 권한으로 즉시 실행
        # 악성 업데이트(Havoc Demon)가 이 경로로 실행됨
        `$proc = Start-Process -FilePath `$patchFile -ArgumentList "/quiet /norestart" `
            -Wait -PassThru

        Write-Log "  [완료] `$(`$patch.kb_id) — 종료코드: `$(`$proc.ExitCode)"

        # 설치 완료 마커 생성
        New-Item -Path `$installedMarker -ItemType File -Force | Out-Null
    }

    Write-Log "===== 업데이트 확인 완료 ====="

} catch {
    Write-Log "[오류] `$_"
}
"@

$scriptPath = "$InstallDir\update-checker.ps1"
$updateScript | Out-File -FilePath $scriptPath -Encoding UTF8

Write-Host "  스크립트 생성: $scriptPath" -ForegroundColor Green

# -------------------------------------------------------
# [2/3] 예약 작업 등록 (30분 간격, SYSTEM 권한)
# -------------------------------------------------------
Write-Host "`n[2/3] 예약 작업 등록 (${IntervalMinutes}분 간격)..." -ForegroundColor Yellow

$taskName = "MND-UpdateChecker"

# 기존 작업 제거
Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue

# [취약점] SYSTEM 권한으로 실행 — 악성코드가 최고 권한 획득
# 올바른 설정: 전용 서비스 계정(최소 권한) 사용
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
    -Description "군 패치 관리 서버 자동 업데이트 (${IntervalMinutes}분 간격) [공급망 공격 벡터]"

Write-Host "  예약 작업 등록: $taskName (SYSTEM 권한, ${IntervalMinutes}분 간격)" -ForegroundColor Green

# -------------------------------------------------------
# [3/3] 초기 실행 및 로그 확인
# -------------------------------------------------------
Write-Host "`n[3/3] 초기 업데이트 확인..." -ForegroundColor Yellow

try {
    & powershell.exe -ExecutionPolicy Bypass -File $scriptPath
    Write-Host "  초기 실행 완료" -ForegroundColor Green

    if (Test-Path $logFile) {
        Write-Host "`n  --- 로그 내용 ---" -ForegroundColor Gray
        Get-Content $logFile | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }
    }
} catch {
    Write-Host "  [경고] 패치 서버 연결 실패 (정상 — 서버가 아직 준비되지 않았을 수 있음)" -ForegroundColor Yellow
}

Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host " 자동 업데이트 클라이언트 설정 완료" -ForegroundColor Cyan
Write-Host "" -ForegroundColor Cyan
Write-Host " [취약점 요약] 공급망 공격 벡터:" -ForegroundColor Red
Write-Host "  1. HTTP 평문 통신 (MITM 가능)" -ForegroundColor Red
Write-Host "  2. 파일 서명/해시 미검증" -ForegroundColor Red
Write-Host "  3. SYSTEM 권한 자동 실행" -ForegroundColor Red
Write-Host "" -ForegroundColor Cyan
Write-Host " [블루팀 탐지 포인트]:" -ForegroundColor Yellow
Write-Host "  - PowerShell 로그: update-checker.ps1 실행" -ForegroundColor Yellow
Write-Host "  - Sysmon Event 1: SecurityPatch_KB*.exe 프로세스 생성" -ForegroundColor Yellow
Write-Host "  - Sysmon Event 3: 비정상 네트워크 연결 (C2)" -ForegroundColor Yellow
Write-Host "  - 로그 파일: $logFile" -ForegroundColor Yellow
Write-Host "============================================" -ForegroundColor Cyan
