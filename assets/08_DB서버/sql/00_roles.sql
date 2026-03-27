-- =============================================================
-- 00_roles.sql — PostgreSQL 역할/계정 생성
-- DB 서버 (192.168.100.20)
-- =============================================================

-- [VULN-DB-01] 서비스 계정에 SUPERUSER 권한 부여 (의도적 취약점)
-- 올바른 구현: 각 DB별로 최소 권한 계정을 분리하여 사용
CREATE ROLE app_service
    WITH SUPERUSER LOGIN PASSWORD 'Sup3rS3cr3t!'
    CREATEDB CREATEROLE;
COMMENT ON ROLE app_service IS '서비스 통합 계정 — 모든 DB 접근 (SUPERUSER, 의도적 취약점)';

-- 읽기 전용 계정 (외부 포털 조회용)
CREATE ROLE portal_ro
    WITH LOGIN PASSWORD 'Portal_R3ad0nly@2026'
    NOSUPERUSER NOCREATEDB NOCREATEROLE;
COMMENT ON ROLE portal_ro IS '외부 포털 읽기 전용 계정';

-- 민원 처리 전용 계정 (읽기/쓰기)
CREATE ROLE complaint_rw
    WITH LOGIN PASSWORD 'Compl@int_RW_2026!'
    NOSUPERUSER NOCREATEDB NOCREATEROLE;
COMMENT ON ROLE complaint_rw IS '민원 처리 읽기/쓰기 계정';

-- 외부 포털 서버 전용 계정 (01번 자산에서 사용)
CREATE ROLE portal_app
    WITH LOGIN PASSWORD 'P0rtal#DB@2026!'
    NOSUPERUSER NOCREATEDB NOCREATEROLE;
COMMENT ON ROLE portal_app IS '외부 포털 서버 전용 계정';
