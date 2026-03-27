-- ============================================================
-- C14 데이터 수집·관리 서버 — PostgreSQL 스키마 + 시드 데이터
-- 데이터베이스: events_db
-- ============================================================

-- 데이터베이스 및 사용자 생성 (psql -U postgres 에서 실행)
-- CREATE USER events_user WITH PASSWORD 'Ev3nts!C4I#2024';
-- CREATE DATABASE events_db OWNER events_user;

-- \c events_db

-- ============================================================
-- events: 작전 이벤트 (핵심 테이블)
-- ============================================================
CREATE TABLE IF NOT EXISTS events (
    id              SERIAL PRIMARY KEY,
    type            VARCHAR(50) NOT NULL,       -- 이벤트 유형
    unit            VARCHAR(100),               -- 부대명
    location_lat    DOUBLE PRECISION,           -- 위도
    location_lng    DOUBLE PRECISION,           -- 경도
    timestamp       TIMESTAMP DEFAULT NOW(),    -- 이벤트 발생 시각
    priority        VARCHAR(10) DEFAULT 'medium', -- 'low', 'medium', 'high', 'critical'
    source          VARCHAR(20) DEFAULT 'relay',  -- 'relay', 'manual', 'sensor'
    verified        BOOLEAN DEFAULT FALSE,      -- 검증 여부
    description     TEXT,                       -- 설명
    metadata        JSONB DEFAULT '{}',         -- 추가 메타데이터
    created_at      TIMESTAMP DEFAULT NOW(),
    updated_at      TIMESTAMP DEFAULT NOW()
);

-- 인덱스
CREATE INDEX IF NOT EXISTS idx_events_type ON events(type);
CREATE INDEX IF NOT EXISTS idx_events_timestamp ON events(timestamp);
CREATE INDEX IF NOT EXISTS idx_events_priority ON events(priority);
CREATE INDEX IF NOT EXISTS idx_events_source ON events(source);

-- ============================================================
-- api_keys: API 키 관리 (있으나 활용 안 함 — 하드코딩 사용)
-- ============================================================
CREATE TABLE IF NOT EXISTS api_keys (
    id              SERIAL PRIMARY KEY,
    key_value       VARCHAR(100) UNIQUE NOT NULL,
    description     VARCHAR(200),
    is_active       BOOLEAN DEFAULT TRUE,
    created_at      TIMESTAMP DEFAULT NOW()
);

-- 기본 API 키 등록
INSERT INTO api_keys (key_value, description) VALUES
    ('dev-key-12345', '개발용 API 키 (운영 환경에서 교체 필요)'),
    ('admin-key-99999', '관리자 전용 키');

-- ============================================================
-- 시드 데이터: 최근 24시간 작전 이벤트 (30건)
-- ============================================================

INSERT INTO events (type, unit, location_lat, location_lng, timestamp, priority, source, verified, description) VALUES

-- 아군 이동 (12건)
('friendly_move', '제1보병사단 11연대', 37.8950, 126.7680, NOW() - INTERVAL '23 hours', 'medium', 'relay', true, '진지 전환 완료, 새 방어 진지 점령'),
('friendly_move', '제3보병사단 22연대', 38.1070, 127.0740, NOW() - INTERVAL '21 hours', 'medium', 'relay', true, '예비 진지로 이동 중'),
('friendly_move', '제1기갑여단', 37.7600, 126.9300, NOW() - INTERVAL '19 hours', 'medium', 'relay', true, '전개 위치 도착, 대기 상태'),
('friendly_move', '제3기갑여단', 38.0200, 127.0900, NOW() - INTERVAL '17 hours', 'medium', 'relay', true, '전방 전개 완료'),
('friendly_move', '제9보병사단 29연대', 37.9500, 127.1200, NOW() - INTERVAL '15 hours', 'low', 'relay', true, '교대 이동 시작'),
('friendly_move', '특전사 제1공수특전여단', 37.5500, 127.0200, NOW() - INTERVAL '13 hours', 'medium', 'relay', true, '침투조 귀환 완료'),
('friendly_move', '제6보병사단 19연대', 38.2300, 127.5800, NOW() - INTERVAL '11 hours', 'medium', 'relay', true, '전방 관측소 교대'),
('friendly_move', '제5보병사단 35연대', 38.0550, 127.3600, NOW() - INTERVAL '9 hours', 'medium', 'relay', true, '예비 병력 전방 배치'),
('friendly_move', '제1포병여단', 37.6800, 126.8500, NOW() - INTERVAL '7 hours', 'medium', 'relay', true, '사격 진지 전환 완료'),
('friendly_move', '제5포병여단', 38.1500, 127.2000, NOW() - INTERVAL '5 hours', 'medium', 'relay', true, '신규 사격 진지 점령'),
('friendly_move', '제1방공여단', 37.7200, 127.0500, NOW() - INTERVAL '3 hours', 'medium', 'relay', true, '방공 진지 재배치'),
('friendly_move', '제1공병여단', 37.8200, 126.9800, NOW() - INTERVAL '1 hour', 'low', 'relay', true, '교량 보수 완료 후 복귀'),

