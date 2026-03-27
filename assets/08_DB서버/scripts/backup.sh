#!/bin/bash
# DB 서버 — 일간 백업 스크립트
# 크론: 0 2 * * * /opt/db-scripts/backup.sh

BACKUP_DIR="/var/backups/postgresql/daily"
DATE=$(date +%Y%m%d_%H%M%S)
DATABASES="mois_portal agency_db complaint_db"

mkdir -p ${BACKUP_DIR}

for DB in ${DATABASES}; do
    pg_dump -U postgres -d ${DB} -F c -f "${BACKUP_DIR}/${DB}_${DATE}.dump" 2>/dev/null
done

# 7일 이상 된 백업 삭제
find ${BACKUP_DIR} -name "*.dump" -mtime +7 -delete
