# ============================================================
# 02_create_ou_users.ps1 — OU, 사용자, 그룹, 서비스 계정 생성
# 대상: DC01 (192.168.100.50) — 재부팅 후 실행
# 도메인: corp.mois.local
# ============================================================

#Requires -RunAsAdministrator

$ErrorActionPreference = "Stop"
Import-Module ActiveDirectory

$domainDN = "DC=corp,DC=mois,DC=local"
$domain = "corp.mois.local"

Write-Host "============================================" -ForegroundColor Cyan
Write-Host " OU, 사용자, 그룹 생성 시작" -ForegroundColor Cyan
Write-Host " 도메인: $domain" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

# -------------------------------------------------------
# [1/6] 최상위 OU 생성
# -------------------------------------------------------
Write-Host "`n[1/6] 최상위 OU 생성..." -ForegroundColor Yellow

$topOUs = @("부서", "워크스테이션", "서버", "서비스계정", "그룹")
foreach ($ou in $topOUs) {
    try {
        New-ADOrganizationalUnit -Name $ou -Path $domainDN `
            -ProtectedFromAccidentalDeletion $false
        Write-Host "  [생성] OU=$ou" -ForegroundColor Green
    } catch {
        Write-Host "  [존재] OU=$ou (이미 존재합니다)" -ForegroundColor DarkYellow
    }
}

# -------------------------------------------------------
# [2/6] 부서별 하위 OU 생성
# -------------------------------------------------------
Write-Host "`n[2/6] 부서별 OU 생성..." -ForegroundColor Yellow

$departments = @("IT운영팀", "민원처리과", "대외협력과", "정보보안과", "총무과", "정보화기획과")
foreach ($dept in $departments) {
    try {
        New-ADOrganizationalUnit -Name $dept `
            -Path "OU=부서,$domainDN" `
            -ProtectedFromAccidentalDeletion $false
        Write-Host "  [생성] OU=$dept" -ForegroundColor Green
    } catch {
        Write-Host "  [존재] OU=$dept" -ForegroundColor DarkYellow
    }
}

# 워크스테이션 하위 OU
$wsOUs = @("업무용PC", "관리자PC")
foreach ($ou in $wsOUs) {
    try {
        New-ADOrganizationalUnit -Name $ou `
            -Path "OU=워크스테이션,$domainDN" `
            -ProtectedFromAccidentalDeletion $false
        Write-Host "  [생성] OU=$ou (워크스테이션 하위)" -ForegroundColor Green
    } catch {
        Write-Host "  [존재] OU=$ou" -ForegroundColor DarkYellow
    }
}

# -------------------------------------------------------
# [3/6] 사용자 계정 생성
# -------------------------------------------------------
Write-Host "`n[3/6] 사용자 계정 생성..." -ForegroundColor Yellow

$users = @(
    @{
        SamAccountName = "admin_kim"
        Name           = "김관리"
        GivenName      = "관리"
        Surname        = "김"
        DisplayName    = "김관리"
        Department     = "IT운영팀"
        Title          = "IT운영팀장"
        Password       = "P@ssw0rd2024!"
        OU             = "OU=IT운영팀,OU=부서,$domainDN"
        Description    = "IT운영팀 도메인 관리자"
        IsAdmin        = $true
    },
    @{
        SamAccountName = "sysadmin"
        Name           = "시스템관리자"
        GivenName      = "관리자"
        Surname        = "시스템"
        DisplayName    = "시스템관리자"
        Department     = "IT운영팀"
        Title          = "시스템관리자"
        Password       = "AdminP@ss!"
        OU             = "OU=IT운영팀,OU=부서,$domainDN"
        Description    = "시스템 관리 서비스 계정 겸용"
        IsAdmin        = $true
    },
    @{
        SamAccountName = "user_park"
        Name           = "박민준"
        GivenName      = "민준"
        Surname        = "박"
        DisplayName    = "박민준"
        Department     = "대외협력과"
        Title          = "주무관"
        Password       = "Minjun2024!"
        OU             = "OU=대외협력과,OU=부서,$domainDN"
        Description    = "대외협력과 담당자"
        IsAdmin        = $false
    },
    @{
        SamAccountName = "user_lee"
        Name           = "이서연"
        GivenName      = "서연"
        Surname        = "이"
        DisplayName    = "이서연"
        Department     = "민원처리과"
        Title          = "주무관"
        Password       = "Seoyeon123!"
        OU             = "OU=민원처리과,OU=부서,$domainDN"
        Description    = "민원처리과 담당자 (피싱 대상)"
        IsAdmin        = $false
    },
    @{
        SamAccountName = "user_choi"
        Name           = "최동현"
        GivenName      = "동현"
        Surname        = "최"
        DisplayName    = "최동현"
        Department     = "정보보안과"
        Title          = "주무관"
        Password       = "Donghyun1!"
        OU             = "OU=정보보안과,OU=부서,$domainDN"
        Description    = "정보보안과 담당자"
        IsAdmin        = $false
    },
    @{
        SamAccountName = "user_jung"
        Name           = "정하은"
        GivenName      = "하은"
        Surname        = "정"
        DisplayName    = "정하은"
        Department     = "총무과"
        Title          = "주무관"
        Password       = "Haeun2024!"
        OU             = "OU=총무과,OU=부서,$domainDN"
        Description    = "총무과 담당자"
        IsAdmin        = $false
    },
    @{
        SamAccountName = "user_han"
        Name           = "한지우"
        GivenName      = "지우"
        Surname        = "한"
        DisplayName    = "한지우"
        Department     = "정보화기획과"
        Title          = "주무관"
        Password       = "Jiwoo2024!"
        OU             = "OU=정보화기획과,OU=부서,$domainDN"
        Description    = "정보화기획과 담당자"
        IsAdmin        = $false
    }
)

foreach ($user in $users) {
    $securePassword = ConvertTo-SecureString $user.Password -AsPlainText -Force

    try {
        New-ADUser `
            -SamAccountName $user.SamAccountName `
            -UserPrincipalName "$($user.SamAccountName)@$domain" `
            -Name $user.Name `
            -GivenName $user.GivenName `
            -Surname $user.Surname `
            -DisplayName $user.DisplayName `
            -Department $user.Department `
            -Title $user.Title `
            -Description $user.Description `
            -Path $user.OU `
            -AccountPassword $securePassword `
            -Enabled $true `
            -PasswordNeverExpires $true `
            -CannotChangePassword $false `
            -ChangePasswordAtLogon $false

        Write-Host "  [생성] $($user.SamAccountName) ($($user.Name)) - $($user.Department)" -ForegroundColor Green

        # Domain Admins 그룹에 관리자 추가
        if ($user.IsAdmin) {
            Add-ADGroupMember -Identity "Domain Admins" -Members $user.SamAccountName
            Write-Host "    -> Domain Admins 그룹 추가" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "  [오류] $($user.SamAccountName): $_" -ForegroundColor Red
    }
}

# -------------------------------------------------------
# [4/6] 부서별 보안 그룹 생성 및 멤버 할당
# -------------------------------------------------------
Write-Host "`n[4/6] 부서별 보안 그룹 생성..." -ForegroundColor Yellow

$groupMembers = @{
    "GRP-IT운영팀"    = @("admin_kim", "sysadmin")
    "GRP-대외협력과"  = @("user_park")
    "GRP-민원처리과"  = @("user_lee")
    "GRP-정보보안과"  = @("user_choi")
    "GRP-총무과"      = @("user_jung")
    "GRP-정보화기획과" = @("user_han")
}

foreach ($grp in $groupMembers.Keys) {
    try {
        New-ADGroup -Name $grp -GroupScope Global -GroupCategory Security `
            -Path "OU=그룹,$domainDN" `
            -Description "$($grp.Replace('GRP-','')) 부서 그룹"
        Write-Host "  [생성] 그룹: $grp" -ForegroundColor Green
    } catch {
        Write-Host "  [존재] 그룹: $grp" -ForegroundColor DarkYellow
    }

    # 멤버 할당
    foreach ($member in $groupMembers[$grp]) {
        Add-ADGroupMember -Identity $grp -Members $member -ErrorAction SilentlyContinue
        Write-Host "    -> $member 추가" -ForegroundColor Gray
    }
}

# [취약점] Remote Desktop Users에 Domain Users 전체 추가 — 모든 사용자가 RDP 접근 가능
# 올바른 설정: 필요한 사용자만 개별적으로 추가해야 함
Add-ADGroupMember -Identity "Remote Desktop Users" -Members "Domain Users"
Write-Host "  [취약점] Remote Desktop Users <- Domain Users (전체 사용자 RDP 허용)" -ForegroundColor Red

# -------------------------------------------------------
# [5/6] 서비스 계정 생성
# -------------------------------------------------------
Write-Host "`n[5/6] 서비스 계정 생성..." -ForegroundColor Yellow

# 백업 서비스 계정
New-ADUser -SamAccountName "svc_backup" `
    -UserPrincipalName "svc_backup@$domain" `
    -Name "백업서비스" `
    -Path "OU=서비스계정,$domainDN" `
    -AccountPassword (ConvertTo-SecureString "Backup2024!" -AsPlainText -Force) `
    -Enabled $true -PasswordNeverExpires $true `
    -Description "백업 서비스 계정"
Write-Host "  [생성] svc_backup (Backup2024!)" -ForegroundColor Green

# SQL 서비스 계정 — Kerberoasting 대상
New-ADUser -SamAccountName "svc_sql" `
    -UserPrincipalName "svc_sql@$domain" `
    -Name "SQL서비스" `
    -Path "OU=서비스계정,$domainDN" `
    -AccountPassword (ConvertTo-SecureString "SqlSvc2024!" -AsPlainText -Force) `
    -Enabled $true -PasswordNeverExpires $true `
    -Description "SQL 서비스 계정"

# [취약점] SPN 등록 — Kerberoasting 공격 대상
# 올바른 설정: 서비스 계정에 강력한 비밀번호(25자 이상 랜덤) 사용, gMSA 사용 권장
setspn -S MSSQLSvc/db01.corp.mois.local svc_sql

# [취약점] 제한 없는 위임 설정 — 자격증명 탈취 가능
# 올바른 설정: 제한된 위임(Constrained Delegation) 또는 리소스 기반 위임 사용
Set-ADUser -Identity "svc_sql" -TrustedForDelegation $true

Write-Host "  [생성] svc_sql (SqlSvc2024!) + SPN 등록" -ForegroundColor Green
Write-Host "  [취약점] svc_sql: 제한 없는 위임 설정됨" -ForegroundColor Red

# -------------------------------------------------------
# [6/6] DNS 조건부 전달자 설정 (비도메인 자산 해석용)
# -------------------------------------------------------
Write-Host "`n[6/6] DNS 레코드 추가..." -ForegroundColor Yellow

# 내부 서비스 DNS 레코드 추가
Add-DnsServerResourceRecordA -ZoneName $domain -Name "dc01" -IPv4Address "192.168.100.50"

# 비도메인 자산 해석용 (mois.local 영역)
try {
    Add-DnsServerPrimaryZone -Name "mois.local" -ReplicationScope Domain -ErrorAction Stop
} catch {
    Write-Host "  mois.local 영역이 이미 존재합니다." -ForegroundColor DarkYellow
}

# 내부 서비스 A 레코드
$dnsRecords = @{
    "webmail"  = "192.168.100.12"
    "portal"   = "192.168.100.11"
    "ai"       = "192.168.100.13"
}

foreach ($name in $dnsRecords.Keys) {
    try {
        Add-DnsServerResourceRecordA -ZoneName "mois.local" -Name $name `
            -IPv4Address $dnsRecords[$name]
        Write-Host "  [DNS] $name.mois.local -> $($dnsRecords[$name])" -ForegroundColor Green
    } catch {
        Write-Host "  [존재] $name.mois.local" -ForegroundColor DarkYellow
    }
}

Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host " OU, 사용자, 그룹 생성 완료" -ForegroundColor Cyan
Write-Host " 다음: 03_configure_gpo.ps1 실행" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
