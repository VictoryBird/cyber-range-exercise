-- =============================================================
-- 02_agency_db_ddl.sql -- agency_db Database Schema
-- Purpose: Internal business portal (employees, departments, approvals, work requests)
-- =============================================================

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- -----------------------------------------------------------
-- Table: departments
-- -----------------------------------------------------------
CREATE TABLE departments (
    dept_id         SERIAL PRIMARY KEY,
    dept_code       VARCHAR(20) NOT NULL UNIQUE,
    dept_name       VARCHAR(100) NOT NULL,
    parent_dept_id  INTEGER REFERENCES departments(dept_id),
    head_employee_id INTEGER,
    floor_location  VARCHAR(20),
    phone_ext       VARCHAR(10),
    created_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- -----------------------------------------------------------
-- Table: employees
-- -----------------------------------------------------------
CREATE TABLE employees (
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

CREATE INDEX idx_employees_dept ON employees(dept_id);
CREATE INDEX idx_employees_empnum ON employees(emp_number);
CREATE INDEX idx_employees_ad ON employees(ad_username);

-- Deferred FK for department head
ALTER TABLE departments
    ADD CONSTRAINT fk_dept_head
    FOREIGN KEY (head_employee_id) REFERENCES employees(employee_id);

-- -----------------------------------------------------------
-- Table: approvals (document approvals)
-- -----------------------------------------------------------
CREATE TABLE approvals (
    approval_id     SERIAL PRIMARY KEY,
    doc_number      VARCHAR(30) NOT NULL UNIQUE,
    title           VARCHAR(300) NOT NULL,
    content         TEXT NOT NULL,
    doc_type        VARCHAR(50) NOT NULL DEFAULT 'General',
    drafter_id      INTEGER NOT NULL REFERENCES employees(employee_id),
    current_step    INTEGER DEFAULT 1,
    total_steps     INTEGER DEFAULT 3,
    status          VARCHAR(20) NOT NULL DEFAULT 'Draft',
    approved_by     TEXT,
    rejected_reason TEXT,
    created_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_approvals_drafter ON approvals(drafter_id);
CREATE INDEX idx_approvals_status ON approvals(status);
CREATE INDEX idx_approvals_docnum ON approvals(doc_number);

-- -----------------------------------------------------------
-- Table: work_requests
-- -----------------------------------------------------------
CREATE TABLE work_requests (
    request_id      SERIAL PRIMARY KEY,
    request_number  VARCHAR(30) NOT NULL UNIQUE,
    title           VARCHAR(300) NOT NULL,
    description     TEXT NOT NULL,
    requester_id    INTEGER NOT NULL REFERENCES employees(employee_id),
    assignee_id     INTEGER REFERENCES employees(employee_id),
    priority        VARCHAR(10) NOT NULL DEFAULT 'Normal',
    status          VARCHAR(20) NOT NULL DEFAULT 'Requested',
    due_date        DATE,
    completed_at    TIMESTAMP WITH TIME ZONE,
    created_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_workreq_requester ON work_requests(requester_id);
CREATE INDEX idx_workreq_assignee ON work_requests(assignee_id);
CREATE INDEX idx_workreq_status ON work_requests(status);

-- -----------------------------------------------------------
-- Permissions
-- -----------------------------------------------------------
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO app_service;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO app_service;