-- 적군 탐지 (5건)
('enemy_advance', '적 제4보병군단', 38.4500, 126.9200, NOW() - INTERVAL '20 hours', 'high', 'sensor', true, '적 전초 활동 증가, 병력 이동 감지'),
('enemy_advance', '적 제105기갑사단', 38.5200, 127.0500, NOW() - INTERVAL '14 hours', 'high', 'sensor', true, '적 기갑부대 야간 이동 포착'),
('enemy_advance', '적 장사정포 여단', 38.4800, 127.1500, NOW() - INTERVAL '8 hours', 'critical', 'sensor', true, '적 장사정포 진지 이동 감지'),
('enemy_advance', '적 경보병사단', 38.5500, 126.8000, NOW() - INTERVAL '4 hours', 'medium', 'sensor', false, '적 소규모 정찰 활동 추정'),
('enemy_advance', '적 제820기갑군단', 38.6000, 127.3000, NOW() - INTERVAL '30 minutes', 'high', 'sensor', false, '적 기갑군단 일부 부대 전방 이동'),

-- 포병 사격 (5건)
('artillery_fire', '제1포병여단', 37.6800, 126.8500, NOW() - INTERVAL '18 hours', 'low', 'manual', true, '제1포병여단 조정 사격 훈련'),
('artillery_fire', '적 장사정포 여단', 38.4800, 127.1500, NOW() - INTERVAL '6 hours', 'high', 'sensor', true, '적 포병 시험 사격 감지'),
('artillery_fire', '제5포병여단', 38.1500, 127.2000, NOW() - INTERVAL '4 hours', 'medium', 'manual', true, '제5포병여단 대응 사격 준비 완료'),
('artillery_fire', '적 제2보병군단 포병', 38.4200, 127.4500, NOW() - INTERVAL '2 hours', 'high', 'sensor', false, '적 포병 진지 활동 증가'),
('artillery_fire', '제1포병여단', 37.6800, 126.8500, NOW() - INTERVAL '45 minutes', 'medium', 'manual', true, '사격 지원 요청 대기'),

-- 항공 지원 (3건)
('air_support', '공군 제20전투비행단', 37.5500, 126.7000, NOW() - INTERVAL '12 hours', 'medium', 'manual', true, 'KF-16 편대 초계 비행 실시'),
('air_support', '육군 항공사단', 38.0000, 127.0000, NOW() - INTERVAL '2 hours', 'medium', 'manual', true, 'AH-64 정찰 비행 실시'),
('air_support', '공군 제11전투비행단', 37.7000, 126.9000, NOW() - INTERVAL '1 hour', 'high', 'manual', false, 'KF-21 비행 지원 대기'),

-- 정찰 (3건)
('friendly_patrol', '특전사 침투조', 38.3500, 127.0500, NOW() - INTERVAL '16 hours', 'medium', 'manual', true, '특수 정찰 임무 수행 중'),
('friendly_patrol', '제1보병사단 수색대', 37.9200, 126.8000, NOW() - INTERVAL '10 hours', 'low', 'relay', true, '전방 수색 정찰 완료'),
('friendly_patrol', '제3보병사단 정찰대', 38.1500, 127.1000, NOW() - INTERVAL '3 hours', 'medium', 'relay', true, '주야간 정찰 교대'),

-- 보급 (2건)
('friendly_resupply', '군수사령부 제1보급대', 37.6000, 126.9000, NOW() - INTERVAL '22 hours', 'low', 'relay', true, '탄약 및 식량 보급 완료'),
('friendly_resupply', '군수사령부 제3보급대', 37.8000, 127.1000, NOW() - INTERVAL '8 hours', 'low', 'relay', true, '연료 보급 수송 완료');
