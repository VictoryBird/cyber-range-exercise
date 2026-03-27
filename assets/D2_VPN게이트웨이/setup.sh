#!/bin/bash
# ============================================================
# D2 VPN 게이트웨이 — 원클릭 배포 스크립트
# 자산: vpn.mnd.valdoria.mil (211.57.64.11)
# OS: Ubuntu 22.04 LTS
# 사이버 훈련 전용 — 실제 운영 환경 사용 금지
# ============================================================
set -e

# ── root 권한 확인 ──
if [ "$EUID" -ne 0 ]; then
    echo "[ERROR] root 권한으로 실행하세요: sudo bash setup.sh"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TOTAL_STEPS=9

echo "============================================================"
echo " D2 VPN 게이트웨이 배포 시작"
echo " 호스트: vpn.mnd.valdoria.mil (211.57.64.11)"
echo "============================================================"

# ── [1/9] 호스트명 및 기본 패키지 ──
echo ""
echo "[1/${TOTAL_STEPS}] 호스트명 설정 및 기본 패키지 설치..."
hostnamectl set-hostname mil-vpn-gw

apt-get update -qq
apt-get install -y -qq openvpn easy-rsa openssl iptables-persistent \
    net-tools curl wget ca-certificates ufw > /dev/null 2>&1

echo "  -> 기본 패키지 설치 완료"

# ── [2/9] IP 포워딩 활성화 ──
echo ""
echo "[2/${TOTAL_STEPS}] IP 포워딩 활성화..."
if ! grep -q "^net.ipv4.ip_forward = 1" /etc/sysctl.conf; then
    echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
fi
sysctl -w net.ipv4.ip_forward=1 > /dev/null
echo "  -> IP 포워딩 활성화 완료"

# ── [3/9] 디렉토리 구조 생성 ──
echo ""
echo "[3/${TOTAL_STEPS}] OpenVPN 디렉토리 구조 생성..."
mkdir -p /etc/openvpn/server/{certs,ccd,auth}
mkdir -p /var/log/openvpn
echo "  -> 디렉토리 생성 완료"

# ── [4/9] 인증서 생성 ──
echo ""
echo "[4/${TOTAL_STEPS}] CA 및 서버 인증서 생성..."
chmod +x "${SCRIPT_DIR}/scripts/generate-certs.sh"
bash "${SCRIPT_DIR}/scripts/generate-certs.sh"
echo "  -> 인증서 생성 완료"

# ── [5/9] 설정 파일 배포 ──
echo ""
echo "[5/${TOTAL_STEPS}] OpenVPN 설정 파일 배포..."

# 서버 설정
cp "${SCRIPT_DIR}/conf/openvpn/server.conf" /etc/openvpn/server/server.conf

# 클라이언트별 설정
cp "${SCRIPT_DIR}/conf/openvpn/ccd/GOV20190847" /etc/openvpn/server/ccd/GOV20190847

# 인증 스크립트 및 사용자 DB
cp "${SCRIPT_DIR}/conf/openvpn/auth/users.txt" /etc/openvpn/server/auth/users.txt
cp "${SCRIPT_DIR}/conf/openvpn/auth/auth-script.sh" /etc/openvpn/server/auth/auth-script.sh
chmod +x /etc/openvpn/server/auth/auth-script.sh
chmod 600 /etc/openvpn/server/auth/users.txt

echo "  -> 설정 파일 배포 완료"

# ── [6/9] iptables 방화벽/라우팅 규칙 ──
echo ""
echo "[6/${TOTAL_STEPS}] iptables 방화벽 및 라우팅 규칙 설정..."

cat > /etc/openvpn/server/iptables-vpn.sh <<'EOFW'
#!/bin/bash
# VPN Post-Auth 라우팅 제한

# 기존 FORWARD 규칙 초기화
iptables -F FORWARD

# 기본 정책
iptables -P FORWARD DROP

# VPN -> 패치관리 서브넷만 허용
# [취약점] VULN-D2-04: 공격자가 이 경로로 패치관리서버(192.168.120.10)에 도달 가능
iptables -A FORWARD -i tun0 -d 192.168.120.0/24 -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT
iptables -A FORWARD -o tun0 -s 192.168.120.0/24 -m state --state ESTABLISHED,RELATED -j ACCEPT

