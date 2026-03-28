-- =============================================================
-- 03_complaint_db_ddl.sql -- complaint_db Database Schema
-- Purpose: Complaint filing and processing
-- =============================================================

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- -----------------------------------------------------------
-- Table: complaints
-- -----------------------------------------------------------
CREATE TABLE complaints (
    complaint_id    SERIAL PRIMARY KEY,
    complaint_number VARCHAR(30) NOT NULL UNIQUE,
    applicant_name  VARCHAR(100) NOT NULL,
    applicant_email VARCHAR(120),
    applicant_phone VARCHAR(20),
    applicant_addr  VARCHAR(300),
    category        VARCHAR(50) NOT NULL,
    title           VARCHAR(300) NOT NULL,
    content         TEXT NOT NULL,
    status          VARCHAR(20) NOT NULL DEFAULT 'Received',
    priority        VARCHAR(10) DEFAULT 'Normal',
    assigned_dept   VARCHAR(100),
    assigned_to     VARCHAR(100),
    response        TEXT,
    responded_at    TIMESTAMP WITH TIME ZONE,
    created_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_complaints_number ON complaints(complaint_number);
CREATE INDEX idx_complaints_status ON complaints(status);
CREATE INDEX idx_complaints_category ON complaints(category);
CREATE INDEX idx_complaints_created ON complaints(created_at DESC);

-- -----------------------------------------------------------
-- Table: attachments (file metadata)
-- -----------------------------------------------------------
CREATE TABLE attachments (
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

CREATE INDEX idx_attachments_complaint ON attachments(complaint_id);

-- -----------------------------------------------------------
-- Table: complaint_file_processing
-- -----------------------------------------------------------
CREATE TABLE complaint_file_processing (
    id              SERIAL PRIMARY KEY,
    complaint_id    INTEGER NOT NULL REFERENCES complaints(complaint_id),
    original_filename VARCHAR(300) NOT NULL,
    original_size   BIGINT,
    converted_files TEXT[],
    file_type       VARCHAR(50),
    processing_time_sec FLOAT,
    status          VARCHAR(20) DEFAULT 'pending',
    error_message   TEXT,
    processed_at    TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_file_proc_complaint ON complaint_file_processing(complaint_id);

-- -----------------------------------------------------------
-- Table: processing_logs
-- -----------------------------------------------------------
CREATE TABLE processing_logs (
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

CREATE INDEX idx_proclogs_complaint ON processing_logs(complaint_id);
CREATE INDEX idx_proclogs_action ON processing_logs(action);
CREATE INDEX idx_proclogs_created ON processing_logs(created_at DESC);

-- -----------------------------------------------------------
-- Permissions
-- -----------------------------------------------------------
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO app_service;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO app_service;
