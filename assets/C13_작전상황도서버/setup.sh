#!/bin/bash
# ============================================================
# C13 작전 상황도 서버 설치 스크립트
# 호스트: cop.c4i.local (192.168.130.11)
# OS: Rocky Linux 9
# ============================================================

set -e

# root 권한 확인
if [ "$EUID" -ne 0 ]; then
    echo "[오류] root 권한으로 실행하세요: sudo bash setup.sh"
    exit 1
fi

echo "=========================================="
echo "C13 작전 상황도 서버 설치 시작"
echo "호스트: cop.c4i.local (192.168.130.11)"
echo "=========================================="

# [1/9] 시스템 업데이트
echo "[1/9] 시스템 업데이트..."
dnf update -y

# [2/9] Java 17 설치
echo "[2/9] Java 17 설치..."
dnf install -y java-17-openjdk java-17-openjdk-devel

# [3/9] PostgreSQL 15 설치
echo "[3/9] PostgreSQL 설치..."
dnf install -y postgresql15-server postgresql15
postgresql-setup --initdb
systemctl enable postgresql
systemctl start postgresql

# [4/9] PostgreSQL 데이터베이스 설정
echo "[4/9] PostgreSQL 데이터베이스 설정..."
sudo -u postgres psql << 'DBSETUP'
CREATE USER cop_user WITH PASSWORD 'C0p!Map#2024';
CREATE DATABASE cop_db OWNER cop_user;
DBSETUP

# 스키마 및 시드 데이터 적용
sudo -u postgres psql -d cop_db -f /opt/cop/sql/init.sql

# PostgreSQL 인증 설정 (md5)
sed -i 's/ident/md5/g' /var/lib/pgsql/15/data/pg_hba.conf
systemctl restart postgresql

# [5/9] Tomcat 9 설치
echo "[5/9] Tomcat 9 설치..."
cd /opt
wget https://archive.apache.org/dist/tomcat/tomcat-9/v9.0.85/bin/apache-tomcat-9.0.85.tar.gz
tar -xzf apache-tomcat-9.0.85.tar.gz
mv apache-tomcat-9.0.85 tomcat
rm apache-tomcat-9.0.85.tar.gz

# PostgreSQL JDBC 드라이버
wget -P /opt/tomcat/lib/ https://jdbc.postgresql.org/download/postgresql-42.7.1.jar

# JSON 라이브러리
wget -P /opt/tomcat/lib/ https://repo1.maven.org/maven2/org/json/json/20231013/json-20231013.jar

# [6/9] Tomcat 설정 배포
echo "[6/9] Tomcat 설정 배포..."
cp /opt/cop/conf/tomcat/server.xml /opt/tomcat/conf/server.xml

# [7/9] JSP 페이지 및 정적 파일 배포
echo "[7/9] JSP 페이지 배포..."
mkdir -p /opt/tomcat/webapps/ROOT/css
cp /opt/cop/src/webapp/*.jsp /opt/tomcat/webapps/ROOT/
cp /opt/cop/src/webapp/css/map.css /opt/tomcat/webapps/ROOT/css/

# [8/9] Tomcat 시작
echo "[8/9] Tomcat 시작..."
/opt/tomcat/bin/startup.sh

# [9/9] 방화벽 설정
echo "[9/9] 방화벽 설정..."
if command -v firewall-cmd &> /dev/null; then
    firewall-cmd --permanent --add-port=8080/tcp  # Tomcat (COP 웹)
    firewall-cmd --reload
fi

# 호스트명 설정
hostnamectl set-hostname cop-c4i

echo "=========================================="
echo "C13 작전 상황도 서버 설치 완료"
echo "=========================================="
echo ""
echo "  COP 지도: http://cop.c4i.local:8080/map.jsp"
echo "  관리자:   http://cop.c4i.local:8080/admin.jsp"
echo ""
echo "  ★ 주의: getUnit.jsp에 SQL Injection 취약점 (VULN-C13-01)"
echo "  ★ 주의: updateUnit.jsp에 Stored XSS 취약점 (VULN-C13-02)"
echo "  ★ 주의: admin.jsp에 인증 없음 (VULN-C13-03)"
echo ""
echo "  DB 별도 안내:"
echo "    호스트: localhost:5432"
echo "    데이터베이스: cop_db"
echo "    사용자: cop_user / C0p!Map#2024"
echo "=========================================="
