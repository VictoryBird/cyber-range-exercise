#!/bin/bash
# =============================================================
# DB Server (192.168.92.208) One-Click Deployment Script
# Asset: 08
#
# Usage: sudo bash setup.sh
# Prerequisites: Ubuntu 22.04 LTS, internet access
# =============================================================

set -euo pipefail

# ----- Script directory (CLAUDE.md: use SCRIPT_DIR) -----
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ----- File existence checks (CLAUDE.md: verify before proceeding) -----
for f in conf/pg_hba.conf conf/pgaudit.conf \
         sql/00_roles.sql sql/01_mois_portal_ddl.sql sql/02_agency_db_ddl.sql sql/03_complaint_db_ddl.sql \
         sql/10_mois_portal_seed.sql sql/11_agency_db_seed.sql sql/12_complaint_db_seed.sql \
         scripts/backup.sh scripts/monitor.sh; do
    if [ ! -f "${SCRIPT_DIR}/${f}" ]; then
        echo "[ERROR] Required file missing: ${f}"
        exit 1
    fi
done

# ----- Root check -----
if [ "$EUID" -ne 0 ]; then
    echo "[ERROR] This script must be run as root (sudo bash setup.sh)"
    exit 1
fi

BACKUP_DIR="/var/backups/postgresql"
SCRIPTS_DIR="/opt/db-scripts"

echo "============================================"
echo " DB Server Deployment Starting"
echo " IP: 192.168.92.208"
echo " PostgreSQL: latest via apt (auto-detect)"
echo "============================================"

# ----- [1/9] System update + locale -----
echo "[1/9] System update and locale configuration..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq locales gnupg lsb-release
sed -i 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen en_US.UTF-8

# ----- [2/9] Install PostgreSQL (latest via apt, NOT hardcoded version) -----
echo "[2/9] Installing PostgreSQL (latest available via apt)..."
apt-get install -y -qq postgresql postgresql-contrib

# Auto-detect installed PG version (CLAUDE.md: never hardcode version)
PG_VERSION=$(pg_config --version | grep -oP '\d+' | head -1)
PG_CONF_DIR="/etc/postgresql/${PG_VERSION}/main"
echo "     Detected PostgreSQL version: ${PG_VERSION}"
echo "     Config directory: ${PG_CONF_DIR}"

# Install pgAudit for the detected version
apt-get install -y -qq "postgresql-${PG_VERSION}-pgaudit" || echo "     [WARN] pgaudit package not found for PG ${PG_VERSION}, skipping"

# ----- [3/9] Deploy PostgreSQL configuration -----
echo "[3/9] Deploying PostgreSQL configuration..."

# CLAUDE.md: Use conf.d/ override -- NEVER overwrite postgresql.conf
mkdir -p "${PG_CONF_DIR}/conf.d"

# Create conf.d override for our custom settings
cat > "${PG_CONF_DIR}/conf.d/00-custom.conf" << 'PGCONF'
# =============================================================
# Custom PostgreSQL Settings for DB Server (192.168.92.208)
# Loaded via conf.d/ override (does NOT overwrite postgresql.conf)
# =============================================================

# ----- Connection -----
listen_addresses = '*'
port = 5432
max_connections = 100

# ----- Authentication -----
# [취약 설정] VULN: md5 instead of scram-sha-256
password_encryption = md5

# ----- Memory -----
shared_buffers = 256MB
work_mem = 8MB
maintenance_work_mem = 128MB
effective_cache_size = 768MB

# ----- WAL -----
wal_level = replica
max_wal_size = 1GB
min_wal_size = 80MB

# ----- Logging -- [취약 설정] VULN-DB-03: intentionally minimal -----
logging_collector = on
log_directory = '/var/log/postgresql'
log_rotation_age = 1d
log_rotation_size = 100MB

# [취약 설정] VULN-DB-03: Query logging disabled
# Correct setting: log_statement = 'all'
log_statement = 'none'

# [취약 설정] Slow query logging disabled
# Correct setting: log_min_duration_statement = 1000
log_min_duration_statement = -1

# [취약 설정] Connection logging disabled
# Correct setting: log_connections = on / log_disconnections = on
log_connections = off
log_disconnections = off

log_line_prefix = '%t [%p]: '
log_timezone = 'UTC'

# ----- Extensions -----
# [취약 설정] pgaudit NOT included in shared_preload_libraries
# Correct setting: shared_preload_libraries = 'pg_stat_statements, pgaudit'
shared_preload_libraries = 'pg_stat_statements'

# ----- pg_stat_statements -----
pg_stat_statements.track = all
pg_stat_statements.max = 10000

# ----- Locale -----
datestyle = 'iso, mdy'
timezone = 'UTC'
default_text_search_config = 'pg_catalog.english'
PGCONF

