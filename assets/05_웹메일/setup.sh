#!/bin/bash
# ============================================================
# 웹메일 서버 원클릭 배포 스크립트
# 대상: 192.168.100.11 / mail.mois.local
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

TOTAL_STEPS=13

# ==========================================================
echo "[1/${TOTAL_STEPS}] 시스템 업데이트 및 기본 패키지 설치..."
# ==========================================================
apt-get update && apt-get upgrade -y
apt-get install -y curl wget gnupg2 apt-transport-https ca-certificates

# ==========================================================
echo "[2/${TOTAL_STEPS}] Postfix 설치..."
# ==========================================================
debconf-set-selections <<< "postfix postfix/mailname string ${MAIL_DOMAIN}"
debconf-set-selections <<< "postfix postfix/main_mailer_type string 'Internet Site'"
DEBIAN_FRONTEND=noninteractive apt-get install -y postfix

# ==========================================================
echo "[3/${TOTAL_STEPS}] Postfix 설정 파일 배포..."
# ==========================================================
[ -f "${SCRIPT_DIR}/conf/postfix/main.cf" ] || { echo "[ERROR] 파일 없음: conf/postfix/main.cf"; exit 1; }
[ -f "${SCRIPT_DIR}/conf/postfix/master.cf" ] || { echo "[ERROR] 파일 없음: conf/postfix/master.cf"; exit 1; }
cp conf/postfix/main.cf /etc/postfix/main.cf
cp conf/postfix/master.cf /etc/postfix/master.cf
cp conf/postfix/virtual_mailbox_maps /etc/postfix/virtual_mailbox_maps
cp conf/postfix/virtual_mailbox_domains /etc/postfix/virtual_mailbox_domains
postmap /etc/postfix/virtual_mailbox_maps

# ==========================================================
echo "[4/${TOTAL_STEPS}] Dovecot 설치 및 설정..."
# ==========================================================
apt-get install -y dovecot-core dovecot-imapd dovecot-lmtpd dovecot-ldap

# Dovecot 설정 파일 배포
[ -f "${SCRIPT_DIR}/conf/dovecot/dovecot.conf" ] || { echo "[ERROR] 파일 없음: conf/dovecot/dovecot.conf"; exit 1; }
cp conf/dovecot/dovecot.conf /etc/dovecot/dovecot.conf
cp conf/dovecot/conf.d/10-auth.conf /etc/dovecot/conf.d/10-auth.conf
cp conf/dovecot/conf.d/10-mail.conf /etc/dovecot/conf.d/10-mail.conf
cp conf/dovecot/conf.d/10-master.conf /etc/dovecot/conf.d/10-master.conf
cp conf/dovecot/conf.d/10-ssl.conf /etc/dovecot/conf.d/10-ssl.conf
cp conf/dovecot/conf.d/20-imap.conf /etc/dovecot/conf.d/20-imap.conf
cp conf/dovecot/conf.d/20-lmtp.conf /etc/dovecot/conf.d/20-lmtp.conf
cp conf/dovecot/conf.d/auth-ldap.conf.ext /etc/dovecot/conf.d/auth-ldap.conf.ext
cp conf/dovecot/dovecot-ldap.conf.ext /etc/dovecot/dovecot-ldap.conf.ext
chmod 600 /etc/dovecot/dovecot-ldap.conf.ext

# 폴백 인증 파일 (AD 미가용 시 사용)
cp conf/dovecot/conf.d/auth-passwdfile.conf.ext /etc/dovecot/conf.d/auth-passwdfile.conf.ext
cp conf/dovecot/users /etc/dovecot/users
chmod 600 /etc/dovecot/users

# ==========================================================
echo "[5/${TOTAL_STEPS}] vmail 사용자 및 메일 디렉토리 생성..."
# ==========================================================
groupadd -g 5000 vmail 2>/dev/null || true
useradd -g vmail -u 5000 -d /var/mail/vhosts -s /usr/sbin/nologin vmail 2>/dev/null || true
mkdir -p /var/mail/vhosts/mois.local
chown -R vmail:vmail /var/mail/vhosts

# ==========================================================
echo "[6/${TOTAL_STEPS}] 자체 서명 TLS 인증서 생성..."
# ==========================================================
mkdir -p /etc/ssl/certs /etc/ssl/private
openssl req -x509 -nodes -days 3650 \
  -newkey rsa:2048 \
  -keyout /etc/ssl/private/mail.key \
  -out /etc/ssl/certs/mail.crt \
  -subj "/C=VL/ST=Valdoria/L=Capital/O=MOIS/OU=IT/CN=mail.mois.local" \
  2>/dev/null
chmod 600 /etc/ssl/private/mail.key

