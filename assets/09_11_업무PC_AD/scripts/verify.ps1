# ============================================================
# verify.ps1 — 환경 검증 스크립트
# AD 구성, GPO 설정, 사용자 계정, 취약점 상태를 확인합니다.
# DC(192.168.100.50) 또는 도메인 가입 PC에서 실행 가능합니다.
# ============================================================

#Requires -RunAsAdministrator

$ErrorActionPreference = "SilentlyContinue"

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " 자산 #09~#11 환경 검증 (corp.mois.local)" -ForegroundColor Cyan
Write-Host " 검증 시각: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

$pass = 0
$fail = 0
$warn = 0

function Test-Check {
    param(
        [string]$Name,
        [bool]$Result,
        [string]$Expected,
        [string]$Actual,
        [switch]$IsVulnerability
    )
    if ($Result) {
        if ($IsVulnerability) {
            Write-Host "  [취약] $Name" -ForegroundColor Red
            Write-Host "         예상: $Expected | 실제: $Actual" -ForegroundColor DarkRed
            $script:warn++
        } else {
            Write-Host "  [PASS] $Name" -ForegroundColor Green
            $script:pass++
        }
    } else {
        Write-Host "  [FAIL] $Name" -ForegroundColor Red
        Write-Host "         예상: $Expected | 실제: $Actual" -ForegroundColor DarkRed
        $script:fail++
    }
}

# -------------------------------------------------------
# [1/7] AD 도메인 확인
# -------------------------------------------------------
Write-Host "`n[1/7] AD 도메인 확인" -ForegroundColor Yellow
Write-Host "  -------------------------------------------" -ForegroundColor DarkGray

try {
    Import-Module ActiveDirectory

    $domain = Get-ADDomain
    Test-Check -Name "도메인 이름" `
        -Result ($domain.DNSRoot -eq "corp.mois.local") `
        -Expected "corp.mois.local" -Actual $domain.DNSRoot

    Test-Check -Name "NetBIOS 이름" `
        -Result ($domain.NetBIOSName -eq "CORP") `
        -Expected "CORP" -Actual $domain.NetBIOSName

    $dc = Get-ADDomainController
    Test-Check -Name "DC 호스트명" `
        -Result ($dc.Name -eq "DC01") `
        -Expected "DC01" -Actual $dc.Name
} catch {
    Write-Host "  [SKIP] AD 모듈 사용 불가 (도메인 가입 PC에서 RSAT 필요)" -ForegroundColor DarkYellow
}

# -------------------------------------------------------
# [2/7] 사용자 계정 확인
# -------------------------------------------------------
Write-Host "`n[2/7] 사용자 계정 확인" -ForegroundColor Yellow
Write-Host "  -------------------------------------------" -ForegroundColor DarkGray

$expectedUsers = @(
    "admin_kim", "sysadmin", "user_park", "user_lee",
    "user_choi", "user_jung", "user_han"
)

