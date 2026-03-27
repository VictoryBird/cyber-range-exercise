# ============================================================
# 05_install_sysmon.ps1 — Sysmon 설치 (블루팀 모니터링용)
# 대상: DC 및 모든 워크스테이션
# ============================================================
# Sysmon은 프로세스 생성, 네트워크 연결, 파일 변경 등
# 상세 이벤트를 Windows 이벤트 로그에 기록합니다.
# 블루팀이 레드팀 공격을 탐지하는 데 핵심적인 도구입니다.
# ============================================================

#Requires -RunAsAdministrator

$ErrorActionPreference = "Stop"

Write-Host "============================================" -ForegroundColor Cyan
Write-Host " Sysmon 설치 시작 (블루팀 모니터링)" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

# -------------------------------------------------------
# [1/4] Sysmon 다운로드 경로 설정
# -------------------------------------------------------
Write-Host "`n[1/4] Sysmon 준비..." -ForegroundColor Yellow

$sysmonDir = "C:\Tools\Sysmon"
if (-not (Test-Path $sysmonDir)) {
    New-Item -Path $sysmonDir -ItemType Directory -Force | Out-Null
}

# Sysmon 바이너리는 사전에 배포되어 있어야 합니다.
# 옵션 1: 네트워크 공유에서 복사
# 옵션 2: Sysinternals에서 직접 다운로드
$sysmonExe = "$sysmonDir\Sysmon64.exe"

