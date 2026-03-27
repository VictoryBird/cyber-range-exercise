-- =============================================================
-- 02_agency_db_ddl.sql — 내부 업무 포털 스키마
-- 데이터베이스: agency_db
-- 용도: 직원정보, 부서, 전자결재, 업무요청
-- =============================================================

\c agency_db;

CREATE TABLE IF NOT EXISTS departments (
    dept_id         SERIAL PRIMARY KEY,
    dept_code       VARCHAR(20) NOT NULL UNIQUE,
    dept_name       VARCHAR(100) NOT NULL,
    parent_dept_id  INTEGER REFERENCES departments(dept_id),
    head_employee_id INTEGER,
    floor_location  VARCHAR(20),
    phone_ext       VARCHAR(10),
    created_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS employees (
    employee_id     SERIAL PRIMARY KEY,
    emp_number      VARCHAR(20) NOT NULL UNIQUE,
    full_name       VARCHAR(100) NOT NULL,
    email           VARCHAR(120) NOT NULL UNIQUE,
    phone           VARCHAR(20),
    dept_id         INTEGER REFERENCES departments(dept_id),
    position_title  VARCHAR(50) NOT NULL,
    role_title      VARCHAR(50),
    hire_date       DATE NOT NULL,
    ad_username     VARCHAR(50) UNIQUE,
    password_hash   VARCHAR(256),
    is_active       BOOLEAN DEFAULT TRUE,
    created_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_employees_dept ON employees(dept_id);
CREATE INDEX IF NOT EXISTS idx_employees_empnum ON employees(emp_number);
CREATE INDEX IF NOT EXISTS idx_employees_ad ON employees(ad_username);

ALTER TABLE departments
    ADD CONSTRAINT fk_dept_head
    FOREIGN KEY (head_employee_id) REFERENCES employees(employee_id);

CREATE TABLE IF NOT EXISTS approvals (
    approval_id     SERIAL PRIMARY KEY,
    doc_number      VARCHAR(30) NOT NULL UNIQUE,
    title           VARCHAR(300) NOT NULL,
    content         TEXT NOT NULL,
    doc_type        VARCHAR(50) NOT NULL DEFAULT '일반기안',
    drafter_id      INTEGER NOT NULL REFERENCES employees(employee_id),
    current_step    INTEGER DEFAULT 1,
    total_steps     INTEGER DEFAULT 3,
    status          VARCHAR(20) NOT NULL DEFAULT '기안',
    approved_by     TEXT,
    rejected_reason TEXT,
    created_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_approvals_drafter ON approvals(drafter_id);
CREATE INDEX IF NOT EXISTS idx_approvals_status ON approvals(status);
CREATE INDEX IF NOT EXISTS idx_approvals_docnum ON approvals(doc_number);

CREATE TABLE IF NOT EXISTS work_requests (
    request_id      SERIAL PRIMARY KEY,
    request_number  VARCHAR(30) NOT NULL UNIQUE,
    title           VARCHAR(300) NOT NULL,
    description     TEXT NOT NULL,
    requester_id    INTEGER NOT NULL REFERENCES employees(employee_id),
    assignee_id     INTEGER REFERENCES employees(employee_id),
    priority        VARCHAR(10) NOT NULL DEFAULT '보통',
    status          VARCHAR(20) NOT NULL DEFAULT '요청',
    due_date        DATE,
    completed_at    TIMESTAMP WITH TIME ZONE,
    created_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_workreq_requester ON work_requests(requester_id);
CREATE INDEX IF NOT EXISTS idx_workreq_assignee ON work_requests(assignee_id);
CREATE INDEX IF NOT EXISTS idx_workreq_status ON work_requests(status);

CREATE EXTENSION IF NOT EXISTS pgcrypto;

GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO app_service;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO app_service;
