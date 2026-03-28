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
