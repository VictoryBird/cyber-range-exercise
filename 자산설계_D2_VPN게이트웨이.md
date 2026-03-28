# 자산 설계서 D2: VPN 게이트웨이 (Military VPN Gateway)

| 항목 | 내용 |
|------|------|
| 자산 ID | D2 |
| 호스트명 | mil-vpn-gw |
| IP 주소 | 192.168.92.222 |
| 도메인 | vpn.mnd.valdoria.mil |
| OS | Ubuntu 22.04 LTS |
| 역할 | 원격접속 VPN 게이트웨이 (OpenVPN Access Server) |
| 공격 체인 위치 | **STEP 4-1 — 핵심 피벗 포인트** |
| 작성일 | 2026-03-26 |

---

## 1. 개요

### 1.1 자산 목적

D2 VPN 게이트웨이는 발도리아국 국방부의 원격접속 VPN 서버이다. 외부 근무자나 협력기관 직원이 군 내부 자원에 안전하게 접근할 수 있도록 OpenVPN Access Server를 운영한다. VPN 인증 후에는 패치관리 전용 서브넷(192.168.92.0/24)에만 접근이 허용된다.

### 1.2 시나리오상 핵심 역할: 공공기관 -> 군 네트워크 진입점

> **이 자산은 PHASE 4 전체의 핵심 피벗 포인트(Key Pivot Point)이다.**

공격자는 STEP 2-7에서 AI 어시스턴트의 프롬프트 인젝션을 통해 추출한 군 VPN 자격증명(GOV20190847 / 20190847890312)으로 이 VPN 게이트웨이에 로그인한다. OPNSense-3이 공공기관 INT와 군 DMZ 간 네트워크를 논리적으로 단절하고 있으므로, 이 VPN 접속이 군 네트워크로의 **유일한 진입 경로**이다.

**취약점 요약:**

| 취약점 | 설명 | 심각도 |
|--------|------|--------|
| 크리덴셜 재사용 | AI 어시스턴트에서 탈취한 GOV20190847 계정 사용 | Critical |
| MFA 미적용 | 다중 인증 없이 ID/PW만으로 VPN 접속 가능 | High |
| 계정 잠금 미설정 | 무제한 로그인 시도 가능 (브루트포스 가능) | Medium |
| 과도한 세션 시간 | 24시간 세션 유지 (자동 만료 없음) | Medium |
| 로깅 미흡 | 첫 로그인 알림, 비업무 시간 접속 알림 미설정 | Medium |

### 1.3 공격 체인 위치

```
[AI 어시스턴트 (192.168.92.207)] — 군 VPN 자격증명 추출 완료
    │
    │  GOV20190847 / 20190847890312
    │  vpn.mnd.valdoria.mil (192.168.92.222)
    │
    ▼
[★ D2 VPN 게이트웨이 (192.168.92.222)] ← STEP 4-1: VPN 로그인
    │
    │  인증 성공 → 클라이언트 IP: 192.168.92.200~200 중 할당
    │  라우팅: 192.168.92.0/24만 허용
    │
    ├──▶ [패치관리서버 (192.168.92.229)] ← STEP 4-2: 공급망 공격
    │       │
    │       ▼
    │    [군 업무용 PC (192.168.92.249~35)] ← 악성 패치 실행
    │
    └──▶ [D3 자료교환체계 (192.168.92.223)] ← STEP 4-3: 문서 탈취
            (VPN 터널과 별개로 동일 크리덴셜 활용)
```

### 1.4 전체 공격 체인 개요

```
[AI 어시스턴트 (192.168.92.207)] — STEP 2-7에서 군 VPN 자격증명 추출
    │
    │  GOV20190847 / 20190847890312
    │  vpn.mnd.valdoria.mil (192.168.92.222)
    │
    ▼
[OPNSense-3] — 논리적 단절 (공공기관 INT ↔ 군 DMZ, 직접 네트워크 경로 없음)
    │           크리덴셜 기반 우회만 가능
    │
    ▼
[D2 VPN 게이트웨이 (192.168.92.222)] ← STEP 4-1: 탈취된 크리덴셜로 VPN 로그인
    │
    │  VPN 인증 성공 → 192.168.92.200x IP 할당
    │  라우팅: 192.168.92.0/24 (패치관리 서브넷)만 허용
    │
    ├──→ [D1 외부 포털 (192.168.92.221)] ← STEP 4 배경: Spring4Shell (CVE-2022-22965)
    │
    ├──→ [D3 자료교환 (192.168.92.223)] ← STEP 4-3: 동일 크리덴셜로 Nextcloud 문서 탈취
    │
    ├──→ [D4 허니팟 SSH (192.168.92.224)] ← 공격자 행위 기록 (함정)
    │
    └──→ [D5 허니팟 Web (192.168.92.225)] ← 공격자 행위 기록 (함정)
    │
    ▼
[OPNSense-6] → 192.168.92.0/24 (패치관리서버) → STEP 4-2: 공급망 공격
              → 192.168.92.0/24 (군 INT) — VPN에서 직접 접근 차단
```

