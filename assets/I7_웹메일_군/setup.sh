#!/bin/bash
# ============================================================
# 군 웹메일 서버 원클릭 배포 스크립트
# 대상: 192.168.110.11 / mail.mnd.local
# OS: Debian 12 (Bookworm)
# [취약점] VULN-I7-01: Roundcube 1.6.6 (CVE-2025-49113 취약 버전)
# [취약점] VULN-I7-02: 계정 잠금 없음 (브루트포스 가능)
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
cp conf/postfix/main.cf /etc/postfix/main.cf

# 가상 메일박스 매핑 파일 생성
cat > /etc/postfix/virtual_mailbox_maps <<'VMAP'
mil_admin@mnd.local    mnd.local/mil_admin/
mil_kim@mnd.local      mnd.local/mil_kim/
mil_lee@mnd.local      mnd.local/mil_lee/
mil_park@mnd.local     mnd.local/mil_park/
mil_choi@mnd.local     mnd.local/mil_choi/
mil_jung@mnd.local     mnd.local/mil_jung/
mil_yoon@mnd.local     mnd.local/mil_yoon/
VMAP
postmap /etc/postfix/virtual_mailbox_maps

cat > /etc/postfix/virtual_mailbox_domains <<'VDOM'
mnd.local
VDOM

# ==========================================================
echo "[4/${TOTAL_STEPS}] Dovecot 설치 및 설정..."
# ==========================================================
apt-get install -y dovecot-core dovecot-imapd dovecot-lmtpd

[ -f "${SCRIPT_DIR}/conf/dovecot/dovecot.conf" ] || { echo "[ERROR] 파일 없음: conf/dovecot/dovecot.conf"; exit 1; }
[ -f "${SCRIPT_DIR}/conf/dovecot/users" ] || { echo "[ERROR] 파일 없음: conf/dovecot/users"; exit 1; }
[ -f "${SCRIPT_DIR}/conf/dovecot/conf.d/10-auth.conf" ] || { echo "[ERROR] 파일 없음: conf/dovecot/conf.d/10-auth.conf"; exit 1; }
[ -f "${SCRIPT_DIR}/conf/dovecot/conf.d/10-mail.conf" ] || { echo "[ERROR] 파일 없음: conf/dovecot/conf.d/10-mail.conf"; exit 1; }
[ -f "${SCRIPT_DIR}/conf/dovecot/conf.d/10-master.conf" ] || { echo "[ERROR] 파일 없음: conf/dovecot/conf.d/10-master.conf"; exit 1; }
[ -f "${SCRIPT_DIR}/conf/dovecot/conf.d/auth-passwdfile.conf.ext" ] || { echo "[ERROR] 파일 없음: conf/dovecot/conf.d/auth-passwdfile.conf.ext"; exit 1; }
cp conf/dovecot/dovecot.conf /etc/dovecot/dovecot.conf
cp conf/dovecot/users /etc/dovecot/users
cp conf/dovecot/conf.d/10-auth.conf /etc/dovecot/conf.d/10-auth.conf
cp conf/dovecot/conf.d/10-mail.conf /etc/dovecot/conf.d/10-mail.conf
cp conf/dovecot/conf.d/10-master.conf /etc/dovecot/conf.d/10-master.conf
cp conf/dovecot/conf.d/auth-passwdfile.conf.ext /etc/dovecot/conf.d/auth-passwdfile.conf.ext

# ==========================================================
echo "[5/${TOTAL_STEPS}] 메일 사용자 및 디렉토리 생성..."
# ==========================================================
groupadd -g 5000 vmail 2>/dev/null || true
useradd -u 5000 -g vmail -d /var/mail/vhosts -s /usr/sbin/nologin vmail 2>/dev/null || true

MAIL_BASE=/var/mail/vhosts/mnd.local
mkdir -p ${MAIL_BASE}

for USER in mil_admin mil_kim mil_lee mil_park mil_choi mil_jung mil_yoon; do
  mkdir -p ${MAIL_BASE}/${USER}/{cur,new,tmp}
  chown -R vmail:vmail ${MAIL_BASE}/${USER}
done

# ==========================================================
echo "[6/${TOTAL_STEPS}] 자체 서명 TLS 인증서 생성..."
# ==========================================================
if [ ! -f /etc/ssl/certs/mail.crt ]; then
  openssl req -x509 -nodes -days 3650 \
    -newkey rsa:2048 \
    -keyout /etc/ssl/private/mail.key \
    -out /etc/ssl/certs/mail.crt \
    -subj "/C=VL/ST=Valdoria/L=Capital/O=MND/CN=mail.mnd.local"
fi

