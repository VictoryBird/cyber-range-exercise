#!/bin/bash
# ============================================================
# DB 서버 — 원클릭 배포 스크립트
# 대상 OS: Ubuntu 22.04 LTS
# IP: 192.168.100.20
# 도메인: db.mois.local
#
# 사용법: sudo bash setup.sh
#
# 취약점 내장:
#   VULN-DB-01: app_service 계정에 SUPERUSER 권한
#   VULN-DB-02: pg_hba.conf에서 INT 전체 서브넷 허용
#   VULN-DB-03: log_statement = 'none' (쿼리 로깅 비활성)
#   VULN-DB-04: SUPERUSER의 COPY TO/FROM 파일 접근 가능
#   VULN-DB-05: 모든 서비스가 동일 계정/비밀번호 사용
# ============================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
IP="192.168.100.20"
HOSTNAME="db-server"

echo "=========================================="
echo " DB 서버 배포 시작"
echo " IP: ${IP}"
echo " 호스트명: ${HOSTNAME}"
echo "=========================================="

# ===== [1] root 확인 =====
if [ "$EUID" -ne 0 ]; then
    echo "[ERROR] root 권한으로 실행하세요: sudo bash setup.sh"
    exit 1
fi

# ===== [2] 호스트명 및 네트워크 =====
echo "[1/7] 호스트명 설정..."
hostnamectl set-hostname ${HOSTNAME}

# ===== [3] PostgreSQL 설치 =====
echo "[2/7] PostgreSQL 설치 중..."
apt-get update -qq
apt-get install -y -qq postgresql postgresql-contrib ufw
# pgaudit 확장 설치 (설치된 PG 버전에 맞게)
PG_VER=$(pg_config --version | grep -oP '\d+' | head -1)
apt-get install -y -qq "postgresql-${PG_VER}-pgaudit" 2>/dev/null || echo "[WARN] pgaudit 설치 실패 — 수동 설치 필요"

# ===== [4] PostgreSQL 설정 파일 배포 =====
echo "[3/7] PostgreSQL 설정 배포..."
PG_CONF_DIR="/etc/postgresql/${PG_VER}/main"

# 기존 설정 백업
cp ${PG_CONF_DIR}/postgresql.conf ${PG_CONF_DIR}/postgresql.conf.bak
cp ${PG_CONF_DIR}/pg_hba.conf ${PG_CONF_DIR}/pg_hba.conf.bak

# pg_hba.conf 덮어쓰기 (접근 제어)
[ -f "${SCRIPT_DIR}/conf/pg_hba.conf" ] || { echo "[ERROR] 파일 없음: conf/pg_hba.conf"; exit 1; }
cp ${SCRIPT_DIR}/conf/pg_hba.conf ${PG_CONF_DIR}/pg_hba.conf

# postgresql.conf — 원본 유지하면서 취약 설정만 오버라이드 (data_directory 등 보존)
# conf.d 디렉토리가 include되도록 설정
mkdir -p ${PG_CONF_DIR}/conf.d
grep -q "include_dir = 'conf.d'" ${PG_CONF_DIR}/postgresql.conf || \
    echo "include_dir = 'conf.d'" >> ${PG_CONF_DIR}/postgresql.conf

# 취약 설정을 conf.d에 배포 (원본 postgresql.conf 위에 오버라이드)
cat > ${PG_CONF_DIR}/conf.d/00_custom.conf << 'PGCONF'
# 연결 설정
listen_addresses = '*'
port = 5432
max_connections = 100

# 메모리
shared_buffers = 256MB
effective_cache_size = 768MB
work_mem = 4MB
maintenance_work_mem = 64MB

# WAL
wal_level = replica
max_wal_size = 1GB
min_wal_size = 80MB

# [VULN-DB-03] 로깅 설정 — 의도적으로 최소 로깅
# 올바른 설정: log_statement = 'all', log_connections = on
logging_collector = on
log_directory = '/var/log/postgresql'
log_rotation_age = 1d
log_rotation_size = 100MB
log_line_prefix = '%t [%p]: '
log_statement = 'none'
log_min_duration_statement = -1
log_connections = off
log_disconnections = off

# shared_preload_libraries — pgaudit 미포함 (블루팀이 수동 활성화)
shared_preload_libraries = 'pg_stat_statements'
pg_stat_statements.max = 1000
pg_stat_statements.track = all

# 로케일/시간
timezone = 'Asia/Seoul'
PGCONF

