#!/bin/bash
# ============================================================
# D1 외부 포털 서버 (Military External Portal) — 원클릭 배포 스크립트
# Asset: D1 | IP: 211.57.64.10 | OS: Rocky Linux 9
# Domain: www.mnd.valdoria.mil
# Stack: Nginx + Tomcat 9.0.62 + Spring 5.3.17 + PostgreSQL 15
# ============================================================

set -e

# --- Root 권한 확인 ---
if [ "$EUID" -ne 0 ]; then
    echo "[ERROR] 이 스크립트는 root 권한으로 실행해야 합니다."
    echo "        sudo bash setup.sh"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TOTAL_STEPS=10

echo "============================================================"
echo "  D1 외부 포털 서버 — 발도리아 국방부 배포"
echo "  www.mnd.valdoria.mil (211.57.64.10)"
echo "============================================================"
echo ""

# ============================================================
# [1/10] 호스트명 설정
# ============================================================
echo "[1/${TOTAL_STEPS}] 호스트명 설정..."
hostnamectl set-hostname mil-ext-portal
echo "211.57.64.10 www.mnd.valdoria.mil" >> /etc/hosts
echo "  완료: mil-ext-portal"

# ============================================================
# [2/10] 시스템 패키지 설치
# ============================================================
echo "[2/${TOTAL_STEPS}] 시스템 패키지 설치..."
dnf install -y epel-release
dnf install -y \
    java-11-openjdk java-11-openjdk-devel \
    wget unzip curl tar \
    nginx \
    postgresql-server postgresql \
    firewalld
echo "  완료: JDK 11, Nginx, PostgreSQL, firewalld 설치됨"

# ============================================================
# [3/10] 방화벽 설정
# ============================================================
echo "[3/${TOTAL_STEPS}] 방화벽 설정 (firewalld)..."
systemctl enable --now firewalld
firewall-cmd --permanent --add-service=http
firewall-cmd --permanent --add-service=https
# [취약 설정] Tomcat 직접 접근 포트 개방 — 프로덕션에서는 Nginx 프록시만 허용해야 함
firewall-cmd --permanent --add-port=8080/tcp
firewall-cmd --reload
echo "  완료: HTTP(80), HTTPS(443), Tomcat(8080) 개방"

# ============================================================
# [4/10] PostgreSQL 설정
# ============================================================
echo "[4/${TOTAL_STEPS}] PostgreSQL 초기화 및 데이터 로드..."
postgresql-setup --initdb 2>/dev/null || true
systemctl enable --now postgresql

# pg_hba.conf에 md5 인증 추가
PG_HBA=$(find /var/lib/pgsql -name pg_hba.conf 2>/dev/null | head -1)
if [ -n "$PG_HBA" ]; then
    # local 연결에 md5 인증 추가
    sed -i 's/^\(local\s\+all\s\+all\s\+\)peer/\1md5/' "$PG_HBA"
    sed -i 's/^\(host\s\+all\s\+all\s\+127.0.0.1\/32\s\+\)ident/\1md5/' "$PG_HBA"
    sed -i 's/^\(host\s\+all\s\+all\s\+::1\/128\s\+\)ident/\1md5/' "$PG_HBA"
    systemctl restart postgresql
fi

# DB, 사용자 생성 및 시드 데이터 로드
sudo -u postgres psql -c "CREATE USER portal WITH PASSWORD 'Portal@DB2024!';" 2>/dev/null || true
sudo -u postgres psql -c "CREATE DATABASE mnd_portal OWNER portal;" 2>/dev/null || true
[ -f "${SCRIPT_DIR}/sql/init.sql" ] || { echo "[ERROR] SQL 파일 없음: sql/init.sql"; exit 1; }
sudo -u postgres psql -d mnd_portal -f "${SCRIPT_DIR}/sql/init.sql"
echo "  완료: mnd_portal DB 생성, 시드 데이터 로드됨"

# ============================================================
# [5/10] Tomcat 9 설치
# ============================================================
echo "[5/${TOTAL_STEPS}] Apache Tomcat 9.0.62 설치..."
TOMCAT_VERSION="9.0.62"
TOMCAT_HOME="/opt/tomcat"

if [ ! -d "$TOMCAT_HOME" ]; then
    cd /opt
    wget -q "https://archive.apache.org/dist/tomcat/tomcat-9/v${TOMCAT_VERSION}/bin/apache-tomcat-${TOMCAT_VERSION}.tar.gz"
    tar xzf "apache-tomcat-${TOMCAT_VERSION}.tar.gz"
    mv "apache-tomcat-${TOMCAT_VERSION}" tomcat
    rm -f "apache-tomcat-${TOMCAT_VERSION}.tar.gz"
fi

# Tomcat 전용 사용자 생성
id tomcat &>/dev/null || useradd -r -M -d /opt/tomcat -s /sbin/nologin tomcat
chown -R tomcat:tomcat /opt/tomcat

# setenv.sh 설정
cat > /opt/tomcat/bin/setenv.sh <<'SETENV'
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk
export CATALINA_OPTS="-Xms512m -Xmx1024m -Djava.awt.headless=true"
SETENV
chmod +x /opt/tomcat/bin/setenv.sh

echo "  완료: Tomcat ${TOMCAT_VERSION} 설치됨 (/opt/tomcat)"

