-- =============================================================
-- 10_mois_portal_seed.sql -- External Portal Seed Data
-- Asset 08: DB Server (192.168.92.208)
-- Database: mois_portal
-- Uses English names per worldbuilding document
-- =============================================================

-- ----- Portal users -----
INSERT INTO users (username, email, password, role, last_login, created_at) VALUES
('daniel.harper',   'daniel.harper@mois.valdoria.gov',   crypt('@dminMOIS2026!', gen_salt('bf')),  'superadmin', '2026-03-25 08:15:00', '2025-06-01 09:00:00'),
('michael.torres',  'michael.torres@mois.valdoria.gov',  crypt('Edit0r#01', gen_salt('bf')),       'editor',     '2026-03-24 17:30:00', '2025-07-15 10:00:00'),
('sarah.mitchell',  'sarah.mitchell@mois.valdoria.gov',   crypt('Edit0r#02', gen_salt('bf')),       'editor',     '2026-03-23 14:20:00', '2025-08-01 11:00:00'),
('david.chen',      'david.chen@mois.valdoria.gov',       crypt('View3r!!', gen_salt('bf')),        'viewer',     '2026-03-22 09:45:00', '2025-09-10 08:30:00'),
('emily.watson',    'emily.watson@mois.valdoria.gov',     crypt('W@tson2026!', gen_salt('bf')),     'editor',     '2026-03-21 16:00:00', '2025-10-01 09:00:00'),
('rachel.kim',      'rachel.kim@mois.valdoria.gov',       crypt('R@chel2026!', gen_salt('bf')),     'viewer',     '2026-03-20 11:30:00', '2025-11-15 10:00:00');

-- ----- Notices -----
INSERT INTO notices (title, content, category, author, is_public, view_count, created_at, updated_at) VALUES
('2026 First Half Policy Briefing Schedule',
 'The Ministry of Interior and Safety announces the 2026 first-half policy briefing schedule.

1. Date: February 15, 2026 (Monday), 14:00
2. Venue: Government Complex Sejong, Building 6, Grand Conference Room
3. Attendees: All division directors and above

Please refer to the internal business portal for details.',
 'Policy', 'Daniel Harper', TRUE, 1542, '2026-01-10 09:00:00', '2026-01-10 09:00:00'),

('E-Government Service Maintenance Notice (3/28-3/29)',
 'A scheduled maintenance will be conducted to improve system stability.

- Maintenance window: March 28, 2026 (Sat) 22:00 ~ March 29, 2026 (Sun) 06:00
- Affected services: Gov24, Digital Government Portal, and related e-government services
- Scope: Database migration and security patching

Services will be temporarily unavailable during the maintenance window. We appreciate your understanding.',
 'System', 'Emily Watson', TRUE, 2831, '2026-03-20 10:00:00', '2026-03-20 10:00:00'),

('Personal Data Protection Training Completion Notice',
 'The 2026 first-half personal data protection training results are as follows:

- Training period: 2026.01.15 ~ 2026.02.28
- Completed: 387 out of 412 employees (93.9%)
- Incomplete: Individual notifications will be sent

Employees who have not completed the training must do so by March 31.',
 'Training', 'David Chen', TRUE, 687, '2026-03-05 14:00:00', '2026-03-05 14:00:00'),

('First Citizen Participation Policy Forum 2026',
 'MOIS will host a policy forum to gather citizen feedback.

1. Topic: Digital Government Innovation and Citizen Engagement
2. Date: April 10, 2026 (Friday), 15:00-17:00
3. Venue: Online (Zoom) / Offline (Government Complex Sejong)
4. Registration: MOIS website > Citizen Participation > Forum Registration',
 'Event', 'Michael Torres', TRUE, 423, '2026-03-15 11:00:00', '2026-03-15 11:00:00'),

('Civil Service Examination Schedule Change',
 'The 2026 Grade 9 National Civil Service Open Competitive Examination schedule has been updated.

- Previous date: April 8, 2026 (Saturday)
- New date: April 15, 2026 (Saturday)
- Reason: Facility scheduling conflict at examination venues

We ask for the understanding of all candidates.',
 'Recruitment', 'Sarah Mitchell', TRUE, 3156, '2026-03-01 09:30:00', '2026-03-01 09:30:00'),

('Government Complex Parking Policy Update',
 'Starting April, the Government Complex parking policy will be updated.

1. External vehicles: Advance reservation required
2. Official vehicles: Existing passes remain valid
3. Citizen visitors: Temporary passes issued at 1st floor information desk

For inquiries, contact Facilities Management Division (044-205-1234).',
 'Facilities', 'Emily Watson', TRUE, 198, '2026-03-18 15:30:00', '2026-03-18 15:30:00'),

('2026 First Half Information Security Audit Results',
 'The results of the 2026 first-half information security audit are as follows:

- Audit period: 2026.02.01 ~ 2026.02.28
- Scope: All departmental workstations and servers
- Key findings:
  1. 42 accounts with unchanged passwords
  2. 15 instances of unauthorized software installation
  3. 8 workstations without USB security software

Affected departments must complete remediation by end of March.',
 'Security', 'David Chen', TRUE, 956, '2026-03-10 09:00:00', '2026-03-10 09:00:00'),