# ==========================================================
echo "[7/${TOTAL_STEPS}] Apache + PHP 설치..."
# ==========================================================
apt-get install -y apache2 libapache2-mod-php8.2 \
  php8.2-fpm php8.2-xml php8.2-mbstring php8.2-intl \
  php8.2-sqlite3 php8.2-curl php8.2-zip php8.2-gd

a2enmod proxy proxy_fcgi rewrite
systemctl restart apache2

# ==========================================================
echo "[8/${TOTAL_STEPS}] Roundcube 1.6.6 설치..."
# ==========================================================
# [취약점] VULN-I7-01: CVE-2025-49113 취약 버전 설치
#   정상 구현: 최신 패치된 Roundcube 버전(1.6.7+) 설치
ROUNDCUBE_VER="1.6.6"

if [ ! -d /var/lib/roundcube ]; then
  cd /tmp
  wget -q "https://github.com/roundcube/roundcubemail/releases/download/${ROUNDCUBE_VER}/roundcubemail-${ROUNDCUBE_VER}-complete.tar.gz" || {
    echo "[안내] Roundcube 다운로드 실패. 오프라인 설치를 진행합니다."
    mkdir -p /var/lib/roundcube/{program/lib/Roundcube,config,temp,logs}
    mkdir -p /var/lib/roundcube/db
  }

  if [ -f "roundcubemail-${ROUNDCUBE_VER}-complete.tar.gz" ]; then
    tar xzf "roundcubemail-${ROUNDCUBE_VER}-complete.tar.gz"
    mv "roundcubemail-${ROUNDCUBE_VER}" /var/lib/roundcube
  fi
  cd "${SCRIPT_DIR}"
fi

# Roundcube 설정 배포
[ -f "${SCRIPT_DIR}/conf/roundcube/config.inc.php" ] || { echo "[ERROR] 파일 없음: conf/roundcube/config.inc.php"; exit 1; }
cp conf/roundcube/config.inc.php /var/lib/roundcube/config/config.inc.php

# SQLite DB 초기화
mkdir -p /var/lib/roundcube/db
if [ -f /var/lib/roundcube/SQL/sqlite.initial.sql ]; then
  sqlite3 /var/lib/roundcube/db/sqlite.db < /var/lib/roundcube/SQL/sqlite.initial.sql 2>/dev/null || true
fi

# 로그 디렉토리
mkdir -p /var/log/roundcube
chown -R www-data:www-data /var/lib/roundcube /var/log/roundcube

# ==========================================================
echo "[9/${TOTAL_STEPS}] CVE-2025-49113 취약점 삽입..."
# ==========================================================
# [취약점] VULN-I7-01: 플러그인 API에 역직렬화 취약점 삽입
VULN_FILE="/var/lib/roundcube/program/lib/Roundcube/rcube_plugin_api_vuln.php"
cat > "${VULN_FILE}" <<'VULN_PHP'
<?php
/**
 * CVE-2025-49113 시뮬레이션 -- 플러그인 메타데이터 역직렬화 취약점
 * [취약점] VULN-I7-01: unserialize()에 사용자 입력 직접 전달
 *   정상 구현: json_decode() 사용, 또는 입력 검증 후 역직렬화
 *
 * 공격 엔드포인트: POST /?_task=utils&_action=plugin.manage
 * 공격 파라미터: _plugin_meta (base64 인코딩된 직렬화 PHP 객체)
 * 공격 효과: 임의 코드 실행 (웹셸 업로드)
 */

class rcube_plugin_api_vuln {

    private $plugin_metadata = [];

    /**
     * 플러그인 설정 로드
     * [취약점] VULN-I7-01: 사용자 입력을 직접 역직렬화
     *   정상 구현: $metadata = json_decode(base64_decode($raw_metadata), true);
     */
    public function load_plugin_metadata($plugin_name) {
        $raw_metadata = isset($_POST['_plugin_meta']) ? $_POST['_plugin_meta'] : null;

        if ($raw_metadata) {
            // [취약점] unserialize()에 사용자 입력 직접 전달
            //   정상 구현: json_decode()를 사용해야 함
            $metadata = unserialize(base64_decode($raw_metadata));

            if (is_array($metadata) && isset($metadata['name'])) {
                $this->plugin_metadata[$plugin_name] = $metadata;
                return true;
            }
        }
        return false;
    }

    /**
     * 플러그인 관리 인터페이스
     * [취약점] 인증 없이 접근 가능
     *   정상 구현: 관리자 인증 필수
     */
    public function api_list_plugins() {
        if (isset($_POST['_plugin_meta'])) {
            $this->load_plugin_metadata('__sync__');
        }

        header('Content-Type: application/json');
        echo json_encode(['plugins' => [], 'status' => 'ok']);
        exit;
    }
}

