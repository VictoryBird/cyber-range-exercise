-- =============================================================
-- 11_agency_db_seed.sql — 내부 업무 포털 시드 데이터
-- =============================================================

\c agency_db;

-- 부서
INSERT INTO departments (dept_code, dept_name, floor_location, phone_ext) VALUES
('POLICY',   '정책실',         '10F', '1000'),
('CYBER',    '사이버작전사령부', '8F',  '2000'),
('HR',       '인사혁신과',      '7F',  '3000'),
('IT',       'IT운영팀',        '6F',  '4000'),
('SECURITY', '정보보안정책과',   '6F',  '4100'),
('EGOV',     '전자정부과',      '5F',  '5000'),
('AFFAIRS',  '총무과',         '3F',  '6000'),
('COOPERATE','대외협력과',      '4F',  '7000'),
('CIVIL',    '민원처리과',      '2F',  '8000'),
('PRIVACY',  '개인정보보호과',   '5F',  '9000')
ON CONFLICT (dept_code) DO NOTHING;

-- 직원 (AD 계정명 포함 — Windows PC/AD 자산과 연동)
INSERT INTO employees (emp_number, full_name, email, phone, dept_id, position_title, role_title, hire_date, ad_username, password_hash) VALUES
('EMP20150101', '김관리',   'admin_kim@mois.local',    '02-2100-4001', 4, '5급', 'IT운영팀장',  '2015-01-01', 'admin_kim',  crypt('P@ssw0rd2024!', gen_salt('bf'))),
('EMP20180301', '이시스템', 'sysadmin@mois.local',     '02-2100-4002', 4, '6급', NULL,          '2018-03-01', 'sysadmin',   crypt('AdminP@ss!', gen_salt('bf'))),
('EMP20190847', '박민준',   'park.mj@mois.local',      '02-2100-7001', 8, '6급', '대외협력담당', '2019-08-01', 'user_park',  crypt('Minjun2024!', gen_salt('bf'))),
('EMP20200515', '이서연',   'lee.sy@mois.local',       '02-2100-8001', 9, '7급', NULL,          '2020-05-15', 'user_lee',   crypt('Seoyeon123!', gen_salt('bf'))),
('EMP20170620', '최동현',   'choi.dh@mois.local',      '02-2100-4101', 5, '6급', '보안감사담당', '2017-06-20', 'user_choi',  crypt('Donghyun1!', gen_salt('bf'))),
('EMP20210101', '정하은',   'jung.he@mois.local',      '02-2100-6001', 7, '7급', NULL,          '2021-01-01', 'user_jung',  crypt('Haeun2024!', gen_salt('bf'))),
('EMP20190301', '한지우',   'han.jw@mois.local',       '02-2100-5001', 6, '6급', NULL,          '2019-03-01', 'user_han',   crypt('Jiwoo2024!', gen_salt('bf'))),
('EMP20160801', '강태호',   'kang.th@mois.local',      '02-2100-1001', 1, '5급', '정책기획관',  '2016-08-01', 'user_kang',  crypt('Taeho2024!', gen_salt('bf'))),
('EMP20220601', '오수진',   'oh.sj@mois.local',        '02-2100-8002', 9, '8급', NULL,          '2022-06-01', 'user_oh',    crypt('Sujin2024!', gen_salt('bf'))),
('EMP20200901', '윤정민',   'yoon.jm@mois.local',      '02-2100-2001', 2, '6급', NULL,          '2020-09-01', 'user_yoon',  crypt('Jungmin2024!', gen_salt('bf')))
ON CONFLICT (emp_number) DO NOTHING;

-- 부서장 업데이트
UPDATE departments SET head_employee_id = 1  WHERE dept_code = 'IT';
UPDATE departments SET head_employee_id = 8  WHERE dept_code = 'POLICY';
UPDATE departments SET head_employee_id = 5  WHERE dept_code = 'SECURITY';

-- 전자 결재
INSERT INTO approvals (doc_number, title, content, doc_type, drafter_id, current_step, total_steps, status, created_at) VALUES
('APPR-2026-0001', '2026년 1분기 보안점검 계획',          '전산실 보안점검 일정 및 담당자 배정 기안',         '일반기안', 5, 3, 3, '승인',   '2026-01-15 09:00:00+09'),
('APPR-2026-0012', '사이버보안 강화 장비 구매 요청',       '차세대 방화벽 도입을 위한 장비 구매 기안',         '지출결의', 1, 2, 3, '진행중', '2026-03-01 10:00:00+09'),
('APPR-2026-0023', '대외협력 업무 출장 신청 (3월)',        '국방부 협력 회의 참석 출장 신청',                 '출장신청', 3, 1, 3, '기안',   '2026-03-18 14:00:00+09'),
('APPR-2026-0031', '개인정보 처리방침 개정안',             '2026년 개인정보 처리방침 개정 기안',              '일반기안', 5, 3, 3, '승인',   '2026-02-20 11:00:00+09'),
('APPR-2026-0045', '전자정부 서비스 개편 예산 요청',       'AI 기반 민원 분류 시스템 개발 예산 신청',          '지출결의', 7, 2, 3, '진행중', '2026-03-05 09:00:00+09')
ON CONFLICT (doc_number) DO NOTHING;

-- 업무 요청
INSERT INTO work_requests (request_number, title, description, requester_id, assignee_id, priority, status, due_date, created_at) VALUES
('WR-2026-0001', '웹메일 계정 초기화 요청',         '박민준 대리 웹메일 비밀번호 초기화 요청',  3, 2, '보통', '완료',   '2026-03-10', '2026-03-05 09:00:00+09'),
('WR-2026-0008', '내부 포털 접속 오류 신고',        '크롬 브라우저에서 인트라넷 접속 불가',     4, 1, '높음', '진행중', '2026-03-25', '2026-03-20 11:00:00+09'),
('WR-2026-0015', '보안 교육 자료 업데이트 요청',    '2026년 보안 교육 자료 최신 버전 반영',    10, 5, '보통', '요청',   '2026-04-01', '2026-03-22 14:00:00+09'),
('WR-2026-0020', 'VPN 접속 권한 신청',              '대외협력 업무를 위한 군 VPN 접속 권한 요청', 3, 1, '긴급', '완료',   '2026-03-08', '2026-03-01 10:00:00+09')
ON CONFLICT (request_number) DO NOTHING;
