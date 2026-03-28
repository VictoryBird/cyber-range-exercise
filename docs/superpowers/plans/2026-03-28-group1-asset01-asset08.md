# Implementation Plan: Asset 08 (DB Server) + Asset 01 (External Portal Server)

**Created:** 2026-03-28
**Assets:** 08_DB Server (PostgreSQL), 01_External Portal Server (Next.js + FastAPI)
**Build Order:** Asset 08 first, then Asset 01 (portal depends on DB)

---

## Reference Documents

- `자산설계_08_DB서버.md` -- DB server full spec
- `자산설계_01_외부포털서버.md` -- External portal full spec
- `IP_대역_설계.md` -- Network layout
- `세계관_설정.md` -- Worldbuilding, English names
- `CLAUDE.md` -- Implementation rules

---

## Task 1: Asset 08 -- setup.sh + Configuration Files

### 1.1 Create directory structure

- [ ] Create `assets/08_DB서버/` with subdirectories

```bash
mkdir -p assets/08_DB서버/{conf,sql,scripts}
```

### 1.2 Write `assets/08_DB서버/.env.example`

- [ ] Write file: `assets/08_DB서버/.env.example`

```bash
# =============================================================
# DB Server (192.168.92.208) Environment Variables
# Copy to .env and adjust values as needed
# =============================================================

# PostgreSQL (auto-detected version -- do NOT hardcode)
PG_LISTEN_ADDRESSES=*
PG_PORT=5432
PG_MAX_CONNECTIONS=100

# Backup
BACKUP_DIR=/var/backups/postgresql
BACKUP_RETENTION_DAYS=30

# Network
ALLOWED_SUBNET=192.168.92.0/24
```

### 1.3 Write `assets/08_DB서버/conf/pg_hba.conf`

- [ ] Write file: `assets/08_DB서버/conf/pg_hba.conf`

```ini
# =============================================================
# pg_hba.conf -- PostgreSQL Client Authentication
# Asset 08: DB Server (192.168.92.208)
# =============================================================

# TYPE  DATABASE        USER            ADDRESS                 METHOD

# Local connections (socket)
local   all             postgres                                peer
local   all             all                                     peer

# IPv4 local
host    all             all             127.0.0.1/32            scram-sha-256

# [취약 설정] VULN-DB-02: INT 전체 서브넷에서 모든 DB, 모든 사용자 접근 허용
# 올바른 설정: 호스트/DB 단위로 제한해야 함
# host    mois_portal     portal_app      192.168.92.201/32       scram-sha-256
# host    agency_db       app_service     192.168.92.204/32       scram-sha-256
# host    complaint_db    complaint_rw    192.168.92.206/32       scram-sha-256
host    all             all             192.168.92.0/24         md5

# DMZ External Portal (via OPNSense-2)
host    mois_portal     portal_app      192.168.92.201/32       md5

# IPv6 local
host    all             all             ::1/128                 scram-sha-256
```

### 1.4 Write `assets/08_DB서버/conf/pgaudit.conf`

- [ ] Write file: `assets/08_DB서버/conf/pgaudit.conf`

```ini
# =============================================================
# pgaudit.conf -- pgAudit Configuration (DISABLED by default)
# Asset 08: DB Server (192.168.92.208)
#
# [취약 설정] VULN-DB-03: pgAudit is installed but not activated.
# Blue team must enable this manually for attack detection.
#
# To enable:
# 1. Edit /etc/postgresql/<VER>/main/postgresql.conf
#    Change: shared_preload_libraries = 'pg_stat_statements'
#    To:     shared_preload_libraries = 'pg_stat_statements, pgaudit'
# 2. Uncomment the settings below
# 3. Restart PostgreSQL: sudo systemctl restart postgresql
# 4. Run in each database: CREATE EXTENSION IF NOT EXISTS pgaudit;
# =============================================================

# pgaudit.log = 'all'
# pgaudit.log_catalog = on
# pgaudit.log_parameter = on
# pgaudit.log_statement_once = off
# pgaudit.log_level = 'log'
```

### 1.5 Write `assets/08_DB서버/setup.sh`

- [ ] Write file: `assets/08_DB서버/setup.sh`

```bash
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
```

---

## Task 2: Asset 08 -- SQL Roles + DDL (All 3 Databases)

### 2.1 Write `assets/08_DB서버/sql/00_roles.sql`

- [ ] Write file: `assets/08_DB서버/sql/00_roles.sql`

```sql
-- =============================================================
-- 00_roles.sql -- PostgreSQL Role/Account Creation
-- Asset 08: DB Server (192.168.92.208)
-- =============================================================

-- Create databases first (roles need them for GRANT CONNECT)
CREATE DATABASE mois_portal
    WITH OWNER = postgres
    ENCODING = 'UTF8'
    TEMPLATE = template0;

CREATE DATABASE agency_db
    WITH OWNER = postgres
    ENCODING = 'UTF8'
    TEMPLATE = template0;

CREATE DATABASE complaint_db
    WITH OWNER = postgres
    ENCODING = 'UTF8'
    TEMPLATE = template0;

-- =============================================================
-- [취약점] VULN-DB-01: Service account with SUPERUSER privilege
-- Correct implementation: separate least-privilege accounts per DB
-- CREATE ROLE portal_service WITH LOGIN PASSWORD '...' NOSUPERUSER;
-- CREATE ROLE agency_service WITH LOGIN PASSWORD '...' NOSUPERUSER;
-- =============================================================
CREATE ROLE app_service
    WITH SUPERUSER LOGIN PASSWORD 'Sup3rS3cr3t!'
    CREATEDB CREATEROLE;
COMMENT ON ROLE app_service IS 'Unified service account -- all DB access (SUPERUSER, intentional vulnerability)';

-- External portal dedicated account
CREATE ROLE portal_app
    WITH LOGIN PASSWORD 'P0rtal#DB@2026!'
    NOSUPERUSER NOCREATEDB NOCREATEROLE;
COMMENT ON ROLE portal_app IS 'External portal application account (mois_portal only)';

-- Read-only account (external portal queries)
CREATE ROLE portal_ro
    WITH LOGIN PASSWORD 'Portal_R3ad0nly@2026'
    NOSUPERUSER NOCREATEDB NOCREATEROLE;
COMMENT ON ROLE portal_ro IS 'External portal read-only account';

-- Complaint processing read/write account
CREATE ROLE complaint_rw
    WITH LOGIN PASSWORD 'Compl@int_RW_2026!'
    NOSUPERUSER NOCREATEDB NOCREATEROLE;
COMMENT ON ROLE complaint_rw IS 'Complaint processing read/write account';

-- GRANT CONNECT
GRANT CONNECT ON DATABASE mois_portal TO portal_app;
GRANT CONNECT ON DATABASE mois_portal TO portal_ro;
GRANT CONNECT ON DATABASE complaint_db TO complaint_rw;
```

### 2.2 Write `assets/08_DB서버/sql/01_mois_portal_ddl.sql`

- [ ] Write file: `assets/08_DB서버/sql/01_mois_portal_ddl.sql`

```sql
-- =============================================================
-- 01_mois_portal_ddl.sql -- mois_portal Database Schema
-- Purpose: External portal (notices, inquiries, user accounts)
-- =============================================================

-- Extension
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- -----------------------------------------------------------
-- Table: users (portal accounts)
-- -----------------------------------------------------------
CREATE TABLE users (
    id              SERIAL PRIMARY KEY,
    username        VARCHAR(100) UNIQUE NOT NULL,
    email           VARCHAR(200),
    password        VARCHAR(200) NOT NULL,
    role            VARCHAR(50) DEFAULT 'viewer',
    last_login      TIMESTAMP,
    created_at      TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_username ON users(username);

-- -----------------------------------------------------------
-- Table: notices (public announcements)
-- -----------------------------------------------------------
CREATE TABLE notices (
    id              SERIAL PRIMARY KEY,
    title           VARCHAR(500) NOT NULL,
    content         TEXT,
    category        VARCHAR(100) DEFAULT 'General',
    author          VARCHAR(100) DEFAULT 'Admin',
    is_public       BOOLEAN DEFAULT TRUE,
    view_count      INTEGER DEFAULT 0,
    created_at      TIMESTAMP DEFAULT NOW(),
    updated_at      TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_notices_category ON notices(category);
CREATE INDEX idx_notices_created ON notices(created_at DESC);
CREATE INDEX idx_notices_is_public ON notices(is_public);

-- -----------------------------------------------------------
-- Table: inquiries (citizen inquiries)
-- -----------------------------------------------------------
CREATE TABLE inquiries (
    id              SERIAL PRIMARY KEY,
    tracking_number VARCHAR(50) UNIQUE NOT NULL,
    subject         VARCHAR(500) NOT NULL,
    description     TEXT,
    status          VARCHAR(50) DEFAULT 'Received',
    department      VARCHAR(200),
    submitter_name  VARCHAR(100),
    submitter_email VARCHAR(200),
    submitted_at    TIMESTAMP DEFAULT NOW(),
    updated_at      TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_inquiries_tracking ON inquiries(tracking_number);
CREATE INDEX idx_inquiries_status ON inquiries(status);

-- -----------------------------------------------------------
-- Permissions
-- -----------------------------------------------------------
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO app_service;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO app_service;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO portal_app;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO portal_app;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO portal_app;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO portal_app;
GRANT USAGE ON SCHEMA public TO portal_ro;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO portal_ro;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO portal_ro;
```

### 2.3 Write `assets/08_DB서버/sql/02_agency_db_ddl.sql`

- [ ] Write file: `assets/08_DB서버/sql/02_agency_db_ddl.sql`

```sql
-- =============================================================
-- 02_agency_db_ddl.sql -- agency_db Database Schema
-- Purpose: Internal business portal (employees, departments, approvals, work requests)
-- =============================================================

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- -----------------------------------------------------------
-- Table: departments
-- -----------------------------------------------------------
CREATE TABLE departments (
    dept_id         SERIAL PRIMARY KEY,
    dept_code       VARCHAR(20) NOT NULL UNIQUE,
    dept_name       VARCHAR(100) NOT NULL,
    parent_dept_id  INTEGER REFERENCES departments(dept_id),
    head_employee_id INTEGER,
    floor_location  VARCHAR(20),
    phone_ext       VARCHAR(10),
    created_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- -----------------------------------------------------------
-- Table: employees
-- -----------------------------------------------------------
CREATE TABLE employees (
    employee_id     SERIAL PRIMARY KEY,
    emp_number      VARCHAR(20) NOT NULL UNIQUE,
    full_name       VARCHAR(100) NOT NULL,
    email           VARCHAR(120) NOT NULL UNIQUE,
    phone           VARCHAR(20),
    dept_id         INTEGER REFERENCES departments(dept_id),
    position_title  VARCHAR(50) NOT NULL,
    role_title      VARCHAR(50),
    hire_date       DATE NOT NULL,
    ad_username     VARCHAR(50) UNIQUE,
    password_hash   VARCHAR(256),
    is_active       BOOLEAN DEFAULT TRUE,
    created_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_employees_dept ON employees(dept_id);
CREATE INDEX idx_employees_empnum ON employees(emp_number);
CREATE INDEX idx_employees_ad ON employees(ad_username);

-- Deferred FK for department head
ALTER TABLE departments
    ADD CONSTRAINT fk_dept_head
    FOREIGN KEY (head_employee_id) REFERENCES employees(employee_id);

-- -----------------------------------------------------------
-- Table: approvals (document approvals)
-- -----------------------------------------------------------
CREATE TABLE approvals (
    approval_id     SERIAL PRIMARY KEY,
    doc_number      VARCHAR(30) NOT NULL UNIQUE,
    title           VARCHAR(300) NOT NULL,
    content         TEXT NOT NULL,
    doc_type        VARCHAR(50) NOT NULL DEFAULT 'General',
    drafter_id      INTEGER NOT NULL REFERENCES employees(employee_id),
    current_step    INTEGER DEFAULT 1,
    total_steps     INTEGER DEFAULT 3,
    status          VARCHAR(20) NOT NULL DEFAULT 'Draft',
    approved_by     TEXT,
    rejected_reason TEXT,
    created_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_approvals_drafter ON approvals(drafter_id);
CREATE INDEX idx_approvals_status ON approvals(status);
CREATE INDEX idx_approvals_docnum ON approvals(doc_number);

-- -----------------------------------------------------------
-- Table: work_requests
-- -----------------------------------------------------------
CREATE TABLE work_requests (
    request_id      SERIAL PRIMARY KEY,
    request_number  VARCHAR(30) NOT NULL UNIQUE,
    title           VARCHAR(300) NOT NULL,
    description     TEXT NOT NULL,
    requester_id    INTEGER NOT NULL REFERENCES employees(employee_id),
    assignee_id     INTEGER REFERENCES employees(employee_id),
    priority        VARCHAR(10) NOT NULL DEFAULT 'Normal',
    status          VARCHAR(20) NOT NULL DEFAULT 'Requested',
    due_date        DATE,
    completed_at    TIMESTAMP WITH TIME ZONE,
    created_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_workreq_requester ON work_requests(requester_id);
CREATE INDEX idx_workreq_assignee ON work_requests(assignee_id);
CREATE INDEX idx_workreq_status ON work_requests(status);

-- -----------------------------------------------------------
-- Permissions
-- -----------------------------------------------------------
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO app_service;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO app_service;
```

### 2.4 Write `assets/08_DB서버/sql/03_complaint_db_ddl.sql`

- [ ] Write file: `assets/08_DB서버/sql/03_complaint_db_ddl.sql`

```sql
-- =============================================================
-- 03_complaint_db_ddl.sql -- complaint_db Database Schema
-- Purpose: Complaint filing and processing
-- =============================================================

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- -----------------------------------------------------------
-- Table: complaints
-- -----------------------------------------------------------
CREATE TABLE complaints (
    complaint_id    SERIAL PRIMARY KEY,
    complaint_number VARCHAR(30) NOT NULL UNIQUE,
    applicant_name  VARCHAR(100) NOT NULL,
    applicant_email VARCHAR(120),
    applicant_phone VARCHAR(20),
    applicant_addr  VARCHAR(300),
    category        VARCHAR(50) NOT NULL,
    title           VARCHAR(300) NOT NULL,
    content         TEXT NOT NULL,
    status          VARCHAR(20) NOT NULL DEFAULT 'Received',
    priority        VARCHAR(10) DEFAULT 'Normal',
    assigned_dept   VARCHAR(100),
    assigned_to     VARCHAR(100),
    response        TEXT,
    responded_at    TIMESTAMP WITH TIME ZONE,
    created_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_complaints_number ON complaints(complaint_number);
CREATE INDEX idx_complaints_status ON complaints(status);
CREATE INDEX idx_complaints_category ON complaints(category);
CREATE INDEX idx_complaints_created ON complaints(created_at DESC);

-- -----------------------------------------------------------
-- Table: attachments (file metadata)
-- -----------------------------------------------------------
CREATE TABLE attachments (
    attachment_id   SERIAL PRIMARY KEY,
    complaint_id    INTEGER NOT NULL REFERENCES complaints(complaint_id),
    original_name   VARCHAR(300) NOT NULL,
    stored_path     VARCHAR(500) NOT NULL,
    file_size       BIGINT,
    mime_type       VARCHAR(100),
    checksum_sha256 VARCHAR(64),
    is_converted    BOOLEAN DEFAULT FALSE,
    converted_path  VARCHAR(500),
    uploaded_at     TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_attachments_complaint ON attachments(complaint_id);

-- -----------------------------------------------------------
-- Table: complaint_file_processing
-- -----------------------------------------------------------
CREATE TABLE complaint_file_processing (
    id              SERIAL PRIMARY KEY,
    complaint_id    INTEGER NOT NULL REFERENCES complaints(complaint_id),
    original_filename VARCHAR(300) NOT NULL,
    original_size   BIGINT,
    converted_files TEXT[],
    file_type       VARCHAR(50),
    processing_time_sec FLOAT,
    status          VARCHAR(20) DEFAULT 'pending',
    error_message   TEXT,
    processed_at    TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_file_proc_complaint ON complaint_file_processing(complaint_id);

-- -----------------------------------------------------------
-- Table: processing_logs
-- -----------------------------------------------------------
CREATE TABLE processing_logs (
    log_id          SERIAL PRIMARY KEY,
    complaint_id    INTEGER NOT NULL REFERENCES complaints(complaint_id),
    action          VARCHAR(50) NOT NULL,
    actor_name      VARCHAR(100) NOT NULL,
    actor_dept      VARCHAR(100),
    description     TEXT,
    previous_status VARCHAR(20),
    new_status      VARCHAR(20),
    created_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_proclogs_complaint ON processing_logs(complaint_id);
CREATE INDEX idx_proclogs_action ON processing_logs(action);
CREATE INDEX idx_proclogs_created ON processing_logs(created_at DESC);

-- -----------------------------------------------------------
-- Permissions
-- -----------------------------------------------------------
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO app_service;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO app_service;
```

