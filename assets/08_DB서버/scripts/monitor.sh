#!/bin/bash
# DB 서버 — 간이 모니터링 스크립트
# 활성 연결, SUPERUSER 목록, DB 크기 출력

echo "=== PostgreSQL 모니터링 ==="
echo ""

echo "--- 활성 연결 ---"
sudo -u postgres psql -c "
SELECT pid, usename, datname, client_addr, state, query_start
FROM pg_stat_activity
WHERE state = 'active' AND pid <> pg_backend_pid()
ORDER BY query_start;"

echo ""
echo "--- SUPERUSER 목록 ---"
sudo -u postgres psql -c "
SELECT rolname, rolsuper, rolcreatedb, rolcanlogin
FROM pg_roles WHERE rolsuper = true;"

echo ""
echo "--- 데이터베이스 크기 ---"
sudo -u postgres psql -c "
SELECT datname, pg_size_pretty(pg_database_size(datname)) as size
FROM pg_database WHERE datistemplate = false ORDER BY pg_database_size(datname) DESC;"
