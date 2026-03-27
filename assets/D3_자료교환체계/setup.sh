#!/bin/bash
# ============================================================
# D3 자료교환체계 — Nextcloud 원클릭 배포 스크립트 (네이티브)
# 대상: 211.57.64.12 (share.mnd.valdoria.mil)
# OS: Ubuntu 22.04 LTS
# ============================================================
set -e

# ── root 권한 확인 ──
if [ "$EUID" -ne 0 ]; then
    echo "[오류] root 권한으로 실행하세요: sudo $0"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# .env 로드
if [ -f "${SCRIPT_DIR}/.env" ]; then
    source "${SCRIPT_DIR}/.env"
elif [ -f "${SCRIPT_DIR}/.env.example" ]; then
    cp "${SCRIPT_DIR}/.env.example" "${SCRIPT_DIR}/.env"
    source "${SCRIPT_DIR}/.env"
fi

# 기본값 설정
NC_DOMAIN="${NEXTCLOUD_DOMAIN:-share.mnd.valdoria.mil}"
NC_ADMIN="${NEXTCLOUD_ADMIN_USER:-admin}"
NC_ADMIN_PASS="${NEXTCLOUD_ADMIN_PASSWORD:-NCadmin@2024!}"
NC_TRUSTED="${NEXTCLOUD_TRUSTED_DOMAINS:-share.mnd.valdoria.mil 211.57.64.12}"
DB_ROOT_PASS="${MYSQL_ROOT_PASSWORD:-MariaRoot@2024!}"
DB_NAME="${MYSQL_DATABASE:-nextcloud}"
DB_USER="${MYSQL_USER:-nextcloud}"
DB_PASS="${MYSQL_PASSWORD:-NC@DB2024!}"
NC_VERSION="27.1.11"
NC_INSTALL_DIR="/var/www/nextcloud"

echo "========================================="
echo " D3 자료교환체계 (Nextcloud) 배포 시작"
echo " IP: 211.57.64.12"
echo " 도메인: ${NC_DOMAIN}"
echo "========================================="
echo ""

# ──────────────────────────────────────────────
echo "[1/8] 호스트명 설정..."
hostnamectl set-hostname mil-share

# ──────────────────────────────────────────────
echo "[2/8] 시스템 패키지 설치..."
apt-get update
apt-get install -y \
    apache2 libapache2-mod-php \
    php php-gd php-mysql php-curl php-mbstring php-intl \
    php-gmp php-bcmath php-xml php-zip php-imagick \
    php-apcu php-redis php-ldap php-bz2 \
    mariadb-server redis-server \
    unzip curl wget sudo

# PHP 메모리 설정
PHP_INI=$(php -i 2>/dev/null | grep "Loaded Configuration File" | awk '{print $NF}')
if [ -n "$PHP_INI" ] && [ -f "$PHP_INI" ]; then
    sed -i 's/^memory_limit = .*/memory_limit = 512M/' "$PHP_INI"
    sed -i 's/^upload_max_filesize = .*/upload_max_filesize = 512M/' "$PHP_INI"
    sed -i 's/^post_max_size = .*/post_max_size = 512M/' "$PHP_INI"
fi

# ──────────────────────────────────────────────
echo "[3/8] MariaDB 설정..."
systemctl enable mariadb
systemctl start mariadb

mysql -u root <<DBSETUP
CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';
GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO '${DB_USER}'@'localhost';
FLUSH PRIVILEGES;
DBSETUP

echo "  MariaDB 데이터베이스 생성 완료"

# ──────────────────────────────────────────────
echo "[4/8] Redis 설정..."
systemctl enable redis-server
systemctl start redis-server

# ──────────────────────────────────────────────
echo "[5/8] Nextcloud ${NC_VERSION} 설치..."
if [ ! -d "${NC_INSTALL_DIR}" ]; then
    cd /tmp
    if [ ! -f "nextcloud-${NC_VERSION}.zip" ]; then
        wget -q "https://download.nextcloud.com/server/releases/nextcloud-${NC_VERSION}.zip"
    fi
    unzip -q "nextcloud-${NC_VERSION}.zip" -d /var/www/
    chown -R www-data:www-data "${NC_INSTALL_DIR}"
    echo "  Nextcloud 파일 설치 완료"
else
    echo "  Nextcloud 디렉토리 이미 존재 — 건너뜀"
fi

# 데이터 디렉토리 생성
mkdir -p "${NC_INSTALL_DIR}/data"
chown -R www-data:www-data "${NC_INSTALL_DIR}/data"

# Nextcloud CLI 설치
echo "  Nextcloud 초기 설정 실행 중..."
sudo -u www-data php "${NC_INSTALL_DIR}/occ" maintenance:install \
    --database "mysql" \
    --database-name "${DB_NAME}" \
    --database-host "localhost" \
    --database-user "${DB_USER}" \
    --database-pass "${DB_PASS}" \
    --admin-user "${NC_ADMIN}" \
    --admin-pass "${NC_ADMIN_PASS}" \
    --data-dir "${NC_INSTALL_DIR}/data" \
    2>/dev/null || echo "  (이미 설치되어 있으면 정상)"

