-- =============================================================
-- 12_complaint_db_seed.sql — 민원 처리 시드 데이터
-- =============================================================

\c complaint_db;

-- 민원 접수
INSERT INTO complaints (complaint_number, applicant_name, applicant_email, applicant_phone, applicant_addr, category, title, content, status, priority, assigned_dept, assigned_to, response, responded_at, created_at) VALUES
('COMP-2026-0001', '홍길동', 'hong@example.com',      '010-1234-5678', '발도리아시 중앙구 정부로 1',    '도로/교통', '도로 포장 불량',        '마곡동 일대 도로 포장 상태가 불량합니다. 보수 요청 드립니다.',  '처리중', '보통', '도로관리과', '강태호', NULL, NULL, '2026-03-15 14:30:00+09'),
('COMP-2026-0002', '김민수', 'kim.ms@example.com',     '010-2345-6789', '발도리아시 서구 자유로 22',     '생활불편',  '가로등 미점등 신고',     '대화동 사거리 부근 가로등 2기 미점등 상태입니다.',             '답변완료', '보통', '시설관리과', '오수진', '현장 확인 후 수리 완료하였습니다.', '2026-03-18 16:00:00+09', '2026-03-10 09:15:00+09'),
('COMP-2026-0003', '박지훈', 'jihun.park@example.com',  '010-3456-7890', '발도리아시 동구 평화로 55',     '환경',      '공사장 야간 소음',       '인근 공사장 야간 소음이 심합니다. 조치 바랍니다.',            '접수',   '높음', NULL, NULL, NULL, NULL, '2026-03-20 22:00:00+09'),
('COMP-2026-0004', '최서연', 'seoyeon.choi@example.com','010-4567-8901', '발도리아시 남구 희망로 88',     '개인정보',  '개인정보 열람 청구',     '본인의 개인정보 처리 현황 열람을 청구합니다.',                '처리중', '보통', '개인정보보호과', '최동현', NULL, NULL, '2026-03-18 10:30:00+09'),
('COMP-2026-0005', '정하은', 'haeun.jung@example.com',  '010-5678-9012', NULL,                          '복지',      '복지 서비스 안내 요청',  '신규 복지 서비스 신청 방법을 안내 부탁드립니다.',              '접수',   '낮음', NULL, NULL, NULL, NULL, '2026-03-22 15:45:00+09'),
('COMP-2026-0006', '이동민', 'dongmin@example.com',     '010-6789-0123', '발도리아시 북구 통일로 100',    '도로/교통', '신호등 고장 신고',       '학교 앞 횡단보도 신호등이 작동하지 않습니다.',                '검토중', '긴급', '교통안전과', NULL, NULL, NULL, '2026-03-23 08:00:00+09'),
('COMP-2026-0007', '강수민', 'sumin.kang@example.com',  '010-7890-1234', '발도리아시 중앙구 번영로 33',   '기타',      '공공시설 이용 문의',     '시민문화회관 대관 절차를 알려주세요.',                        '답변완료', '낮음', '문화체육과', '정하은', '대관 안내 자료를 이메일로 발송하였습니다.', '2026-03-21 11:00:00+09', '2026-03-19 16:30:00+09')
ON CONFLICT (complaint_number) DO NOTHING;

-- 첨부파일 메타데이터
INSERT INTO attachments (complaint_id, original_name, stored_path, file_size, mime_type, checksum_sha256, is_converted) VALUES
(1, '도로상태_사진1.jpg',      'complaints/2026/03/COMP-2026-0001/도로상태_사진1.jpg',      2458901, 'image/jpeg', 'a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2', FALSE),
(1, '도로상태_사진2.jpg',      'complaints/2026/03/COMP-2026-0001/도로상태_사진2.jpg',      3102456, 'image/jpeg', 'b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3', FALSE),
(3, '소음측정_결과.pdf',       'complaints/2026/03/COMP-2026-0003/소음측정_결과.pdf',       512034,  'application/pdf', 'c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4', FALSE),
(4, '개인정보_열람_청구서.hwp', 'complaints/2026/03/COMP-2026-0004/개인정보_열람_청구서.hwp', 245760,  'application/x-hwp', 'd4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5', FALSE),
(6, '신호등_고장_동영상.mp4',  'complaints/2026/03/COMP-2026-0006/신호등_고장_동영상.mp4',  15728640, 'video/mp4', 'e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6', FALSE);

-- 처리 이력
INSERT INTO processing_logs (complaint_id, action, actor_name, actor_dept, description, previous_status, new_status, created_at) VALUES
(1, '접수',   '시스템',   NULL,          '온라인 민원 접수',                      NULL,      '접수',    '2026-03-15 14:30:00+09'),
(1, '배정',   '김관리',   'IT운영팀',     '도로관리과로 배정',                     '접수',    '검토중',  '2026-03-15 15:00:00+09'),
(1, '처리',   '강태호',   '도로관리과',   '현장 조사 진행 중',                     '검토중',  '처리중',  '2026-03-17 10:00:00+09'),
(2, '접수',   '시스템',   NULL,          '온라인 민원 접수',                      NULL,      '접수',    '2026-03-10 09:15:00+09'),
(2, '배정',   '김관리',   'IT운영팀',     '시설관리과로 배정',                     '접수',    '검토중',  '2026-03-10 10:00:00+09'),
(2, '답변',   '오수진',   '시설관리과',   '현장 확인 후 수리 완료',                '검토중',  '답변완료', '2026-03-18 16:00:00+09'),
(3, '접수',   '시스템',   NULL,          '온라인 민원 접수',                      NULL,      '접수',    '2026-03-20 22:00:00+09'),
(6, '접수',   '시스템',   NULL,          '온라인 민원 접수 (긴급)',               NULL,      '접수',    '2026-03-23 08:00:00+09'),
(6, '배정',   '김관리',   'IT운영팀',     '교통안전과로 긴급 배정',                '접수',    '검토중',  '2026-03-23 08:30:00+09');