---

## 2. 기술 스택

### 2.1 기반 인프라

| 구성요소 | 버전/사양 | 용도 |
|----------|-----------|------|
| Ubuntu | 22.04 LTS | 호스트 운영체제 |
| OpenVPN Access Server | 2.13.x | 상용 VPN 서버 (무료 라이선스 2 동시접속) |
| iptables/nftables | 기본 설치 | 방화벽 및 NAT |
| SQLite | 3.x | OpenVPN AS 내부 데이터베이스 |

### 2.2 네트워크 인터페이스

| 인터페이스 | IP | 용도 |
|------------|-----|------|
| ens192 | 192.168.92.222/24 | DMZ 인터페이스 (VPN 리스닝) |
| tun0 | 192.168.92.200/24 | VPN 터널 인터페이스 |

---

## 3. OpenVPN Access Server 구성

### 3.1 서버 핵심 설정

```bash
# OpenVPN AS sacli 명령으로 설정 조회/변경
# 설정 파일 위치: /usr/local/openvpn_as/etc/config.json

# VPN 데몬 설정
/usr/local/openvpn_as/scripts/sacli ConfigPut "vpn.daemon.0.listen.0.0" "192.168.92.222"
/usr/local/openvpn_as/scripts/sacli ConfigPut "vpn.daemon.0.listen.0.1" "1194"    # UDP
/usr/local/openvpn_as/scripts/sacli ConfigPut "vpn.daemon.0.listen.0.2" "udp"

# TCP 폴백 (방화벽 우회용)
/usr/local/openvpn_as/scripts/sacli ConfigPut "vpn.daemon.0.listen.1.0" "192.168.92.222"
/usr/local/openvpn_as/scripts/sacli ConfigPut "vpn.daemon.0.listen.1.1" "443"     # TCP
/usr/local/openvpn_as/scripts/sacli ConfigPut "vpn.daemon.0.listen.1.2" "tcp"

# 클라이언트 IP 풀
/usr/local/openvpn_as/scripts/sacli ConfigPut "vpn.server.dhcp_option.address.1" "192.168.92.200"
/usr/local/openvpn_as/scripts/sacli ConfigPut "vpn.server.dhcp_option.netmask.1" "255.255.255.0"
/usr/local/openvpn_as/scripts/sacli ConfigPut "vpn.server.dhcp_option.pool.start" "192.168.92.200"
/usr/local/openvpn_as/scripts/sacli ConfigPut "vpn.server.dhcp_option.pool.end" "192.168.92.200"

# 인증 방식: 로컬 사용자 데이터베이스 (LDAP/AD 미연동 — 단순화)
/usr/local/openvpn_as/scripts/sacli ConfigPut "auth.module.type" "local"

# MFA 미설정 (의도적 취약점)
# MFA 관련 설정 없음 — TOTP, RADIUS 등 미연동

# 세션 타임아웃: 24시간 (과도하게 길게 설정)
/usr/local/openvpn_as/scripts/sacli ConfigPut "vpn.server.session_timeout" "86400"

# 계정 잠금 미설정 (의도적 취약점)
# vpn.server.lockout_policy 미설정 → 무제한 시도 가능

# 라우팅 설정: 패치관리 서브넷만 허용
/usr/local/openvpn_as/scripts/sacli ConfigPut "vpn.server.routing.private_network.0" "192.168.92.0/24"
# 군 INT (192.168.92.0/24) 라우팅은 의도적으로 미설정

# 설정 적용
/usr/local/openvpn_as/scripts/sacli start
```

### 3.2 상세 서버 설정 (config.json 핵심 발췌)

