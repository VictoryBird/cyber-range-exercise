-- =============================================================
-- 11_agency_db_seed.sql -- Internal Business Portal Seed Data
-- Asset 08: DB Server (192.168.92.208)
-- Database: agency_db
-- =============================================================

-- ----- Departments -----
INSERT INTO departments (dept_code, dept_name, parent_dept_id, floor_location, phone_ext) VALUES
('PLAN',     'Planning & Coordination Office',       NULL, '6F',  '1100'),
('POLICY',   'Policy Planning Division',             1,    '6F',  '1110'),
('BUDGET',   'Budget Management Office',             1,    '6F',  '1120'),
('DIG',      'Digital Government Bureau',            NULL, '5F',  '2100'),
('DIGPLAN',  'Digital Government Planning Division', 4,    '5F',  '2110'),
('INFOSEC',  'Information Security Division',        4,    '5F',  '2120'),
('INFOPLAN', 'Information Planning Office',          4,    '5F',  '2130'),
('SAFETY',   'Disaster & Safety Management Bureau',  NULL, '4F',  '3100'),
('DISAST',   'Disaster Response Division',           8,    '4F',  '3110'),
('FIRESAF',  'Fire Safety Division',                 8,    '4F',  '3120'),
('CIVIL',    'Complaint Processing Division',        NULL, '3F',  '4100'),
('PRIVACY',  'Privacy Protection Office',            NULL, '3F',  '4200'),
('HR',       'Human Resources Division',             NULL, '7F',  '5100'),
('IT',       'IT Management Office',                 4,    '5F',  '2140'),
('FACILITY', 'Facilities Management Division',       NULL, '1F',  '6100');