---

## Task 3: Asset 08 -- Seed Data (All 3 Databases) + Scripts

### 3.1 Write `assets/08_DB서버/sql/10_mois_portal_seed.sql`

- [ ] Write file: `assets/08_DB서버/sql/10_mois_portal_seed.sql`

Uses English names from worldbuilding doc: Daniel Harper (admin), Michael Torres (editor), Sarah Mitchell (editor), David Chen (viewer).

```sql
-- =============================================================
-- 10_mois_portal_seed.sql -- External Portal Seed Data
-- Asset 08: DB Server (192.168.92.208)
-- Database: mois_portal
-- Uses English names per worldbuilding document
-- =============================================================

-- ----- Portal users -----
INSERT INTO users (username, email, password, role, last_login, created_at) VALUES
('daniel.harper',   'daniel.harper@mois.valdoria.gov',   crypt('@dminMOIS2026!', gen_salt('bf')),  'superadmin', '2026-03-25 08:15:00', '2025-06-01 09:00:00'),
('michael.torres',  'michael.torres@mois.valdoria.gov',  crypt('Edit0r#01', gen_salt('bf')),       'editor',     '2026-03-24 17:30:00', '2025-07-15 10:00:00'),
('sarah.mitchell',  'sarah.mitchell@mois.valdoria.gov',   crypt('Edit0r#02', gen_salt('bf')),       'editor',     '2026-03-23 14:20:00', '2025-08-01 11:00:00'),
('david.chen',      'david.chen@mois.valdoria.gov',       crypt('View3r!!', gen_salt('bf')),        'viewer',     '2026-03-22 09:45:00', '2025-09-10 08:30:00'),
('emily.watson',    'emily.watson@mois.valdoria.gov',     crypt('W@tson2026!', gen_salt('bf')),     'editor',     '2026-03-21 16:00:00', '2025-10-01 09:00:00'),
('rachel.kim',      'rachel.kim@mois.valdoria.gov',       crypt('R@chel2026!', gen_salt('bf')),     'viewer',     '2026-03-20 11:30:00', '2025-11-15 10:00:00');

-- ----- Notices -----
INSERT INTO notices (title, content, category, author, is_public, view_count, created_at, updated_at) VALUES
('2026 First Half Policy Briefing Schedule',
 'The Ministry of Interior and Safety announces the 2026 first-half policy briefing schedule.

1. Date: February 15, 2026 (Monday), 14:00
2. Venue: Government Complex Sejong, Building 6, Grand Conference Room
3. Attendees: All division directors and above

Please refer to the internal business portal for details.',
 'Policy', 'Daniel Harper', TRUE, 1542, '2026-01-10 09:00:00', '2026-01-10 09:00:00'),

('E-Government Service Maintenance Notice (3/28-3/29)',
 'A scheduled maintenance will be conducted to improve system stability.

- Maintenance window: March 28, 2026 (Sat) 22:00 ~ March 29, 2026 (Sun) 06:00
- Affected services: Gov24, Digital Government Portal, and related e-government services
- Scope: Database migration and security patching

Services will be temporarily unavailable during the maintenance window. We appreciate your understanding.',
 'System', 'Emily Watson', TRUE, 2831, '2026-03-20 10:00:00', '2026-03-20 10:00:00'),

('Personal Data Protection Training Completion Notice',
 'The 2026 first-half personal data protection training results are as follows:

- Training period: 2026.01.15 ~ 2026.02.28
- Completed: 387 out of 412 employees (93.9%)
- Incomplete: Individual notifications will be sent

Employees who have not completed the training must do so by March 31.',
 'Training', 'David Chen', TRUE, 687, '2026-03-05 14:00:00', '2026-03-05 14:00:00'),

('First Citizen Participation Policy Forum 2026',
 'MOIS will host a policy forum to gather citizen feedback.

1. Topic: Digital Government Innovation and Citizen Engagement
2. Date: April 10, 2026 (Friday), 15:00-17:00
3. Venue: Online (Zoom) / Offline (Government Complex Sejong)
4. Registration: MOIS website > Citizen Participation > Forum Registration',
 'Event', 'Michael Torres', TRUE, 423, '2026-03-15 11:00:00', '2026-03-15 11:00:00'),

('Civil Service Examination Schedule Change',
 'The 2026 Grade 9 National Civil Service Open Competitive Examination schedule has been updated.

- Previous date: April 8, 2026 (Saturday)
- New date: April 15, 2026 (Saturday)
- Reason: Facility scheduling conflict at examination venues

We ask for the understanding of all candidates.',
 'Recruitment', 'Sarah Mitchell', TRUE, 3156, '2026-03-01 09:30:00', '2026-03-01 09:30:00'),

('Government Complex Parking Policy Update',
 'Starting April, the Government Complex parking policy will be updated.

1. External vehicles: Advance reservation required
2. Official vehicles: Existing passes remain valid
3. Citizen visitors: Temporary passes issued at 1st floor information desk

For inquiries, contact Facilities Management Division (044-205-1234).',
 'Facilities', 'Emily Watson', TRUE, 198, '2026-03-18 15:30:00', '2026-03-18 15:30:00'),

('2026 First Half Information Security Audit Results',
 'The results of the 2026 first-half information security audit are as follows:

- Audit period: 2026.02.01 ~ 2026.02.28
- Scope: All departmental workstations and servers
- Key findings:
  1. 42 accounts with unchanged passwords
  2. 15 instances of unauthorized software installation
  3. 8 workstations without USB security software

Affected departments must complete remediation by end of March.',
 'Security', 'David Chen', TRUE, 956, '2026-03-10 09:00:00', '2026-03-10 09:00:00'),

('MOIS Organizational Restructuring Notice',
 'Effective April 1, 2026, the following organizational changes will take effect:

- New: Digital Safety Division
- Merger: Disaster Management Office + Safety Policy Office -> Disaster and Safety Management Bureau
- Dissolved: Regional Development Division (transferred to Local Government Academy)

Detailed personnel orders will be announced separately.',
 'Personnel', 'Daniel Harper', TRUE, 1287, '2026-03-22 10:00:00', '2026-03-22 10:00:00'),

('2026 Valdoria E-Government Innovation Roadmap',
 'MOIS has established and published the 2026 E-Government Innovation Roadmap.

Key initiatives:
1. AI-powered complaint auto-classification system enhancement
2. Cloud-native government system transition
3. Zero Trust security model adoption
4. Digital identity verification framework development

Please refer to the attached document for details.',
 'Policy', 'Emily Watson', TRUE, 2104, '2026-03-25 14:00:00', '2026-03-25 14:00:00'),

('Citizen Service Improvement Announcement',
 'The Gov24 citizen service has been improved.

Major updates:
1. AI assistant consultation feature added during complaint filing
2. Real-time complaint status notifications (SMS/Email)
3. Attachment upload size increased (10MB -> 50MB)

We look forward to your continued use of our services.',
 'Service', 'Michael Torres', TRUE, 567, '2026-03-24 09:30:00', '2026-03-24 09:30:00'),

-- Non-public notices (admin-only)
('INTERNAL: Database Migration Technical Notes',
 'Technical details for the upcoming database migration:

- Migration target: PostgreSQL 15 cluster on 192.168.92.208
- Service account: portal_app (mois_portal database)
- Backup window: Pre-migration full backup at 20:00
- Rollback plan: Restore from pg_dump if migration fails

Contact IT Management Office for questions.',
 'Internal', 'Daniel Harper', FALSE, 45, '2026-03-26 09:00:00', '2026-03-26 09:00:00'),

('INTERNAL: Q2 Budget Allocation Draft',
 'Draft budget allocation for Q2 2026:

- Cloud infrastructure: 450,000,000 VCR
- Security tools renewal: 120,000,000 VCR
- Staff training: 35,000,000 VCR
- Contractor support: 280,000,000 VCR

This document is for internal review only. Do not distribute.',
 'Internal', 'Daniel Harper', FALSE, 23, '2026-03-27 11:00:00', '2026-03-27 11:00:00');

-- ----- Inquiries -----
INSERT INTO inquiries (tracking_number, subject, description, status, department, submitter_name, submitter_email, submitted_at, updated_at) VALUES
('INQ-20260315-0001', 'E-Government Login Error',
 'I am receiving an "Authentication Certificate Error" when trying to log into the Gov24 service. My certificate is valid but the error persists. Please investigate.',
 'Resolved', 'IT Support Division', 'James Wilson', 'j.wilson@vmail.vd', '2026-03-15 10:20:00', '2026-03-16 14:30:00'),

('INQ-20260317-0002', 'Personal Data Access Request Inquiry',
 'I would like to view my personal data held by MOIS. Please provide the procedure for making a data access request.',
 'Resolved', 'Privacy Protection Office', 'Linda Park', 'l.park@vmail.vd', '2026-03-17 09:30:00', '2026-03-18 11:00:00'),

('INQ-20260320-0003', 'Complaint Processing Delay',
 'The complaint I filed on March 5 (Reference: COMP-2026-0234) has not been processed yet. Please provide a status update.',
 'In Progress', 'Complaint Processing Division', 'Robert Chang', 'r.chang@vmail.vd', '2026-03-20 16:45:00', '2026-03-20 16:45:00'),

('INQ-20260325-0004', 'Government Subsidy Application Process',
 'Please provide information on how to apply for the 2026 small business support subsidy, including eligibility requirements.',
 'Received', 'External Affairs Division', 'Amy Lee', 'a.lee@vmail.vd', '2026-03-25 08:00:00', '2026-03-25 08:00:00'),

('INQ-20260311-0005', 'Civil Service Exam Score Unavailable',
 'I am trying to check my 2025 second-half civil service exam scores but getting a "No results found" message. I have my exam admission ticket as proof of registration.',
 'Resolved', 'Personnel Division', 'Kevin Yoo', 'k.yoo@vmail.vd', '2026-03-11 14:00:00', '2026-03-12 15:00:00'),

('INQ-20260322-0006', 'Website Accessibility Issue',
 'The MOIS portal website has poor contrast ratio on several pages, making it difficult for visually impaired users. The navigation menu is also not properly accessible via screen readers.',
 'In Progress', 'IT Planning Division', 'Susan Oh', 's.oh@vmail.vd', '2026-03-22 10:15:00', '2026-03-23 09:00:00'),

('INQ-20260326-0007', 'Document Certification Request',
 'I need a certified copy of my complaint resolution document (COMP-2025-1847) for legal proceedings. How can I request this?',
 'Received', 'General Affairs Division', 'Thomas Shin', 't.shin@vmail.vd', '2026-03-26 14:00:00', '2026-03-26 14:00:00'),

('INQ-20260327-0008', 'Data Breach Notification Request',
 'I received an email claiming to be from MOIS asking me to verify my identity. I suspect this may be a phishing attempt. Can you confirm whether MOIS sent this communication?',
 'Received', 'Information Security Division', 'Diana Han', 'd.han@vmail.vd', '2026-03-27 08:30:00', '2026-03-27 08:30:00');
```

### 3.2 Write `assets/08_DB서버/sql/11_agency_db_seed.sql`

- [ ] Write file: `assets/08_DB서버/sql/11_agency_db_seed.sql`

Uses English names from worldbuilding for key personnel. Departments use English names.

