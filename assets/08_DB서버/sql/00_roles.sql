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