```json
{
  "Default": {
    "vpn.daemon.0.listen.0.0": "192.168.92.222",
    "vpn.daemon.0.listen.0.1": "1194",
    "vpn.daemon.0.listen.0.2": "udp",
    "vpn.daemon.0.listen.1.0": "192.168.92.222",
    "vpn.daemon.0.listen.1.1": "443",
    "vpn.daemon.0.listen.1.2": "tcp",
    "vpn.server.dhcp_option.dns.0": "192.168.92.230",
    "vpn.server.routing.private_network.0": "192.168.92.0/24",
    "vpn.server.session_timeout": "86400",
    "auth.module.type": "local",
    "cs.tls_version_min": "1.2",
    "cs.tls_version_min_strict": "false",
    "vpn.client.config_text": "",
    "vpn.server.port_share.enable": "true",
    "vpn.server.port_share.service": "admin+client",
    "host.name": "vpn.mnd.valdoria.mil"
  }
}
```

### 3.3 사용자 계정 구성

| 사용자 ID | 비밀번호 | 소속 | 용도 | 비고 |
|-----------|----------|------|------|------|
| **GOV20190847** | **20190847890312** | 행정안전부 협력 | 공공기관-군 연계 업무 | **공격자 탈취 계정** |
| MIL_ADMIN01 | Mil@Adm!n2024 | 국방정보화기획관 | VPN 관리자 | 정상 계정 |
| MIL_USER01 | SecurePass!01 | 사이버작전사 | 원격 근무 | 정상 계정 |
| MIL_USER02 | SecurePass!02 | 합참 J6 | 원격 근무 | 정상 계정 |
| MIL_USER03 | SecurePass!03 | 방사청 SW사업팀 | 사업 관리 | 정상 계정 |
| MIL_USER04 | MilPatch@2024 | 정보체계관리단 | 패치 관리 | 정상 계정 |
| MIL_USER05 | DefNet!Sec05 | 국방망관리소 | 망 관리 | 정상 계정 |
| CONTRACTOR01 | Cont@ct2024! | 외부 유지보수업체 | 시스템 유지보수 | 정상 계정 |
| MIL_USER06 | MilUser#06! | 합참 정보본부 | 정보 분석 | 정상 계정 |
| MIL_USER07 | PatrolDef!07 | 군사안보지원사 | 보안 점검 | 정상 계정 |

```bash
# 사용자 계정 생성 명령
/usr/local/openvpn_as/scripts/sacli --user "GOV20190847" --new_pass "20190847890312" SetLocalPassword
/usr/local/openvpn_as/scripts/sacli --user "GOV20190847" --key "type" --value "user_connect" UserPropPut

/usr/local/openvpn_as/scripts/sacli --user "MIL_ADMIN01" --new_pass "Mil@Adm!n2024" SetLocalPassword
/usr/local/openvpn_as/scripts/sacli --user "MIL_ADMIN01" --key "type" --value "user_connect" UserPropPut
/usr/local/openvpn_as/scripts/sacli --user "MIL_ADMIN01" --key "prop_superuser" --value "true" UserPropPut

/usr/local/openvpn_as/scripts/sacli --user "MIL_USER01" --new_pass "SecurePass!01" SetLocalPassword
/usr/local/openvpn_as/scripts/sacli --user "MIL_USER01" --key "type" --value "user_connect" UserPropPut

/usr/local/openvpn_as/scripts/sacli --user "MIL_USER02" --new_pass "SecurePass!02" SetLocalPassword
/usr/local/openvpn_as/scripts/sacli --user "MIL_USER02" --key "type" --value "user_connect" UserPropPut

/usr/local/openvpn_as/scripts/sacli --user "MIL_USER03" --new_pass "SecurePass!03" SetLocalPassword
/usr/local/openvpn_as/scripts/sacli --user "MIL_USER03" --key "type" --value "user_connect" UserPropPut

/usr/local/openvpn_as/scripts/sacli --user "MIL_USER04" --new_pass "MilPatch@2024" SetLocalPassword
/usr/local/openvpn_as/scripts/sacli --user "MIL_USER04" --key "type" --value "user_connect" UserPropPut

/usr/local/openvpn_as/scripts/sacli --user "MIL_USER05" --new_pass "DefNet!Sec05" SetLocalPassword
/usr/local/openvpn_as/scripts/sacli --user "MIL_USER05" --key "type" --value "user_connect" UserPropPut

/usr/local/openvpn_as/scripts/sacli --user "CONTRACTOR01" --new_pass "Cont@ct2024!" SetLocalPassword
/usr/local/openvpn_as/scripts/sacli --user "CONTRACTOR01" --key "type" --value "user_connect" UserPropPut

/usr/local/openvpn_as/scripts/sacli --user "MIL_USER06" --new_pass "MilUser#06!" SetLocalPassword
/usr/local/openvpn_as/scripts/sacli --user "MIL_USER06" --key "type" --value "user_connect" UserPropPut

/usr/local/openvpn_as/scripts/sacli --user "MIL_USER07" --new_pass "PatrolDef!07" SetLocalPassword
/usr/local/openvpn_as/scripts/sacli --user "MIL_USER07" --key "type" --value "user_connect" UserPropPut
```

