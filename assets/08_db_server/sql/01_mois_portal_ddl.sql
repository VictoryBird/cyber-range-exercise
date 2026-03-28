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