# Deploy pg_hba.conf (this one we DO replace, it's the auth file)
cp "${SCRIPT_DIR}/conf/pg_hba.conf" "${PG_CONF_DIR}/pg_hba.conf"

# Deploy pgaudit conf (disabled by default)
cp "${SCRIPT_DIR}/conf/pgaudit.conf" "${PG_CONF_DIR}/conf.d/pgaudit.conf"

# Ensure conf.d is included (most distros include it by default)
if ! grep -q "include_dir = 'conf.d'" "${PG_CONF_DIR}/postgresql.conf"; then
    echo "include_dir = 'conf.d'" >> "${PG_CONF_DIR}/postgresql.conf"
fi

chown -R postgres:postgres "${PG_CONF_DIR}"

# ----- [4/9] Restart PostgreSQL -----
echo "[4/9] Restarting PostgreSQL..."
systemctl restart postgresql
systemctl enable postgresql

# ----- [5/9] Create roles and databases -----
echo "[5/9] Creating roles and databases..."
# CLAUDE.md: Copy SQL to temp dir for postgres user access
TEMP_SQL=$(mktemp -d)
cp "${SCRIPT_DIR}"/sql/*.sql "${TEMP_SQL}/"
chown -R postgres:postgres "${TEMP_SQL}"

sudo -u postgres psql -f "${TEMP_SQL}/00_roles.sql"

# ----- [6/9] Create schemas (DDL) -----
echo "[6/9] Creating database schemas..."
sudo -u postgres psql -d mois_portal -f "${TEMP_SQL}/01_mois_portal_ddl.sql"
sudo -u postgres psql -d agency_db -f "${TEMP_SQL}/02_agency_db_ddl.sql"
sudo -u postgres psql -d complaint_db -f "${TEMP_SQL}/03_complaint_db_ddl.sql"

# Grant permissions for restricted accounts
sudo -u postgres psql -d mois_portal -c "
    GRANT USAGE ON SCHEMA public TO portal_ro;
    GRANT SELECT ON ALL TABLES IN SCHEMA public TO portal_ro;
    ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO portal_ro;
"
sudo -u postgres psql -d complaint_db -c "
    GRANT USAGE ON SCHEMA public TO complaint_rw;
    GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA public TO complaint_rw;
    GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO complaint_rw;
    ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE ON TABLES TO complaint_rw;
"

# ----- [7/9] Insert seed data -----
echo "[7/9] Inserting seed data..."
sudo -u postgres psql -d mois_portal -f "${TEMP_SQL}/10_mois_portal_seed.sql"
sudo -u postgres psql -d agency_db -f "${TEMP_SQL}/11_agency_db_seed.sql"
sudo -u postgres psql -d complaint_db -f "${TEMP_SQL}/12_complaint_db_seed.sql"

# Clean up temp SQL directory
rm -rf "${TEMP_SQL}"

# ----- [8/9] Deploy scripts and directories -----
echo "[8/9] Setting up backup and monitoring scripts..."
mkdir -p "${BACKUP_DIR}/daily" "${BACKUP_DIR}/weekly"
mkdir -p "${SCRIPTS_DIR}"
cp "${SCRIPT_DIR}/scripts/backup.sh" "${SCRIPTS_DIR}/"
cp "${SCRIPT_DIR}/scripts/monitor.sh" "${SCRIPTS_DIR}/"
chmod +x "${SCRIPTS_DIR}"/*.sh
chown -R postgres:postgres "${BACKUP_DIR}"

# ----- [9/9] Firewall -----
echo "[9/9] Configuring firewall..."
# [취약 설정] Allow entire subnet instead of specific hosts
ufw allow from 192.168.92.0/24 to any port 5432 proto tcp comment "PostgreSQL - INT subnet (VULN: overly permissive)"
ufw allow ssh
ufw --force enable

echo ""
echo "============================================"
echo " DB Server Deployment Complete"
echo " PostgreSQL ${PG_VERSION} running"
echo " Port: 5432"
echo " Databases: mois_portal, agency_db, complaint_db"
echo "============================================"
echo ""
echo "Accounts:"
echo "  app_service / Sup3rS3cr3t!  (SUPERUSER - VULN)"
echo "  portal_app  / P0rtal#DB@2026!"
echo "  portal_ro   / Portal_R3ad0nly@2026"
echo "  complaint_rw / Compl@int_RW_2026!"
echo ""
echo "Intentional Vulnerabilities:"
echo "  - VULN-DB-01: app_service has SUPERUSER privilege"
echo "  - VULN-DB-02: pg_hba.conf allows entire INT subnet"
echo "  - VULN-DB-03: log_statement = 'none' (no query logging)"
echo "  - VULN-DB-04: COPY TO/FROM unrestricted (SUPERUSER)"
echo "  - VULN-DB-05: Same credentials used across all services"
echo "============================================"