('MOIS Organizational Restructuring Notice',
 'Effective April 1, 2026, the following organizational changes will take effect:

- New: Digital Safety Division
- Merger: Disaster Management Office + Safety Policy Office -> Disaster and Safety Management Bureau
- Dissolved: Regional Development Division (transferred to Local Government Academy)

Detailed personnel orders will be announced separately.',
 'Personnel', 'Daniel Harper', TRUE, 1287, '2026-03-22 10:00:00', '2026-03-22 10:00:00'),

('2026 Valdoria E-Government Innovation Roadmap',
 'MOIS has established and published the 2026 E-Government Innovation Roadmap.

Key initiatives:
1. AI-powered complaint auto-classification system enhancement
2. Cloud-native government system transition
3. Zero Trust security model adoption
4. Digital identity verification framework development

Please refer to the attached document for details.',
 'Policy', 'Emily Watson', TRUE, 2104, '2026-03-25 14:00:00', '2026-03-25 14:00:00'),

('Citizen Service Improvement Announcement',
 'The Gov24 citizen service has been improved.

Major updates:
1. AI assistant consultation feature added during complaint filing
2. Real-time complaint status notifications (SMS/Email)
3. Attachment upload size increased (10MB -> 50MB)

We look forward to your continued use of our services.',
 'Service', 'Michael Torres', TRUE, 567, '2026-03-24 09:30:00', '2026-03-24 09:30:00'),

-- Non-public notices (admin-only)
('INTERNAL: Database Migration Technical Notes',
 'Technical details for the upcoming database migration:

- Migration target: PostgreSQL 15 cluster on 192.168.92.208
- Service account: portal_app (mois_portal database)
- Backup window: Pre-migration full backup at 20:00
- Rollback plan: Restore from pg_dump if migration fails

Contact IT Management Office for questions.',
 'Internal', 'Daniel Harper', FALSE, 45, '2026-03-26 09:00:00', '2026-03-26 09:00:00'),

('INTERNAL: Q2 Budget Allocation Draft',
 'Draft budget allocation for Q2 2026:

- Cloud infrastructure: 450,000,000 VCR
- Security tools renewal: 120,000,000 VCR
- Staff training: 35,000,000 VCR
- Contractor support: 280,000,000 VCR

This document is for internal review only. Do not distribute.',
 'Internal', 'Daniel Harper', FALSE, 23, '2026-03-27 11:00:00', '2026-03-27 11:00:00');

-- ----- Inquiries -----
INSERT INTO inquiries (tracking_number, subject, description, status, department, submitter_name, submitter_email, submitted_at, updated_at) VALUES
('INQ-20260315-0001', 'E-Government Login Error',
 'I am receiving an "Authentication Certificate Error" when trying to log into the Gov24 service. My certificate is valid but the error persists. Please investigate.',
 'Resolved', 'IT Support Division', 'James Wilson', 'j.wilson@vmail.vd', '2026-03-15 10:20:00', '2026-03-16 14:30:00'),

('INQ-20260317-0002', 'Personal Data Access Request Inquiry',
 'I would like to view my personal data held by MOIS. Please provide the procedure for making a data access request.',
 'Resolved', 'Privacy Protection Office', 'Linda Park', 'l.park@vmail.vd', '2026-03-17 09:30:00', '2026-03-18 11:00:00'),

('INQ-20260320-0003', 'Complaint Processing Delay',
 'The complaint I filed on March 5 (Reference: COMP-2026-0234) has not been processed yet. Please provide a status update.',
 'In Progress', 'Complaint Processing Division', 'Robert Chang', 'r.chang@vmail.vd', '2026-03-20 16:45:00', '2026-03-20 16:45:00'),

('INQ-20260325-0004', 'Government Subsidy Application Process',
 'Please provide information on how to apply for the 2026 small business support subsidy, including eligibility requirements.',
 'Received', 'External Affairs Division', 'Amy Lee', 'a.lee@vmail.vd', '2026-03-25 08:00:00', '2026-03-25 08:00:00'),

('INQ-20260311-0005', 'Civil Service Exam Score Unavailable',
 'I am trying to check my 2025 second-half civil service exam scores but getting a "No results found" message. I have my exam admission ticket as proof of registration.',
 'Resolved', 'Personnel Division', 'Kevin Yoo', 'k.yoo@vmail.vd', '2026-03-11 14:00:00', '2026-03-12 15:00:00'),

('INQ-20260322-0006', 'Website Accessibility Issue',
 'The MOIS portal website has poor contrast ratio on several pages, making it difficult for visually impaired users. The navigation menu is also not properly accessible via screen readers.',
 'In Progress', 'IT Planning Division', 'Susan Oh', 's.oh@vmail.vd', '2026-03-22 10:15:00', '2026-03-23 09:00:00'),

('INQ-20260326-0007', 'Document Certification Request',
 'I need a certified copy of my complaint resolution document (COMP-2025-1847) for legal proceedings. How can I request this?',
 'Received', 'General Affairs Division', 'Thomas Shin', 't.shin@vmail.vd', '2026-03-26 14:00:00', '2026-03-26 14:00:00'),

('INQ-20260327-0008', 'Data Breach Notification Request',
 'I received an email claiming to be from MOIS asking me to verify my identity. I suspect this may be a phishing attempt. Can you confirm whether MOIS sent this communication?',
 'Received', 'Information Security Division', 'Diana Han', 'd.han@vmail.vd', '2026-03-27 08:30:00', '2026-03-27 08:30:00');
