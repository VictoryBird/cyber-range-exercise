-- ============================================================
-- 문서 저장 서버 초기 데이터 (I8 / 192.168.110.12)
-- 실행: psql -U docstorage -d mil_docstorage -f init.sql
-- ============================================================

-- 데이터베이스 생성 (PostgreSQL 관리자 권한 필요)
-- CREATE DATABASE mil_docstorage OWNER docstorage;

-- 사용자 시드 데이터 (비밀번호 해시는 bcrypt)
-- 평문 비밀번호 참고: mil_admin/Admin2026!, mil_kim/Jungsu2026!, mil_lee/Younghee2026!
INSERT INTO users (username, password_hash, name, email, department, role) VALUES
('mil_admin', '$2b$12$LJ3m5Z1Z1Z1Z1Z1Z1Z1Z1uKJ3m5Z1Z1Z1Z1Z1Z1Z1Z1Z1Z1Z1Z1Z', '김영호', 'mil_admin@mnd.local', '정보통신과', 'admin'),
('mil_kim', '$2b$12$QR8n6Y2Y2Y2Y2Y2Y2Y2Y2uKJ3m5Z1Z1Z1Z1Z1Z1Z1Z1Z1Z1Z1Z1Z', '김정수', 'mil_kim@mnd.local', '작전지원과', 'user'),
('mil_lee', '$2b$12$ST9o7Z3Z3Z3Z3Z3Z3Z3Z3uKJ3m5Z1Z1Z1Z1Z1Z1Z1Z1Z1Z1Z1Z1Z', '이민지', 'mil_lee@mnd.local', '군수보급과', 'user'),
('mil_park', '$2b$12$UV0p8A4A4A4A4A4A4A4A4uKJ3m5Z1Z1Z1Z1Z1Z1Z1Z1Z1Z1Z1Z1Z', '박준혁', 'mil_park@mnd.local', '인사행정과', 'user'),
('mil_choi', '$2b$12$WX1q9B5B5B5B5B5B5B5B5uKJ3m5Z1Z1Z1Z1Z1Z1Z1Z1Z1Z1Z1Z1Z', '최서연', 'mil_choi@mnd.local', '통신보안과', 'user'),
('mil_jung', '$2b$12$YZ2r0C6C6C6C6C6C6C6C6uKJ3m5Z1Z1Z1Z1Z1Z1Z1Z1Z1Z1Z1Z1Z', '정동욱', 'mil_jung@mnd.local', '작전지원과', 'user'),
('mil_yoon', '$2b$12$AB3s1D7D7D7D7D7D7D7D7uKJ3m5Z1Z1Z1Z1Z1Z1Z1Z1Z1Z1Z1Z1Z', '윤세라', 'mil_yoon@mnd.local', '정보통신과', 'user')
ON CONFLICT (username) DO NOTHING;

-- 문서 시드 데이터 (14개 군사 문서)
INSERT INTO documents (filename, original_filename, file_path, file_size, category, classification, description, uploaded_by) VALUES
('2026년_상반기_작전계획(초안).pdf', '2026년_상반기_작전계획(초안).pdf', '/opt/docstorage/files/작전계획/2026년_상반기_작전계획(초안).pdf', 2458624, '작전계획', '비밀', '2026년 상반기 작전계획 초안', 'mil_kim'),
('합동작전_수행지침_v3.2.pdf', '합동작전_수행지침_v3.2.pdf', '/opt/docstorage/files/작전계획/합동작전_수행지침_v3.2.pdf', 1843200, '작전계획', '비밀', '합동작전 수행지침 3.2판', 'mil_kim'),
('전술통신망_구성도_2026.pdf', '전술통신망_구성도_2026.pdf', '/opt/docstorage/files/통신보안/전술통신망_구성도_2026.pdf', 3145728, '통신보안', '비밀', '2026년 전술통신망 구성도', 'mil_choi'),
('군수물자_수급현황_3월.xlsx', '군수물자_수급현황_3월.xlsx', '/opt/docstorage/files/군수보급/군수물자_수급현황_3월.xlsx', 524288, '군수보급', '대외비', '3월 군수물자 수급 현황', 'mil_lee'),
('탄약_재고관리_현황.xlsx', '탄약_재고관리_현황.xlsx', '/opt/docstorage/files/군수보급/탄약_재고관리_현황.xlsx', 716800, '군수보급', '비밀', '탄약 재고 관리 현황표', 'mil_lee'),
('2026년_인사명령_제12호.pdf', '2026년_인사명령_제12호.pdf', '/opt/docstorage/files/인사명령/2026년_인사명령_제12호.pdf', 204800, '인사명령', '대외비', '인사명령 제12호', 'mil_park'),
('간부_전보발령_목록.xlsx', '간부_전보발령_목록.xlsx', '/opt/docstorage/files/인사명령/간부_전보발령_목록.xlsx', 153600, '인사명령', '대외비', '간부 전보 발령 목록', 'mil_park'),
('암호체계_운용지침_개정.pdf', '암호체계_운용지침_개정.pdf', '/opt/docstorage/files/통신보안/암호체계_운용지침_개정.pdf', 1048576, '통신보안', '극비', '암호체계 운용지침 개정판', 'mil_choi'),
('보안점검_결과보고_2026Q1.pdf', '보안점검_결과보고_2026Q1.pdf', '/opt/docstorage/files/통신보안/보안점검_결과보고_2026Q1.pdf', 819200, '통신보안', '대외비', '2026년 1분기 보안 점검 결과', 'mil_choi'),
('부대_이동계획_4월.pdf', '부대_이동계획_4월.pdf', '/opt/docstorage/files/작전계획/부대_이동계획_4월.pdf', 1228800, '작전계획', '비밀', '4월 부대 이동 계획', 'mil_jung'),
('업무보고_정보통신과_3월.docx', '업무보고_정보통신과_3월.docx', '/opt/docstorage/files/일반행정/업무보고_정보통신과_3월.docx', 307200, '일반행정', '일반', '정보통신과 3월 업무보고', 'mil_yoon'),
('출장명령서_2026-0312.pdf', '출장명령서_2026-0312.pdf', '/opt/docstorage/files/일반행정/출장명령서_2026-0312.pdf', 102400, '일반행정', '일반', '출장명령서', 'mil_park'),
('네트워크_접근통제_정책.pdf', '네트워크_접근통제_정책.pdf', '/opt/docstorage/files/통신보안/네트워크_접근통제_정책.pdf', 614400, '통신보안', '대외비', '네트워크 접근 통제 정책 문서', 'mil_yoon'),
('예비군_훈련계획_2026.pdf', '예비군_훈련계획_2026.pdf', '/opt/docstorage/files/작전계획/예비군_훈련계획_2026.pdf', 409600, '작전계획', '일반', '2026년 예비군 훈련 계획', 'mil_jung')
ON CONFLICT DO NOTHING;