# VPN -> 군 INT, C4I 명시적 차단
iptables -A FORWARD -i tun0 -d 192.168.110.0/24 -j DROP
iptables -A FORWARD -i tun0 -d 192.168.130.0/24 -j DROP

# NAT 설정 (VPN 클라이언트 -> 패치관리 서브넷)
iptables -t nat -C POSTROUTING -s 172.20.100.0/24 -d 192.168.120.0/24 -j MASQUERADE 2>/dev/null || \
    iptables -t nat -A POSTROUTING -s 172.20.100.0/24 -d 192.168.120.0/24 -j MASQUERADE

# 차단 트래픽 로깅
iptables -A FORWARD -i tun0 -j LOG --log-prefix "VPN-BLOCKED: " --log-level 4
iptables -A FORWARD -i tun0 -j DROP
EOFW
chmod +x /etc/openvpn/server/iptables-vpn.sh
bash /etc/openvpn/server/iptables-vpn.sh

# 영구 저장
netfilter-persistent save > /dev/null 2>&1 || true

echo "  -> iptables 규칙 설정 완료"

# ── [7/9] systemd 서비스 등록 ──
echo ""
echo "[7/${TOTAL_STEPS}] systemd 서비스 등록..."
cp "${SCRIPT_DIR}/conf/systemd/openvpn.service" /etc/systemd/system/openvpn-server.service
systemctl daemon-reload
systemctl enable openvpn-server.service
systemctl start openvpn-server.service

echo "  -> OpenVPN 서비스 시작 완료"

# ── [8/9] UFW 방화벽 설정 ──
echo ""
echo "[8/${TOTAL_STEPS}] UFW 방화벽 설정..."
ufw --force reset > /dev/null 2>&1
ufw default deny incoming
ufw default allow outgoing

# SSH
ufw allow 22/tcp comment "SSH"

# [취약점] VULN-D2-01: VPN 포트 — MFA 없이 패스워드만으로 접속 가능
ufw allow 1194/udp comment "OpenVPN UDP"
ufw allow 443/tcp comment "OpenVPN TCP fallback"

# 관리 포트 (내부 접근만 허용하는 것이 바람직하나 훈련용 개방)
ufw allow 943/tcp comment "OpenVPN Admin UI"

ufw --force enable > /dev/null 2>&1
echo "  -> UFW 방화벽 설정 완료"

# ── [9/9] 최종 검증 ──
echo ""
echo "[9/${TOTAL_STEPS}] 서비스 상태 확인..."
systemctl is-active openvpn-server.service && echo "  -> OpenVPN 서비스: 정상 동작" || echo "  -> [WARNING] OpenVPN 서비스 시작 실패 — 로그 확인 필요"

echo ""
echo "============================================================"
echo " D2 VPN 게이트웨이 배포 완료"
echo "============================================================"
echo ""
echo " VPN 접속 정보:"
echo "   - UDP: vpn.mnd.valdoria.mil:1194"
echo "   - TCP: vpn.mnd.valdoria.mil:443"
echo "   - Admin UI: https://211.57.64.11:943/admin"
echo ""
echo " VPN 라우팅:"
echo "   - 허용: 192.168.120.0/24 (패치관리 서브넷)"
echo "   - 차단: 192.168.110.0/24 (군 INT)"
echo "   - 차단: 192.168.130.0/24 (C4I)"
echo ""
echo " 의도적 취약점 (훈련용):"
echo "   - VULN-D2-01: MFA 미적용 (패스워드 단독 인증)"
echo "   - VULN-D2-02: 계정 잠금 미설정 (무제한 시도 가능)"
echo "   - VULN-D2-03: GOV20190847 초기 비밀번호 미변경"
echo "   - VULN-D2-04: VPN → 패치관리서버 접근 가능"
echo ""
echo " 로그 경로:"
echo "   - OpenVPN: /var/log/openvpn/openvpn.log"
echo "   - 인증: /var/log/openvpn/auth.log"
echo "   - iptables 차단: /var/log/kern.log (VPN-BLOCKED: prefix)"
echo "============================================================"