```sql
-- =============================================================
-- 11_agency_db_seed.sql -- Internal Business Portal Seed Data
-- Asset 08: DB Server (192.168.92.208)
-- Database: agency_db
-- =============================================================

-- ----- Departments -----
INSERT INTO departments (dept_code, dept_name, parent_dept_id, floor_location, phone_ext) VALUES
('PLAN',     'Planning & Coordination Office',       NULL, '6F',  '1100'),
('POLICY',   'Policy Planning Division',             1,    '6F',  '1110'),
('BUDGET',   'Budget Management Office',             1,    '6F',  '1120'),
('DIG',      'Digital Government Bureau',            NULL, '5F',  '2100'),
('DIGPLAN',  'Digital Government Planning Division', 4,    '5F',  '2110'),
('INFOSEC',  'Information Security Division',        4,    '5F',  '2120'),
('INFOPLAN', 'Information Planning Office',          4,    '5F',  '2130'),
('SAFETY',   'Disaster & Safety Management Bureau',  NULL, '4F',  '3100'),
('DISAST',   'Disaster Response Division',           8,    '4F',  '3110'),
('FIRESAF',  'Fire Safety Division',                 8,    '4F',  '3120'),
('CIVIL',    'Complaint Processing Division',        NULL, '3F',  '4100'),
('PRIVACY',  'Privacy Protection Office',            NULL, '3F',  '4200'),
('HR',       'Human Resources Division',             NULL, '7F',  '5100'),
('IT',       'IT Management Office',                 4,    '5F',  '2140'),
('FACILITY', 'Facilities Management Division',       NULL, '1F',  '6100');

-- ----- Employees -----
INSERT INTO employees (emp_number, full_name, email, phone, dept_id, position_title, role_title, hire_date, ad_username, password_hash, is_active) VALUES
('MOI-2018-0042', 'Daniel Harper',   'daniel.harper@mois.valdoria.gov',    '044-205-1100', 1,  'Director',         'Planning Office Director',     '2018-03-02', 'admin_harper',     crypt('Mois2026!Harper', gen_salt('bf')),  TRUE),
('MOI-2019-0087', 'Olivia Bennett',  'olivia.bennett@mois.valdoria.gov',   '044-205-1110', 2,  'Deputy Director',  'Policy Planning Chief',        '2019-05-15', 'user_obennett',    crypt('Mois2026!Bennett', gen_salt('bf')), TRUE),
('MOI-2020-0103', 'Nathan Brooks',   'nathan.brooks@mois.valdoria.gov',    '044-205-1120', 3,  'Deputy Director',  'Budget Manager',               '2020-01-06', 'user_nbrooks',     crypt('Mois2026!Brooks', gen_salt('bf')),  TRUE),
('MOI-2017-0031', 'Emily Watson',    'emily.watson@mois.valdoria.gov',     '044-205-2100', 4,  'Senior Director',  'Digital Government Director',  '2017-09-01', 'user_watson',      crypt('Mois2026!Watson', gen_salt('bf')),  TRUE),
('MOI-2021-0156', 'Michael Torres',  'michael.torres@mois.valdoria.gov',   '044-205-2110', 5,  'Staff',            NULL,                           '2021-03-15', 'user_torres',      crypt('Mois2026!Torres', gen_salt('bf')),  TRUE),
('MOI-2019-0092', 'David Chen',      'david.chen@mois.valdoria.gov',       '044-205-2120', 6,  'Deputy Director',  'InfoSec Division Chief',       '2019-07-22', 'user_chen',        crypt('Mois2026!Chen', gen_salt('bf')),    TRUE),
('MOI-2020-0115', 'Rachel Kim',      'rachel.kim@mois.valdoria.gov',       '044-205-2130', 7,  'Deputy Director',  'Information Planning Chief',   '2020-04-01', 'user_rkim',        crypt('Mois2026!Kim', gen_salt('bf')),     TRUE),
('MOI-2016-0015', 'Andrew Lawson',   'andrew.lawson@mois.valdoria.gov',    '044-205-3100', 8,  'Senior Director',  'Disaster Bureau Director',    '2016-06-10', 'user_alawson',     crypt('Mois2026!Lawson', gen_salt('bf')),  TRUE),
('MOI-2022-0201', 'Jessica Park',    'jessica.park@mois.valdoria.gov',     '044-205-3110', 9,  'Staff',            NULL,                           '2022-01-03', 'user_jpark',       crypt('Mois2026!JePark', gen_salt('bf')),  TRUE),
('MOI-2021-0178', 'Brandon Lee',     'brandon.lee@mois.valdoria.gov',      '044-205-3120', 10, 'Staff',            NULL,                           '2021-09-01', 'user_blee',        crypt('Mois2026!BLee', gen_salt('bf')),    TRUE),
('MOI-2018-0055', 'Sarah Mitchell',  'sarah.mitchell@mois.valdoria.gov',   '044-205-4100', 11, 'Deputy Director',  'Complaint Division Chief',    '2018-11-15', 'user_mitchell',    crypt('Mois2026!Mitchell', gen_salt('bf')),TRUE),
('MOI-2019-0099', 'Christopher Hall','christopher.hall@mois.valdoria.gov',  '044-205-4200', 12, 'Deputy Director',  'Privacy Officer',             '2019-02-18', 'user_chall',       crypt('Mois2026!Hall', gen_salt('bf')),    TRUE),
('MOI-2023-0245', 'Kevin Yoo',       'kevin.yoo@mois.valdoria.gov',        '044-205-5100', 13, 'Staff',            NULL,                           '2023-03-02', 'user_kyoo',        crypt('Mois2026!Yoo', gen_salt('bf')),     TRUE),
('MOI-2020-0120', 'Amanda Liu',      'amanda.liu@mois.valdoria.gov',       '044-205-2140', 14, 'Deputy Director',  'IT Management Chief',         '2020-06-01', 'user_aliu',        crypt('Mois2026!Liu', gen_salt('bf')),     TRUE),
('MOI-2022-0210', 'Jason Kang',      'jason.kang@mois.valdoria.gov',       '044-205-2141', 14, 'Staff',            NULL,                           '2022-07-15', 'user_jkang',       crypt('Mois2026!Kang', gen_salt('bf')),    TRUE),
('MOI-2024-0301', 'Michelle Cho',    'michelle.cho@mois.valdoria.gov',     '044-205-2112', 5,  'Staff',            NULL,                           '2024-01-08', 'user_mcho',        crypt('Mois2026!MCho', gen_salt('bf')),    TRUE),
('MOI-2023-0260', 'Eric Song',       'eric.song@mois.valdoria.gov',        '044-205-3111', 9,  'Staff',            NULL,                           '2023-09-01', 'user_esong',       crypt('Mois2026!Song', gen_salt('bf')),    TRUE),
('MOI-2021-0165', 'Victoria Yoon',   'victoria.yoon@mois.valdoria.gov',    '044-205-4101', 11, 'Staff',            NULL,                           '2021-05-17', 'user_vyoon',       crypt('Mois2026!VYoon', gen_salt('bf')),   TRUE),
('MOI-2025-0350', 'Tyler Hwang',     'tyler.hwang@mois.valdoria.gov',      '044-205-6100', 15, 'Staff',            NULL,                           '2025-03-03', 'user_thwang',      crypt('Mois2026!Hwang', gen_salt('bf')),   TRUE);

-- Department head mapping
UPDATE departments SET head_employee_id = 1  WHERE dept_code = 'PLAN';
UPDATE departments SET head_employee_id = 2  WHERE dept_code = 'POLICY';
UPDATE departments SET head_employee_id = 3  WHERE dept_code = 'BUDGET';
UPDATE departments SET head_employee_id = 4  WHERE dept_code = 'DIG';
UPDATE departments SET head_employee_id = 7  WHERE dept_code = 'INFOPLAN';
UPDATE departments SET head_employee_id = 6  WHERE dept_code = 'INFOSEC';
UPDATE departments SET head_employee_id = 8  WHERE dept_code = 'SAFETY';
UPDATE departments SET head_employee_id = 11 WHERE dept_code = 'CIVIL';
UPDATE departments SET head_employee_id = 12 WHERE dept_code = 'PRIVACY';
UPDATE departments SET head_employee_id = 14 WHERE dept_code = 'IT';

-- ----- Approvals -----
INSERT INTO approvals (doc_number, title, content, doc_type, drafter_id, current_step, total_steps, status, approved_by, created_at) VALUES
('APPR-2026-0001', 'Q1 2026 Information Security Training Plan',
 '1. Objective: Strengthen all-staff information security capabilities
2. Target: All MOIS employees (412 personnel)
3. Period: 2026.01.15 ~ 2026.02.28
4. Method: Online training + offline seminar
5. Budget: 12,500,000 VCR',
 'General', 6, 3, 3, 'Approved',
 '["David Chen (Drafter)", "Emily Watson (Review)", "Daniel Harper (Approval)"]',
 '2026-01-05 09:00:00+00'),

('APPR-2026-0012', 'E-Government Cloud Migration Project Plan',
 '1. Project: 2026 E-Government Cloud-Native Transition
2. Budget: 4,500,000,000 VCR
3. Period: 2026.04 ~ 2026.12
4. Scope: 22 major information systems
5. Structure: PMO + Cloud specialist vendor',
 'General', 7, 2, 3, 'In Progress',
 '["Rachel Kim (Drafter)", "Emily Watson (Under Review)"]',
 '2026-02-10 10:30:00+00'),

('APPR-2026-0023', 'Complaint System AI Enhancement Contract Request',
 '1. Service: Complaint Auto-Classification AI Model Enhancement
2. Budget: 850,000,000 VCR
3. Period: 2026.05 ~ 2026.10
4. Procurement: Restricted competitive bidding',
 'Expenditure', 11, 3, 3, 'Approved',
 '["Sarah Mitchell (Drafter)", "Daniel Harper (Review)", "Emily Watson (Approval)"]',
 '2026-02-20 14:00:00+00'),

('APPR-2026-0034', 'H1 2026 Overseas Trip Application -- Digital Government Benchmarking',
 '1. Destination: Tallinn, Estonia
2. Period: 2026.05.10 ~ 2026.05.17 (8 days)
3. Objective: X-Road e-Government platform benchmarking
4. Travelers: Michael Torres (Staff), Michelle Cho (Staff)
5. Budget: 8,200,000 VCR',
 'Travel', 5, 1, 3, 'Draft',
 '["Michael Torres (Drafter)"]',
 '2026-03-15 11:00:00+00'),

('APPR-2026-0045', 'Emergency Vulnerability Patch Request',
 '1. Urgency: High
2. Target: MOIS External Portal Server
3. Issue: Log4j-like vulnerability pattern detected (CVE-2021-44228 variant)
4. Action: Immediate patching and monitoring enhancement
5. Impact: All externally accessible services',
 'General', 6, 3, 3, 'Approved',
 '["David Chen (Drafter)", "Emily Watson (Emergency Review)", "Daniel Harper (Emergency Approval)"]',
 '2026-03-22 08:30:00+00'),

('APPR-2026-0056', 'Civil Service Exam Support Plan 2026',
 '1. Exam: 2026 Grade 9 National Civil Service Open Competitive Exam
2. Date: April 15, 2026 (Saturday)
3. Support: Venue inspection, network infrastructure support
4. Budget: 3,200,000 VCR',
 'General', 13, 1, 3, 'Draft',
 '["Kevin Yoo (Drafter)"]',
 '2026-03-24 09:00:00+00');

-- ----- Work Requests -----
INSERT INTO work_requests (request_number, title, description, requester_id, assignee_id, priority, status, due_date, created_at) VALUES
('WR-2026-0001', 'External Portal SSL Certificate Renewal',
 'The SSL certificate for the external portal (mois.valdoria.gov) expires on April 15, 2026. Please arrange renewal.',
 7, 14, 'High', 'Completed', '2026-04-10',
 '2026-03-01 10:00:00+00'),

('WR-2026-0002', 'Internal Portal Search Bug Fix',
 'The internal business portal search function returns no results when searching in certain languages. Please investigate and fix.
Reproduction: Type "approval" in search bar -> No results',
 2, 15, 'Urgent', 'In Progress', '2026-03-25',
 '2026-03-20 14:30:00+00'),

('WR-2026-0003', 'DB Server Backup Script Audit',
 'During quarterly inspection, DB backup files were found to not be generating properly. Please audit the backup script and cron configuration.',
 6, 14, 'High', 'Requested', '2026-03-28',
 '2026-03-23 09:00:00+00'),

('WR-2026-0004', 'Complaint System Performance Optimization',
 'Complaint attachment PDF conversion is averaging 45 seconds. Please evaluate server resource scaling or processing logic optimization.',
 11, 5, 'Normal', 'Accepted', '2026-04-15',
 '2026-03-24 11:00:00+00'),

('WR-2026-0005', 'New Employee AD Account Creation Request',
 'Please create AD accounts for 3 new employees starting April 1, 2026:
1. Grace Cho (Digital Government Planning Division)
2. Marcus Yang (Disaster Response Division)
3. Sophia Lim (Complaint Processing Division)',
 13, 14, 'Normal', 'Requested', '2026-03-30',
 '2026-03-25 10:00:00+00');
```

### 3.3 Write `assets/08_DB서버/sql/12_complaint_db_seed.sql`

- [ ] Write file: `assets/08_DB서버/sql/12_complaint_db_seed.sql`

```sql
-- =============================================================
-- 12_complaint_db_seed.sql -- Complaint Processing Seed Data
-- Asset 08: DB Server (192.168.92.208)
-- Database: complaint_db
-- =============================================================

-- ----- Complaints -----
INSERT INTO complaints (complaint_number, applicant_name, applicant_email, applicant_phone, applicant_addr, category, title, content, status, priority, assigned_dept, assigned_to, response, responded_at, created_at) VALUES
('COMP-2026-0001', 'James Wilson', 'j.wilson@vmail.vd', '010-2345-6789', '15 Maple Street, Elaris District',
 'Public Facilities', 'Broken Street Lights on Maple Street',
 'Two street lights near 15 Maple Street have been non-functional for two weeks. This creates a safety hazard for pedestrians at night. Please arrange urgent repairs.',
 'Resolved', 'Normal', 'Facilities Management Division', 'Tyler Hwang',
 'Dear Mr. Wilson,

Thank you for your report. The Elaris District Facilities Management team has been dispatched and completed repairs on March 20, 2026.

Best regards,
Facilities Management Division',
 '2026-03-20 15:00:00+00',
 '2026-03-10 08:30:00+00'),

('COMP-2026-0002', 'Linda Park', 'l.park@vmail.vd', '010-3456-7890', '411 Central Avenue, Sejong District',
 'Roads/Traffic', 'Pothole on Central Avenue near Government Complex',
 'A pothole approximately 30cm in diameter has appeared on Central Avenue near Government Complex Building 6. This poses a risk to vehicles. Please arrange emergency repair.',
 'In Progress', 'Urgent', 'Facilities Management Division', 'Tyler Hwang',
 NULL, NULL,
 '2026-03-15 09:00:00+00'),

('COMP-2026-0003', 'Robert Chang', 'r.chang@vmail.vd', '010-4567-8901', '209 Jongno Road, Capital City',
 'Environment', 'Air Quality Improvement Request for Capital District',
 'Air quality index in the Capital District consistently shows "Poor" levels. Request implementation of effective measures such as traffic restrictions during peak commute hours.',
 'Under Review', 'Normal', 'Disaster & Safety Management Bureau', 'Jessica Park',
 NULL, NULL,
 '2026-03-12 14:20:00+00'),

('COMP-2026-0004', 'Amy Lee', 'a.lee@vmail.vd', '010-5678-9012', '1 Expo Road, Daehan District',
 'Welfare', 'Request to Expand Disability Support Services',
 'The current monthly hours for disability activity support services are insufficient. For severely disabled individuals, I propose increasing from the current 480 hours per month to a minimum of 600 hours.',
 'Resolved', 'Normal', 'Complaint Processing Division', 'Victoria Yoon',
 'Dear Ms. Lee,

The disability activity support service hours expansion falls under the jurisdiction of the Ministry of Health and Welfare. Your complaint has been transferred. Reference number: MW-2026-0456.

Ministry of Health helpline: 129',
 '2026-03-18 10:00:00+00',
 '2026-03-14 11:00:00+00'),

('COMP-2026-0005', 'Kevin Yoo', 'k.yoo2@vmail.vd', '010-6789-0123', '100 Innovation Road, Suwon District',
 'Technical', 'Gov24 Mobile App Crash on File Upload',
 'The Gov24 mobile app (Android) force-closes when uploading attachments during complaint filing.

- Device: Galaxy S24
- OS: Android 15
- App version: 4.2.1
- Reproduction rate: 100%',
 'In Progress', 'High', 'Digital Government Planning Division', 'Michael Torres',
 NULL, NULL,
 '2026-03-16 10:30:00+00'),

('COMP-2026-0006', 'Susan Oh', 's.oh@vmail.vd', '010-7890-1234', '48 Centum Road, Haeun District',
 'Public Facilities', 'Noise Complaint Near Haeun Beach Construction Site',
 'The construction site near Haeun Beach continues work past 22:00, causing significant noise disturbance. Request enforcement of nighttime construction restrictions.',
 'Received', 'Normal', NULL, NULL,
 NULL, NULL,
 '2026-03-22 22:30:00+00'),

('COMP-2026-0007', 'Thomas Shin', 't.shin@vmail.vd', '010-8901-2345', '55 Harbor Road, Port Valdis',
 'Technical', 'Gov24 Website Accessibility Issues',
 'The MOIS portal has poor contrast ratio on several pages, making it difficult for visually impaired users. The navigation menu is not accessible via screen readers. This violates accessibility standards.',
 'Under Review', 'Normal', 'IT Management Office', 'Amanda Liu',
 NULL, NULL,
 '2026-03-23 09:00:00+00'),

('COMP-2026-0008', 'Diana Han', 'd.han@vmail.vd', '010-9012-3456', '22 University Road, Academic District',
 'General', 'Suspicious Email Claiming to Be from MOIS',
 'I received an email from mois-security@valdoria-gov.net asking me to verify my identity by clicking a link. The email address does not match the official domain. Is this a legitimate communication?',
 'In Progress', 'High', 'Information Security Division', 'David Chen',
 NULL, NULL,
 '2026-03-27 08:30:00+00');

-- ----- Processing Logs -----
INSERT INTO processing_logs (complaint_id, action, actor_name, actor_dept, description, previous_status, new_status, created_at) VALUES
(1, 'Received',  'System',        'Auto',                       'Complaint received via online portal',     NULL,          'Received',    '2026-03-10 08:30:00+00'),
(1, 'Assigned',  'Sarah Mitchell','Complaint Processing Div.',  'Assigned to Facilities Management',       'Received',    'In Progress', '2026-03-10 10:00:00+00'),
(1, 'Resolved',  'Tyler Hwang',   'Facilities Management Div.', 'Street lights repaired on site',          'In Progress', 'Resolved',    '2026-03-20 15:00:00+00'),
(2, 'Received',  'System',        'Auto',                       'Complaint received via online portal',     NULL,          'Received',    '2026-03-15 09:00:00+00'),
(2, 'Assigned',  'Sarah Mitchell','Complaint Processing Div.',  'Urgent: assigned to Facilities',          'Received',    'In Progress', '2026-03-15 09:30:00+00'),
(4, 'Received',  'System',        'Auto',                       'Complaint received via online portal',     NULL,          'Received',    '2026-03-14 11:00:00+00'),
(4, 'Transferred','Victoria Yoon','Complaint Processing Div.',  'Transferred to Ministry of Health',       'Received',    'Resolved',    '2026-03-18 10:00:00+00'),
(5, 'Received',  'System',        'Auto',                       'Complaint received via mobile app',        NULL,          'Received',    '2026-03-16 10:30:00+00'),
(5, 'Assigned',  'Sarah Mitchell','Complaint Processing Div.',  'Assigned to Digital Government team',     'Received',    'In Progress', '2026-03-16 14:00:00+00'),
(8, 'Received',  'System',        'Auto',                       'Complaint received via online portal',     NULL,          'Received',    '2026-03-27 08:30:00+00'),
(8, 'Assigned',  'Sarah Mitchell','Complaint Processing Div.',  'Potential phishing - assigned to InfoSec','Received',    'In Progress', '2026-03-27 09:00:00+00');
```

