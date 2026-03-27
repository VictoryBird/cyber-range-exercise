#!/bin/bash
# ============================================================
# D2 VPN 게이트웨이 — CA 및 서버 인증서 생성
# 사이버 훈련 전용 — 실제 운영 환경 사용 금지
# ============================================================
set -e

CERT_DIR="${VPN_CERT_DIR:-/etc/openvpn/server/certs}"
CA_CN="${VPN_CA_CN:-MND-VPN-CA}"
SERVER_CN="${VPN_SERVER_CN:-vpn.mnd.valdoria.mil}"
KEY_SIZE="${VPN_KEY_SIZE:-2048}"
CA_DAYS=3650
SERVER_DAYS=825

echo "============================================"
echo " D2 VPN 인증서 생성"
echo " CA CN: ${CA_CN}"
echo " Server CN: ${SERVER_CN}"
echo "============================================"

# 디렉토리 생성
mkdir -p "${CERT_DIR}"
cd "${CERT_DIR}"

# ── 1. CA 키 및 인증서 ──
echo "[1/5] CA 키 생성..."
openssl genrsa -out ca.key ${KEY_SIZE}

echo "[2/5] CA 인증서 생성..."
openssl req -new -x509 -days ${CA_DAYS} -key ca.key -out ca.crt \
    -subj "/C=VD/ST=Valdoria/L=Capital/O=MND/OU=CyberOps/CN=${CA_CN}"

# ── 2. 서버 키 및 인증서 ──
echo "[3/5] 서버 키 및 CSR 생성..."
openssl genrsa -out server.key ${KEY_SIZE}

openssl req -new -key server.key -out server.csr \
    -subj "/C=VD/ST=Valdoria/L=Capital/O=MND/OU=VPN/CN=${SERVER_CN}"

# 서버 확장 설정
cat > server-ext.cnf <<'EOF'
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
DNS.1 = vpn.mnd.valdoria.mil
IP.1 = 211.57.64.11
EOF

echo "[4/5] 서버 인증서 서명..."
openssl x509 -req -days ${SERVER_DAYS} -in server.csr -CA ca.crt -CAkey ca.key \
    -CAcreateserial -out server.crt -extfile server-ext.cnf

# ── 3. DH 파라미터 ──
echo "[5/5] DH 파라미터 생성 (시간이 걸릴 수 있습니다)..."
openssl dhparam -out dh2048.pem ${KEY_SIZE}

# ── 4. TLS-Auth 키 ──
openvpn --genkey secret ta.key 2>/dev/null || \
    openssl rand -out ta.key 256

# ── 정리 ──
rm -f server.csr server-ext.cnf ca.srl
chmod 600 ca.key server.key ta.key
chmod 644 ca.crt server.crt dh2048.pem

echo ""
echo "============================================"
echo " 인증서 생성 완료"
echo " 경로: ${CERT_DIR}"
echo "============================================"
ls -la "${CERT_DIR}"
