#!/bin/bash
# ============================================================
# 메일 포털 게이트 — 원클릭 배포 스크립트
# 대상 OS: Ubuntu 22.04 LTS
# IP: 203.238.140.11
# 도메인: webmail.mois.valdoria.gov
#
# 사용법: sudo bash setup.sh
#
# 취약점 내장:
#   VULN-02-01: 프록시 헤더 신뢰 (X-Forwarded-For 조작 가능)
#   VULN-02-02: 경로 정규화 우회 (merge_slashes off)
#   VULN-02-03: Host 헤더 라우팅 조작 (server_name _)
#   VULN-02-04: 내부 경로 무단 노출 (/internal/, /admin/)
#
# 주의: 백엔드 웹메일 서버(192.168.100.11)가 먼저 구축되어야 합니다.
# ============================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
IP="203.238.140.11"
DOMAIN="webmail.mois.valdoria.gov"
HOSTNAME="mail-gateway"

echo "=========================================="
echo " 메일 포털 게이트 배포 시작"
echo " IP: ${IP}"
echo " 도메인: ${DOMAIN}"
echo "=========================================="

# ===== [1] root 확인 =====
if [ "$EUID" -ne 0 ]; then
    echo "[ERROR] root 권한으로 실행하세요: sudo bash setup.sh"
    exit 1
fi

# ===== [2] 호스트명 설정 =====
echo "[1/5] 호스트명 설정..."
hostnamectl set-hostname ${HOSTNAME}

# ===== [3] Nginx 설치 =====
echo "[2/5] Nginx 설치 중..."
apt-get update -qq
apt-get install -y -qq nginx openssl ufw

# ===== [4] Nginx 설정 배포 =====
echo "[3/5] Nginx 설정 배포..."

# 메인 설정
[ -f "${SCRIPT_DIR}/conf/nginx/nginx.conf" ] || { echo "[ERROR] 파일 없음: conf/nginx/nginx.conf"; exit 1; }
cp ${SCRIPT_DIR}/conf/nginx/nginx.conf /etc/nginx/nginx.conf

# 스니펫
mkdir -p /etc/nginx/snippets
[ -f "${SCRIPT_DIR}/conf/nginx/snippets/ssl-params.conf" ] || { echo "[ERROR] 파일 없음: conf/nginx/snippets/ssl-params.conf"; exit 1; }
cp ${SCRIPT_DIR}/conf/nginx/snippets/ssl-params.conf /etc/nginx/snippets/
[ -f "${SCRIPT_DIR}/conf/nginx/snippets/proxy-params.conf" ] || { echo "[ERROR] 파일 없음: conf/nginx/snippets/proxy-params.conf"; exit 1; }
cp ${SCRIPT_DIR}/conf/nginx/snippets/proxy-params.conf /etc/nginx/snippets/

# 사이트 설정
[ -f "${SCRIPT_DIR}/conf/nginx/sites-available/webmail.conf" ] || { echo "[ERROR] 파일 없음: conf/nginx/sites-available/webmail.conf"; exit 1; }
cp ${SCRIPT_DIR}/conf/nginx/sites-available/webmail.conf /etc/nginx/sites-available/
ln -sf /etc/nginx/sites-available/webmail.conf /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# TLS 자체 서명 인증서 생성
echo "[4/5] TLS 인증서 생성..."
mkdir -p /etc/nginx/ssl
if [ ! -f /etc/nginx/ssl/webmail.crt ]; then
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /etc/nginx/ssl/webmail.key \
        -out /etc/nginx/ssl/webmail.crt \
        -subj "/C=VD/ST=Valdoria/L=Capital/O=MOIS/CN=${DOMAIN}" \
        2>/dev/null
fi

# 설정 검증 및 재시작
nginx -t && systemctl restart nginx
systemctl enable nginx

# ===== [5] 방화벽 설정 =====
echo "[5/5] 방화벽 설정..."
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 22/tcp
ufw --force enable

# ===== 완료 =====
echo ""
echo "=========================================="
echo " 메일 포털 게이트 배포 완료!"
echo "=========================================="
echo ""
echo " HTTPS:  https://${DOMAIN}"
echo " HTTP:   http://${DOMAIN} (→ HTTPS 리다이렉트)"
echo ""
echo " 백엔드: http://192.168.100.11:8080 (Roundcube)"
echo ""
echo " [주의] 백엔드 웹메일 서버(자산 05)가 먼저 구축되어야 합니다."
echo ""
echo " 취약점 테스트:"
echo "   curl -k -H 'X-Forwarded-For: 127.0.0.1' https://${IP}/"
echo "   curl -k 'https://${IP}/..%2Finternal/'"
echo "   curl -k -H 'Host: mail.mois.local' https://${IP}/"
echo "   curl -k https://${IP}/admin/"
echo ""
echo " 로그: /var/log/nginx/webmail_access.log"
echo "=========================================="