# pgaudit 설정 (비활성 상태 — 블루팀이 수동 활성화)
[ -f "${SCRIPT_DIR}/conf/pgaudit.conf" ] || { echo "[ERROR] 파일 없음: conf/pgaudit.conf"; exit 1; }
cp ${SCRIPT_DIR}/conf/pgaudit.conf ${PG_CONF_DIR}/conf.d/pgaudit.conf

chown postgres:postgres ${PG_CONF_DIR}/pg_hba.conf
chown -R postgres:postgres ${PG_CONF_DIR}/conf.d

# ===== [5] PostgreSQL 재시작 및 DB/역할 생성 =====
echo "[4/7] PostgreSQL 재시작 및 데이터베이스 초기화..."
systemctl restart postgresql
systemctl enable postgresql

# SQL 파일을 postgres 유저가 읽을 수 있는 임시 디렉토리로 복사
SQL_TMP=$(mktemp -d)
cp ${SCRIPT_DIR}/sql/*.sql ${SQL_TMP}/
chown -R postgres:postgres ${SQL_TMP}

# 역할 생성
[ -f "${SQL_TMP}/00_roles.sql" ] || { echo "[ERROR] SQL 파일 없음: sql/00_roles.sql"; exit 1; }
sudo -u postgres psql -f ${SQL_TMP}/00_roles.sql

# 데이터베이스 생성
sudo -u postgres psql -c "CREATE DATABASE mois_portal OWNER postgres ENCODING 'UTF8' TEMPLATE template0;" 2>/dev/null || true
sudo -u postgres psql -c "CREATE DATABASE agency_db OWNER postgres ENCODING 'UTF8' TEMPLATE template0;" 2>/dev/null || true
sudo -u postgres psql -c "CREATE DATABASE complaint_db OWNER postgres ENCODING 'UTF8' TEMPLATE template0;" 2>/dev/null || true

# DDL 실행
echo "[5/7] 스키마 생성 중..."
sudo -u postgres psql -f ${SQL_TMP}/01_mois_portal_ddl.sql
sudo -u postgres psql -f ${SQL_TMP}/02_agency_db_ddl.sql
sudo -u postgres psql -f ${SQL_TMP}/03_complaint_db_ddl.sql

# 시드 데이터 삽입
echo "[6/7] 시드 데이터 삽입 중..."
sudo -u postgres psql -f ${SQL_TMP}/10_mois_portal_seed.sql
sudo -u postgres psql -f ${SQL_TMP}/11_agency_db_seed.sql
sudo -u postgres psql -f ${SQL_TMP}/12_complaint_db_seed.sql

# 임시 디렉토리 정리
rm -rf ${SQL_TMP}

# ===== [6] 관리 스크립트 배포 =====
mkdir -p /opt/db-scripts /var/backups/postgresql/{daily,weekly}
cp ${SCRIPT_DIR}/scripts/backup.sh /opt/db-scripts/
cp ${SCRIPT_DIR}/scripts/monitor.sh /opt/db-scripts/
chmod +x /opt/db-scripts/*.sh

# 일간 백업 크론 등록
echo "0 2 * * * root /opt/db-scripts/backup.sh" > /etc/cron.d/db-backup

# ===== [7] 방화벽 설정 =====
echo "[7/7] 방화벽 설정..."
# [VULN-DB-02] INT 전체 서브넷에서 PostgreSQL 접근 허용
ufw allow from 192.168.100.0/24 to any port 5432 proto tcp
# DMZ 외부 포털 서버
ufw allow from 203.238.140.10 to any port 5432 proto tcp
ufw allow 22/tcp
ufw --force enable

# ===== 완료 =====
echo ""
echo "=========================================="
echo " DB 서버 배포 완료!"
echo "=========================================="
echo ""
echo " PostgreSQL: ${IP}:5432"
echo " 데이터베이스: mois_portal, agency_db, complaint_db"
echo ""
echo " 계정 정보:"
echo "   app_service / Sup3rS3cr3t!  (SUPERUSER — 취약점)"
echo "   portal_ro   / Portal_R3ad0nly@2026  (읽기 전용)"
echo "   complaint_rw / Compl@int_RW_2026!  (민원 읽기/쓰기)"
echo ""
echo " 접속 테스트:"
echo "   psql -h ${IP} -U app_service -d agency_db"
echo ""
echo " 모니터링: /opt/db-scripts/monitor.sh"
echo " 백업: /opt/db-scripts/backup.sh (매일 02:00 자동)"
echo "=========================================="