// 취약 엔드포인트 핸들러
if (isset($_GET['_task']) && $_GET['_task'] === 'utils'
    && isset($_GET['_action']) && $_GET['_action'] === 'plugin.manage') {
    $api = new rcube_plugin_api_vuln();
    $api->api_list_plugins();
}
VULN_PHP

chown www-data:www-data "${VULN_FILE}"

# Apache 설정에 취약 엔드포인트 라우팅 추가
cat > /etc/apache2/conf-available/roundcube-vuln.conf <<'APACHE_VULN'
# CVE-2025-49113 취약 엔드포인트 라우팅
Alias /roundcube /var/lib/roundcube/

<Directory /var/lib/roundcube/>
    Options -Indexes
    AllowOverride All
    Require all granted

    <IfModule mod_php.c>
        php_flag display_errors Off
    </IfModule>
</Directory>
APACHE_VULN

a2enconf roundcube-vuln 2>/dev/null || true
systemctl reload apache2

# ==========================================================
echo "[10/${TOTAL_STEPS}] 시드 이메일 배치..."
# ==========================================================
MAIL_BASE=/var/mail/vhosts/mnd.local

# 시드 이메일을 각 사용자 메일함에 배달
for EML in seed/emails/*.eml; do
  if [ -f "$EML" ]; then
    BASENAME=$(basename "$EML")
    TIMESTAMP=$(date +%s).$(date +%N)

    # 수신자 파싱하여 해당 메일함에 복사
    RECIPIENTS=$(grep -i "^To:" "$EML" | sed 's/To://i' | tr ',' '\n' | sed 's/@mnd.local//g' | tr -d ' ')

    for RCPT in $RECIPIENTS; do
      RCPT=$(echo "$RCPT" | tr -d '[:space:]')
      if [ -d "${MAIL_BASE}/${RCPT}/new" ]; then
        cp "$EML" "${MAIL_BASE}/${RCPT}/new/${TIMESTAMP}.${BASENAME}"
      fi
    done

    # 발신자 Sent 폴더에도 복사
    SENDER=$(grep -i "^From:" "$EML" | sed 's/From://i' | sed 's/@mnd.local//' | tr -d ' ')
    if [ -d "${MAIL_BASE}/${SENDER}" ]; then
      mkdir -p "${MAIL_BASE}/${SENDER}/.Sent/new"
      cp "$EML" "${MAIL_BASE}/${SENDER}/.Sent/new/${TIMESTAMP}.${BASENAME}"
    fi
  fi
done

chown -R vmail:vmail ${MAIL_BASE}

# ==========================================================
echo "[11/${TOTAL_STEPS}] 서비스 시작..."
# ==========================================================
systemctl enable --now postfix
systemctl enable --now dovecot
systemctl enable --now apache2

# ==========================================================
echo "[12/${TOTAL_STEPS}] UFW 방화벽 설정..."
# ==========================================================
ufw allow 22/tcp comment "SSH"
ufw allow 25/tcp comment "SMTP"
ufw allow 80/tcp comment "HTTP (Roundcube)"
ufw allow 143/tcp comment "IMAP"
ufw --force enable

# ==========================================================
echo "[13/${TOTAL_STEPS}] 서비스 상태 확인..."
# ==========================================================
echo ""
echo "서비스 상태:"
systemctl is-active postfix && echo "  Postfix: 실행 중" || echo "  Postfix: 중지"
systemctl is-active dovecot && echo "  Dovecot: 실행 중" || echo "  Dovecot: 중지"
systemctl is-active apache2 && echo "  Apache: 실행 중" || echo "  Apache: 중지"

echo ""
echo "============================================================"
echo " 군 웹메일 서버 배포 완료"
echo "============================================================"
echo " 웹메일 URL: http://mail.mnd.local/"
echo "             http://192.168.110.11/"
echo " SMTP: 192.168.110.11:25"
echo " IMAP: 192.168.110.11:143"
echo ""
echo " 테스트 계정 (7명):"
echo "   mil_admin / Admin2026!"
echo "   mil_kim   / Jungsu2026!"
echo "   mil_lee   / Younghee2026!"
echo "   mil_park  / Junhyuk2026!"
echo "   mil_choi  / Seryeon2026!"
echo "   mil_jung  / Dongwook2026!"
echo "   mil_yoon  / Sera2026!"
echo ""
echo " [취약점]"
echo "   VULN-I7-01: CVE-2025-49113 (Roundcube 1.6.6 RCE)"
echo "     -> POST /?_task=utils&_action=plugin.manage"
echo "   VULN-I7-02: 계정 잠금 없음 (브루트포스 가능)"
echo ""
echo " [주의사항]"
echo "   - /etc/hosts 에 '192.168.110.11 mail.mnd.local' 추가 필요"
echo "   - 시드 이메일 5건 배달됨"
echo "============================================================"