### 3.4 Write `assets/08_DB서버/scripts/backup.sh`

- [ ] Write file: `assets/08_DB서버/scripts/backup.sh`

```bash
#!/bin/bash
# =============================================================
# PostgreSQL Daily Backup Script
# Asset 08: DB Server (192.168.92.208)
# Usage: Run via cron as postgres user
# Cron: 0 2 * * * /opt/db-scripts/backup.sh
# =============================================================

set -euo pipefail

BACKUP_DIR="/var/backups/postgresql/daily"
DATE=$(date +%Y%m%d_%H%M%S)
RETENTION_DAYS=30
DATABASES=("mois_portal" "agency_db" "complaint_db")

echo "[$(date)] Starting daily backup..."

for DB in "${DATABASES[@]}"; do
    DUMP_FILE="${BACKUP_DIR}/${DB}_${DATE}.sql.gz"
    echo "  Backing up ${DB}..."
    pg_dump -U postgres "${DB}" | gzip > "${DUMP_FILE}"
    echo "  -> ${DUMP_FILE} ($(du -h "${DUMP_FILE}" | cut -f1))"
done

# Remove backups older than retention period
echo "  Cleaning up backups older than ${RETENTION_DAYS} days..."
find "${BACKUP_DIR}" -name "*.sql.gz" -mtime +"${RETENTION_DAYS}" -delete

echo "[$(date)] Daily backup complete."
```

### 3.5 Write `assets/08_DB서버/scripts/monitor.sh`

- [ ] Write file: `assets/08_DB서버/scripts/monitor.sh`

```bash
#!/bin/bash
# =============================================================
# PostgreSQL Simple Monitoring Script
# Asset 08: DB Server (192.168.92.208)
# Usage: bash /opt/db-scripts/monitor.sh
# =============================================================

echo "===== PostgreSQL Server Status ====="
echo "Date: $(date)"
echo ""

echo "--- Service Status ---"
systemctl is-active postgresql && echo "PostgreSQL: RUNNING" || echo "PostgreSQL: STOPPED"
echo ""

echo "--- Active Connections ---"
sudo -u postgres psql -t -c "
SELECT datname, usename, client_addr, state, query
FROM pg_stat_activity
WHERE state IS NOT NULL AND pid != pg_backend_pid()
ORDER BY backend_start DESC
LIMIT 20;"
echo ""

echo "--- Database Sizes ---"
sudo -u postgres psql -t -c "
SELECT datname, pg_size_pretty(pg_database_size(datname)) as size
FROM pg_database
WHERE datistemplate = false
ORDER BY pg_database_size(datname) DESC;"
echo ""

echo "--- SUPERUSER Accounts (Security Check) ---"
sudo -u postgres psql -t -c "
SELECT rolname, rolsuper, rolcanlogin
FROM pg_roles
WHERE rolsuper = true;"
echo ""

echo "--- Recent Log Entries ---"
PG_VERSION=$(pg_config --version | grep -oP '\d+' | head -1)
tail -20 "/var/log/postgresql/postgresql-${PG_VERSION}-main.log" 2>/dev/null || echo "Log file not found"
echo ""
echo "===== End of Report ====="
```

---

## Task 4: Asset 01 -- FastAPI Backend

### 4.1 Create directory structure

- [ ] Create `assets/01_외부포털서버/` with subdirectories

```bash
mkdir -p assets/01_외부포털서버/{certs,src/{backend/routers,frontend/{app/{notices,search,inquiry,login},components,lib},config/{nginx,systemd}}}
```

### 4.2 Write `assets/01_외부포털서버/.env.example`

- [ ] Write file: `assets/01_외부포털서버/.env.example`

```bash
# =============================================================
# External Portal Server (192.168.92.201) Environment Variables
# Copy to .env and adjust values as needed
# =============================================================

# Application
APP_NAME="MOIS Portal"
APP_VERSION=1.2.0
ENVIRONMENT=production
DEBUG=false

# Database (PostgreSQL - remote)
DB_HOST=192.168.92.208
DB_PORT=5432
DB_NAME=mois_portal
DB_USER=portal_app
DB_PASSWORD=P0rtal#DB@2026!

# JWT Authentication
JWT_SECRET=valdoria-mois-jwt-secret-key-2026
JWT_ALGORITHM=HS256
JWT_EXPIRE_MINUTES=60

# CORS
ALLOWED_ORIGINS=["https://www.mois.valdoria.gov"]

# Logging
LOG_LEVEL=INFO
LOG_FILE=/var/log/mois-portal/app.log

# Frontend
NEXT_PUBLIC_API_URL=https://www.mois.valdoria.gov
```

### 4.3 Write `assets/01_외부포털서버/src/backend/config.py`

- [ ] Write file: `assets/01_외부포털서버/src/backend/config.py`

```python
"""
Application Configuration
Asset 01: External Portal Server (192.168.92.201)
"""

import os
from urllib.parse import quote_plus
from dotenv import load_dotenv

load_dotenv()


class Settings:
    APP_NAME: str = os.getenv("APP_NAME", "MOIS Portal")
    VERSION: str = os.getenv("APP_VERSION", "1.2.0")
    ENVIRONMENT: str = os.getenv("ENVIRONMENT", "production")
    DEBUG: bool = os.getenv("DEBUG", "false").lower() == "true"

    # Database
    DB_HOST: str = os.getenv("DB_HOST", "192.168.92.208")
    DB_PORT: int = int(os.getenv("DB_PORT", "5432"))
    DB_NAME: str = os.getenv("DB_NAME", "mois_portal")
    DB_USER: str = os.getenv("DB_USER", "portal_app")
    DB_PASSWORD: str = os.getenv("DB_PASSWORD", "P0rtal#DB@2026!")

    # JWT
    JWT_SECRET: str = os.getenv("JWT_SECRET", "valdoria-mois-jwt-secret-key-2026")
    JWT_ALGORITHM: str = os.getenv("JWT_ALGORITHM", "HS256")
    JWT_EXPIRE_MINUTES: int = int(os.getenv("JWT_EXPIRE_MINUTES", "60"))

    # CORS
    ALLOWED_ORIGINS: list = ["https://www.mois.valdoria.gov"]

    # Logging
    LOG_LEVEL: str = os.getenv("LOG_LEVEL", "INFO")
    LOG_FILE: str = os.getenv("LOG_FILE", "/var/log/mois-portal/app.log")

    @property
    def DATABASE_URL(self) -> str:
        # CLAUDE.md: URL-encode password with quote_plus()
        password = quote_plus(self.DB_PASSWORD)
        return f"postgresql+asyncpg://{self.DB_USER}:{password}@{self.DB_HOST}:{self.DB_PORT}/{self.DB_NAME}"


settings = Settings()
```

### 4.4 Write `assets/01_외부포털서버/src/backend/database.py`

- [ ] Write file: `assets/01_외부포털서버/src/backend/database.py`

```python
"""
Database Connection (asyncpg direct, no databases library)
Asset 01: External Portal Server (192.168.92.201)
"""

import asyncpg
from config import settings
from urllib.parse import quote_plus


_pool: asyncpg.Pool = None


async def get_pool() -> asyncpg.Pool:
    global _pool
    if _pool is None:
        # CLAUDE.md: URL-encode password with quote_plus()
        password = quote_plus(settings.DB_PASSWORD)
        dsn = f"postgresql://{settings.DB_USER}:{password}@{settings.DB_HOST}:{settings.DB_PORT}/{settings.DB_NAME}"
        _pool = await asyncpg.create_pool(
            dsn=dsn,
            min_size=2,
            max_size=10,
        )
    return _pool


async def close_pool():
    global _pool
    if _pool is not None:
        await _pool.close()
        _pool = None


async def get_db():
    """Dependency: yields an asyncpg connection from the pool."""
    pool = await get_pool()
    async with pool.acquire() as conn:
        yield conn
```

### 4.5 Write `assets/01_외부포털서버/src/backend/requirements.txt`

- [ ] Write file: `assets/01_외부포털서버/src/backend/requirements.txt`

```
fastapi==0.104.1
uvicorn[standard]==0.24.0
asyncpg==0.29.0
python-dotenv==1.0.0
python-jose[cryptography]==3.3.0
passlib[bcrypt]==1.7.4
pydantic==2.5.2
httpx==0.25.2
```

### 4.6 Write `assets/01_외부포털서버/src/backend/routers/__init__.py`

- [ ] Write file: `assets/01_외부포털서버/src/backend/routers/__init__.py`

```python
```

### 4.7 Write `assets/01_외부포털서버/src/backend/routers/notices.py`

- [ ] Write file: `assets/01_외부포털서버/src/backend/routers/notices.py`

```python
"""
Notice Board API Router
Asset 01: External Portal Server (192.168.92.201)
"""

from fastapi import APIRouter, Query, Depends, HTTPException
from database import get_db

router = APIRouter(prefix="/api", tags=["notices"])


@router.get("/notices")
async def list_notices(
    page: int = Query(1, ge=1),
    size: int = Query(20, ge=1, le=100),
    category: str = Query(None),
    conn=Depends(get_db),
):
    """List public notices with pagination."""
    offset = (page - 1) * size

    # Build query
    where_clause = "WHERE is_public = true"
    params = []
    param_idx = 1

    if category:
        where_clause += f" AND category = ${param_idx}"
        params.append(category)
        param_idx += 1

    # Count query (no LIMIT/OFFSET per CLAUDE.md)
    count_query = f"SELECT COUNT(*) FROM notices {where_clause}"
    total = await conn.fetchval(count_query, *params)

    # Data query
    data_query = f"""
        SELECT id, title, category, author, view_count, created_at
        FROM notices
        {where_clause}
        ORDER BY created_at DESC
        LIMIT ${param_idx} OFFSET ${param_idx + 1}
    """
    params.extend([size, offset])
    rows = await conn.fetch(data_query, *params)

    return {
        "total": total,
        "page": page,
        "size": size,
        "items": [dict(r) for r in rows],
    }


@router.get("/notices/{notice_id}")
async def get_notice(notice_id: int, conn=Depends(get_db)):
    """Get notice detail and increment view count."""
    row = await conn.fetchrow(
        """SELECT id, title, content, category, author, is_public,
                  view_count, created_at, updated_at
           FROM notices WHERE id = $1""",
        notice_id,
    )
    if not row:
        raise HTTPException(status_code=404, detail="Notice not found")

    if not row["is_public"]:
        raise HTTPException(status_code=404, detail="Notice not found")

    # Increment view count
    await conn.execute(
        "UPDATE notices SET view_count = view_count + 1 WHERE id = $1",
        notice_id,
    )

    result = dict(row)
    result["view_count"] += 1
    return result
```

### 4.8 Write `assets/01_외부포털서버/src/backend/routers/search.py`

- [ ] Write file: `assets/01_외부포털서버/src/backend/routers/search.py`

```python
"""
Search API Router
Asset 01: External Portal Server (192.168.92.201)

[취약점] VULN-01-03: SQL Injection in search endpoint
The user input 'q' is directly interpolated into the SQL query using f-string.
Correct implementation: use parameterized queries ($1, $2) with asyncpg.
"""

from fastapi import APIRouter, Query, Depends
from database import get_db
import logging

logger = logging.getLogger("mois-portal")
router = APIRouter(prefix="/api", tags=["search"])


@router.get("/search")
async def search(
    q: str = Query(..., description="Search keyword"),
    type: str = Query(None, description="Search type: notice or inquiry"),
    page: int = Query(1, ge=1),
    size: int = Query(20, ge=1, le=100),
    conn=Depends(get_db),
):
    """
    Integrated search endpoint.

    [취약점] VULN-01-03: SQL Injection
    User input 'q' is directly embedded in SQL via f-string.
    Correct implementation:
        await conn.fetch(
            "SELECT ... WHERE title ILIKE $1", f"%{q}%"
        )
    """
    offset = (page - 1) * size

    # [취약점] Raw f-string SQL injection
    if type == "inquiry":
        base_query = f"""
            SELECT id, 'inquiry' as type, subject as title,
                   SUBSTRING(description, 1, 200) as snippet
            FROM inquiries
            WHERE subject ILIKE '%{q}%' OR tracking_number ILIKE '%{q}%'
        """
    else:
        base_query = f"""
            SELECT id, 'notice' as type, title,
                   SUBSTRING(content, 1, 200) as snippet
            FROM notices
            WHERE (title ILIKE '%{q}%' OR content ILIKE '%{q}%')
              AND is_public = true
        """

    count_query = f"SELECT COUNT(*) FROM ({base_query}) as sub"
    data_query = f"{base_query} ORDER BY id DESC LIMIT {size} OFFSET {offset}"

    try:
        total = await conn.fetchval(count_query)
        rows = await conn.fetch(data_query)
        logger.info(f"Search query executed: q={q}, results={total}")
        return {
            "total": total,
            "query": q,
            "items": [dict(r) for r in rows],
        }
    except Exception as e:
        # [취약점] SQL error details exposed in response
        # Correct implementation: return generic error message
        logger.error(f"Search error: {str(e)}, query={q}")
        return {"error": f"Search error occurred: {str(e)}"}
```

### 4.9 Write `assets/01_외부포털서버/src/backend/routers/inquiry.py`

- [ ] Write file: `assets/01_외부포털서버/src/backend/routers/inquiry.py`

```python
"""
Inquiry Status API Router
Asset 01: External Portal Server (192.168.92.201)
"""

from fastapi import APIRouter, Depends, HTTPException
from database import get_db

router = APIRouter(prefix="/api", tags=["inquiry"])


@router.get("/inquiry/{tracking_number}")
async def get_inquiry_status(tracking_number: str, conn=Depends(get_db)):
    """Look up inquiry status by tracking number."""
    row = await conn.fetchrow(
        """SELECT tracking_number, subject, status, department,
                  submitter_name, submitted_at, updated_at
           FROM inquiries WHERE tracking_number = $1""",
        tracking_number,
    )
    if not row:
        raise HTTPException(
            status_code=404,
            detail="No inquiry found with the provided tracking number",
        )
    return dict(row)
```

### 4.10 Write `assets/01_외부포털서버/src/backend/routers/admin.py`

- [ ] Write file: `assets/01_외부포털서버/src/backend/routers/admin.py`

```python
"""
Admin API Router
Asset 01: External Portal Server (192.168.92.201)

[취약점] VULN-01-02: Missing authentication on admin endpoints.
All endpoints in this router are accessible without any authentication.
Correct implementation:
    from auth import get_current_admin_user
    router = APIRouter(
        prefix="/api/admin",
        dependencies=[Depends(get_current_admin_user)]
    )
"""

from fastapi import APIRouter, Query, Depends, HTTPException
from database import get_db
from pydantic import BaseModel
from typing import Optional

router = APIRouter(prefix="/api/admin", tags=["admin"])


class NoticeCreate(BaseModel):
    title: str
    content: str
    category: str = "General"
    is_public: bool = True


@router.get("/users")
async def list_users(conn=Depends(get_db)):
    """
    [취약점] Admin user list -- NO authentication check.
    Returns all registered portal users including emails and roles.
    """
    rows = await conn.fetch(
        "SELECT id, username, email, role, last_login, created_at FROM users ORDER BY id"
    )
    return {"users": [dict(r) for r in rows]}


@router.get("/notices")
async def admin_list_notices(
    page: int = Query(1, ge=1),
    size: int = Query(20, ge=1, le=100),
    conn=Depends(get_db),
):
    """
    [취약점] Admin notice list -- includes non-public notices, NO auth.
    """
    offset = (page - 1) * size
    total = await conn.fetchval("SELECT COUNT(*) FROM notices")
    rows = await conn.fetch(
        """SELECT id, title, category, author, is_public, view_count, created_at
           FROM notices ORDER BY created_at DESC
           LIMIT $1 OFFSET $2""",
        size,
        offset,
    )
    return {
        "total": total,
        "page": page,
        "size": size,
        "items": [dict(r) for r in rows],
    }


@router.post("/notices")
async def create_notice(notice: NoticeCreate, conn=Depends(get_db)):
    """
    [취약점] Create notice -- NO authentication required.
    Anyone can publish notices.
    """
    row = await conn.fetchrow(
        """INSERT INTO notices (title, content, category, is_public, author)
           VALUES ($1, $2, $3, $4, 'Anonymous')
           RETURNING id, title, created_at""",
        notice.title,
        notice.content,
        notice.category,
        notice.is_public,
    )
    return {"message": "Notice created", "notice": dict(row)}
```