### 3.4 클라이언트 프로파일 (.ovpn)

VPN 로그인 후 자동 다운로드되는 클라이언트 설정:

```
# OpenVPN Access Server 자동 생성 프로파일
client
dev tun
proto udp
remote vpn.mnd.valdoria.mil 1194
resolv-retry infinite
nobind
persist-key
persist-tun
remote-cert-tls server
cipher AES-256-GCM
auth SHA256
verb 3
auth-user-pass
<ca>
-----BEGIN CERTIFICATE-----
(서버 CA 인증서 — 설치 시 자동 생성)
-----END CERTIFICATE-----
</ca>
```

### 3.5 Post-Auth 라우팅 제한

**핵심 설계 포인트**: VPN 인증 성공 후 클라이언트는 **192.168.92.0/24 (패치관리 서브넷)에만** 접근할 수 있다. 군 INT(192.168.92.0/24)로의 직접 접근은 차단된다.

```bash
# iptables 규칙 (VPN 서버에서)
# VPN 터널(tun0) → 패치관리 서브넷만 허용
iptables -A FORWARD -i tun0 -d 192.168.92.0/24 -j ACCEPT
iptables -A FORWARD -i tun0 -d 192.168.92.0/24 -j DROP    # 군 INT 직접 차단
iptables -A FORWARD -i tun0 -d 192.168.92.0/24 -j DROP    # C4I 직접 차단
iptables -A FORWARD -i tun0 -j DROP                          # 그 외 전부 차단

# NAT (VPN 클라이언트 → 패치관리 서브넷)
iptables -t nat -A POSTROUTING -s 192.168.92.0/24 -d 192.168.92.0/24 -o ens192 -j MASQUERADE

# 라우팅 확인 (클라이언트 측)
# VPN 접속 후:
# $ ip route
# 192.168.92.0/24 dev tun0 scope link
# 192.168.92.0/24 via 192.168.92.200 dev tun0
```

### 3.6 OPNSense-6 방화벽 규칙 (VPN 트래픽)

| # | 방향 | 출발지 | 목적지 | 포트 | 프로토콜 | 동작 | 비고 |
|---|------|--------|--------|------|----------|------|------|
| 1 | IN | 192.168.92.0/24 | 192.168.92.229 | 80, 8080 | TCP | ALLOW | VPN→패치관리서버 |
| 2 | IN | 192.168.92.0/24 | 192.168.92.0/24 | ANY | ANY | **DENY** | VPN→군INT 직접 차단 |
| 3 | IN | 192.168.92.0/24 | 192.168.92.0/24 | ANY | ANY | **DENY** | VPN→C4I 직접 차단 |
| 4 | IN | 192.168.92.0/24 | ANY | ANY | ANY | **DENY** | 기본 차단 |
| 5 | IN | 192.168.92.0/24 | 192.168.92.0/24 | 특정 포트 | TCP | ALLOW | DMZ→INT 서비스 |

---

## 4. 공격 시나리오 상세 (STEP 4-1)

### 4.1 VPN 로그인

