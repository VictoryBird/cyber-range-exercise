-- =============================================================
-- 01_mois_portal_ddl.sql — 외부 포털 스키마
-- 데이터베이스: mois_portal
-- 용도: 시민 대상 공지, 문의, 사용자 관리
-- =============================================================

\c mois_portal;

CREATE TABLE IF NOT EXISTS users (
    user_id         SERIAL PRIMARY KEY,
    username        VARCHAR(50) NOT NULL UNIQUE,
    email           VARCHAR(120) NOT NULL UNIQUE,
    password_hash   VARCHAR(256) NOT NULL,
    full_name       VARCHAR(100) NOT NULL,
    phone           VARCHAR(20),
    is_active       BOOLEAN DEFAULT TRUE,
    is_admin        BOOLEAN DEFAULT FALSE,
    created_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_login      TIMESTAMP WITH TIME ZONE
);

CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_username ON users(username);

CREATE TABLE IF NOT EXISTS notices (
    notice_id       SERIAL PRIMARY KEY,
    title           VARCHAR(300) NOT NULL,
    content         TEXT NOT NULL,
    category        VARCHAR(50) NOT NULL DEFAULT '일반',
    author_name     VARCHAR(100) NOT NULL,
    is_pinned       BOOLEAN DEFAULT FALSE,
    view_count      INTEGER DEFAULT 0,
    created_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_notices_category ON notices(category);
CREATE INDEX IF NOT EXISTS idx_notices_created ON notices(created_at DESC);

CREATE TABLE IF NOT EXISTS inquiries (
    inquiry_id      SERIAL PRIMARY KEY,
    user_id         INTEGER REFERENCES users(user_id),
    subject         VARCHAR(300) NOT NULL,
    content         TEXT NOT NULL,
    category        VARCHAR(50) NOT NULL DEFAULT '일반문의',
    status          VARCHAR(20) NOT NULL DEFAULT '접수',
    reply           TEXT,
    replied_by      VARCHAR(100),
    replied_at      TIMESTAMP WITH TIME ZONE,
    created_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_inquiries_user ON inquiries(user_id);
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