### 4.11 Write `assets/01_외부포털서버/src/backend/routers/internal.py`

- [ ] Write file: `assets/01_외부포털서버/src/backend/routers/internal.py`

```python
"""
Internal API Router
Asset 01: External Portal Server (192.168.92.201)

[취약점] VULN-01-02: No authentication on internal endpoints.
The /config endpoint exposes database credentials in plaintext.
Correct implementation: remove this endpoint entirely, or require
admin authentication AND never expose raw credentials.
"""

from fastapi import APIRouter, Depends
from config import settings
from database import get_pool
import time

router = APIRouter(prefix="/api/internal", tags=["internal"])

_start_time = time.time()


@router.get("/config")
async def get_config():
    """
    [취약점] VULN-01-02: Internal configuration with DB credentials exposed.
    No authentication required. Password shown in plaintext.
    This is the key vulnerability that allows attackers to obtain DB credentials
    and pivot to the internal database server (192.168.92.208).
    """
    return {
        "app_name": settings.APP_NAME,
        "version": settings.VERSION,
        "environment": settings.ENVIRONMENT,
        "database": {
            "host": settings.DB_HOST,
            "port": settings.DB_PORT,
            "name": settings.DB_NAME,
            "user": settings.DB_USER,
            "password": settings.DB_PASSWORD,  # [취약점] Plaintext password exposure
        },
        "jwt_secret": settings.JWT_SECRET,  # [취약점] JWT secret exposed
        "debug_mode": settings.DEBUG,
        "allowed_origins": settings.ALLOWED_ORIGINS,
    }


@router.get("/health")
async def health_check():
    """Service health check with internal details."""
    uptime = time.time() - _start_time
    db_status = "unknown"
    try:
        pool = await get_pool()
        async with pool.acquire() as conn:
            await conn.fetchval("SELECT 1")
            db_status = "connected"
    except Exception as e:
        db_status = f"error: {str(e)}"

    return {
        "status": "healthy",
        "uptime_seconds": round(uptime, 2),
        "database": db_status,
        "version": settings.VERSION,
        "environment": settings.ENVIRONMENT,
    }
```

### 4.12 Write `assets/01_외부포털서버/src/backend/main.py`

- [ ] Write file: `assets/01_외부포털서버/src/backend/main.py`

```python
"""
MOIS External Portal API Server
Asset 01: External Portal Server (192.168.92.201)

[취약점] VULN-01-01: Swagger UI and OpenAPI spec exposed in production.
Correct implementation: set docs_url=None, redoc_url=None, openapi_url=None
"""

from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from config import settings
from database import get_pool, close_pool
from routers import notices, search, inquiry, admin, internal
import logging

# Configure logging
logging.basicConfig(
    level=getattr(logging, settings.LOG_LEVEL),
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
    handlers=[
        logging.StreamHandler(),
    ],
)

logger = logging.getLogger("mois-portal")

# Try to add file handler (may fail if log dir doesn't exist in dev)
try:
    fh = logging.FileHandler(settings.LOG_FILE)
    fh.setFormatter(logging.Formatter("%(asctime)s [%(levelname)s] %(name)s: %(message)s"))
    logger.addHandler(fh)
except (FileNotFoundError, PermissionError):
    pass


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Startup/shutdown lifecycle."""
    logger.info("MOIS Portal API starting up...")
    await get_pool()
    logger.info("Database connection pool initialized")
    yield
    logger.info("MOIS Portal API shutting down...")
    await close_pool()


# [취약점] VULN-01-01: API documentation exposed in production
# Correct implementation:
#   app = FastAPI(docs_url=None, redoc_url=None, openapi_url=None)
app = FastAPI(
    title="MOIS Portal API",
    version=settings.VERSION,
    description="Republic of Valdoria - Ministry of Interior and Safety Portal API",
    docs_url="/docs",           # [취약점] Swagger UI active
    redoc_url="/redoc",         # [취약점] ReDoc active
    openapi_url="/openapi.json",  # [취약점] OpenAPI spec exposed
    lifespan=lifespan,
)

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.ALLOWED_ORIGINS + ["http://localhost:3000"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Register routers
app.include_router(notices.router)
app.include_router(search.router)
app.include_router(inquiry.router)
app.include_router(admin.router)
app.include_router(internal.router)


@app.get("/")
async def root():
    return {
        "service": "MOIS Portal API",
        "version": settings.VERSION,
        "status": "running",
    }
```

---

## Task 5: Asset 01 -- Next.js 15 Frontend

### 5.1 Write `assets/01_외부포털서버/src/frontend/package.json`

- [ ] Write file: `assets/01_외부포털서버/src/frontend/package.json`

```json
{
  "name": "mois-portal",
  "version": "1.2.0",
  "private": true,
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start -p 3000"
  },
  "dependencies": {
    "next": "15.0.3",
    "react": "19.1.0",
    "react-dom": "19.1.0"
  },
  "devDependencies": {
    "tailwindcss": "^3.4.0",
    "postcss": "^8.4.31",
    "autoprefixer": "^10.4.16"
  }
}
```

### 5.2 Write `assets/01_외부포털서버/src/frontend/next.config.js`

- [ ] Write file: `assets/01_외부포털서버/src/frontend/next.config.js`

```javascript
/** @type {import('next').NextConfig} */
const nextConfig = {
  // App Router with RSC enabled by default (DO NOT disable)
  // [취약점] VULN-01-05: React2Shell CVE-2025-55182 requires RSC to be active
  // Next.js 15.0.3 + React 19.1.0 are vulnerable versions
  // Correct implementation: upgrade to Next.js 15.0.4+ and React 19.1.2+
  async rewrites() {
    return [
      {
        source: '/api/:path*',
        destination: 'http://127.0.0.1:8000/api/:path*',
      },
    ];
  },
};

module.exports = nextConfig;
```

### 5.3 Write `assets/01_외부포털서버/src/frontend/tailwind.config.js`

- [ ] Write file: `assets/01_외부포털서버/src/frontend/tailwind.config.js`

```javascript
/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    './app/**/*.{js,ts,jsx,tsx}',
    './components/**/*.{js,ts,jsx,tsx}',
  ],
  theme: {
    extend: {
      colors: {
        // Government-appropriate professional palette
        gov: {
          navy: '#1B2A4A',
          blue: '#2E5090',
          sky: '#4A90D9',
          light: '#E8F0FE',
          accent: '#D4A843',
          dark: '#0F1B33',
          gray: '#64748B',
          border: '#CBD5E1',
        },
      },
      fontFamily: {
        sans: ['Inter', 'Pretendard', '-apple-system', 'BlinkMacSystemFont', 'sans-serif'],
      },
    },
  },
  plugins: [],
};
```

### 5.4 Write `assets/01_외부포털서버/src/frontend/postcss.config.js`

- [ ] Write file: `assets/01_외부포털서버/src/frontend/postcss.config.js`

```javascript
module.exports = {
  plugins: {
    tailwindcss: {},
    autoprefixer: {},
  },
};
```

### 5.5 Write `assets/01_외부포털서버/src/frontend/lib/api.js`

- [ ] Write file: `assets/01_외부포털서버/src/frontend/lib/api.js`

```javascript
/**
 * API Client for MOIS Portal
 * Asset 01: External Portal Server (192.168.92.201)
 */

const API_BASE = process.env.NEXT_PUBLIC_API_URL || '';

async function fetchAPI(endpoint, options = {}) {
  const url = `${API_BASE}${endpoint}`;
  const res = await fetch(url, {
    ...options,
    headers: {
      'Content-Type': 'application/json',
      ...options.headers,
    },
    cache: 'no-store',
  });

  if (!res.ok) {
    throw new Error(`API Error: ${res.status} ${res.statusText}`);
  }

  return res.json();
}

export async function getNotices(page = 1, size = 20, category = null) {
  let url = `/api/notices?page=${page}&size=${size}`;
  if (category) url += `&category=${encodeURIComponent(category)}`;
  return fetchAPI(url);
}

export async function getNotice(id) {
  return fetchAPI(`/api/notices/${id}`);
}

export async function searchContent(query, type = null, page = 1) {
  let url = `/api/search?q=${encodeURIComponent(query)}&page=${page}`;
  if (type) url += `&type=${type}`;
  return fetchAPI(url);
}

export async function getInquiryStatus(trackingNumber) {
  return fetchAPI(`/api/inquiry/${encodeURIComponent(trackingNumber)}`);
}
```

### 5.6 Write `assets/01_외부포털서버/src/frontend/app/globals.css`

- [ ] Write file: `assets/01_외부포털서버/src/frontend/app/globals.css`

```css
@tailwind base;
@tailwind components;
@tailwind utilities;

@layer base {
  html {
    scroll-behavior: smooth;
  }
  body {
    @apply antialiased text-slate-800 bg-white;
  }
}

@layer components {
  .btn-primary {
    @apply inline-flex items-center justify-center px-5 py-2.5 text-sm font-medium text-white bg-gov-blue rounded-lg hover:bg-gov-navy transition-colors focus:outline-none focus:ring-2 focus:ring-gov-sky focus:ring-offset-2;
  }
  .btn-outline {
    @apply inline-flex items-center justify-center px-5 py-2.5 text-sm font-medium text-gov-blue border border-gov-blue rounded-lg hover:bg-gov-light transition-colors focus:outline-none focus:ring-2 focus:ring-gov-sky focus:ring-offset-2;
  }
  .card {
    @apply bg-white rounded-xl border border-slate-200 shadow-sm hover:shadow-md transition-shadow;
  }
  .badge {
    @apply inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium;
  }
}
```

### 5.7 Write `assets/01_외부포털서버/src/frontend/app/layout.js`

- [ ] Write file: `assets/01_외부포털서버/src/frontend/app/layout.js`

```javascript
/**
 * Root Layout -- App Router (RSC enabled by default)
 * Asset 01: External Portal Server
 *
 * [취약점] VULN-01-05: Next.js 15.0.3 App Router with React 19.1.0
 * enables RSC Flight protocol, which is vulnerable to CVE-2025-55182.
 * Correct implementation: upgrade to Next.js 15.0.4+ / React 19.1.2+
 */

import './globals.css';

export const metadata = {
  title: 'MOIS - Ministry of Interior and Safety | Republic of Valdoria',
  description: 'Official portal of the Ministry of Interior and Safety, Republic of Valdoria. Access government notices, search services, and track inquiries.',
  icons: { icon: '/favicon.ico' },
};

export default function RootLayout({ children }) {
  return (
    <html lang="en">
      <head>
        <link rel="preconnect" href="https://fonts.googleapis.com" />
        <link
          href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap"
          rel="stylesheet"
        />
      </head>
      <body className="min-h-screen flex flex-col">
        {children}
      </body>
    </html>
  );
}
```

### 5.8 Write `assets/01_외부포털서버/src/frontend/components/Header.jsx`

- [ ] Write file: `assets/01_외부포털서버/src/frontend/components/Header.jsx`

```jsx
'use client';

import Link from 'next/link';
import { useState } from 'react';

export default function Header() {
  const [menuOpen, setMenuOpen] = useState(false);

  return (
    <header className="bg-gov-navy text-white shadow-lg">
      {/* Top utility bar */}
      <div className="bg-gov-dark/50 border-b border-white/10">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 flex justify-between items-center h-8 text-xs text-slate-300">
          <span>Republic of Valdoria - Official Government Website</span>
          <div className="hidden sm:flex items-center gap-4">
            <span>Accessibility</span>
            <span>|</span>
            <span>Sitemap</span>
          </div>
        </div>
      </div>

      {/* Main header */}
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex items-center justify-between h-16">
          {/* Logo */}
          <Link href="/" className="flex items-center gap-3 group">
            <div className="w-10 h-10 bg-gov-accent rounded-lg flex items-center justify-center text-gov-navy font-bold text-lg shadow-inner">
              V
            </div>
            <div>
              <div className="text-lg font-bold tracking-tight leading-tight group-hover:text-gov-accent transition-colors">
                MOIS
              </div>
              <div className="text-[10px] text-slate-300 leading-tight tracking-wide uppercase">
                Ministry of Interior & Safety
              </div>
            </div>
          </Link>

          {/* Desktop nav */}
          <nav className="hidden md:flex items-center gap-1">
            <Link
              href="/notices"
              className="px-4 py-2 rounded-lg text-sm font-medium text-slate-200 hover:text-white hover:bg-white/10 transition-all"
            >
              Notices
            </Link>
            <Link
              href="/search"
              className="px-4 py-2 rounded-lg text-sm font-medium text-slate-200 hover:text-white hover:bg-white/10 transition-all"
            >
              Search
            </Link>
            <Link
              href="/inquiry"
              className="px-4 py-2 rounded-lg text-sm font-medium text-slate-200 hover:text-white hover:bg-white/10 transition-all"
            >
              Inquiry Status
            </Link>
          </nav>

          {/* Mobile hamburger */}
          <button
            className="md:hidden p-2 rounded-lg hover:bg-white/10 transition-colors"
            onClick={() => setMenuOpen(!menuOpen)}
            aria-label="Toggle menu"
          >
            <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              {menuOpen ? (
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
              ) : (
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 6h16M4 12h16M4 18h16" />
              )}
            </svg>
          </button>
        </div>
      </div>

      {/* Mobile menu */}
      {menuOpen && (
        <nav className="md:hidden border-t border-white/10 bg-gov-dark/30">
          <div className="px-4 py-3 space-y-1">
            <Link href="/notices" className="block px-4 py-2.5 rounded-lg text-sm text-slate-200 hover:text-white hover:bg-white/10">
              Notices
            </Link>
            <Link href="/search" className="block px-4 py-2.5 rounded-lg text-sm text-slate-200 hover:text-white hover:bg-white/10">
              Search
            </Link>
            <Link href="/inquiry" className="block px-4 py-2.5 rounded-lg text-sm text-slate-200 hover:text-white hover:bg-white/10">
              Inquiry Status
            </Link>
          </div>
        </nav>
      )}
    </header>
  );
}
```

### 5.9 Write `assets/01_외부포털서버/src/frontend/components/Footer.jsx`

- [ ] Write file: `assets/01_외부포털서버/src/frontend/components/Footer.jsx`

```jsx
export default function Footer() {
  return (
    <footer className="bg-slate-800 text-slate-300 mt-auto">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
        <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
          {/* Logo and info */}
          <div>
            <div className="flex items-center gap-2 mb-4">
              <div className="w-8 h-8 bg-gov-accent rounded-lg flex items-center justify-center text-gov-navy font-bold text-sm">
                V
              </div>
              <span className="text-white font-semibold">MOIS</span>
            </div>
            <p className="text-sm leading-relaxed text-slate-400">
              Ministry of Interior and Safety<br />
              Republic of Valdoria<br />
              Government Complex Sejong, 11 Doum 6-ro,<br />
              Sejong Special District, Valdoria
            </p>
          </div>

          {/* Quick links */}
          <div>
            <h3 className="text-white font-semibold mb-4 text-sm uppercase tracking-wider">Quick Links</h3>
            <ul className="space-y-2 text-sm">
              <li><a href="/notices" className="hover:text-white transition-colors">Notices</a></li>
              <li><a href="/search" className="hover:text-white transition-colors">Search</a></li>
              <li><a href="/inquiry" className="hover:text-white transition-colors">Inquiry Status</a></li>
              <li><a href="https://gov24.valdoria.gov" className="hover:text-white transition-colors">Gov24</a></li>
            </ul>
          </div>

          {/* Contact */}
          <div>
            <h3 className="text-white font-semibold mb-4 text-sm uppercase tracking-wider">Contact</h3>
            <ul className="space-y-2 text-sm">
              <li>General Inquiries: 044-205-1100</li>
              <li>Citizen Helpline: 110</li>
              <li>Email: contact@mois.valdoria.gov</li>
              <li>Operating Hours: Mon-Fri 09:00-18:00</li>
            </ul>
          </div>
        </div>

        <div className="border-t border-slate-700 mt-8 pt-8 flex flex-col sm:flex-row justify-between items-center text-xs text-slate-500">
          <p>&copy; 2026 Ministry of Interior and Safety, Republic of Valdoria. All rights reserved.</p>
          <div className="flex gap-4 mt-2 sm:mt-0">
            <a href="#" className="hover:text-slate-300">Privacy Policy</a>
            <a href="#" className="hover:text-slate-300">Terms of Use</a>
            <a href="#" className="hover:text-slate-300">Accessibility</a>
          </div>
        </div>
      </div>
    </footer>
  );
}
```

