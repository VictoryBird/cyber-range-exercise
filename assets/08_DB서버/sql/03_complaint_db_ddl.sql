-- =============================================================
-- 03_complaint_db_ddl.sql — 민원 처리 스키마
-- 데이터베이스: complaint_db
-- 용도: 민원 접수/처리, 첨부파일, 처리 이력
-- =============================================================

\c complaint_db;

CREATE TABLE IF NOT EXISTS complaints (
    complaint_id    SERIAL PRIMARY KEY,
    complaint_number VARCHAR(30) NOT NULL UNIQUE,
    applicant_name  VARCHAR(100) NOT NULL,
    applicant_email VARCHAR(120),
    applicant_phone VARCHAR(20),
    applicant_addr  VARCHAR(300),
    category        VARCHAR(50) NOT NULL,
    title           VARCHAR(300) NOT NULL,
    content         TEXT NOT NULL,
    status          VARCHAR(20) NOT NULL DEFAULT '접수',
    priority        VARCHAR(10) DEFAULT '보통',
    assigned_dept   VARCHAR(100),
    assigned_to     VARCHAR(100),
    response        TEXT,
    responded_at    TIMESTAMP WITH TIME ZONE,
    created_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_complaints_number ON complaints(complaint_number);
CREATE INDEX IF NOT EXISTS idx_complaints_status ON complaints(status);
CREATE INDEX IF NOT EXISTS idx_complaints_category ON complaints(category);
CREATE INDEX IF NOT EXISTS idx_complaints_created ON complaints(created_at DESC);

CREATE TABLE IF NOT EXISTS attachments (
    attachment_id   SERIAL PRIMARY KEY,
    complaint_id    INTEGER NOT NULL REFERENCES complaints(complaint_id),
    original_name   VARCHAR(300) NOT NULL,
    stored_path     VARCHAR(500) NOT NULL,
    file_size       BIGINT,
    mime_type       VARCHAR(100),
    checksum_sha256 VARCHAR(64),
    is_converted    BOOLEAN DEFAULT FALSE,
    converted_path  VARCHAR(500),
    uploaded_at     TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_attachments_complaint ON attachments(complaint_id);

CREATE TABLE IF NOT EXISTS processing_logs (
    log_id          SERIAL PRIMARY KEY,
    complaint_id    INTEGER NOT NULL REFERENCES complaints(complaint_id),
    action          VARCHAR(50) NOT NULL,
    actor_name      VARCHAR(100) NOT NULL,
    actor_dept      VARCHAR(100),
    description     TEXT,
    previous_status VARCHAR(20),
    new_status      VARCHAR(20),
    created_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_proclogs_complaint ON processing_logs(complaint_id);
CREATE INDEX IF NOT EXISTS idx_proclogs_action ON processing_logs(action);
CREATE INDEX IF NOT EXISTS idx_proclogs_created ON processing_logs(created_at DESC);

CREATE EXTENSION IF NOT EXISTS pgcrypto;

GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO app_service;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO app_service;
GRANT USAGE ON SCHEMA public TO complaint_rw;
GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA public TO complaint_rw;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO complaint_rw;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE ON TABLES TO complaint_rw;
