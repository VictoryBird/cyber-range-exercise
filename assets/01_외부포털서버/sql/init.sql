-- ============================================================
-- 외부 포털 서버 — PostgreSQL 초기 스키마 및 시드 데이터
-- DB: mois_portal (원격 DB 서버 192.168.100.20에서 실행)
-- ============================================================

-- 사용자 테이블
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(100) UNIQUE NOT NULL,
    email VARCHAR(200),
    password VARCHAR(200) NOT NULL,
    role VARCHAR(50) DEFAULT 'viewer',
    last_login TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW()
);

-- 공지사항 테이블
CREATE TABLE IF NOT EXISTS notices (
    id SERIAL PRIMARY KEY,
    title VARCHAR(500) NOT NULL,
    content TEXT,
    category VARCHAR(100) DEFAULT '일반',
    author VARCHAR(100) DEFAULT '관리자',
    is_public BOOLEAN DEFAULT true,
    view_count INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- 민원 테이블
CREATE TABLE IF NOT EXISTS inquiries (
    id SERIAL PRIMARY KEY,
    tracking_number VARCHAR(50) UNIQUE NOT NULL,
    subject VARCHAR(500) NOT NULL,
    description TEXT,
    status VARCHAR(50) DEFAULT '접수',
    department VARCHAR(200),
    submitter_name VARCHAR(100),
    submitter_email VARCHAR(200),
    submitted_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- 인덱스
CREATE INDEX IF NOT EXISTS idx_notices_category ON notices(category);
CREATE INDEX IF NOT EXISTS idx_notices_created_at ON notices(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notices_is_public ON notices(is_public);
CREATE INDEX IF NOT EXISTS idx_inquiries_tracking ON inquiries(tracking_number);

-- ============================================================
-- 시드 데이터: 사용자
-- [취약 설정] bcrypt 해시이지만 약한 비밀번호 사용
-- ============================================================
INSERT INTO users (username, email, password, role, last_login) VALUES
-- 비밀번호: @dminMOIS2026!
('admin', 'admin@mois.valdoria.gov',
 '$2b$12$LJ3m4ys1vG8RkH5qZ9Xmje6YdF5N8VPXM7uRv2kqWz7xD1mKJlI2e',
 'superadmin', '2026-03-25 08:15:00'),
-- 비밀번호: Edit0r#01
('editor01', 'editor01@mois.valdoria.gov',
 '$2b$12$5NaTs7fV9z4yZ1LuQ6wR8SzN9oCzFzPtUI4b0P1rR.uTvCzQpRnYu',
 'editor', '2026-03-24 17:30:00'),
-- 비밀번호: Edit0r#02
('editor02', 'editor02@mois.valdoria.gov',
 '$2b$12$HqJx8Kz3mP5WvR2dN7eYfO1sA4tB6uC9wX0yZ3aD5gH7iJ2kL4nP',
 'editor', '2026-03-23 14:20:00'),
-- 비밀번호: View3r!!
('viewer', 'viewer@mois.valdoria.gov',
 '$2b$12$Qm8nR5tW2xY4zA7bC9dE1fG3hI5jK7lM9nO1pQ3rS5tU7vW9xY1z',
 'viewer', '2026-03-22 11:00:00')
ON CONFLICT (username) DO NOTHING;

-- ============================================================
-- 시드 데이터: 공지사항
-- ============================================================
INSERT INTO notices (title, content, category, author, is_public, created_at, view_count) VALUES
('2026년 상반기 정책 브리핑 일정 안내',
 '행정안전부에서는 2026년 상반기 주요 정책 브리핑 일정을 다음과 같이 안내합니다.

1분기: 1월 15일 - 디지털 정부 혁신 전략
2분기: 4월 10일 - 지방자치 분권 강화 방안

브리핑 참석을 희망하시는 분은 사전 등록 바랍니다.',
 '정책', '홍보담당관', true, '2026-01-10 09:00:00', 1523),

('공공기관 정보보안 강화 지침 (제2026-03호)',
 '최근 사이버 위협 증가에 따라 공공기관 정보보안 강화 지침을 시행합니다.

주요 내용:
1. 관리자 계정 2단계 인증 의무화
2. 외부 접속 VPN 적용 강화
3. 분기별 보안 점검 실시
4. 개인정보 처리시스템 접근 로그 1년 보관

시행일: 2026년 3월 1일',
 '보안', '정보보안정책과', true, '2026-02-15 10:00:00', 2847),

('전자정부 서비스 개편 안내',
 'Valdoria 전자정부 서비스가 2026년 4월부터 새롭게 개편됩니다.

개편 내용:
- 통합 로그인 시스템 도입
- 모바일 민원 서비스 확대
- AI 기반 민원 자동 분류 시스템

관련 문의: 전자정부과 (032-xxx-xxxx)',
 '서비스', '전자정부과', true, '2026-03-01 09:00:00', 956),

('2026년 1분기 채용 공고 (행정직 5급)',
 '행정안전부 2026년 1분기 경력경쟁채용 시험을 다음과 같이 공고합니다.

모집 분야: 행정직 5급 (정보보호)
모집 인원: 3명
접수 기간: 2026.03.15 ~ 2026.03.31
시험 일시: 2026.04.20

자세한 사항은 첨부 파일을 참조하세요.',
 '채용', '인사혁신과', true, '2026-03-10 09:00:00', 4215),

('시스템 정기 점검 안내 (3월)',
 '행정안전부 홈페이지 시스템 정기 점검을 아래와 같이 실시합니다.

점검 일시: 2026년 3월 22일(토) 02:00 ~ 06:00
점검 내용: 서버 보안 업데이트 및 DB 최적화
영향 범위: 홈페이지 및 민원 조회 서비스 일시 중단

이용에 불편을 드려 죄송합니다.',
 '시스템', '정보화기획과', true, '2026-03-18 14:00:00', 312),

-- 비공개 공지 (관리자 API로만 조회 가능)
('[내부] 보안 취약점 점검 결과 보고',
 '2026년 1분기 보안 취약점 점검 결과:
- 웹 애플리케이션: 고위험 2건, 중위험 5건
- 네트워크: 고위험 1건, 중위험 3건
- 서버: 중위험 4건

조치 기한: 2026.04.30까지
담당: 정보보안정책과',
 '보안', '정보보안정책과', false, '2026-03-20 16:00:00', 45),

('[내부] DB 서버 접속 정보 변경 안내',
 'DB 서버 접속 정보가 다음과 같이 변경되었습니다.
호스트: 192.168.100.20
포트: 5432
사용자: portal_app
비밀번호: P0rtal#DB@2026!

변경일: 2026.03.01',
 '시스템', '정보화기획과', false, '2026-03-01 11:00:00', 12)
ON CONFLICT DO NOTHING;

-- ============================================================
-- 시드 데이터: 민원
-- ============================================================
INSERT INTO inquiries (tracking_number, subject, description, status, department, submitter_name, submitter_email, submitted_at) VALUES
('INQ-20260315-0042', '도로 보수 요청', '마곡동 일대 도로 포장 상태가 불량합니다. 보수 요청 드립니다.', '처리중', '도로관리과', '김민수', 'minsu.kim@example.com', '2026-03-15 14:30:00'),
('INQ-20260310-0035', '가로등 고장 신고', '대화동 사거리 부근 가로등 2기 미점등 상태입니다.', '처리완료', '시설관리과', '이영희', 'younghee@example.com', '2026-03-10 09:15:00'),
('INQ-20260320-0051', '소음 민원', '인근 공사장 야간 소음이 심합니다. 조치 바랍니다.', '접수', '환경정책과', '박지훈', 'jihun.park@example.com', '2026-03-20 22:00:00'),
('INQ-20260318-0048', '개인정보 열람 요청', '본인의 개인정보 처리 현황 열람을 요청합니다.', '처리중', '개인정보보호과', '최서연', 'seoyeon.choi@example.com', '2026-03-18 10:30:00'),
('INQ-20260322-0055', '복지 서비스 문의', '신규 복지 서비스 신청 방법을 안내 부탁드립니다.', '접수', '복지정책과', '정하은', 'haeun.jung@example.com', '2026-03-22 15:45:00')
ON CONFLICT (tracking_number) DO NOTHING;