# ==========================================================
echo "[7/${TOTAL_STEPS}] Apache + PHP 설치..."
# ==========================================================
apt-get install -y apache2 libapache2-mod-php8.2 \
  php8.2 php8.2-fpm php8.2-xml php8.2-mbstring php8.2-intl \
  php8.2-ldap php8.2-sqlite3 php8.2-curl php8.2-zip php8.2-gd

a2enmod proxy_fcgi setenvif rewrite remoteip 2>/dev/null || true
a2enconf php8.2-fpm 2>/dev/null || true

# ==========================================================
echo "[8/${TOTAL_STEPS}] Roundcube 설치 및 설정..."
# ==========================================================
DEBIAN_FRONTEND=noninteractive apt-get install -y \
  roundcube roundcube-core roundcube-plugins roundcube-plugins-extra

# Roundcube 설정 배포
[ -f "${SCRIPT_DIR}/conf/roundcube/config.inc.php" ] || { echo "[ERROR] 파일 없음: conf/roundcube/config.inc.php"; exit 1; }
cp conf/roundcube/config.inc.php /etc/roundcube/config.inc.php
chmod 640 /etc/roundcube/config.inc.php
chown root:www-data /etc/roundcube/config.inc.php

# Roundcube SQLite DB 디렉토리
mkdir -p /var/lib/roundcube/db
chown www-data:www-data /var/lib/roundcube/db

# ==========================================================
echo "[9/${TOTAL_STEPS}] Apache VirtualHost 설정..."
# ==========================================================
[ -f "${SCRIPT_DIR}/conf/apache/roundcube.conf" ] || { echo "[ERROR] 파일 없음: conf/apache/roundcube.conf"; exit 1; }
[ -f "${SCRIPT_DIR}/conf/apache/roundcube-proxy.conf" ] || { echo "[ERROR] 파일 없음: conf/apache/roundcube-proxy.conf"; exit 1; }
cp conf/apache/roundcube.conf /etc/apache2/sites-available/roundcube.conf
cp conf/apache/roundcube-proxy.conf /etc/apache2/sites-available/roundcube-proxy.conf

a2dissite 000-default.conf 2>/dev/null || true
a2ensite roundcube.conf roundcube-proxy.conf 2>/dev/null || true

# 8080 포트 리스닝 추가
if ! grep -q 'Listen 8080' /etc/apache2/ports.conf; then
  echo 'Listen 8080' >> /etc/apache2/ports.conf
fi

# ==========================================================
echo "[10/${TOTAL_STEPS}] 로그 디렉토리 생성..."
# ==========================================================
mkdir -p /var/log/roundcube
chown www-data:www-data /var/log/roundcube

# ==========================================================
echo "[11/${TOTAL_STEPS}] 사용자 메일박스 생성..."
# ==========================================================
bash seed/seed_mailboxes.sh

# ==========================================================
echo "[12/${TOTAL_STEPS}] 서비스 시작 및 활성화..."
# ==========================================================
systemctl restart postfix
systemctl restart dovecot
systemctl restart php8.2-fpm
systemctl restart apache2

systemctl enable postfix dovecot php8.2-fpm apache2

# ==========================================================
echo "[13/${TOTAL_STEPS}] 초기 메일 데이터 삽입..."
# ==========================================================
bash seed/seed_emails.sh

# ==========================================================
# 방화벽 설정 (UFW)
# OPNSense가 네트워크 방화벽을 담당하므로 로컬 UFW는 참고용
# ==========================================================
if command -v ufw &>/dev/null; then
  ufw allow 22/tcp comment "SSH"
  ufw allow 25/tcp comment "SMTP"
  ufw allow 80/tcp comment "HTTP (Roundcube)"
  ufw allow 143/tcp comment "IMAP"
  ufw allow 993/tcp comment "IMAPS"
  ufw allow 8080/tcp comment "Roundcube proxy port"
  # ufw --force enable
  echo "[안내] UFW 규칙 추가 완료 (활성화는 수동으로: ufw --force enable)"
fi

echo ""
echo "============================================"
echo "  웹메일 서버 배포 완료!"
echo "============================================"
echo ""
echo "  Roundcube WebUI : http://${MAIL_HOST}/"
echo "  Roundcube Proxy : http://${MAIL_HOST}:8080/"
echo "  SMTP            : ${MAIL_HOST}:${SMTP_PORT}"
echo "  IMAP            : ${MAIL_HOST}:${IMAP_PORT}"
echo "  IMAPS           : ${MAIL_HOST}:${IMAPS_PORT}"
echo ""
echo "  [참고] AD 서버(${AD_HOST})가 미가용한 경우:"
echo "    /etc/dovecot/conf.d/10-auth.conf 에서"
echo "    auth-ldap.conf.ext → auth-passwdfile.conf.ext 로 변경"
echo ""
echo "  [참고] 초기 메일 데이터가 각 사용자 메일함에 삽입되었습니다."
echo "============================================"