if (-not (Test-Path $sysmonExe)) {
    Write-Host "  Sysmon 다운로드 중 (Sysinternals)..." -ForegroundColor Gray
    try {
        # 훈련 환경에서는 인터넷 접근이 제한될 수 있으므로
        # DC의 SYSVOL 공유에서 복사하는 것을 권장합니다.
        $sysvolPath = "\\192.168.100.50\SYSVOL\corp.mois.local\scripts\Sysmon64.exe"
        if (Test-Path $sysvolPath) {
            Copy-Item $sysvolPath -Destination $sysmonExe
            Write-Host "  SYSVOL에서 복사 완료" -ForegroundColor Green
        } else {
            # 인터넷 접근 가능 시 직접 다운로드
            Invoke-WebRequest -Uri "https://live.sysinternals.com/Sysmon64.exe" `
                -OutFile $sysmonExe
            Write-Host "  Sysinternals에서 다운로드 완료" -ForegroundColor Green
        }
    } catch {
        Write-Host "  [경고] Sysmon 다운로드 실패. 수동으로 $sysmonExe 에 배치하세요." -ForegroundColor Red
        Write-Host "  다운로드: https://learn.microsoft.com/en-us/sysinternals/downloads/sysmon" -ForegroundColor Yellow
        exit 1
    }
}

# -------------------------------------------------------
# [2/4] Sysmon 구성 파일 생성
# -------------------------------------------------------
Write-Host "`n[2/4] Sysmon 구성 파일 생성..." -ForegroundColor Yellow

$sysmonConfig = @'
<Sysmon schemaversion="4.90">
  <!-- 사이버 훈련용 Sysmon 구성 — 블루팀 탐지 최적화 -->
  <HashAlgorithms>md5,sha256,IMPHASH</HashAlgorithms>
  <CheckRevocation/>

  <EventFiltering>
    <!-- 프로세스 생성 (Event ID 1) — 모든 프로세스 기록 -->
    <ProcessCreate onmatch="exclude">
      <!-- 노이즈 제외 -->
      <Image condition="is">C:\Windows\System32\backgroundTaskHost.exe</Image>
      <Image condition="is">C:\Windows\System32\SearchProtocolHost.exe</Image>
    </ProcessCreate>

    <!-- 네트워크 연결 (Event ID 3) — 핵심 탐지 대상 -->
    <NetworkConnect onmatch="include">
      <!-- C2 통신 탐지 -->
      <DestinationPort condition="is">443</DestinationPort>
      <DestinationPort condition="is">80</DestinationPort>
      <DestinationPort condition="is">8080</DestinationPort>
      <DestinationPort condition="is">4443</DestinationPort>
      <!-- SMB 측면 이동 탐지 -->
      <DestinationPort condition="is">445</DestinationPort>
      <!-- WinRM 탐지 -->
      <DestinationPort condition="is">5985</DestinationPort>
      <!-- RDP 탐지 -->
      <DestinationPort condition="is">3389</DestinationPort>
    </NetworkConnect>

    <!-- 프로세스 접근 (Event ID 10) — LSASS 접근 탐지 (Mimikatz) -->
    <ProcessAccess onmatch="include">
      <TargetImage condition="is">C:\Windows\System32\lsass.exe</TargetImage>
    </ProcessAccess>

    <!-- 파일 생성 (Event ID 11) — 의심 경로 모니터링 -->
    <FileCreate onmatch="include">
      <TargetFilename condition="contains">\Temp\</TargetFilename>
      <TargetFilename condition="contains">\AppData\</TargetFilename>
      <TargetFilename condition="contains">\Downloads\</TargetFilename>
      <TargetFilename condition="end with">.exe</TargetFilename>
      <TargetFilename condition="end with">.dll</TargetFilename>
      <TargetFilename condition="end with">.ps1</TargetFilename>
      <TargetFilename condition="end with">.lnk</TargetFilename>
    </FileCreate>

    <!-- 레지스트리 변경 (Event ID 13) — 지속성 메커니즘 탐지 -->
    <RegistryEvent onmatch="include">
      <TargetObject condition="contains">CurrentVersion\Run</TargetObject>
      <TargetObject condition="contains">CurrentVersion\RunOnce</TargetObject>
      <TargetObject condition="contains">WDigest</TargetObject>
      <TargetObject condition="contains">SecurityProviders</TargetObject>
    </RegistryEvent>

    <!-- 파이프 생성 (Event ID 17/18) — PsExec, 측면 이동 탐지 -->
    <PipeEvent onmatch="include">
      <PipeName condition="is">\psexec</PipeName>
      <PipeName condition="is">\PSEXESVC</PipeName>
      <PipeName condition="contains">msagent_</PipeName>
    </PipeEvent>

    <!-- DNS 쿼리 (Event ID 22) — 비정상 DNS 탐지 -->
    <DnsQuery onmatch="exclude">
      <QueryName condition="end with">.mois.local</QueryName>
      <QueryName condition="end with">.mnd.local</QueryName>
      <QueryName condition="is">localhost</QueryName>
    </DnsQuery>
  </EventFiltering>
</Sysmon>
'@

$configPath = "$sysmonDir\sysmon_config.xml"
$sysmonConfig | Out-File -FilePath $configPath -Encoding UTF8
Write-Host "  구성 파일: $configPath" -ForegroundColor Green

# -------------------------------------------------------
# [3/4] Sysmon 설치/업데이트
# -------------------------------------------------------
Write-Host "`n[3/4] Sysmon 설치..." -ForegroundColor Yellow

# 기존 설치 확인
$sysmonService = Get-Service -Name "Sysmon64" -ErrorAction SilentlyContinue
if ($sysmonService) {
    Write-Host "  기존 Sysmon 발견 — 구성 업데이트..." -ForegroundColor DarkYellow
    & $sysmonExe -c $configPath
} else {
    # 신규 설치 (EULA 자동 수락)
    & $sysmonExe -accepteula -i $configPath
}

Write-Host "  Sysmon 설치/구성 완료" -ForegroundColor Green

# -------------------------------------------------------
# [4/4] 이벤트 로그 크기 확장 (블루팀용)
# -------------------------------------------------------
Write-Host "`n[4/4] 이벤트 로그 크기 확장..." -ForegroundColor Yellow

# Sysmon 로그 최대 크기 확장 (기본 1MB → 100MB)
wevtutil sl "Microsoft-Windows-Sysmon/Operational" /ms:104857600

# Security 로그 크기 확장 (기본 20MB → 200MB)
wevtutil sl "Security" /ms:209715200

# PowerShell 로그 크기 확장
wevtutil sl "Microsoft-Windows-PowerShell/Operational" /ms:104857600

Write-Host "  Sysmon 로그: 100MB, Security: 200MB, PowerShell: 100MB" -ForegroundColor Green

Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host " Sysmon 설치 완료" -ForegroundColor Cyan
Write-Host " 블루팀 주요 탐지 이벤트:" -ForegroundColor Cyan
Write-Host "  - Event 1: 프로세스 생성 (C2 에이전트)" -ForegroundColor White
Write-Host "  - Event 3: 네트워크 연결 (C2 통신)" -ForegroundColor White
Write-Host "  - Event 10: LSASS 접근 (Mimikatz)" -ForegroundColor White
Write-Host "  - Event 17/18: 명명된 파이프 (PsExec)" -ForegroundColor White
Write-Host "============================================" -ForegroundColor Cyan