try {
    foreach ($userName in $expectedUsers) {
        $user = Get-ADUser -Identity $userName -Properties Department, MemberOf -ErrorAction Stop
        $isAdmin = ($user.MemberOf -match "Domain Admins")
        $adminTag = if ($isAdmin) { " [Domain Admin]" } else { "" }
        Test-Check -Name "사용자: $userName ($($user.Name))$adminTag" `
            -Result $true -Expected "존재" -Actual "존재"
    }

    # 서비스 계정 확인
    $svcBackup = Get-ADUser -Identity "svc_backup" -ErrorAction Stop
    Test-Check -Name "서비스계정: svc_backup" `
        -Result $true -Expected "존재" -Actual "존재"

    $svcSql = Get-ADUser -Identity "svc_sql" -ErrorAction Stop
    Test-Check -Name "서비스계정: svc_sql" `
        -Result $true -Expected "존재" -Actual "존재"
} catch {
    Write-Host "  [SKIP] AD 사용자 조회 실패: $_" -ForegroundColor DarkYellow
}

# -------------------------------------------------------
# [3/7] Domain Admins 그룹 멤버 확인
# -------------------------------------------------------
Write-Host "`n[3/7] Domain Admins 그룹 확인" -ForegroundColor Yellow
Write-Host "  -------------------------------------------" -ForegroundColor DarkGray

try {
    $domainAdmins = Get-ADGroupMember -Identity "Domain Admins" | Select-Object -ExpandProperty SamAccountName
    $expectedAdmins = @("Administrator", "admin_kim", "sysadmin")

    foreach ($admin in $expectedAdmins) {
        Test-Check -Name "Domain Admin: $admin" `
            -Result ($domainAdmins -contains $admin) `
            -Expected "멤버" -Actual $(if ($domainAdmins -contains $admin) { "멤버" } else { "비멤버" })
    }

    # 예상 외 Domain Admin 확인
    $unexpected = $domainAdmins | Where-Object { $_ -notin $expectedAdmins }
    if ($unexpected) {
        Write-Host "  [경고] 예상 외 Domain Admin: $($unexpected -join ', ')" -ForegroundColor Yellow
    }
} catch {
    Write-Host "  [SKIP] 그룹 조회 실패" -ForegroundColor DarkYellow
}

# -------------------------------------------------------
# [4/7] OU 구조 확인
# -------------------------------------------------------
Write-Host "`n[4/7] OU 구조 확인" -ForegroundColor Yellow
Write-Host "  -------------------------------------------" -ForegroundColor DarkGray

$expectedOUs = @(
    "OU=부서,DC=corp,DC=mois,DC=local",
    "OU=IT운영팀,OU=부서,DC=corp,DC=mois,DC=local",
    "OU=민원처리과,OU=부서,DC=corp,DC=mois,DC=local",
    "OU=대외협력과,OU=부서,DC=corp,DC=mois,DC=local",
    "OU=정보보안과,OU=부서,DC=corp,DC=mois,DC=local",
    "OU=총무과,OU=부서,DC=corp,DC=mois,DC=local",
    "OU=정보화기획과,OU=부서,DC=corp,DC=mois,DC=local",
    "OU=워크스테이션,DC=corp,DC=mois,DC=local",
    "OU=업무용PC,OU=워크스테이션,DC=corp,DC=mois,DC=local",
    "OU=관리자PC,OU=워크스테이션,DC=corp,DC=mois,DC=local"
)

try {
    foreach ($ouDN in $expectedOUs) {
        $ouName = ($ouDN -split ',')[0].Replace('OU=','')
        try {
            Get-ADOrganizationalUnit -Identity $ouDN -ErrorAction Stop | Out-Null
            Test-Check -Name "OU: $ouName" -Result $true -Expected "존재" -Actual "존재"
        } catch {
            Test-Check -Name "OU: $ouName" -Result $false -Expected "존재" -Actual "없음"
        }
    }
} catch {
    Write-Host "  [SKIP] OU 조회 실패" -ForegroundColor DarkYellow
}

# -------------------------------------------------------
# [5/7] GPO 취약점 상태 확인
# -------------------------------------------------------
Write-Host "`n[5/7] GPO 취약점 상태 확인" -ForegroundColor Yellow
Write-Host "  -------------------------------------------" -ForegroundColor DarkGray

# WDigest 확인
$wdigest = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\WDigest" `
    -Name "UseLogonCredential" -ErrorAction SilentlyContinue
Test-Check -Name "WDigest 활성화 (평문 PW 노출)" `
    -Result ($wdigest.UseLogonCredential -eq 1) `
    -Expected "UseLogonCredential=1" `
    -Actual "UseLogonCredential=$($wdigest.UseLogonCredential)" `
    -IsVulnerability

# Credential Guard 확인
$devGuard = Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard" `
    -Name "EnableVirtualizationBasedSecurity" -ErrorAction SilentlyContinue
Test-Check -Name "Credential Guard 비활성화" `
    -Result ($devGuard.EnableVirtualizationBasedSecurity -eq 0 -or $null -eq $devGuard) `
    -Expected "VBS=0 또는 미설정" `
    -Actual "VBS=$($devGuard.EnableVirtualizationBasedSecurity)" `
    -IsVulnerability

# SMB 서명 확인
$smbServer = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" `
    -Name "RequireSecuritySignature" -ErrorAction SilentlyContinue
Test-Check -Name "SMB 서명 미적용 (NTLM 릴레이 가능)" `
    -Result ($smbServer.RequireSecuritySignature -eq 0 -or $null -eq $smbServer) `
    -Expected "RequireSecuritySignature=0" `
    -Actual "RequireSecuritySignature=$($smbServer.RequireSecuritySignature)" `
    -IsVulnerability

# PowerShell 실행 정책 확인
$psPolicy = Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell" `
    -Name "ExecutionPolicy" -ErrorAction SilentlyContinue
Test-Check -Name "PowerShell Unrestricted" `
    -Result ($psPolicy.ExecutionPolicy -eq "Unrestricted") `
    -Expected "Unrestricted" `
    -Actual "$($psPolicy.ExecutionPolicy)" `
    -IsVulnerability

# -------------------------------------------------------
# [6/7] Sysmon 설치 확인 (블루팀)
# -------------------------------------------------------
Write-Host "`n[6/7] Sysmon 설치 확인 (블루팀)" -ForegroundColor Yellow
Write-Host "  -------------------------------------------" -ForegroundColor DarkGray

$sysmonSvc = Get-Service -Name "Sysmon64" -ErrorAction SilentlyContinue
Test-Check -Name "Sysmon 서비스 실행" `
    -Result ($sysmonSvc -and $sysmonSvc.Status -eq "Running") `
    -Expected "Running" `
    -Actual $(if ($sysmonSvc) { $sysmonSvc.Status } else { "미설치" })

# PowerShell 로깅 확인
$psLog = Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging" `
    -Name "EnableScriptBlockLogging" -ErrorAction SilentlyContinue
Test-Check -Name "PowerShell 스크립트 블록 로깅" `
    -Result ($psLog.EnableScriptBlockLogging -eq 1) `
    -Expected "EnableScriptBlockLogging=1" `
    -Actual "EnableScriptBlockLogging=$($psLog.EnableScriptBlockLogging)"

# -------------------------------------------------------
# [7/7] 네트워크 연결 확인
# -------------------------------------------------------
Write-Host "`n[7/7] 네트워크 연결 확인" -ForegroundColor Yellow
Write-Host "  -------------------------------------------" -ForegroundColor DarkGray

$targets = @(
    @{ Name = "DC (192.168.100.50)"; IP = "192.168.100.50" },
    @{ Name = "게이트웨이 (192.168.100.1)"; IP = "192.168.100.1" }
)

foreach ($target in $targets) {
    $reachable = Test-Connection -ComputerName $target.IP -Count 1 -Quiet
    Test-Check -Name "연결: $($target.Name)" `
        -Result $reachable -Expected "응답" `
        -Actual $(if ($reachable) { "응답" } else { "타임아웃" })
}

# -------------------------------------------------------
# 결과 요약
# -------------------------------------------------------
Write-Host "`n============================================================" -ForegroundColor Cyan
Write-Host " 검증 결과 요약" -ForegroundColor Cyan
Write-Host "  통과: $pass" -ForegroundColor Green
Write-Host "  실패: $fail" -ForegroundColor $(if ($fail -gt 0) { "Red" } else { "Green" })
Write-Host "  취약점 확인: $warn" -ForegroundColor $(if ($warn -gt 0) { "Red" } else { "Green" })
Write-Host "============================================================" -ForegroundColor Cyan

if ($fail -gt 0) {
    Write-Host "`n [주의] $fail 개 항목이 실패했습니다. 설정을 확인하세요." -ForegroundColor Red
}