-- ----- Employees -----
INSERT INTO employees (emp_number, full_name, email, phone, dept_id, position_title, role_title, hire_date, ad_username, password_hash, is_active) VALUES
('MOI-2018-0042', 'Daniel Harper',   'daniel.harper@mois.valdoria.gov',    '044-205-1100', 1,  'Director',         'Planning Office Director',     '2018-03-02', 'admin_harper',     crypt('Mois2026!Harper', gen_salt('bf')),  TRUE),
('MOI-2019-0087', 'Olivia Bennett',  'olivia.bennett@mois.valdoria.gov',   '044-205-1110', 2,  'Deputy Director',  'Policy Planning Chief',        '2019-05-15', 'user_obennett',    crypt('Mois2026!Bennett', gen_salt('bf')), TRUE),
('MOI-2020-0103', 'Nathan Brooks',   'nathan.brooks@mois.valdoria.gov',    '044-205-1120', 3,  'Deputy Director',  'Budget Manager',               '2020-01-06', 'user_nbrooks',     crypt('Mois2026!Brooks', gen_salt('bf')),  TRUE),
('MOI-2017-0031', 'Emily Watson',    'emily.watson@mois.valdoria.gov',     '044-205-2100', 4,  'Senior Director',  'Digital Government Director',  '2017-09-01', 'user_watson',      crypt('Mois2026!Watson', gen_salt('bf')),  TRUE),
('MOI-2021-0156', 'Michael Torres',  'michael.torres@mois.valdoria.gov',   '044-205-2110', 5,  'Staff',            NULL,                           '2021-03-15', 'user_torres',      crypt('Mois2026!Torres', gen_salt('bf')),  TRUE),
('MOI-2019-0092', 'David Chen',      'david.chen@mois.valdoria.gov',       '044-205-2120', 6,  'Deputy Director',  'InfoSec Division Chief',       '2019-07-22', 'user_chen',        crypt('Mois2026!Chen', gen_salt('bf')),    TRUE),
('MOI-2020-0115', 'Rachel Kim',      'rachel.kim@mois.valdoria.gov',       '044-205-2130', 7,  'Deputy Director',  'Information Planning Chief',   '2020-04-01', 'user_rkim',        crypt('Mois2026!Kim', gen_salt('bf')),     TRUE),
('MOI-2016-0015', 'Andrew Lawson',   'andrew.lawson@mois.valdoria.gov',    '044-205-3100', 8,  'Senior Director',  'Disaster Bureau Director',    '2016-06-10', 'user_alawson',     crypt('Mois2026!Lawson', gen_salt('bf')),  TRUE),
('MOI-2022-0201', 'Jessica Park',    'jessica.park@mois.valdoria.gov',     '044-205-3110', 9,  'Staff',            NULL,                           '2022-01-03', 'user_jpark',       crypt('Mois2026!JePark', gen_salt('bf')),  TRUE),
('MOI-2021-0178', 'Brandon Lee',     'brandon.lee@mois.valdoria.gov',      '044-205-3120', 10, 'Staff',            NULL,                           '2021-09-01', 'user_blee',        crypt('Mois2026!BLee', gen_salt('bf')),    TRUE),
('MOI-2018-0055', 'Sarah Mitchell',  'sarah.mitchell@mois.valdoria.gov',   '044-205-4100', 11, 'Deputy Director',  'Complaint Division Chief',    '2018-11-15', 'user_mitchell',    crypt('Mois2026!Mitchell', gen_salt('bf')),TRUE),
('MOI-2019-0099', 'Christopher Hall','christopher.hall@mois.valdoria.gov',  '044-205-4200', 12, 'Deputy Director',  'Privacy Officer',             '2019-02-18', 'user_chall',       crypt('Mois2026!Hall', gen_salt('bf')),    TRUE),
('MOI-2023-0245', 'Kevin Yoo',       'kevin.yoo@mois.valdoria.gov',        '044-205-5100', 13, 'Staff',            NULL,                           '2023-03-02', 'user_kyoo',        crypt('Mois2026!Yoo', gen_salt('bf')),     TRUE),
('MOI-2020-0120', 'Amanda Liu',      'amanda.liu@mois.valdoria.gov',       '044-205-2140', 14, 'Deputy Director',  'IT Management Chief',         '2020-06-01', 'user_aliu',        crypt('Mois2026!Liu', gen_salt('bf')),     TRUE),
('MOI-2022-0210', 'Jason Kang',      'jason.kang@mois.valdoria.gov',       '044-205-2141', 14, 'Staff',            NULL,                           '2022-07-15', 'user_jkang',       crypt('Mois2026!Kang', gen_salt('bf')),    TRUE),
('MOI-2024-0301', 'Michelle Cho',    'michelle.cho@mois.valdoria.gov',     '044-205-2112', 5,  'Staff',            NULL,                           '2024-01-08', 'user_mcho',        crypt('Mois2026!MCho', gen_salt('bf')),    TRUE),
('MOI-2023-0260', 'Eric Song',       'eric.song@mois.valdoria.gov',        '044-205-3111', 9,  'Staff',            NULL,                           '2023-09-01', 'user_esong',       crypt('Mois2026!Song', gen_salt('bf')),    TRUE),
('MOI-2021-0165', 'Victoria Yoon',   'victoria.yoon@mois.valdoria.gov',    '044-205-4101', 11, 'Staff',            NULL,                           '2021-05-17', 'user_vyoon',       crypt('Mois2026!VYoon', gen_salt('bf')),   TRUE),
('MOI-2025-0350', 'Tyler Hwang',     'tyler.hwang@mois.valdoria.gov',      '044-205-6100', 15, 'Staff',            NULL,                           '2025-03-03', 'user_thwang',      crypt('Mois2026!Hwang', gen_salt('bf')),   TRUE);

-- Department head mapping
UPDATE departments SET head_employee_id = 1  WHERE dept_code = 'PLAN';
UPDATE departments SET head_employee_id = 2  WHERE dept_code = 'POLICY';
UPDATE departments SET head_employee_id = 3  WHERE dept_code = 'BUDGET';
UPDATE departments SET head_employee_id = 4  WHERE dept_code = 'DIG';
UPDATE departments SET head_employee_id = 7  WHERE dept_code = 'INFOPLAN';
UPDATE departments SET head_employee_id = 6  WHERE dept_code = 'INFOSEC';
UPDATE departments SET head_employee_id = 8  WHERE dept_code = 'SAFETY';
UPDATE departments SET head_employee_id = 11 WHERE dept_code = 'CIVIL';
UPDATE departments SET head_employee_id = 12 WHERE dept_code = 'PRIVACY';
UPDATE departments SET head_employee_id = 14 WHERE dept_code = 'IT';

-- ----- Approvals -----
INSERT INTO approvals (doc_number, title, content, doc_type, drafter_id, current_step, total_steps, status, approved_by, created_at) VALUES
('APPR-2026-0001', 'Q1 2026 Information Security Training Plan',
 '1. Objective: Strengthen all-staff information security capabilities
2. Target: All MOIS employees (412 personnel)
3. Period: 2026.01.15 ~ 2026.02.28
4. Method: Online training + offline seminar
5. Budget: 12,500,000 VCR',
 'General', 6, 3, 3, 'Approved',
 '["David Chen (Drafter)", "Emily Watson (Review)", "Daniel Harper (Approval)"]',
 '2026-01-05 09:00:00+00'),