### 5.10 Write `assets/01_외부포털서버/src/frontend/components/Pagination.jsx`

- [ ] Write file: `assets/01_외부포털서버/src/frontend/components/Pagination.jsx`

```jsx
'use client';

export default function Pagination({ currentPage, totalPages, onPageChange }) {
  if (totalPages <= 1) return null;

  const pages = [];
  const maxVisible = 5;
  let start = Math.max(1, currentPage - Math.floor(maxVisible / 2));
  let end = Math.min(totalPages, start + maxVisible - 1);
  if (end - start + 1 < maxVisible) {
    start = Math.max(1, end - maxVisible + 1);
  }

  for (let i = start; i <= end; i++) {
    pages.push(i);
  }

  return (
    <nav className="flex items-center justify-center gap-1 mt-8" aria-label="Pagination">
      <button
        onClick={() => onPageChange(currentPage - 1)}
        disabled={currentPage <= 1}
        className="px-3 py-2 text-sm rounded-lg border border-slate-200 text-slate-600 hover:bg-slate-50 disabled:opacity-40 disabled:cursor-not-allowed transition-colors"
      >
        Previous
      </button>

      {start > 1 && (
        <>
          <button onClick={() => onPageChange(1)} className="w-10 h-10 text-sm rounded-lg border border-slate-200 text-slate-600 hover:bg-slate-50 transition-colors">1</button>
          {start > 2 && <span className="px-1 text-slate-400">...</span>}
        </>
      )}

      {pages.map((p) => (
        <button
          key={p}
          onClick={() => onPageChange(p)}
          className={`w-10 h-10 text-sm rounded-lg border transition-colors ${
            p === currentPage
              ? 'bg-gov-blue text-white border-gov-blue font-semibold'
              : 'border-slate-200 text-slate-600 hover:bg-slate-50'
          }`}
        >
          {p}
        </button>
      ))}

      {end < totalPages && (
        <>
          {end < totalPages - 1 && <span className="px-1 text-slate-400">...</span>}
          <button onClick={() => onPageChange(totalPages)} className="w-10 h-10 text-sm rounded-lg border border-slate-200 text-slate-600 hover:bg-slate-50 transition-colors">{totalPages}</button>
        </>
      )}

      <button
        onClick={() => onPageChange(currentPage + 1)}
        disabled={currentPage >= totalPages}
        className="px-3 py-2 text-sm rounded-lg border border-slate-200 text-slate-600 hover:bg-slate-50 disabled:opacity-40 disabled:cursor-not-allowed transition-colors"
      >
        Next
      </button>
    </nav>
  );
}
```

### 5.11 Write `assets/01_외부포털서버/src/frontend/components/SearchBar.jsx`

- [ ] Write file: `assets/01_외부포털서버/src/frontend/components/SearchBar.jsx`

```jsx
'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';

export default function SearchBar({ initialQuery = '', size = 'default' }) {
  const [query, setQuery] = useState(initialQuery);
  const router = useRouter();

  const handleSubmit = (e) => {
    e.preventDefault();
    if (query.trim()) {
      router.push(`/search?q=${encodeURIComponent(query.trim())}`);
    }
  };

  const isLarge = size === 'large';

  return (
    <form onSubmit={handleSubmit} className="w-full">
      <div className="relative flex">
        <input
          type="text"
          value={query}
          onChange={(e) => setQuery(e.target.value)}
          placeholder="Search notices, policies, and services..."
          className={`flex-1 border border-slate-300 rounded-l-xl bg-white text-slate-800 placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-gov-sky focus:border-gov-sky transition-all ${
            isLarge ? 'px-6 py-4 text-lg' : 'px-4 py-2.5 text-sm'
          }`}
        />
        <button
          type="submit"
          className={`bg-gov-blue text-white rounded-r-xl hover:bg-gov-navy transition-colors flex items-center justify-center ${
            isLarge ? 'px-8' : 'px-5'
          }`}
        >
          <svg className={isLarge ? 'w-6 h-6' : 'w-5 h-5'} fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
          </svg>
        </button>
      </div>
    </form>
  );
}
```

### 5.12 Write `assets/01_외부포털서버/src/frontend/app/page.js` (Home)

- [ ] Write file: `assets/01_외부포털서버/src/frontend/app/page.js`

```jsx
import Header from '../components/Header';
import Footer from '../components/Footer';
import SearchBar from '../components/SearchBar';
import Link from 'next/link';

async function getRecentNotices() {
  try {
    const res = await fetch('http://127.0.0.1:8000/api/notices?page=1&size=5', {
      cache: 'no-store',
    });
    if (!res.ok) return [];
    const data = await res.json();
    return data.items || [];
  } catch {
    return [];
  }
}

export default async function Home() {
  const notices = await getRecentNotices();

  return (
    <>
      <Header />

      {/* Hero section */}
      <section className="relative bg-gradient-to-br from-gov-navy via-gov-blue to-gov-navy overflow-hidden">
        <div className="absolute inset-0 opacity-10">
          <div className="absolute top-0 right-0 w-96 h-96 bg-gov-accent rounded-full blur-3xl translate-x-1/2 -translate-y-1/2" />
          <div className="absolute bottom-0 left-0 w-80 h-80 bg-gov-sky rounded-full blur-3xl -translate-x-1/2 translate-y-1/2" />
        </div>
        <div className="relative max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-20 sm:py-28">
          <div className="text-center max-w-3xl mx-auto">
            <div className="inline-flex items-center gap-2 px-4 py-1.5 rounded-full bg-white/10 text-sm text-white/80 mb-6 backdrop-blur-sm border border-white/10">
              <span className="w-2 h-2 bg-green-400 rounded-full animate-pulse" />
              Official Government Portal
            </div>
            <h1 className="text-4xl sm:text-5xl lg:text-6xl font-bold text-white mb-6 leading-tight">
              Ministry of Interior<br />
              <span className="text-gov-accent">&amp; Safety</span>
            </h1>
            <p className="text-lg text-slate-300 mb-10 max-w-2xl mx-auto leading-relaxed">
              Serving the citizens of the Republic of Valdoria with transparent governance,
              efficient public services, and unwavering commitment to safety.
            </p>
            <div className="max-w-xl mx-auto">
              <SearchBar size="large" />
            </div>
          </div>
        </div>
      </section>

      {/* Quick access cards */}
      <section className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 -mt-8 relative z-10">
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          <Link href="/notices" className="card p-6 flex items-center gap-4 group">
            <div className="w-12 h-12 rounded-xl bg-blue-50 text-gov-blue flex items-center justify-center group-hover:bg-gov-blue group-hover:text-white transition-all">
              <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M19 20H5a2 2 0 01-2-2V6a2 2 0 012-2h10a2 2 0 012 2v1m2 13a2 2 0 01-2-2V7m2 13a2 2 0 002-2V9a2 2 0 00-2-2h-2m-4-3H9M7 16h6M7 8h6v4H7V8z" />
              </svg>
            </div>
            <div>
              <div className="font-semibold text-slate-800">Notices</div>
              <div className="text-sm text-slate-500">Policy updates and announcements</div>
            </div>
          </Link>

          <Link href="/search" className="card p-6 flex items-center gap-4 group">
            <div className="w-12 h-12 rounded-xl bg-emerald-50 text-emerald-600 flex items-center justify-center group-hover:bg-emerald-600 group-hover:text-white transition-all">
              <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
              </svg>
            </div>
            <div>
              <div className="font-semibold text-slate-800">Search</div>
              <div className="text-sm text-slate-500">Find documents and services</div>
            </div>
          </Link>

          <Link href="/inquiry" className="card p-6 flex items-center gap-4 group">
            <div className="w-12 h-12 rounded-xl bg-amber-50 text-amber-600 flex items-center justify-center group-hover:bg-amber-600 group-hover:text-white transition-all">
              <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
              </svg>
            </div>
            <div>
              <div className="font-semibold text-slate-800">Inquiry Status</div>
              <div className="text-sm text-slate-500">Track your submitted inquiries</div>
            </div>
          </Link>
        </div>
      </section>

      {/* Recent notices */}
      <section className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-16">
        <div className="flex items-center justify-between mb-8">
          <div>
            <h2 className="text-2xl font-bold text-slate-800">Latest Notices</h2>
            <p className="text-slate-500 mt-1">Recent announcements and policy updates</p>
          </div>
          <Link href="/notices" className="btn-outline text-sm">
            View All
          </Link>
        </div>

        <div className="space-y-3">
          {notices.length > 0 ? (
            notices.map((notice) => (
              <Link
                key={notice.id}
                href={`/notices/${notice.id}`}
                className="flex items-center justify-between p-4 rounded-xl border border-slate-100 hover:border-gov-sky hover:bg-gov-light/30 transition-all group"
              >
                <div className="flex items-center gap-4 min-w-0">
                  <span className="badge bg-gov-light text-gov-blue shrink-0">
                    {notice.category}
                  </span>
                  <span className="text-slate-800 font-medium group-hover:text-gov-blue transition-colors truncate">
                    {notice.title}
                  </span>
                </div>
                <div className="flex items-center gap-4 shrink-0 ml-4">
                  <span className="text-xs text-slate-400">
                    {new Date(notice.created_at).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' })}
                  </span>
                  <span className="text-xs text-slate-400">
                    {notice.view_count?.toLocaleString()} views
                  </span>
                </div>
              </Link>
            ))
          ) : (
            <div className="text-center py-12 text-slate-400">No notices available</div>
          )}
        </div>
      </section>

      {/* Service information */}
      <section className="bg-slate-50 border-t border-slate-100">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-16">
          <h2 className="text-2xl font-bold text-slate-800 text-center mb-10">Government Services</h2>
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
            {[
              { title: 'Gov24', desc: 'One-stop government service platform', icon: 'M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6' },
              { title: 'Digital ID', desc: 'Secure digital identity verification', icon: 'M10 6H5a2 2 0 00-2 2v9a2 2 0 002 2h14a2 2 0 002-2V8a2 2 0 00-2-2h-5m-4 0V5a2 2 0 114 0v1m-4 0a2 2 0 104 0m-5 8a2 2 0 100-4 2 2 0 000 4zm0 0c1.306 0 2.417.835 2.83 2M9 14a3.001 3.001 0 00-2.83 2M15 11h3m-3 4h2' },
              { title: 'Complaint Filing', desc: 'Submit and track public complaints', icon: 'M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z' },
              { title: 'Safety Alerts', desc: 'Disaster and emergency notifications', icon: 'M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z' },
            ].map((item, i) => (
              <div key={i} className="card p-6 text-center">
                <div className="w-12 h-12 mx-auto mb-4 rounded-xl bg-gov-light text-gov-blue flex items-center justify-center">
                  <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d={item.icon} />
                  </svg>
                </div>
                <h3 className="font-semibold text-slate-800 mb-1">{item.title}</h3>
                <p className="text-sm text-slate-500">{item.desc}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      <Footer />
    </>
  );
}
```

### 5.13 Write `assets/01_외부포털서버/src/frontend/app/notices/page.js` (Notice List)

- [ ] Write file: `assets/01_외부포털서버/src/frontend/app/notices/page.js`

```jsx
'use client';

import { useState, useEffect } from 'react';
import Header from '../../components/Header';
import Footer from '../../components/Footer';
import Pagination from '../../components/Pagination';
import Link from 'next/link';

const CATEGORIES = ['All', 'Policy', 'System', 'Security', 'Training', 'Service', 'Event', 'Recruitment', 'Personnel', 'Facilities'];

export default function NoticesPage() {
  const [notices, setNotices] = useState([]);
  const [total, setTotal] = useState(0);
  const [page, setPage] = useState(1);
  const [category, setCategory] = useState(null);
  const [loading, setLoading] = useState(true);
  const size = 10;

  useEffect(() => {
    async function load() {
      setLoading(true);
      try {
        let url = `/api/notices?page=${page}&size=${size}`;
        if (category) url += `&category=${encodeURIComponent(category)}`;
        const res = await fetch(url);
        const data = await res.json();
        setNotices(data.items || []);
        setTotal(data.total || 0);
      } catch {
        setNotices([]);
      }
      setLoading(false);
    }
    load();
  }, [page, category]);

  const totalPages = Math.ceil(total / size);

  return (
    <>
      <Header />

      <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-10">
        {/* Breadcrumb */}
        <nav className="text-sm text-slate-500 mb-6">
          <Link href="/" className="hover:text-gov-blue">Home</Link>
          <span className="mx-2">/</span>
          <span className="text-slate-800 font-medium">Notices</span>
        </nav>

        <h1 className="text-3xl font-bold text-slate-800 mb-2">Notices</h1>
        <p className="text-slate-500 mb-8">Official announcements and policy updates from MOIS</p>

        {/* Category filter */}
        <div className="flex flex-wrap gap-2 mb-8">
          {CATEGORIES.map((cat) => {
            const isActive = cat === 'All' ? !category : category === cat;
            return (
              <button
                key={cat}
                onClick={() => { setCategory(cat === 'All' ? null : cat); setPage(1); }}
                className={`px-4 py-2 rounded-full text-sm font-medium transition-all ${
                  isActive
                    ? 'bg-gov-blue text-white shadow-sm'
                    : 'bg-slate-100 text-slate-600 hover:bg-slate-200'
                }`}
              >
                {cat}
              </button>
            );
          })}
        </div>

        {/* Table */}
        <div className="border border-slate-200 rounded-xl overflow-hidden">
          <table className="w-full">
            <thead>
              <tr className="bg-slate-50 border-b border-slate-200">
                <th className="text-left px-6 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wider w-16">No.</th>
                <th className="text-left px-6 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wider">Title</th>
                <th className="text-left px-6 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wider w-28">Category</th>
                <th className="text-left px-6 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wider w-32">Date</th>
                <th className="text-right px-6 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wider w-24">Views</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {loading ? (
                <tr><td colSpan={5} className="text-center py-16 text-slate-400">Loading...</td></tr>
              ) : notices.length === 0 ? (
                <tr><td colSpan={5} className="text-center py-16 text-slate-400">No notices found</td></tr>
              ) : (
                notices.map((n) => (
                  <tr key={n.id} className="hover:bg-slate-50 transition-colors">
                    <td className="px-6 py-4 text-sm text-slate-400">{n.id}</td>
                    <td className="px-6 py-4">
                      <Link href={`/notices/${n.id}`} className="text-sm font-medium text-slate-800 hover:text-gov-blue transition-colors">
                        {n.title}
                      </Link>
                    </td>
                    <td className="px-6 py-4">
                      <span className="badge bg-gov-light text-gov-blue">{n.category}</span>
                    </td>
                    <td className="px-6 py-4 text-sm text-slate-500">
                      {new Date(n.created_at).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' })}
                    </td>
                    <td className="px-6 py-4 text-sm text-slate-500 text-right">
                      {n.view_count?.toLocaleString()}
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>

        <Pagination currentPage={page} totalPages={totalPages} onPageChange={setPage} />
      </main>

      <Footer />
    </>
  );
}
```

### 5.14 Write `assets/01_외부포털서버/src/frontend/app/notices/[id]/page.js` (Notice Detail)

