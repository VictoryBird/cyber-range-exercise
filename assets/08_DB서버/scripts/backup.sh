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
