-- ============================================================
-- D1 외부 포털 서버 — PostgreSQL 초기화 스크립트
-- Database: mnd_portal
-- ============================================================

-- 데이터베이스 및 사용자 생성 (psql -U postgres 로 실행)
-- CREATE USER portal WITH PASSWORD 'Portal@DB2024!';
-- CREATE DATABASE mnd_portal OWNER portal;
-- \c mnd_portal

-- ============================================================
-- 테이블 생성
-- ============================================================

-- 공지사항
CREATE TABLE IF NOT EXISTS notice (
    id SERIAL PRIMARY KEY,
    title VARCHAR(500) NOT NULL,
    content TEXT,
    author VARCHAR(100) DEFAULT '국방부',
    created_at TIMESTAMP DEFAULT NOW(),
    view_count INT DEFAULT 0
);

-- 자료실
CREATE TABLE IF NOT EXISTS download (
    id SERIAL PRIMARY KEY,
    filename VARCHAR(500) NOT NULL,
    description TEXT,
    filepath VARCHAR(1000),
    filesize BIGINT,
    created_at TIMESTAMP DEFAULT NOW(),
    download_count INT DEFAULT 0
);

-- 연락처
CREATE TABLE IF NOT EXISTS contact (
    id SERIAL PRIMARY KEY,
    department VARCHAR(200) NOT NULL,
    phone VARCHAR(50),
    email VARCHAR(200),
    address TEXT
);

-- ============================================================
-- 시드 데이터: 공지사항 (5건)
-- ============================================================
INSERT INTO notice (title, content, author, created_at, view_count) VALUES
(
    '2026년 상반기 국방 정책 방향',
    '올해 상반기 국방 정책의 핵심 방향은 첨단과학기술 기반의 강한 국방 구현, 한반도 평화 프로세스 뒷받침, 국민과 함께하는 국방 운영입니다. 국방부는 AI, 드론, 사이버 분야의 혁신적 전력 증강을 통해 미래전 대비 태세를 확립하고, 장병 복지 향상 및 투명한 국방 행정을 추진하겠습니다.',
    '국방정책실',
    '2026-01-15 09:00:00',
    342
),
(
    '사이버보안 강화 지침 시행 안내',
    '전군 사이버보안 강화 지침이 2026년 2월 1일부터 시행됩니다. 주요 내용으로는 다중인증(MFA) 의무화, 비밀번호 복잡도 강화(12자 이상), 분기별 보안 교육 이수 필수, USB 등 이동식 매체 사용 제한 확대 등이 포함됩니다. 각 부대 정보보호담당관은 지침 이행 현황을 매월 보고하시기 바랍니다.',
    '사이버작전사령부',
    '2026-02-01 10:00:00',
    589
),
(
    '군 정보시스템 보안 점검 일정 공지',
    '2026년 상반기 군 정보시스템 보안 점검 일정을 안내드립니다.\n\n1차 점검: 3월 10일 ~ 3월 21일 (국방망 시스템)\n2차 점검: 4월 7일 ~ 4월 18일 (인터넷망 시스템)\n3차 점검: 5월 12일 ~ 5월 23일 (전술 네트워크)\n\n점검 기간 중 일시적 서비스 중단이 발생할 수 있으며, 사전 공지 후 진행합니다. 각 부서 협조 부탁드립니다.',
    '정보화기획관',
    '2026-02-20 14:00:00',
    267
),
(
    '병역의무 이행 안내 (2026년 개정)',
    '2026년 개정된 병역법에 따른 주요 변경사항을 안내합니다.\n\n- 현역 복무기간: 육군 18개월, 해군 20개월, 공군 21개월 (변동 없음)\n- 산업기능요원 편입 자격 기준 변경\n- 대체복무 신청 절차 간소화\n- 전공분야 병역 특례 확대\n\n자세한 사항은 병무청 홈페이지를 참고하시기 바랍니다.',
    '병무청',
    '2026-03-01 09:30:00',
    1024
),
(
    '국방부 홈페이지 시스템 점검 안내',
    '국방부 홈페이지 성능 개선 및 보안 패치 적용을 위한 시스템 점검을 실시합니다.\n\n- 점검일시: 2026년 3월 15일(토) 02:00 ~ 06:00 (4시간)\n- 영향범위: 홈페이지 전체 서비스 일시 중단\n- 점검내용: 서버 보안 업데이트, 데이터베이스 최적화, SSL 인증서 갱신\n\n점검 시간 동안 서비스 이용이 불가하오니 양해 부탁드립니다.',
    '정보화기획관',
    '2026-03-15 16:00:00',
    156
);

-- ============================================================
-- 시드 데이터: 자료실 (4건)
-- ============================================================
INSERT INTO download (filename, description, filepath, filesize, created_at, download_count) VALUES
(
    '2026_defense_whitepaper.pdf',
    '2026 국방백서 (공개본) — 국방 정책, 전력 현황, 국제 안보 환경 분석',
    '/data/downloads/2026_defense_whitepaper.pdf',
    15728640,
    '2026-01-20 09:00:00',
    487
),
(
    'military_service_guide.pdf',
    '병역의무 안내서 — 병역의무 이행 절차, FAQ, 관련 서식 포함',
    '/data/downloads/military_service_guide.pdf',
    8388608,
    '2026-02-05 10:00:00',
    312
),
(
    'cyber_security_policy.pdf',
    '사이버보안 정책 요약본 — 2026년 군 사이버보안 강화 지침 요약',
    '/data/downloads/cyber_security_policy.pdf',
    3145728,
    '2026-02-10 11:00:00',
    198
),
(
    'procurement_form.hwp',
    '조달 신청 양식 — 국방부 물품 조달 신청서 서식',
    '/data/downloads/procurement_form.hwp',
    524288,
    '2026-03-01 09:00:00',
    89
);

-- ============================================================
-- 시드 데이터: 연락처 (4건)
-- ============================================================
INSERT INTO contact (department, phone, email, address) VALUES
(
    '국방정책실',
    '02-748-5114',
    'policy@mnd.valdoria.mil',
    '발도리아 수도 중앙로 22, 국방부 본관 3층'
),
(
    '사이버작전사령부',
    '042-550-5000',
    'cyber@mnd.valdoria.mil',
    '발도리아 대전시 유성구 국방로 88'
),
(
    '인사복지실',
    '02-748-5200',
    'hr@mnd.valdoria.mil',
    '발도리아 수도 중앙로 22, 국방부 본관 5층'
),
(
    '정보화기획관',
    '02-748-5300',
    'it@mnd.valdoria.mil',
    '발도리아 수도 중앙로 22, 국방부 별관 2층'
);

-- ============================================================
-- 권한 부여
-- ============================================================
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO portal;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO portal;