- [ ] Write file: `assets/01_외부포털서버/src/frontend/app/notices/[id]/page.js`

```jsx
import Header from '../../../components/Header';
import Footer from '../../../components/Footer';
import Link from 'next/link';

async function getNotice(id) {
  try {
    const res = await fetch(`http://127.0.0.1:8000/api/notices/${id}`, {
      cache: 'no-store',
    });
    if (!res.ok) return null;
    return res.json();
  } catch {
    return null;
  }
}

export default async function NoticeDetailPage({ params }) {
  const { id } = await params;
  const notice = await getNotice(id);

  return (
    <>
      <Header />

      <main className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-10">
        {/* Breadcrumb */}
        <nav className="text-sm text-slate-500 mb-6">
          <Link href="/" className="hover:text-gov-blue">Home</Link>
          <span className="mx-2">/</span>
          <Link href="/notices" className="hover:text-gov-blue">Notices</Link>
          <span className="mx-2">/</span>
          <span className="text-slate-800 font-medium">Detail</span>
        </nav>

        {!notice ? (
          <div className="text-center py-20">
            <h2 className="text-xl font-semibold text-slate-800 mb-2">Notice Not Found</h2>
            <p className="text-slate-500 mb-6">The requested notice does not exist or has been removed.</p>
            <Link href="/notices" className="btn-primary">Back to Notices</Link>
          </div>
        ) : (
          <article>
            {/* Header */}
            <div className="border-b border-slate-200 pb-6 mb-8">
              <span className="badge bg-gov-light text-gov-blue mb-3">{notice.category}</span>
              <h1 className="text-2xl sm:text-3xl font-bold text-slate-800 mb-4 leading-tight">
                {notice.title}
              </h1>
              <div className="flex flex-wrap items-center gap-4 text-sm text-slate-500">
                <span className="flex items-center gap-1.5">
                  <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
                  </svg>
                  {notice.author}
                </span>
                <span className="flex items-center gap-1.5">
                  <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
                  </svg>
                  {new Date(notice.created_at).toLocaleDateString('en-US', { month: 'long', day: 'numeric', year: 'numeric' })}
                </span>
                <span className="flex items-center gap-1.5">
                  <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
                  </svg>
                  {notice.view_count?.toLocaleString()} views
                </span>
              </div>
            </div>

            {/* Content */}
            <div className="prose prose-slate max-w-none">
              {notice.content?.split('\n').map((line, i) => (
                <p key={i} className="mb-3 text-slate-700 leading-relaxed">{line || '\u00A0'}</p>
              ))}
            </div>

            {/* Footer */}
            <div className="border-t border-slate-200 mt-12 pt-6 flex justify-between">
              <Link href="/notices" className="btn-outline text-sm">
                Back to List
              </Link>
            </div>
          </article>
        )}
      </main>

      <Footer />
    </>
  );
}
```

### 5.15 Write `assets/01_외부포털서버/src/frontend/app/search/page.js`

- [ ] Write file: `assets/01_외부포털서버/src/frontend/app/search/page.js`

```jsx
'use client';

import { useState, useEffect, Suspense } from 'react';
import { useSearchParams } from 'next/navigation';
import Header from '../../components/Header';
import Footer from '../../components/Footer';
import SearchBar from '../../components/SearchBar';
import Link from 'next/link';

function SearchResults() {
  const searchParams = useSearchParams();
  const q = searchParams.get('q') || '';
  const [results, setResults] = useState([]);
  const [total, setTotal] = useState(0);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  useEffect(() => {
    if (!q) return;
    async function doSearch() {
      setLoading(true);
      setError(null);
      try {
        const res = await fetch(`/api/search?q=${encodeURIComponent(q)}`);
        const data = await res.json();
        if (data.error) {
          setError(data.error);
          setResults([]);
        } else {
          setResults(data.items || []);
          setTotal(data.total || 0);
        }
      } catch (err) {
        setError('An error occurred while searching');
      }
      setLoading(false);
    }
    doSearch();
  }, [q]);

  return (
    <>
      {q && (
        <div className="mb-8">
          <p className="text-slate-500">
            {loading ? 'Searching...' : `${total} result${total !== 1 ? 's' : ''} for`}
            {!loading && <span className="font-semibold text-slate-800 ml-1">&quot;{q}&quot;</span>}
          </p>
        </div>
      )}

      {error && (
        <div className="bg-red-50 border border-red-200 rounded-xl p-4 mb-6 text-sm text-red-700">
          {error}
        </div>
      )}

      <div className="space-y-4">
        {results.map((item, i) => (
          <Link
            key={i}
            href={item.type === 'notice' ? `/notices/${item.id}` : `/inquiry/${item.title}`}
            className="block card p-5 group"
          >
            <div className="flex items-center gap-2 mb-2">
              <span className={`badge ${item.type === 'notice' ? 'bg-blue-50 text-blue-700' : 'bg-amber-50 text-amber-700'}`}>
                {item.type === 'notice' ? 'Notice' : 'Inquiry'}
              </span>
            </div>
            <h3 className="font-semibold text-slate-800 group-hover:text-gov-blue transition-colors mb-1">
              {item.title}
            </h3>
            {item.snippet && (
              <p className="text-sm text-slate-500 line-clamp-2">{item.snippet}</p>
            )}
          </Link>
        ))}
      </div>

      {!loading && q && results.length === 0 && !error && (
        <div className="text-center py-16">
          <p className="text-slate-500">No results found. Try different keywords.</p>
        </div>
      )}
    </>
  );
}

export default function SearchPage() {
  const searchParams = useSearchParams();
  const q = searchParams.get('q') || '';

  return (
    <>
      <Header />

      <main className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-10">
        <nav className="text-sm text-slate-500 mb-6">
          <Link href="/" className="hover:text-gov-blue">Home</Link>
          <span className="mx-2">/</span>
          <span className="text-slate-800 font-medium">Search</span>
        </nav>

        <h1 className="text-3xl font-bold text-slate-800 mb-6">Search</h1>

        <div className="mb-8">
          <SearchBar initialQuery={q} />
        </div>

        <Suspense fallback={<div className="text-center py-8 text-slate-400">Loading...</div>}>
          <SearchResults />
        </Suspense>
      </main>

      <Footer />
    </>
  );
}
```

### 5.16 Write `assets/01_외부포털서버/src/frontend/app/inquiry/page.js`

- [ ] Write file: `assets/01_외부포털서버/src/frontend/app/inquiry/page.js`

```jsx
'use client';

import { useState } from 'react';
import Header from '../../components/Header';
import Footer from '../../components/Footer';
import Link from 'next/link';

export default function InquiryPage() {
  const [trackingNumber, setTrackingNumber] = useState('');
  const [result, setResult] = useState(null);
  const [error, setError] = useState(null);
  const [loading, setLoading] = useState(false);

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!trackingNumber.trim()) return;

    setLoading(true);
    setError(null);
    setResult(null);

    try {
      const res = await fetch(`/api/inquiry/${encodeURIComponent(trackingNumber.trim())}`);
      if (res.status === 404) {
        setError('No inquiry found with the provided tracking number. Please check and try again.');
      } else if (!res.ok) {
        setError('An error occurred. Please try again later.');
      } else {
        setResult(await res.json());
      }
    } catch {
      setError('Connection error. Please check your network and try again.');
    }
    setLoading(false);
  };

  const statusColor = (status) => {
    switch (status) {
      case 'Resolved': return 'bg-green-50 text-green-700 border-green-200';
      case 'In Progress': return 'bg-blue-50 text-blue-700 border-blue-200';
      case 'Received': return 'bg-slate-100 text-slate-600 border-slate-200';
      default: return 'bg-amber-50 text-amber-700 border-amber-200';
    }
  };

  return (
    <>
      <Header />

      <main className="max-w-3xl mx-auto px-4 sm:px-6 lg:px-8 py-10">
        <nav className="text-sm text-slate-500 mb-6">
          <Link href="/" className="hover:text-gov-blue">Home</Link>
          <span className="mx-2">/</span>
          <span className="text-slate-800 font-medium">Inquiry Status</span>
        </nav>

        <h1 className="text-3xl font-bold text-slate-800 mb-2">Inquiry Status</h1>
        <p className="text-slate-500 mb-8">
          Enter your inquiry tracking number to check the current processing status.
        </p>

        {/* Search form */}
        <form onSubmit={handleSubmit} className="mb-10">
          <label className="block text-sm font-medium text-slate-700 mb-2">
            Tracking Number
          </label>
          <div className="flex gap-3">
            <input
              type="text"
              value={trackingNumber}
              onChange={(e) => setTrackingNumber(e.target.value)}
              placeholder="e.g., INQ-20260315-0001"
              className="flex-1 px-4 py-3 border border-slate-300 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-gov-sky focus:border-gov-sky"
            />
            <button
              type="submit"
              disabled={loading}
              className="btn-primary disabled:opacity-50"
            >
              {loading ? 'Checking...' : 'Check Status'}
            </button>
          </div>
          <p className="text-xs text-slate-400 mt-2">
            Format: INQ-YYYYMMDD-XXXX (provided when you submitted your inquiry)
          </p>
        </form>

        {/* Error */}
        {error && (
          <div className="bg-red-50 border border-red-200 rounded-xl p-5 mb-6">
            <div className="flex items-start gap-3">
              <svg className="w-5 h-5 text-red-500 mt-0.5 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
              </svg>
              <p className="text-sm text-red-700">{error}</p>
            </div>
          </div>
        )}

        {/* Result */}
        {result && (
          <div className="card p-6">
            <div className="flex items-center justify-between mb-6">
              <div>
                <div className="text-xs text-slate-400 uppercase tracking-wider mb-1">Tracking Number</div>
                <div className="text-lg font-semibold text-slate-800 font-mono">{result.tracking_number}</div>
              </div>
              <span className={`badge px-3 py-1.5 text-sm border ${statusColor(result.status)}`}>
                {result.status}
              </span>
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-6">
              <div>
                <div className="text-xs text-slate-400 uppercase tracking-wider mb-1">Subject</div>
                <div className="text-sm text-slate-800">{result.subject}</div>
              </div>
              <div>
                <div className="text-xs text-slate-400 uppercase tracking-wider mb-1">Department</div>
                <div className="text-sm text-slate-800">{result.department || 'Pending assignment'}</div>
              </div>
              <div>
                <div className="text-xs text-slate-400 uppercase tracking-wider mb-1">Submitted By</div>
                <div className="text-sm text-slate-800">{result.submitter_name}</div>
              </div>
              <div>
                <div className="text-xs text-slate-400 uppercase tracking-wider mb-1">Submitted Date</div>
                <div className="text-sm text-slate-800">
                  {new Date(result.submitted_at).toLocaleDateString('en-US', {
                    month: 'long', day: 'numeric', year: 'numeric', hour: '2-digit', minute: '2-digit',
                  })}
                </div>
              </div>
            </div>

            {result.updated_at && result.updated_at !== result.submitted_at && (
              <div className="mt-4 pt-4 border-t border-slate-100">
                <div className="text-xs text-slate-400">
                  Last updated: {new Date(result.updated_at).toLocaleDateString('en-US', {
                    month: 'long', day: 'numeric', year: 'numeric', hour: '2-digit', minute: '2-digit',
                  })}
                </div>
              </div>
            )}
          </div>
        )}
      </main>

      <Footer />
    </>
  );
}
```

### 5.17 Write `assets/01_외부포털서버/src/frontend/app/login/page.js` (Hidden admin login)

- [ ] Write file: `assets/01_외부포털서버/src/frontend/app/login/page.js`

```jsx
'use client';

import { useState } from 'react';
import Link from 'next/link';

export default function LoginPage() {
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState(null);

  const handleSubmit = (e) => {
    e.preventDefault();
    // This login page is intentionally non-functional.
    // It exists as a hidden endpoint for red team discovery.
    setError('Authentication service is temporarily unavailable. Please contact the IT Management Office.');
  };

  return (
    <div className="min-h-screen bg-slate-50 flex items-center justify-center px-4">
      <div className="w-full max-w-md">
        <div className="text-center mb-8">
          <div className="w-14 h-14 mx-auto bg-gov-navy rounded-xl flex items-center justify-center text-gov-accent font-bold text-2xl mb-4 shadow-lg">
            V
          </div>
          <h1 className="text-xl font-bold text-slate-800">MOIS Portal Administration</h1>
          <p className="text-sm text-slate-500 mt-1">Authorized personnel only</p>
        </div>

        <div className="card p-8">
          <form onSubmit={handleSubmit} className="space-y-5">
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1.5">Username</label>
              <input
                type="text"
                value={username}
                onChange={(e) => setUsername(e.target.value)}
                className="w-full px-4 py-2.5 border border-slate-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-gov-sky focus:border-gov-sky"
                placeholder="Enter your username"
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1.5">Password</label>
              <input
                type="password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                className="w-full px-4 py-2.5 border border-slate-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-gov-sky focus:border-gov-sky"
                placeholder="Enter your password"
              />
            </div>

            {error && (
              <div className="bg-red-50 border border-red-200 rounded-lg p-3 text-sm text-red-700">
                {error}
              </div>
            )}

            <button type="submit" className="w-full btn-primary py-3">
              Sign In
            </button>
          </form>
        </div>

        <div className="text-center mt-6">
          <Link href="/" className="text-sm text-slate-500 hover:text-gov-blue transition-colors">
            Return to main site
          </Link>
        </div>
      </div>
    </div>
  );
}
```

---

## Task 6: Asset 01 -- Nginx + systemd + setup.sh

### 6.1 Write `assets/01_외부포털서버/src/config/nginx/mois-portal.conf`

- [ ] Write file: `assets/01_외부포털서버/src/config/nginx/mois-portal.conf`

```nginx
# =============================================================
# Nginx Configuration -- MOIS External Portal
# Asset 01: External Portal Server (192.168.92.201)
# =============================================================

# Detailed log format (for blue team detection)
log_format detailed '$remote_addr - $remote_user [$time_local] '
                    '"$request" $status $body_bytes_sent '
                    '"$http_referer" "$http_user_agent" '
                    '$request_time $upstream_response_time';

# HTTP -> HTTPS redirect
server {
    listen 80;
    server_name www.mois.valdoria.gov mois.valdoria.gov _;

    # robots.txt served directly (even over HTTP)
    location = /robots.txt {
        root /opt/mois-portal/public;
    }

    location / {
        return 301 https://$host$request_uri;
    }
}

# HTTPS server
server {
    listen 443 ssl http2;
    server_name www.mois.valdoria.gov mois.valdoria.gov _;

    ssl_certificate     /etc/nginx/ssl/mois-portal.crt;
    ssl_certificate_key /etc/nginx/ssl/mois-portal.key;
    ssl_protocols       TLSv1.2 TLSv1.3;
    ssl_ciphers         HIGH:!aNULL:!MD5;

    access_log /var/log/nginx/mois-portal-access.log detailed;
    error_log  /var/log/nginx/mois-portal-error.log;

    # robots.txt -- [취약점] VULN-01-04: Hints at hidden paths
    location = /robots.txt {
        root /opt/mois-portal/public;
    }

    # FastAPI API proxy
    location /api/ {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # [취약점] VULN-01-01: Swagger UI and OpenAPI spec proxied to public
    # Correct implementation: block these paths or return 404
    location /docs {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }

    location /redoc {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }

    location /openapi.json {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }

    # Next.js application (main site)
    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }

    # Next.js static assets
    location /_next/ {
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header Host $host;
    }
}
```

### 6.2 Write `assets/01_외부포털서버/src/config/systemd/mois-portal-api.service`

- [ ] Write file: `assets/01_외부포털서버/src/config/systemd/mois-portal-api.service`

```ini
# =============================================================
# systemd Service: MOIS Portal FastAPI Backend
# Asset 01: External Portal Server (192.168.92.201)
# =============================================================

[Unit]
Description=MOIS Portal API (FastAPI/Uvicorn)
After=network.target

[Service]
Type=simple
User=portaladm
Group=portaladm
WorkingDirectory=/opt/mois-portal/backend
Environment="PATH=/opt/mois-portal/venv/bin:/usr/bin"
EnvironmentFile=/opt/mois-portal/.env

