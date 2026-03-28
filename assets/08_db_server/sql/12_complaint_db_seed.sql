-- =============================================================
-- 12_complaint_db_seed.sql -- Complaint Processing Seed Data
-- Asset 08: DB Server (192.168.92.208)
-- Database: complaint_db
-- =============================================================

-- ----- Complaints -----
INSERT INTO complaints (complaint_number, applicant_name, applicant_email, applicant_phone, applicant_addr, category, title, content, status, priority, assigned_dept, assigned_to, response, responded_at, created_at) VALUES
('COMP-2026-0001', 'James Wilson', 'j.wilson@vmail.vd', '010-2345-6789', '15 Maple Street, Elaris District',
 'Public Facilities', 'Broken Street Lights on Maple Street',
 'Two street lights near 15 Maple Street have been non-functional for two weeks. This creates a safety hazard for pedestrians at night. Please arrange urgent repairs.',
 'Resolved', 'Normal', 'Facilities Management Division', 'Tyler Hwang',
 'Dear Mr. Wilson,

Thank you for your report. The Elaris District Facilities Management team has been dispatched and completed repairs on March 20, 2026.

Best regards,
Facilities Management Division',
 '2026-03-20 15:00:00+00',
 '2026-03-10 08:30:00+00'),

('COMP-2026-0002', 'Linda Park', 'l.park@vmail.vd', '010-3456-7890', '411 Central Avenue, Sejong District',
 'Roads/Traffic', 'Pothole on Central Avenue near Government Complex',
 'A pothole approximately 30cm in diameter has appeared on Central Avenue near Government Complex Building 6. This poses a risk to vehicles. Please arrange emergency repair.',
 'In Progress', 'Urgent', 'Facilities Management Division', 'Tyler Hwang',
 NULL, NULL,
 '2026-03-15 09:00:00+00'),

('COMP-2026-0003', 'Robert Chang', 'r.chang@vmail.vd', '010-4567-8901', '209 Jongno Road, Capital City',
 'Environment', 'Air Quality Improvement Request for Capital District',
 'Air quality index in the Capital District consistently shows "Poor" levels. Request implementation of effective measures such as traffic restrictions during peak commute hours.',
 'Under Review', 'Normal', 'Disaster & Safety Management Bureau', 'Jessica Park',
 NULL, NULL,
 '2026-03-12 14:20:00+00'),

('COMP-2026-0004', 'Amy Lee', 'a.lee@vmail.vd', '010-5678-9012', '1 Expo Road, Daehan District',
 'Welfare', 'Request to Expand Disability Support Services',
 'The current monthly hours for disability activity support services are insufficient. For severely disabled individuals, I propose increasing from the current 480 hours per month to a minimum of 600 hours.',
 'Resolved', 'Normal', 'Complaint Processing Division', 'Victoria Yoon',
 'Dear Ms. Lee,

The disability activity support service hours expansion falls under the jurisdiction of the Ministry of Health and Welfare. Your complaint has been transferred. Reference number: MW-2026-0456.

Ministry of Health helpline: 129',
 '2026-03-18 10:00:00+00',
 '2026-03-14 11:00:00+00'),

('COMP-2026-0005', 'Kevin Yoo', 'k.yoo2@vmail.vd', '010-6789-0123', '100 Innovation Road, Suwon District',
 'Technical', 'Gov24 Mobile App Crash on File Upload',
 'The Gov24 mobile app (Android) force-closes when uploading attachments during complaint filing.

- Device: Galaxy S24
- OS: Android 15
- App version: 4.2.1
- Reproduction rate: 100%',
 'In Progress', 'High', 'Digital Government Planning Division', 'Michael Torres',
 NULL, NULL,
 '2026-03-16 10:30:00+00'),

('COMP-2026-0006', 'Susan Oh', 's.oh@vmail.vd', '010-7890-1234', '48 Centum Road, Haeun District',
 'Public Facilities', 'Noise Complaint Near Haeun Beach Construction Site',
 'The construction site near Haeun Beach continues work past 22:00, causing significant noise disturbance. Request enforcement of nighttime construction restrictions.',
 'Received', 'Normal', NULL, NULL,
 NULL, NULL,
 '2026-03-22 22:30:00+00'),

('COMP-2026-0007', 'Thomas Shin', 't.shin@vmail.vd', '010-8901-2345', '55 Harbor Road, Port Valdis',
 'Technical', 'Gov24 Website Accessibility Issues',
 'The MOIS portal has poor contrast ratio on several pages, making it difficult for visually impaired users. The navigation menu is not accessible via screen readers. This violates accessibility standards.',
 'Under Review', 'Normal', 'IT Management Office', 'Amanda Liu',
 NULL, NULL,
 '2026-03-23 09:00:00+00'),

('COMP-2026-0008', 'Diana Han', 'd.han@vmail.vd', '010-9012-3456', '22 University Road, Academic District',
 'General', 'Suspicious Email Claiming to Be from MOIS',
 'I received an email from mois-security@valdoria-gov.net asking me to verify my identity by clicking a link. The email address does not match the official domain. Is this a legitimate communication?',
 'In Progress', 'High', 'Information Security Division', 'David Chen',
 NULL, NULL,
 '2026-03-27 08:30:00+00');

-- ----- Processing Logs -----
INSERT INTO processing_logs (complaint_id, action, actor_name, actor_dept, description, previous_status, new_status, created_at) VALUES
(1, 'Received',  'System',        'Auto',                       'Complaint received via online portal',     NULL,          'Received',    '2026-03-10 08:30:00+00'),
(1, 'Assigned',  'Sarah Mitchell','Complaint Processing Div.',  'Assigned to Facilities Management',       'Received',    'In Progress', '2026-03-10 10:00:00+00'),
(1, 'Resolved',  'Tyler Hwang',   'Facilities Management Div.', 'Street lights repaired on site',          'In Progress', 'Resolved',    '2026-03-20 15:00:00+00'),
(2, 'Received',  'System',        'Auto',                       'Complaint received via online portal',     NULL,          'Received',    '2026-03-15 09:00:00+00'),
(2, 'Assigned',  'Sarah Mitchell','Complaint Processing Div.',  'Urgent: assigned to Facilities',          'Received',    'In Progress', '2026-03-15 09:30:00+00'),
(4, 'Received',  'System',        'Auto',                       'Complaint received via online portal',     NULL,          'Received',    '2026-03-14 11:00:00+00'),
(4, 'Transferred','Victoria Yoon','Complaint Processing Div.',  'Transferred to Ministry of Health',       'Received',    'Resolved',    '2026-03-18 10:00:00+00'),
(5, 'Received',  'System',        'Auto',                       'Complaint received via mobile app',        NULL,          'Received',    '2026-03-16 10:30:00+00'),
(5, 'Assigned',  'Sarah Mitchell','Complaint Processing Div.',  'Assigned to Digital Government team',     'Received',    'In Progress', '2026-03-16 14:00:00+00'),
(8, 'Received',  'System',        'Auto',                       'Complaint received via online portal',     NULL,          'Received',    '2026-03-27 08:30:00+00'),
(8, 'Assigned',  'Sarah Mitchell','Complaint Processing Div.',  'Potential phishing - assigned to InfoSec','Received',    'In Progress', '2026-03-27 09:00:00+00');
