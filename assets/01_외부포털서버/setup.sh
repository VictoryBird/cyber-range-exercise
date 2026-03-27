#!/bin/bash
# ============================================================
# 외부 포털 서버 — 원클릭 배포 스크립트
# 대상 OS: Ubuntu 22.04 LTS
# IP: 203.238.140.10
# 도메인: www.mois.valdoria.gov
#
# 사용법: sudo bash setup.sh
#
# 이 스크립트는 다음을 수행합니다:
# 1. 시스템 패키지 설치 (Python, Nginx, Node.js)
# 2. 애플리케이션 사용자 생성
# 3. 백엔드 배포 (FastAPI + Uvicorn)
# 4. 프론트엔드 빌드 (React + Vite)
# 5. Nginx 설정
# 6. TLS 자체 서명 인증서 생성
# 7. systemd 서비스 등록
# 8. 방화벽 설정
#
# 주의: PostgreSQL DB는 별도 서버(192.168.100.20)에 구성해야 합니다.
#       DB 서버에서 sql/init.sql을 실행하세요.
# ============================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_DIR="/opt/mois-portal"
APP_USER="portaladm"
DOMAIN="www.mois.valdoria.gov"
IP="203.238.140.10"

echo "=========================================="
echo " 외부 포털 서버 배포 시작"
echo " IP: ${IP}"
echo " 도메인: ${DOMAIN}"
echo "=========================================="

# ===== [1] root 확인 =====
if [ "$EUID" -ne 0 ]; then
    echo "[ERROR] root 권한으로 실행하세요: sudo bash setup.sh"
    exit 1
fi

# ===== [2] 시스템 패키지 설치 =====
echo "[1/9] 시스템 패키지 설치 중..."
apt-get update -qq
apt-get install -y -qq python3 python3-pip python3-venv nginx curl wget \
    software-properties-common ufw ssl-cert

# Node.js 20 LTS 설치 (프론트엔드 빌드용)
if ! command -v node &> /dev/null; then
    echo "[1/9] Node.js 20 LTS 설치 중..."
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
    apt-get install -y -qq nodejs
fi

# ===== [3] 애플리케이션 사용자 생성 =====
echo "[2/9] 애플리케이션 사용자 생성..."
if ! id "${APP_USER}" &>/dev/null; then
    useradd -r -m -d /home/${APP_USER} -s /bin/bash ${APP_USER}
    echo "${APP_USER}:Portal@dmin2026" | chpasswd
fi

# ===== [4] 애플리케이션 디렉토리 구성 =====
echo "[3/9] 애플리케이션 디렉토리 구성..."
mkdir -p ${APP_DIR}/{backend,frontend,logs}
mkdir -p /var/log/mois-portal

# 백엔드 복사
cp -r ${SCRIPT_DIR}/src/backend/* ${APP_DIR}/backend/
cp ${SCRIPT_DIR}/.env.example ${APP_DIR}/.env

# 프론트엔드 복사
cp -r ${SCRIPT_DIR}/src/frontend/* ${APP_DIR}/frontend/

# ===== [5] Python 가상환경 및 백엔드 설치 =====
echo "[4/9] Python 백엔드 설치 중..."
python3 -m venv ${APP_DIR}/venv
${APP_DIR}/venv/bin/pip install --quiet --upgrade pip
${APP_DIR}/venv/bin/pip install --quiet -r ${APP_DIR}/backend/requirements.txt
${APP_DIR}/venv/bin/python -c "import fastapi; import uvicorn; print('Dependencies OK')" || { echo "[ERROR] 의존성 설치 실패"; exit 1; }

# ===== [6] 프론트엔드 빌드 =====
echo "[5/9] 프론트엔드 빌드 중..."
cd ${APP_DIR}/frontend
npm install --silent 2>/dev/null
npm run build 2>/dev/null

# robots.txt 복사 (빌드 결과물에 포함)
if [ -f ${APP_DIR}/frontend/public/robots.txt ]; then
    cp ${APP_DIR}/frontend/public/robots.txt ${APP_DIR}/frontend/dist/robots.txt 2>/dev/null || true
fi

# ===== [7] TLS 자체 서명 인증서 생성 =====
echo "[6/9] TLS 인증서 생성 중..."
mkdir -p /etc/nginx/ssl
if [ ! -f /etc/nginx/ssl/mois-portal.crt ]; then
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /etc/nginx/ssl/mois-portal.key \
        -out /etc/nginx/ssl/mois-portal.crt \
        -subj "/C=VD/ST=Valdoria/L=Capital/O=MOIS/CN=${DOMAIN}" \
        2>/dev/null
fi

# ===== [8] Nginx 설정 =====
echo "[7/9] Nginx 설정 중..."
[ -f "${SCRIPT_DIR}/src/config/nginx/mois-portal.conf" ] || { echo "[ERROR] 파일 없음: src/config/nginx/mois-portal.conf"; exit 1; }
cp ${SCRIPT_DIR}/src/config/nginx/mois-portal.conf /etc/nginx/sites-available/mois-portal.conf
ln -sf /etc/nginx/sites-available/mois-portal.conf /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
nginx -t && systemctl restart nginx

# ===== [9] systemd 서비스 등록 =====
echo "[8/9] systemd 서비스 등록 중..."
cp ${SCRIPT_DIR}/src/config/systemd/mois-portal.service /etc/systemd/system/
systemctl daemon-reload
systemctl enable mois-portal
systemctl start mois-portal

# ===== Remote DB 연결 확인 =====
if ! timeout 5 bash -c "echo > /dev/tcp/192.168.100.20/5432" 2>/dev/null; then
    echo "[WARN] DB 서버(192.168.100.20:5432) 연결 불가 — 나중에 수동 확인 필요"
fi

# ===== [10] 방화벽 설정 =====
echo "[9/9] 방화벽 설정 중..."
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 8000/tcp   # [취약 설정] FastAPI 직접 접근 포트 개방
ufw allow 22/tcp
ufw --force enable

# ===== 권한 설정 =====
chown -R ${APP_USER}:${APP_USER} ${APP_DIR}
chown -R ${APP_USER}:${APP_USER} /var/log/mois-portal

# ===== 완료 =====
echo ""
echo "=========================================="
echo " 외부 포털 서버 배포 완료!"
echo "=========================================="
echo ""
echo " 웹사이트:  https://${DOMAIN}"
echo "            https://${IP}"
echo " API 직접:  http://${IP}:8000"
echo " Swagger:   http://${IP}:8000/docs"
echo ""
echo " [주의] DB 서버(192.168.100.20)에서 다음을 실행하세요:"
echo "   psql -U postgres -c \"CREATE USER portal_app WITH PASSWORD 'P0rtal#DB@2026!';\""
echo "   psql -U postgres -c \"CREATE DATABASE mois_portal OWNER portal_app;\""
echo "   psql -U portal_app -d mois_portal -f ${SCRIPT_DIR}/sql/init.sql"
echo ""
echo " 서비스 상태: systemctl status mois-portal"
echo " 로그 확인:   journalctl -u mois-portal -f"
echo "=========================================="
