#!/bin/bash
set -e

# mois_portal DDL + seed
psql -U postgres -d mois_portal -f /docker-entrypoint-initdb.d/sql/01_mois_portal_ddl.sql
psql -U postgres -d mois_portal -f /docker-entrypoint-initdb.d/sql/10_mois_portal_seed.sql

# agency_db DDL + seed
psql -U postgres -d agency_db -f /docker-entrypoint-initdb.d/sql/02_agency_db_ddl.sql
psql -U postgres -d agency_db -f /docker-entrypoint-initdb.d/sql/11_agency_db_seed.sql

# complaint_db DDL + seed
psql -U postgres -d complaint_db -f /docker-entrypoint-initdb.d/sql/03_complaint_db_ddl.sql
psql -U postgres -d complaint_db -f /docker-entrypoint-initdb.d/sql/12_complaint_db_seed.sql

# Grants
psql -U postgres -d mois_portal -c "
CREATE EXTENSION IF NOT EXISTS pgcrypto;
GRANT ALL ON ALL TABLES IN SCHEMA public TO app_service;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO app_service;
GRANT ALL ON ALL TABLES IN SCHEMA public TO portal_app;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO portal_app;
GRANT USAGE ON SCHEMA public TO portal_ro;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO portal_ro;
"

psql -U postgres -d agency_db -c "
GRANT ALL ON ALL TABLES IN SCHEMA public TO app_service;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO app_service;
"

psql -U postgres -d complaint_db -c "
GRANT ALL ON ALL TABLES IN SCHEMA public TO app_service;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO app_service;
GRANT USAGE ON SCHEMA public TO complaint_rw;
GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA public TO complaint_rw;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO complaint_rw;
"

echo "=== All schemas and seeds initialized ==="