```bash
# 공격자 측 (공공기관 INT에서 실행 또는 외부에서)

# 1. OpenVPN 클라이언트 설정 파일 생성
cat > mil-vpn.ovpn <<'EOF'
client
dev tun
proto udp
remote vpn.mnd.valdoria.mil 1194
resolv-retry infinite
nobind
persist-key
persist-tun
remote-cert-tls server
cipher AES-256-GCM
auth SHA256
verb 3
auth-user-pass
<ca>
-----BEGIN CERTIFICATE-----
(사전에 VPN 웹 포털에서 다운로드)
-----END CERTIFICATE-----
</ca>
EOF

# 2. VPN 접속 (탈취된 크리덴셜 사용)
openvpn --config mil-vpn.ovpn \
  --auth-user-pass <(printf "GOV20190847\n20190847890312\n")

# 3. 접속 확인
ip addr show tun0
# 예상: inet 192.168.92.200xxx/24

ip route | grep 192.168.120
# 예상: 192.168.92.0/24 via 192.168.92.200 dev tun0

# 4. 패치관리서버 접근 확인
curl -s http://192.168.92.229/
# 예상: 패치관리서버 웹 페이지 응답

# 5. 군 INT 직접 접근 시도 (실패 예상)
curl -s --connect-timeout 3 http://192.168.92.226/
# 예상: timeout (라우팅 차단)
```

---

## 5. 설치 및 구성 절차

### 5.1 Ubuntu 22.04 기본 설정

```bash
# 호스트명 설정
hostnamectl set-hostname mil-vpn-gw

# 네트워크 설정
cat > /etc/netplan/01-netcfg.yaml <<'EOF'
network:
  version: 2
  renderer: networkd
  ethernets:
    ens192:
      addresses:
        - 192.168.92.222/24
      routes:
        - to: default
          via: 192.168.92.1
      nameservers:
        addresses:
          - 192.168.1.20
EOF
netplan apply

# IP 포워딩 활성화
echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
sysctl -p
```

### 5.2 OpenVPN Access Server 설치

```bash
# 리포지터리 추가
apt-get update && apt-get -y install ca-certificates wget net-tools gnupg

wget https://as-repository.openvpn.net/as-repo-public.asc -qO /etc/apt/trusted.gpg.d/as-repository.asc
echo "deb [arch=amd64 signed-by=/etc/apt/trusted.gpg.d/as-repository.asc] http://as-repository.openvpn.net/as/debian jammy main" \
  > /etc/apt/sources.list.d/openvpn-as-repo.list

apt-get update && apt-get -y install openvpn-as

# 초기 설정 (설치 시 자동 실행됨)
# Admin URL: https://192.168.92.222:943/admin
# Client URL: https://192.168.92.222:943/

# 관리자 비밀번호 설정
/usr/local/openvpn_as/scripts/sacli --user "openvpn" --new_pass "VPN@dmin2024!" SetLocalPassword
```

### 5.3 사용자 계정 일괄 생성 스크립트

```bash
#!/bin/bash
# create_vpn_users.sh — 군 VPN 사용자 일괄 생성

SACLI="/usr/local/openvpn_as/scripts/sacli"

declare -A USERS=(
    ["GOV20190847"]="20190847890312"
    ["MIL_ADMIN01"]="Mil@Adm!n2024"
    ["MIL_USER01"]="SecurePass!01"
    ["MIL_USER02"]="SecurePass!02"
    ["MIL_USER03"]="SecurePass!03"
    ["MIL_USER04"]="MilPatch@2024"
    ["MIL_USER05"]="DefNet!Sec05"
    ["CONTRACTOR01"]="Cont@ct2024!"
    ["MIL_USER06"]="MilUser#06!"
    ["MIL_USER07"]="PatrolDef!07"
)

for user in "${!USERS[@]}"; do
    echo "[+] Creating user: $user"
    $SACLI --user "$user" --new_pass "${USERS[$user]}" SetLocalPassword
    $SACLI --user "$user" --key "type" --value "user_connect" UserPropPut
done

# MIL_ADMIN01에 관리자 권한 부여
$SACLI --user "MIL_ADMIN01" --key "prop_superuser" --value "true" UserPropPut

# 서비스 재시작
$SACLI start

echo "[+] All VPN users created successfully"
```

### 5.4 방화벽/라우팅 설정

