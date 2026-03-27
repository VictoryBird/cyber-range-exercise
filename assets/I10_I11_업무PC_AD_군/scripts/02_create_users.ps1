# ============================================================
# 02_create_users.ps1 — 군 AD OU, 사용자, 그룹 생성
# 대상: MIL-DC01 (192.168.110.50) — 재부팅 후 실행
# 도메인: corp.mnd.local
# ============================================================

#Requires -RunAsAdministrator

$ErrorActionPreference = "Stop"
Import-Module ActiveDirectory

$domainDN = "DC=corp,DC=mnd,DC=local"
$domain = "corp.mnd.local"

Write-Host "============================================" -ForegroundColor Cyan
Write-Host " 군 AD OU, 사용자, 그룹 생성 시작" -ForegroundColor Cyan
Write-Host " 도메인: $domain" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

# -------------------------------------------------------
# [1/5] 최상위 OU 생성
# -------------------------------------------------------
Write-Host "`n[1/5] 최상위 OU 생성..." -ForegroundColor Yellow

$topOUs = @("부서", "워크스테이션", "서버", "서비스계정", "그룹")
foreach ($ou in $topOUs) {
    try {
        New-ADOrganizationalUnit -Name $ou -Path $domainDN `
            -ProtectedFromAccidentalDeletion $false
        Write-Host "  [생성] OU=$ou" -ForegroundColor Green
    } catch {
        Write-Host "  [존재] OU=$ou" -ForegroundColor DarkYellow
    }
}

# -------------------------------------------------------
# [2/5] 부서별 하위 OU 생성
# -------------------------------------------------------
Write-Host "`n[2/5] 부서별 OU 생성..." -ForegroundColor Yellow

$departments = @("정보통신과", "작전지원과", "정보보호과", "군수지원과", "통신운영과", "인사과", "전산과")
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
foreach ($ou in @("업무용PC", "관리자PC")) {
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
# [3/5] 군 사용자 계정 생성
# -------------------------------------------------------
Write-Host "`n[3/5] 군 사용자 계정 생성..." -ForegroundColor Yellow

$users = @(
    @{ Sam = "mil_admin"; Name = "김영호"; Dept = "정보통신과"; Title = "과장";  PW = "MilAdmin2026!"; Admin = $true },
    @{ Sam = "mil_kim";   Name = "김정수"; Dept = "작전지원과"; Title = "소령";  PW = "Jungsu2026!";   Admin = $false },
    @{ Sam = "mil_lee";   Name = "이현우"; Dept = "정보보호과"; Title = "대위";  PW = "Hyunwoo123!";   Admin = $false },
    @{ Sam = "mil_park";  Name = "박서준"; Dept = "군수지원과"; Title = "상사";  PW = "Seojun2026!";   Admin = $false },
    @{ Sam = "mil_choi";  Name = "최민서"; Dept = "통신운영과"; Title = "중위";  PW = "Minseo2026!";   Admin = $false },
    @{ Sam = "mil_jung";  Name = "정유진"; Dept = "인사과";     Title = "대위";  PW = "Yujin2026!";    Admin = $false },
    @{ Sam = "mil_han";   Name = "한도현"; Dept = "전산과";     Title = "병장";  PW = "Dohyun2026!";   Admin = $false }
)

foreach ($u in $users) {
    $ouPath = "OU=$($u.Dept),OU=부서,$domainDN"

    try {
        New-ADUser `
            -SamAccountName $u.Sam `
            -UserPrincipalName "$($u.Sam)@$domain" `
            -Name $u.Name `
            -DisplayName $u.Name `
            -Department $u.Dept `
            -Title $u.Title `
            -Path $ouPath `
            -AccountPassword (ConvertTo-SecureString $u.PW -AsPlainText -Force) `
            -Enabled $true `
            -PasswordNeverExpires $true `
            -CannotChangePassword $false `
            -ChangePasswordAtLogon $false

        Write-Host "  [생성] $($u.Sam) ($($u.Name)) - $($u.Dept) [$($u.Title)]" -ForegroundColor Green

        if ($u.Admin) {
            Add-ADGroupMember -Identity "Domain Admins" -Members $u.Sam
            Write-Host "    -> Domain Admins 그룹 추가" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "  [오류] $($u.Sam): $_" -ForegroundColor Red
    }
}

# -------------------------------------------------------
# [4/5] 부서별 보안 그룹 생성 및 멤버 할당
# -------------------------------------------------------
Write-Host "`n[4/5] 부서별 보안 그룹 생성..." -ForegroundColor Yellow

$groupMembers = @{
    "GRP-정보통신과" = @("mil_admin")
    "GRP-작전지원과" = @("mil_kim")
    "GRP-정보보호과" = @("mil_lee")
    "GRP-군수지원과" = @("mil_park")
    "GRP-통신운영과" = @("mil_choi")
    "GRP-인사과"     = @("mil_jung")
    "GRP-전산과"     = @("mil_han")
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

    foreach ($member in $groupMembers[$grp]) {
        Add-ADGroupMember -Identity $grp -Members $member -ErrorAction SilentlyContinue
    }
}

# [취약점] Remote Desktop Users에 Domain Users 전체 추가
# 올바른 설정: 필요한 사용자만 개별 추가
Add-ADGroupMember -Identity "Remote Desktop Users" -Members "Domain Users"
Write-Host "  [취약점] Remote Desktop Users <- Domain Users (전체 RDP 허용)" -ForegroundColor Red

# -------------------------------------------------------
# [5/5] 서비스 계정 생성
# -------------------------------------------------------
Write-Host "`n[5/5] 서비스 계정 생성..." -ForegroundColor Yellow

# 패치 서비스 계정
New-ADUser -SamAccountName "svc_patch" `
    -UserPrincipalName "svc_patch@$domain" `
    -Name "패치서비스" `
    -Path "OU=서비스계정,$domainDN" `
    -AccountPassword (ConvertTo-SecureString "PatchSvc2026!" -AsPlainText -Force) `
    -Enabled $true -PasswordNeverExpires $true `
    -Description "패치 서비스 계정"
Write-Host "  [생성] svc_patch (PatchSvc2026!)" -ForegroundColor Green

# 백업 서비스 계정
New-ADUser -SamAccountName "svc_backup" `
    -UserPrincipalName "svc_backup@$domain" `
    -Name "백업서비스" `
    -Path "OU=서비스계정,$domainDN" `
    -AccountPassword (ConvertTo-SecureString "MilBackup2026!" -AsPlainText -Force) `
    -Enabled $true -PasswordNeverExpires $true `
    -Description "백업 서비스 계정"
Write-Host "  [생성] svc_backup (MilBackup2026!)" -ForegroundColor Green

# DNS 레코드 추가
Write-Host "`n  DNS 레코드 추가..." -ForegroundColor Yellow
try {
    Add-DnsServerPrimaryZone -Name "mnd.local" -ReplicationScope Domain -ErrorAction Stop
} catch {
    Write-Host "  mnd.local 영역이 이미 존재합니다." -ForegroundColor DarkYellow
}

$dnsRecords = @{
    "update" = "192.168.120.10"  # 패치 서버
}
foreach ($name in $dnsRecords.Keys) {
    try {
        Add-DnsServerResourceRecordA -ZoneName "mnd.local" -Name $name `
            -IPv4Address $dnsRecords[$name]
        Write-Host "  [DNS] $name.mnd.local -> $($dnsRecords[$name])" -ForegroundColor Green
    } catch {
        Write-Host "  [존재] $name.mnd.local" -ForegroundColor DarkYellow
    }
}

Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host " 군 AD 사용자/그룹 생성 완료" -ForegroundColor Cyan
Write-Host " 다음: 03_configure_gpo.ps1 실행" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
