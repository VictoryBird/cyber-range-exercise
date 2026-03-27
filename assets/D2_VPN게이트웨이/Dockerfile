# ============================================================
# D2 VPN 게이트웨이 — Docker 테스트용
# 사이버 훈련 전용 — 실제 운영 환경 사용 금지
# ============================================================
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    openvpn \
    openssl \
    iptables \
    net-tools \
    iproute2 \
    curl \
    && rm -rf /var/lib/apt/lists/*

# 디렉토리 생성
RUN mkdir -p /etc/openvpn/server/{certs,ccd,auth} \
    && mkdir -p /var/log/openvpn

# 설정 파일 복사
COPY conf/openvpn/server.conf /etc/openvpn/server/server.conf
COPY conf/openvpn/ccd/ /etc/openvpn/server/ccd/
COPY conf/openvpn/auth/users.txt /etc/openvpn/server/auth/users.txt
COPY conf/openvpn/auth/auth-script.sh /etc/openvpn/server/auth/auth-script.sh
COPY scripts/generate-certs.sh /opt/generate-certs.sh

RUN chmod +x /etc/openvpn/server/auth/auth-script.sh \
    && chmod +x /opt/generate-certs.sh \
    && chmod 600 /etc/openvpn/server/auth/users.txt

# IP 포워딩
RUN echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf

# 인증서 생성 및 서버 시작 엔트리포인트
COPY <<'EOF' /entrypoint.sh
#!/bin/bash
set -e

# 인증서가 없으면 생성
if [ ! -f /etc/openvpn/server/certs/ca.crt ]; then
    echo "[*] Generating certificates..."
    bash /opt/generate-certs.sh
fi

# tun 디바이스 확인
mkdir -p /dev/net
if [ ! -c /dev/net/tun ]; then
    mknod /dev/net/tun c 10 200
    chmod 600 /dev/net/tun
fi

echo "[*] Starting OpenVPN server..."
exec openvpn --config /etc/openvpn/server/server.conf
EOF
RUN chmod +x /entrypoint.sh

EXPOSE 1194/udp
EXPOSE 443/tcp

ENTRYPOINT ["/entrypoint.sh"]