# Trusted domains 설정
IFS=' ' read -ra DOMAINS <<< "${NC_TRUSTED}"
idx=0
for domain in "${DOMAINS[@]}"; do
    sudo -u www-data php "${NC_INSTALL_DIR}/occ" config:system:set trusted_domains ${idx} --value="${domain}"
    ((idx++))
done
sudo -u www-data php "${NC_INSTALL_DIR}/occ" config:system:set trusted_domains ${idx} --value="localhost"

# ──────────────────────────────────────────────
echo "[6/8] Nextcloud 추가 설정 적용..."

OCC="sudo -u www-data php ${NC_INSTALL_DIR}/occ"

# Redis 캐시 설정
${OCC} config:system:set memcache.local --value="\\OC\\Memcache\\APCu"
${OCC} config:system:set memcache.distributed --value="\\OC\\Memcache\\Redis"
${OCC} config:system:set memcache.locking --value="\\OC\\Memcache\\Redis"
${OCC} config:system:set redis host --value="localhost"
${OCC} config:system:set redis port --value=6379 --type=integer

# 지역 설정
${OCC} config:system:set default_language --value="ko"
${OCC} config:system:set default_locale --value="ko_KR"
${OCC} config:system:set default_phone_region --value="KR"

# URL 설정
${OCC} config:system:set overwrite.cli.url --value="http://${NC_DOMAIN}"

# 로깅
${OCC} config:system:set loglevel --value=2 --type=integer
${OCC} config:system:set log_type --value="file"

# [취약 설정] VULN-D3-02: WebDAV 대량 다운로드에 대한 속도/건수 제한 없음
# 올바른 구현: ratelimit.protection => true 및 Apache에서 rate limit 적용
${OCC} config:system:set ratelimit.protection --value=false --type=boolean

echo "  Nextcloud 설정 완료"

# ──────────────────────────────────────────────
echo "[7/8] Apache 설정..."

# Apache 모듈 활성화
a2enmod rewrite headers env dir mime setenvif ssl

# VirtualHost 설정
cat > /etc/apache2/sites-available/nextcloud.conf << 'APACHECONF'
<VirtualHost *:80>
    ServerName share.mnd.valdoria.mil
    ServerAlias 211.57.64.12

    DocumentRoot /var/www/nextcloud

    <Directory /var/www/nextcloud>
        Require all granted
        AllowOverride All
        Options FollowSymLinks MultiViews

        <IfModule mod_dav.c>
            Dav off
        </IfModule>
    </Directory>

    ErrorLog ${APACHE_LOG_DIR}/nextcloud_error.log
    CustomLog ${APACHE_LOG_DIR}/nextcloud_access.log combined
</VirtualHost>
APACHECONF

a2dissite 000-default.conf 2>/dev/null || true
a2ensite nextcloud.conf
systemctl enable apache2
systemctl restart apache2

echo "  Apache 설정 완료"

# ──────────────────────────────────────────────
echo "[8/8] UFW 방화벽 설정..."
if command -v ufw &> /dev/null; then
    ufw allow 22/tcp    comment "SSH 관리용"
    ufw allow 80/tcp    comment "Nextcloud HTTP"
    ufw allow 443/tcp   comment "Nextcloud HTTPS"
    ufw --force enable
    echo "  UFW 규칙 적용 완료"
else
    echo "  UFW 미설치 — 건너뜀"
fi

# ──────────────────────────────────────────────
echo ""
echo "Nextcloud 시드 데이터 적용 중..."
chmod +x "${SCRIPT_DIR}/seed/seed_documents.sh"
bash "${SCRIPT_DIR}/seed/seed_documents.sh"

echo "========================================="
echo " D3 자료교환체계 배포 완료"
echo "========================================="
echo ""
echo " 접속 URL:"
echo "   - http://211.57.64.12"
echo "   - http://share.mnd.valdoria.mil"
echo ""
echo " 관리자 계정:"
echo "   - admin / NCadmin@2024!"
echo ""
echo " 훈련용 취약점:"
echo "   - VULN-D3-01: GOV20190847 계정 크리덴셜 재사용"
echo "     (VPN 비밀번호 20190847890312 와 동일)"
echo "   - VULN-D3-02: WebDAV 대량 다운로드 제한 없음"
echo "     (PROPFIND Depth:infinity, wget -r 가능)"
echo ""
echo " WebDAV 테스트:"
echo "   curl -X PROPFIND -u GOV20190847:20190847890312 \\"
echo "     http://211.57.64.12/remote.php/dav/files/GOV20190847/"
echo ""
echo " 주의: 훈련 종료 후 모든 계정 비밀번호를 변경하거나 삭제하세요."
echo "========================================="
