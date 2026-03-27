#!/bin/bash
# ============================================================
# 군 패치 관리 서버 원클릭 배포 스크립트
# 대상: 192.168.120.10 / update.mnd.local
# OS: Debian 12 (Bookworm)
# 실행: sudo bash setup.sh
# ============================================================

set -e

# --- Root 권한 확인 ---
if [ "$EUID" -ne 0 ]; then
  echo "[오류] root 권한으로 실행하세요: sudo bash setup.sh"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "${SCRIPT_DIR}"

# --- 환경변수 로드 ---
if [ -f .env ]; then
  source .env
elif [ -f .env.example ]; then
  echo "[안내] .env 파일이 없어 .env.example을 사용합니다."
  cp .env.example .env
  source .env
else
  echo "[오류] .env 또는 .env.example 파일이 필요합니다."
  exit 1
fi

TOTAL_STEPS=9

# ==========================================================
echo "[1/${TOTAL_STEPS}] 시스템 업데이트 및 기본 패키지 설치..."
# ==========================================================
apt-get update && apt-get upgrade -y
apt-get install -y curl wget nginx php8.2-fpm php8.2-json php8.2-mbstring

# ==========================================================
echo "[2/${TOTAL_STEPS}] 디렉토리 구조 생성..."
# ==========================================================
WEB_ROOT=/var/www/update-server
mkdir -p ${WEB_ROOT}/{updates,admin/assets,logs}

# ==========================================================
echo "[3/${TOTAL_STEPS}] PHP 관리 패널 배포..."
# ==========================================================
cp src/admin/*.php ${WEB_ROOT}/admin/
cp src/admin/assets/* ${WEB_ROOT}/admin/assets/

# ==========================================================
echo "[4/${TOTAL_STEPS}] manifest.json 및 시드 패치 파일 배치..."
# ==========================================================
cp src/updates/manifest.json ${WEB_ROOT}/updates/

# 시드 패치 파일 (플레이스홀더 -- 실제 파일 크기 시뮬레이션)
dd if=/dev/urandom of=${WEB_ROOT}/updates/SecurityPatch_KB2024001.exe bs=1024 count=2400 2>/dev/null
dd if=/dev/urandom of=${WEB_ROOT}/updates/OfficeUpdate_KB2024002.msi bs=1024 count=15360 2>/dev/null
dd if=/dev/urandom of=${WEB_ROOT}/updates/NetworkDriver_KB2024003.exe bs=1024 count=5120 2>/dev/null

echo "시드 패치 파일 3개 생성 완료"

# ==========================================================
echo "[5/${TOTAL_STEPS}] 로그 파일 초기화..."
# ==========================================================
touch ${WEB_ROOT}/logs/download.log

# ==========================================================
echo "[6/${TOTAL_STEPS}] 파일 권한 설정..."
# ==========================================================
chown -R www-data:www-data ${WEB_ROOT}
chmod -R 755 ${WEB_ROOT}
chmod 666 ${WEB_ROOT}/logs/download.log

# ==========================================================
echo "[7/${TOTAL_STEPS}] Nginx 설정..."
# ==========================================================
cp conf/nginx/update-server.conf /etc/nginx/sites-available/update-server
ln -sf /etc/nginx/sites-available/update-server /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
nginx -t && systemctl reload nginx

# ==========================================================
echo "[8/${TOTAL_STEPS}] PHP-FPM 설정..."
# ==========================================================
# upload_max_filesize 증가
sed -i 's/upload_max_filesize = .*/upload_max_filesize = 100M/' /etc/php/8.2/fpm/php.ini
sed -i 's/post_max_size = .*/post_max_size = 100M/' /etc/php/8.2/fpm/php.ini
systemctl restart php8.2-fpm

# ==========================================================
echo "[9/${TOTAL_STEPS}] UFW 방화벽 설정..."
# ==========================================================
ufw allow 22/tcp comment "SSH"
# [취약 설정] VULN-I9-04: HTTP만 허용 (HTTPS 미구성)
ufw allow 80/tcp comment "HTTP (패치 서버 + 관리 패널)"
ufw --force enable

echo ""
echo "============================================================"
echo " 패치 관리 서버 배포 완료"
echo "============================================================"
echo " 관리 패널:  http://update.mnd.local/admin/"
echo "             http://192.168.120.10/admin/"
echo " 업데이트:   http://192.168.120.10/updates/manifest.json"
echo ""
echo " [주의사항]"
echo "  - /etc/hosts 에 '192.168.120.10 update.mnd.local' 추가 필요"
echo "  - 관리자 인증: admin / admin123 (의도적 취약 -- 훈련용)"
echo "  - 패치 파일: /var/www/update-server/updates/"
echo "  - 활동 로그: /var/www/update-server/logs/download.log"
echo "============================================================"