```bash
# iptables 규칙 설정 스크립트
cat > /etc/iptables-vpn.sh <<'EOFW'
#!/bin/bash
# VPN Post-Auth 라우팅 제한

# 기본 정책
iptables -P FORWARD DROP

# VPN → 패치관리 서브넷만 허용
iptables -A FORWARD -i tun0 -d 192.168.92.0/24 -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT
iptables -A FORWARD -o tun0 -s 192.168.92.0/24 -m state --state ESTABLISHED,RELATED -j ACCEPT

# VPN → 군 INT, C4I 명시적 차단
iptables -A FORWARD -i tun0 -d 192.168.92.0/24 -j DROP
iptables -A FORWARD -i tun0 -d 192.168.92.0/24 -j DROP

# NAT 설정
iptables -t nat -A POSTROUTING -s 192.168.92.0/24 -d 192.168.92.0/24 -j MASQUERADE

# 로깅 (차단된 트래픽)
iptables -A FORWARD -i tun0 -j LOG --log-prefix "VPN-BLOCKED: " --log-level 4
iptables -A FORWARD -i tun0 -j DROP
EOFW

chmod +x /etc/iptables-vpn.sh
/etc/iptables-vpn.sh

# 부팅 시 자동 적용
apt-get install -y iptables-persistent
netfilter-persistent save
```

---

## 6. 탐지 포인트

### 6.1 VPN 인증 로그 분석

| 탐지 항목 | 탐지 방법 | 설명 |
|-----------|-----------|------|
| 최초 로그인 | `GOV20190847` 계정 첫 접속 | 이전에 접속 이력이 없는 계정 |
| 비업무 시간 접속 | 야간/주말 VPN 로그인 | 정상 근무시간 외 접속 |
| 출발지 IP 이상 | 공공기관 INT 대역에서 VPN 접속 | 일반적이지 않은 출발지 |
| 다중 세션 | 동시 접속 시도 | 같은 계정 중복 사용 |
| 접속 직후 스캔 | VPN 연결 후 즉시 네트워크 스캔 | 정상 사용자와 다른 패턴 |

### 6.2 로그 위치

| 로그 | 경로 | 내용 |
|------|------|------|
| OpenVPN AS 로그 | `/var/log/openvpnas.log` | VPN 인증/연결 이벤트 |
| 사용자 접속 로그 | `/usr/local/openvpn_as/etc/db/log.db` | SQLite — 접속 이력 |
| iptables 로그 | `/var/log/kern.log` (`VPN-BLOCKED:` 프리픽스) | 차단된 라우팅 시도 |
| syslog | `/var/log/syslog` | 시스템 전반 이벤트 |

### 6.3 핵심 탐지 로그 예시

```
# VPN 로그인 성공 (공격자)
2026-03-27 02:34:17 [OVPN] user 'GOV20190847' authenticated -- session started
2026-03-27 02:34:17 [OVPN] GOV20190847/192.168.92.200xxx: Assigned IP 192.168.92.200

# 비업무 시간 접속 (새벽 2시)
# 이전에 GOV20190847 접속 이력 없음 → 최초 로그인 알림 필요

# VPN 접속 직후 패치관리 서브넷 스캔
2026-03-27 02:35:01 [iptables] VPN-ALLOWED: IN=tun0 SRC=192.168.92.200 DST=192.168.92.229
2026-03-27 02:35:02 [iptables] VPN-BLOCKED: IN=tun0 SRC=192.168.92.200 DST=192.168.92.226
```

### 6.4 블루팀 탐지 요약

| 탐지 이벤트 | 심각도 | MITRE ATT&CK |
|-------------|--------|--------------|
| GOV20190847 최초 VPN 로그인 | High | T1078 (Valid Accounts) |
| 비업무 시간(02:00-06:00) VPN 접속 | High | T1078 |
| VPN 접속 후 192.168.92.0/24 접근 시도(차단) | Medium | T1046 (Network Service Discovery) |

---

## 7. 네트워크 및 방화벽 설정

### 7.1 IP 및 포트 매핑

| 자산 | IP | 포트 | 프로토콜 | 비고 |
|------|-----|------|----------|------|
| OPNSense-3/6 (GW) | 192.168.92.1 | - | - | DMZ 게이트웨이 |
| D1 외부 포털 | 192.168.92.221 | 80, 443, 8080 | TCP | Nginx + Tomcat |
| D2 VPN 게이트웨이 | 192.168.92.222 | 1194(UDP), 443(TCP) | UDP/TCP | OpenVPN AS |
| D2 VPN 관리 | 192.168.92.222 | 943 | TCP | OpenVPN AS Admin UI |
| D3 자료교환 | 192.168.92.223 | 80, 443 | TCP | Nextcloud |
| D4 허니팟 SSH | 192.168.92.224 | 22 | TCP | Cowrie |
| D5 허니팟 Web | 192.168.92.225 | 80, 443 | TCP | SNARE |