# [취약점] VULN-01-01: Binding to 0.0.0.0 exposes FastAPI directly on port 8000
# Correct implementation: --host 127.0.0.1 (localhost only, behind Nginx)
ExecStart=/opt/mois-portal/venv/bin/uvicorn main:app \
    --host 0.0.0.0 \
    --port 8000 \
    --workers 2 \
    --log-level info \
    --access-log

Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal
SyslogIdentifier=mois-portal-api

[Install]
WantedBy=multi-user.target
```

### 6.3 Write `assets/01_외부포털서버/src/config/systemd/mois-portal-web.service`

- [ ] Write file: `assets/01_외부포털서버/src/config/systemd/mois-portal-web.service`

```ini
# =============================================================
# systemd Service: MOIS Portal Next.js Frontend
# Asset 01: External Portal Server (192.168.92.201)
# =============================================================

[Unit]
Description=MOIS Portal Web (Next.js)
After=network.target mois-portal-api.service

[Service]
Type=simple
User=portaladm
Group=portaladm
WorkingDirectory=/opt/mois-portal/frontend
Environment="NODE_ENV=production"
Environment="PORT=3000"
ExecStart=/usr/bin/node /opt/mois-portal/frontend/node_modules/.bin/next start -p 3000

Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal
SyslogIdentifier=mois-portal-web

[Install]
WantedBy=multi-user.target
```

### 6.4 Write `assets/01_외부포털서버/setup.sh`

- [ ] Write file: `assets/01_외부포털서버/setup.sh`

```bash
#!/bin/bash
# =============================================================
# External Portal Server (192.168.92.201) One-Click Deployment
# Asset: 01
#
# Usage: sudo bash setup.sh
# Prerequisites: Ubuntu 22.04 LTS, internet access
# =============================================================

set -euo pipefail

# ----- Script directory (CLAUDE.md: use SCRIPT_DIR) -----
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ----- File existence checks (CLAUDE.md: verify before proceeding) -----
for f in .env.example \
         src/backend/main.py src/backend/config.py src/backend/database.py src/backend/requirements.txt \
         src/backend/routers/notices.py src/backend/routers/search.py src/backend/routers/inquiry.py \
         src/backend/routers/admin.py src/backend/routers/internal.py \
         src/frontend/package.json src/frontend/next.config.js src/frontend/app/layout.js src/frontend/app/page.js \
         src/config/nginx/mois-portal.conf \
         src/config/systemd/mois-portal-api.service src/config/systemd/mois-portal-web.service; do
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

APP_DIR="/opt/mois-portal"
APP_USER="portaladm"
LOG_DIR="/var/log/mois-portal"

echo "============================================"
echo " External Portal Server Deployment Starting"
echo " IP: 192.168.92.201"
echo " Next.js 15.0.3 + FastAPI 0.104.1"
echo "============================================"

# ----- [1/12] .env check -----
echo "[1/12] Checking environment configuration..."
if [ -f "${SCRIPT_DIR}/.env" ]; then
    echo "  Using existing .env file"
else
    echo "  Creating .env from .env.example"
    cp "${SCRIPT_DIR}/.env.example" "${SCRIPT_DIR}/.env"
fi

# ----- [2/12] System update + base packages -----
echo "[2/12] System update and base packages..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq curl gnupg nginx python3.11 python3.11-venv python3-pip postgresql-client

# ----- [3/12] Install Node.js 20 LTS -----
echo "[3/12] Installing Node.js 20 LTS..."
if ! command -v node &>/dev/null || ! node -v | grep -q "v20"; then
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
    apt-get install -y -qq nodejs
fi
echo "  Node.js: $(node -v)"
echo "  npm: $(npm -v)"

# ----- [4/12] Create application user -----
echo "[4/12] Creating application user..."
id -u ${APP_USER} &>/dev/null || useradd -m -s /bin/bash ${APP_USER}

# ----- [5/12] Deploy application files -----
echo "[5/12] Deploying application files..."
mkdir -p ${APP_DIR}
cp -r "${SCRIPT_DIR}/src/backend" "${APP_DIR}/backend"
cp -r "${SCRIPT_DIR}/src/frontend" "${APP_DIR}/frontend"
cp "${SCRIPT_DIR}/.env" "${APP_DIR}/.env"

# ----- [6/12] Python virtual environment -----
echo "[6/12] Setting up Python virtual environment..."
python3.11 -m venv "${APP_DIR}/venv"
"${APP_DIR}/venv/bin/pip" install --upgrade pip -q
"${APP_DIR}/venv/bin/pip" install -r "${APP_DIR}/backend/requirements.txt" -q
echo "  Python packages installed"

# ----- [7/12] Build Next.js frontend -----
echo "[7/12] Building Next.js frontend (this may take a few minutes)..."
cd "${APP_DIR}/frontend"
npm install --legacy-peer-deps 2>&1 | tail -1
npm run build 2>&1 | tail -5
echo "  Next.js build complete"

# ----- [8/12] TLS certificates -----
echo "[8/12] Setting up TLS certificates..."
mkdir -p /etc/nginx/ssl
if [ -d "${SCRIPT_DIR}/certs" ] && [ -f "${SCRIPT_DIR}/certs/server.crt" ]; then
    cp "${SCRIPT_DIR}/certs/server.crt" /etc/nginx/ssl/mois-portal.crt
    cp "${SCRIPT_DIR}/certs/server.key" /etc/nginx/ssl/mois-portal.key
else
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /etc/nginx/ssl/mois-portal.key \
        -out /etc/nginx/ssl/mois-portal.crt \
        -subj "/C=VD/ST=Valdoria/L=Elaris/O=MOIS/CN=www.mois.valdoria.gov" 2>/dev/null
    echo "  Self-signed certificate generated"
fi

# ----- [9/12] Nginx configuration -----
echo "[9/12] Configuring Nginx..."
cp "${SCRIPT_DIR}/src/config/nginx/mois-portal.conf" /etc/nginx/sites-available/
ln -sf /etc/nginx/sites-available/mois-portal.conf /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Create robots.txt directory and file
# [취약점] VULN-01-04: robots.txt hints at hidden paths
mkdir -p "${APP_DIR}/public"
cat > "${APP_DIR}/public/robots.txt" << 'ROBOTS'
User-agent: *
Disallow: /api/admin/
Disallow: /api/internal/
Disallow: /docs
Disallow: /redoc
ROBOTS

nginx -t && systemctl restart nginx
systemctl enable nginx
echo "  Nginx configured and running"

# ----- [10/12] systemd services -----
echo "[10/12] Registering systemd services..."
cp "${SCRIPT_DIR}/src/config/systemd/mois-portal-api.service" /etc/systemd/system/
cp "${SCRIPT_DIR}/src/config/systemd/mois-portal-web.service" /etc/systemd/system/
systemctl daemon-reload

# ----- [11/12] Log directory and permissions -----
echo "[11/12] Setting up log directory and file permissions..."
mkdir -p "${LOG_DIR}"
chown -R ${APP_USER}:${APP_USER} "${APP_DIR}"
chown -R ${APP_USER}:${APP_USER} "${LOG_DIR}"

# ----- [12/12] Start services and firewall -----
echo "[12/12] Starting services and configuring firewall..."
systemctl enable mois-portal-api mois-portal-web
systemctl start mois-portal-api
sleep 2
systemctl start mois-portal-web

# Firewall
ufw allow 80/tcp comment "HTTP"
ufw allow 443/tcp comment "HTTPS"
# [취약점] VULN-01-01: Port 8000 open externally
ufw allow 8000/tcp comment "FastAPI direct access (VULN: should be localhost only)"
ufw allow ssh
ufw --force enable

echo ""
echo "============================================"
echo " External Portal Server Deployment Complete"
echo "============================================"
echo ""
echo " Service URLs:"
echo "   Main site:     https://www.mois.valdoria.gov (or https://192.168.92.201)"
echo "   Swagger UI:    https://192.168.92.201/docs"
echo "   FastAPI direct: http://192.168.92.201:8000/docs"
echo ""
echo " System accounts:"
echo "   portaladm / Portal@dmin2026"
echo ""
echo " Application accounts (in DB):"
echo "   daniel.harper / @dminMOIS2026!  (superadmin)"
echo "   michael.torres / Edit0r#01      (editor)"
echo "   sarah.mitchell / Edit0r#02      (editor)"
echo "   david.chen / View3r!!           (viewer)"
echo ""
echo " Intentional Vulnerabilities:"
echo "   1. API structure exposure (/docs, /openapi.json, port 8000)"
echo "   2. Missing auth on /api/admin/*, /api/internal/*"
echo "   3. SQL Injection in /api/search?q="
echo "   4. Directory enumeration hints (robots.txt)"
echo "   5. React2Shell CVE-2025-55182 (Next.js 15.0.3 + React 19.1.0)"
echo "============================================"
echo ""
echo " NOTE: DB server (192.168.92.208) must be set up first!"
echo "   Run Asset 08 setup.sh on the DB VM before starting this portal."
echo "============================================"
```

---

## Task 7: Verification Steps

### 7.1 Asset 08 Verification

- [ ] After running `sudo bash setup.sh` on 192.168.92.208:

```bash
# 1. Check PostgreSQL is running
systemctl status postgresql

# 2. Verify databases exist
sudo -u postgres psql -l | grep -E "mois_portal|agency_db|complaint_db"

# 3. Verify roles
sudo -u postgres psql -c "SELECT rolname, rolsuper, rolcanlogin FROM pg_roles WHERE rolcanlogin = true;"

# 4. Verify seed data
sudo -u postgres psql -d mois_portal -c "SELECT COUNT(*) FROM users;"
sudo -u postgres psql -d mois_portal -c "SELECT COUNT(*) FROM notices;"
sudo -u postgres psql -d mois_portal -c "SELECT COUNT(*) FROM inquiries;"
sudo -u postgres psql -d agency_db -c "SELECT COUNT(*) FROM employees;"
sudo -u postgres psql -d agency_db -c "SELECT COUNT(*) FROM departments;"
sudo -u postgres psql -d complaint_db -c "SELECT COUNT(*) FROM complaints;"

# 5. Verify vulnerability: SUPERUSER
sudo -u postgres psql -c "SELECT rolname FROM pg_roles WHERE rolsuper = true AND rolname != 'postgres';"
# Expected: app_service

# 6. Verify vulnerability: pg_hba allows subnet
grep "192.168.92.0/24" /etc/postgresql/*/main/pg_hba.conf

# 7. Verify vulnerability: logging disabled
PG_VER=$(pg_config --version | grep -oP '\d+' | head -1)
grep "log_statement" /etc/postgresql/${PG_VER}/main/conf.d/00-custom.conf
# Expected: log_statement = 'none'

# 8. Test remote connection from another host
PGPASSWORD='P0rtal#DB@2026!' psql -h 192.168.92.208 -U portal_app -d mois_portal -c "SELECT COUNT(*) FROM notices;"
```

### 7.2 Asset 01 Verification

- [ ] After running `sudo bash setup.sh` on 192.168.92.201:

```bash
# 1. Check services are running
systemctl status mois-portal-api
systemctl status mois-portal-web
systemctl status nginx

# 2. Test FastAPI directly (VULN: exposed on 8000)
curl -s http://localhost:8000/ | python3 -m json.tool
curl -s http://localhost:8000/docs | head -5

# 3. Test Nginx proxy
curl -sk https://localhost/api/notices | python3 -m json.tool | head -20

# 4. Test vulnerability: unauthenticated admin API
curl -s http://localhost:8000/api/admin/users | python3 -m json.tool
# Expected: returns user list without auth

# 5. Test vulnerability: internal config with DB creds
curl -s http://localhost:8000/api/internal/config | python3 -m json.tool
# Expected: returns DB host, user, password

# 6. Test vulnerability: SQL injection
curl -s "http://localhost:8000/api/search?q=test' UNION SELECT 1,'a','b','c'--" | python3 -m json.tool

# 7. Test robots.txt
curl -s http://localhost/robots.txt
# Expected: Disallow entries for /api/admin/, /api/internal/

# 8. Test Next.js frontend
curl -sk https://localhost/ | head -20
# Expected: HTML with MOIS Portal content

# 9. Verify React/Next.js versions
cat /opt/mois-portal/frontend/package.json | grep -E '"next"|"react"'
# Expected: next 15.0.3, react 19.1.0

# 10. Test inquiry lookup
curl -s http://localhost:8000/api/inquiry/INQ-20260315-0001 | python3 -m json.tool
```

---

## Execution Order Summary

1. **Asset 08 first** (DB must exist before portal can connect):
   - Task 1: setup.sh + conf files
   - Task 2: SQL DDL files
   - Task 3: Seed data + scripts
   - Task 7.1: Verify Asset 08

2. **Asset 01 second** (depends on Asset 08):
   - Task 4: FastAPI backend
   - Task 5: Next.js frontend
   - Task 6: Nginx + systemd + setup.sh
   - Task 7.2: Verify Asset 01

---

## File Count Summary

**Asset 08 (11 files):**
- `assets/08_DB서버/.env.example`
- `assets/08_DB서버/setup.sh`
- `assets/08_DB서버/conf/pg_hba.conf`
- `assets/08_DB서버/conf/pgaudit.conf`
- `assets/08_DB서버/sql/00_roles.sql`
- `assets/08_DB서버/sql/01_mois_portal_ddl.sql`
- `assets/08_DB서버/sql/02_agency_db_ddl.sql`
- `assets/08_DB서버/sql/03_complaint_db_ddl.sql`
- `assets/08_DB서버/sql/10_mois_portal_seed.sql`
- `assets/08_DB서버/sql/11_agency_db_seed.sql`
- `assets/08_DB서버/sql/12_complaint_db_seed.sql`
- `assets/08_DB서버/scripts/backup.sh`
- `assets/08_DB서버/scripts/monitor.sh`

**Asset 01 (24 files):**
- `assets/01_외부포털서버/.env.example`
- `assets/01_외부포털서버/setup.sh`
- `assets/01_외부포털서버/src/backend/main.py`
- `assets/01_외부포털서버/src/backend/config.py`
- `assets/01_외부포털서버/src/backend/database.py`
- `assets/01_외부포털서버/src/backend/requirements.txt`
- `assets/01_외부포털서버/src/backend/routers/__init__.py`
- `assets/01_외부포털서버/src/backend/routers/notices.py`
- `assets/01_외부포털서버/src/backend/routers/search.py`
- `assets/01_외부포털서버/src/backend/routers/inquiry.py`
- `assets/01_외부포털서버/src/backend/routers/admin.py`
- `assets/01_외부포털서버/src/backend/routers/internal.py`
- `assets/01_외부포털서버/src/frontend/package.json`
- `assets/01_외부포털서버/src/frontend/next.config.js`
- `assets/01_외부포털서버/src/frontend/tailwind.config.js`
- `assets/01_외부포털서버/src/frontend/postcss.config.js`
- `assets/01_외부포털서버/src/frontend/lib/api.js`
- `assets/01_외부포털서버/src/frontend/app/globals.css`
- `assets/01_외부포털서버/src/frontend/app/layout.js`
- `assets/01_외부포털서버/src/frontend/app/page.js`
- `assets/01_외부포털서버/src/frontend/app/notices/page.js`
- `assets/01_외부포털서버/src/frontend/app/notices/[id]/page.js`
- `assets/01_외부포털서버/src/frontend/app/search/page.js`
- `assets/01_외부포털서버/src/frontend/app/inquiry/page.js`
- `assets/01_외부포털서버/src/frontend/app/login/page.js`
- `assets/01_외부포털서버/src/frontend/components/Header.jsx`
- `assets/01_외부포털서버/src/frontend/components/Footer.jsx`
- `assets/01_외부포털서버/src/frontend/components/Pagination.jsx`
- `assets/01_외부포털서버/src/frontend/components/SearchBar.jsx`
- `assets/01_외부포털서버/src/config/nginx/mois-portal.conf`
- `assets/01_외부포털서버/src/config/systemd/mois-portal-api.service`
- `assets/01_외부포털서버/src/config/systemd/mois-portal-web.service`
