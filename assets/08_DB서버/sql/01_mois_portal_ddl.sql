-- =============================================================
-- 01_mois_portal_ddl.sql — 외부 포털 스키마
-- 데이터베이스: mois_portal
-- 용도: 시민 대상 공지, 문의, 사용자 관리
-- =============================================================

\c mois_portal;

CREATE TABLE IF NOT EXISTS users (
    id              SERIAL PRIMARY KEY,
    username        VARCHAR(100) UNIQUE NOT NULL,
    email           VARCHAR(200),
    password        VARCHAR(200) NOT NULL,
    role            VARCHAR(50) DEFAULT 'viewer',
    last_login      TIMESTAMP,
    created_at      TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_username ON users(username);

CREATE TABLE IF NOT EXISTS notices (
    id              SERIAL PRIMARY KEY,
    title           VARCHAR(500) NOT NULL,
    content         TEXT,
    category        VARCHAR(100) DEFAULT '일반',
    author          VARCHAR(100) DEFAULT '관리자',
    is_public       BOOLEAN DEFAULT TRUE,
    view_count      INTEGER DEFAULT 0,
    created_at      TIMESTAMP DEFAULT NOW(),
    updated_at      TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_notices_category ON notices(category);
CREATE INDEX IF NOT EXISTS idx_notices_created ON notices(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notices_is_public ON notices(is_public);

CREATE TABLE IF NOT EXISTS inquiries (
    id              SERIAL PRIMARY KEY,
    tracking_number VARCHAR(50) UNIQUE NOT NULL,
    subject         VARCHAR(500) NOT NULL,
    description     TEXT,
    status          VARCHAR(50) DEFAULT '접수',
    department      VARCHAR(200),
    submitter_name  VARCHAR(100),
    submitter_email VARCHAR(200),
    submitted_at    TIMESTAMP DEFAULT NOW(),
    updated_at      TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_inquiries_tracking ON inquiries(tracking_number);
CREATE INDEX IF NOT EXISTS idx_inquiries_status ON inquiries(status);

-- 확장 모듈
CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

-- 권한 부여
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO app_service;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO app_service;
GRANT USAGE ON SCHEMA public TO portal_ro;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO portal_ro;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO portal_ro;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO portal_app;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO portal_app;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO portal_app;
