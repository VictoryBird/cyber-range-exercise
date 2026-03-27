#!/bin/bash
# ===================================================================
# 내부 업무 포털 (Internal Business Portal) 원클릭 배포 스크립트
# 대상: Ubuntu 22.04 LTS
# IP: 192.168.100.10
# 도메인: intranet.mois.local
# 용도: 사이버 훈련 환경 구축
# ===================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_DIR="/opt/intranet-portal"
STATIC_DIR="/var/www/intranet/static"
LOG_DIR="/var/log/intranet-portal"

echo "============================================"
echo " 내부 업무 포털 배포 시작"
echo " $(date '+%Y-%m-%d %H:%M:%S')"
echo "============================================"

# root 권한 확인
if [ "$EUID" -ne 0 ]; then
    echo "오류: root 권한이 필요합니다. sudo로 실행하세요."
    exit 1
fi

# [1/10] 시스템 패키지 설치
echo "[1/10] 시스템 패키지 설치..."
apt-get update -qq
apt-get install -y -qq \
    python3 python3-pip python3-venv \
    nginx \
    libldap2-dev libsasl2-dev \
    libpq-dev \
    curl

# [2/10] 애플리케이션 디렉토리 생성
echo "[2/10] 디렉토리 구조 생성..."
mkdir -p "$APP_DIR"
mkdir -p "$STATIC_DIR"
mkdir -p "$LOG_DIR"
chown www-data:www-data "$LOG_DIR"

# [3/10] 소스 코드 복사
echo "[3/10] 소스 코드 복사..."
cp -r "$SCRIPT_DIR/src/intranet_portal" "$APP_DIR/src/"
cp "$SCRIPT_DIR/src/requirements.txt" "$APP_DIR/src/"

# [4/10] 환경변수 설정
echo "[4/10] 환경변수 설정..."
if [ ! -f "$APP_DIR/.env" ]; then
    cp "$SCRIPT_DIR/.env.example" "$APP_DIR/.env"
    echo "  -> .env 파일이 생성되었습니다. 필요시 수정하세요: $APP_DIR/.env"
fi

# [5/10] Python 가상환경 및 의존성 설치
echo "[5/10] Python 가상환경 설정..."
python3 -m venv "$APP_DIR/venv"
source "$APP_DIR/venv/bin/activate"
pip install --quiet --upgrade pip
pip install --quiet -r "$APP_DIR/src/requirements.txt"
${APP_DIR}/venv/bin/python -c "import django; print('Dependencies OK')" || { echo "[ERROR] 의존성 설치 실패"; exit 1; }

# [6/10] Django 마이그레이션 및 초기화
echo "[6/10] Django 초기화..."
cd "$APP_DIR/src/intranet_portal"
export DJANGO_SETTINGS_MODULE=intranet_portal.settings
python manage.py migrate --noinput
python manage.py collectstatic --noinput --clear 2>/dev/null || true
python manage.py seed_data

# [7/10] Nginx 설정
echo "[7/10] Nginx 설정..."
[ -f "${SCRIPT_DIR}/conf/nginx/intranet.conf" ] || { echo "[ERROR] 파일 없음: conf/nginx/intranet.conf"; exit 1; }
cp "$SCRIPT_DIR/conf/nginx/intranet.conf" /etc/nginx/sites-available/
ln -sf /etc/nginx/sites-available/intranet.conf /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
nginx -t
systemctl restart nginx

# [8/10] systemd 서비스 등록
echo "[8/10] systemd 서비스 등록..."
[ -f "${SCRIPT_DIR}/conf/systemd/intranet-portal.service" ] || { echo "[ERROR] 파일 없음: conf/systemd/intranet-portal.service"; exit 1; }
cp "$SCRIPT_DIR/conf/systemd/intranet-portal.service" /etc/systemd/system/
systemctl daemon-reload
systemctl enable intranet-portal
systemctl start intranet-portal

# [9/10] 호스트 파일 설정
echo "[9/10] 호스트 파일 설정..."
if ! grep -q "intranet.mois.local" /etc/hosts; then
    echo "192.168.100.10  intranet.mois.local" >> /etc/hosts
    echo "192.168.100.11  mail.mois.local" >> /etc/hosts
    echo "192.168.100.20  db.mois.local" >> /etc/hosts
    echo "192.168.100.50  corp.mois.local dc01.corp.mois.local" >> /etc/hosts
fi

# [10/10] 방화벽 설정 및 서비스 확인
echo "[10/10] 방화벽 설정 및 서비스 확인..."
if command -v ufw &> /dev/null; then
    ufw allow 80/tcp    # HTTP
    ufw allow 8080/tcp  # HTTP (메인 포트)
    ufw allow 22/tcp    # SSH
    echo "  -> UFW 방화벽 규칙 추가 완료"
fi

# Remote DB 연결 확인
if ! timeout 5 bash -c "echo > /dev/tcp/192.168.100.20/5432" 2>/dev/null; then
    echo "[WARN] DB 서버(192.168.100.20:5432) 연결 불가 — 나중에 수동 확인 필요"
fi

sleep 3
systemctl status intranet-portal --no-pager || true
curl -s -o /dev/null -w "HTTP %{http_code}" http://localhost:8080/ && echo " - 포털 정상 응답" || echo " - 포털 응답 실패 (DB 연결 확인 필요)"

echo ""
echo "============================================"
echo " 배포 완료!"
echo "============================================"
echo ""
echo " 포털 URL: http://192.168.100.10:8080"
echo " (또는 http://intranet.mois.local:8080)"
echo ""
echo " 테스트 계정:"
echo "   - admin_park / @dminP@rk2026!  (관리자)"
echo "   - kimbs / KimB\$2026           (보안과장)"
echo "   - leecs / Lee(S2026            (일반)"
echo ""
echo " 로그 경로: $LOG_DIR/"
echo " 설정 파일: $APP_DIR/.env"
echo ""
echo " [주의사항]"
echo " - DB 서버(192.168.100.20)에 mois_intranet 데이터베이스가 필요합니다."
echo "   DB 서버가 별도인 경우 먼저 DB 서버를 구성하세요."
echo " - AD 서버(192.168.100.50)가 없으면 Django 로컬 인증으로 동작합니다."
echo "============================================"