### 7.2 OPNSense-3 규칙 (공공기관 INT <-> 군 DMZ)

| # | 방향 | 출발지 | 목적지 | 동작 | 비고 |
|---|------|--------|--------|------|------|
| 1 | ANY | 192.168.92.0/24 | 192.168.92.0/24 | **DENY ALL** | 논리적 단절 |
| 2 | ANY | 192.168.92.0/24 | 192.168.92.0/24 | **DENY ALL** | 논리적 단절 |

> OPNSense-3은 네트워크 레벨에서 완전 차단되어 있다. 공격자는 오직 AI 어시스턴트에서 탈취한 크리덴셜을 통해 VPN으로 군 네트워크에 접근할 수 있다.

### 7.3 OPNSense-6 규칙 (군 DMZ <-> 군 INT + 패치관리)

| # | 방향 | 출발지 | 목적지 | 포트 | 동작 | 비고 |
|---|------|--------|--------|------|------|------|
| 1 | IN | 192.168.92.221 | 192.168.92.230 | 5432 | ALLOW | 포털→INT DB (필요시) |
| 2 | IN | 192.168.92.0/24 | 192.168.92.229 | 80, 8080 | ALLOW | VPN→패치관리 |
| 3 | IN | 192.168.92.0/24 | 192.168.92.0/24 | ANY | **DENY** | VPN→INT 차단 |
| 4 | IN | 192.168.92.0/24 | 192.168.92.0/24 | ANY | **DENY** | VPN→C4I 차단 |
| 5 | IN | 192.168.92.0/24 | 192.168.92.0/24 | 특정포트 | ALLOW | DMZ→INT 서비스 |
| 6 | DEFAULT | ANY | ANY | ANY | **DENY** | 기본 차단 |

---

## 8. DNS 레코드

| 도메인 | 타입 | 값 | 비고 |
|--------|------|-----|------|
| www.mnd.valdoria.mil | A | 192.168.92.221 | D1 외부 포털 |
| vpn.mnd.valdoria.mil | A | 192.168.92.222 | D2 VPN 게이트웨이 |
| share.mnd.valdoria.mil | A | 192.168.92.223 | D3 자료교환체계 |

---

## 9. 환경변수

```env
# ── D2 VPN 게이트웨이 (192.168.92.222) ───────────────────────
MIL_DOMAIN_EXT=mnd.valdoria.mil
VPN_HOST=192.168.92.222
VPN_PORT_UDP=1194
VPN_PORT_TCP=443
VPN_ADMIN_PORT=943
VPN_CLIENT_POOL=192.168.92.200-200
VPN_ROUTE_ALLOWED=192.168.92.0/24
```

---

## 10. vSphere 리소스 할당

| CPU | RAM | Disk | Port Group |
|-----|-----|------|------------|
| 2 vCPU | 2 GB | 20 GB | PG-MIL-DMZ (VLAN 110) |

---

## 11. 체크리스트: 구축 후 검증

| # | 검증 항목 | 명령/방법 | 예상 결과 |
|---|-----------|-----------|-----------|
| 1 | D2 VPN 웹 포털 | `curl https://vpn.mnd.valdoria.mil:943` | OpenVPN 로그인 페이지 |
| 2 | D2 VPN 로그인 | OpenVPN 클라이언트 + GOV20190847 | 192.168.92.200x 할당 |
| 3 | D2 패치관리 접근 | VPN 후 `curl http://192.168.92.229` | 200 OK |
| 4 | D2 군INT 차단 | VPN 후 `curl http://192.168.92.226` | Timeout |

---

## 12. 보안 주의사항

> 본 문서에 기술된 모든 취약점, 크리덴셜, 공격 기법은 **폐쇄형 사이버 전술훈련 환경 전용**이다.
> 외부 네트워크에서 사용하거나, 실제 운영 시스템에 적용하는 것은 **엄격히 금지**한다.

| 항목 | 제한 사항 |
|------|-----------|
| 네트워크 격리 | 훈련 환경은 vSphere 내부에서 완전 격리 운영 |
| 크리덴셜 관리 | 훈련 종료 후 모든 계정 비밀번호 즉시 변경 또는 삭제 |
| 문서 관리 | 본 문서는 훈련 기간 중에만 배포, 종료 후 회수 |