('APPR-2026-0012', 'E-Government Cloud Migration Project Plan',
 '1. Project: 2026 E-Government Cloud-Native Transition
2. Budget: 4,500,000,000 VCR
3. Period: 2026.04 ~ 2026.12
4. Scope: 22 major information systems
5. Structure: PMO + Cloud specialist vendor',
 'General', 7, 2, 3, 'In Progress',
 '["Rachel Kim (Drafter)", "Emily Watson (Under Review)"]',
 '2026-02-10 10:30:00+00'),

('APPR-2026-0023', 'Complaint System AI Enhancement Contract Request',
 '1. Service: Complaint Auto-Classification AI Model Enhancement
2. Budget: 850,000,000 VCR
3. Period: 2026.05 ~ 2026.10
4. Procurement: Restricted competitive bidding',
 'Expenditure', 11, 3, 3, 'Approved',
 '["Sarah Mitchell (Drafter)", "Daniel Harper (Review)", "Emily Watson (Approval)"]',
 '2026-02-20 14:00:00+00'),

('APPR-2026-0034', 'H1 2026 Overseas Trip Application -- Digital Government Benchmarking',
 '1. Destination: Tallinn, Estonia
2. Period: 2026.05.10 ~ 2026.05.17 (8 days)
3. Objective: X-Road e-Government platform benchmarking
4. Travelers: Michael Torres (Staff), Michelle Cho (Staff)
5. Budget: 8,200,000 VCR',
 'Travel', 5, 1, 3, 'Draft',
 '["Michael Torres (Drafter)"]',
 '2026-03-15 11:00:00+00'),

('APPR-2026-0045', 'Emergency Vulnerability Patch Request',
 '1. Urgency: High
2. Target: MOIS External Portal Server
3. Issue: Log4j-like vulnerability pattern detected (CVE-2021-44228 variant)
4. Action: Immediate patching and monitoring enhancement
5. Impact: All externally accessible services',
 'General', 6, 3, 3, 'Approved',
 '["David Chen (Drafter)", "Emily Watson (Emergency Review)", "Daniel Harper (Emergency Approval)"]',
 '2026-03-22 08:30:00+00'),

('APPR-2026-0056', 'Civil Service Exam Support Plan 2026',
 '1. Exam: 2026 Grade 9 National Civil Service Open Competitive Exam
2. Date: April 15, 2026 (Saturday)
3. Support: Venue inspection, network infrastructure support
4. Budget: 3,200,000 VCR',
 'General', 13, 1, 3, 'Draft',
 '["Kevin Yoo (Drafter)"]',
 '2026-03-24 09:00:00+00');

-- ----- Work Requests -----
INSERT INTO work_requests (request_number, title, description, requester_id, assignee_id, priority, status, due_date, created_at) VALUES
('WR-2026-0001', 'External Portal SSL Certificate Renewal',
 'The SSL certificate for the external portal (mois.valdoria.gov) expires on April 15, 2026. Please arrange renewal.',
 7, 14, 'High', 'Completed', '2026-04-10',
 '2026-03-01 10:00:00+00'),

('WR-2026-0002', 'Internal Portal Search Bug Fix',
 'The internal business portal search function returns no results when searching in certain languages. Please investigate and fix.
Reproduction: Type "approval" in search bar -> No results',
 2, 15, 'Urgent', 'In Progress', '2026-03-25',
 '2026-03-20 14:30:00+00'),

('WR-2026-0003', 'DB Server Backup Script Audit',
 'During quarterly inspection, DB backup files were found to not be generating properly. Please audit the backup script and cron configuration.',
 6, 14, 'High', 'Requested', '2026-03-28',
 '2026-03-23 09:00:00+00'),

('WR-2026-0004', 'Complaint System Performance Optimization',
 'Complaint attachment PDF conversion is averaging 45 seconds. Please evaluate server resource scaling or processing logic optimization.',
 11, 5, 'Normal', 'Accepted', '2026-04-15',
 '2026-03-24 11:00:00+00'),

('WR-2026-0005', 'New Employee AD Account Creation Request',
 'Please create AD accounts for 3 new employees starting April 1, 2026:
1. Grace Cho (Digital Government Planning Division)
2. Marcus Yang (Disaster Response Division)
3. Sophia Lim (Complaint Processing Division)',
 13, 14, 'Normal', 'Requested', '2026-03-30',
 '2026-03-25 10:00:00+00');