# ============================================================
# [6/10] Tomcat 설정 적용
# ============================================================
echo "[6/${TOTAL_STEPS}] Tomcat 설정 적용..."
[ -f "${SCRIPT_DIR}/conf/tomcat/server.xml" ] || { echo "[ERROR] 파일 없음: conf/tomcat/server.xml"; exit 1; }
cp "${SCRIPT_DIR}/conf/tomcat/server.xml" /opt/tomcat/conf/server.xml
chown tomcat:tomcat /opt/tomcat/conf/server.xml
echo "  완료: server.xml 적용됨"

# ============================================================
# [7/10] Tomcat systemd 서비스 등록
# ============================================================
echo "[7/${TOTAL_STEPS}] Tomcat systemd 서비스 등록..."
[ -f "${SCRIPT_DIR}/conf/systemd/tomcat.service" ] || { echo "[ERROR] 파일 없음: conf/systemd/tomcat.service"; exit 1; }
cp "${SCRIPT_DIR}/conf/systemd/tomcat.service" /etc/systemd/system/tomcat.service
systemctl daemon-reload
systemctl enable tomcat
echo "  완료: tomcat.service 등록됨"

# ============================================================
# [8/10] 웹 정적 파일 배포
# ============================================================
echo "[8/${TOTAL_STEPS}] 정적 파일 배포..."
WEB_ROOT="/var/www/mnd-portal"
mkdir -p "${WEB_ROOT}/css" "${WEB_ROOT}/js" "${WEB_ROOT}/images"

# HTML 파일 복사
cp "${SCRIPT_DIR}/src/webapp/index.html" "${WEB_ROOT}/"
cp "${SCRIPT_DIR}/src/webapp/notice.html" "${WEB_ROOT}/"
cp "${SCRIPT_DIR}/src/webapp/notice_view.html" "${WEB_ROOT}/"
cp "${SCRIPT_DIR}/src/webapp/search.html" "${WEB_ROOT}/"
cp "${SCRIPT_DIR}/src/webapp/contact.html" "${WEB_ROOT}/"
cp "${SCRIPT_DIR}/src/webapp/css/style.css" "${WEB_ROOT}/css/"
cp "${SCRIPT_DIR}/src/webapp/js/main.js" "${WEB_ROOT}/js/"

chown -R nginx:nginx "${WEB_ROOT}"
echo "  완료: 정적 파일 → ${WEB_ROOT}"

# ============================================================
# [9/10] Nginx 설정
# ============================================================
echo "[9/${TOTAL_STEPS}] Nginx 설정..."

# 자체서명 SSL 인증서 생성
mkdir -p /etc/nginx/ssl
if [ ! -f /etc/nginx/ssl/mnd_valdoria_mil.crt ]; then
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /etc/nginx/ssl/mnd_valdoria_mil.key \
        -out /etc/nginx/ssl/mnd_valdoria_mil.crt \
        -subj "/C=VD/ST=Capital/L=Valdoria/O=Ministry of National Defense/CN=www.mnd.valdoria.mil" \
        2>/dev/null
fi

# Nginx 설정 복사
[ -f "${SCRIPT_DIR}/conf/nginx/mnd-portal.conf" ] || { echo "[ERROR] 파일 없음: conf/nginx/mnd-portal.conf"; exit 1; }
cp "${SCRIPT_DIR}/conf/nginx/mnd-portal.conf" /etc/nginx/conf.d/mnd-portal.conf

# 기본 설정 비활성화 (충돌 방지)
if [ -f /etc/nginx/conf.d/default.conf ]; then
    mv /etc/nginx/conf.d/default.conf /etc/nginx/conf.d/default.conf.bak
fi

nginx -t && systemctl enable --now nginx
echo "  완료: Nginx 설정 적용, SSL 인증서 생성됨"

# ============================================================
# [10/10] 서비스 시작
# ============================================================
echo "[10/${TOTAL_STEPS}] 서비스 시작..."
systemctl start tomcat
systemctl restart nginx
echo "  완료: Tomcat, Nginx 시작됨"

# ============================================================
# 배포 완료 안내
# ============================================================
echo ""
echo "============================================================"
echo "  배포 완료!"
echo "============================================================"
echo ""
echo "  접속 URL:"
echo "    - HTTP:  http://www.mnd.valdoria.mil/"
echo "    - HTTPS: https://www.mnd.valdoria.mil/"
echo "    - Tomcat 직접: http://211.57.64.10:8080/"
echo ""
echo "  데이터베이스:"
echo "    - Host: 127.0.0.1:5432"
echo "    - DB:   mnd_portal"
echo "    - User: portal / Portal@DB2024!"
echo ""
echo "  서비스 관리:"
echo "    systemctl status tomcat"
echo "    systemctl status nginx"
echo "    systemctl status postgresql"
echo ""
echo "  [참고] Spring4Shell (CVE-2022-22965) 취약점 테스트를 위해서는"
echo "  별도로 eGov WAR를 빌드하여 /opt/tomcat/webapps/ROOT.war 로"
echo "  배포해야 합니다. (src/spring/ 참조)"
echo ""
echo "  주의사항:"
echo "    - Tomcat 8080 포트가 외부에 직접 노출되어 있습니다"
echo "    - SSL 인증서는 자체서명입니다 (훈련 환경)"
echo "============================================================"
