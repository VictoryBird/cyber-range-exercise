-- ============================================================
-- C13 작전 상황도 서버 — PostgreSQL 스키마 + 시드 데이터
-- 데이터베이스: cop_db
-- ============================================================

-- 데이터베이스 및 사용자 생성 (psql -U postgres 에서 실행)
-- CREATE USER cop_user WITH PASSWORD 'C0p!Map#2024';
-- CREATE DATABASE cop_db OWNER cop_user;

-- \c cop_db

-- ============================================================
-- map_objects: 지도 위 표시 객체 (부대 마커, 방어선, 구역)
-- ============================================================
CREATE TABLE IF NOT EXISTS map_objects (
    id              SERIAL PRIMARY KEY,
    obj_type        VARCHAR(20) NOT NULL,       -- 'unit', 'line', 'area'
    sub_type        VARCHAR(30),                -- 'infantry', 'armor', 'artillery', 'defense_line', 'op_area'
    affiliation     VARCHAR(10) NOT NULL,       -- 'friendly', 'enemy', 'neutral'
    label           VARCHAR(200) NOT NULL,      -- ★ Stored XSS 가능 (미검증)
    position_lat    DOUBLE PRECISION,
    position_lng    DOUBLE PRECISION,
    positions_json  TEXT,                        -- 다중 좌표 (라인/영역용, JSON 배열)
    color           VARCHAR(7) DEFAULT '#0066CC',
    icon            VARCHAR(50) DEFAULT 'circle',
    metadata        JSONB DEFAULT '{}',
    status          VARCHAR(20) DEFAULT 'active', -- 'active', 'inactive', 'destroyed'
    created_at      TIMESTAMP DEFAULT NOW(),
    updated_at      TIMESTAMP DEFAULT NOW()
);

-- ============================================================
-- events: 작전 이벤트 (타임라인 표시용)
-- ============================================================
CREATE TABLE IF NOT EXISTS events (
    id              SERIAL PRIMARY KEY,
    event_type      VARCHAR(30) NOT NULL,       -- 'friendly_move', 'enemy_advance', 'artillery_fire', 'air_support'
    description     TEXT,
    unit_name       VARCHAR(100),
    location_lat    DOUBLE PRECISION,
    location_lng    DOUBLE PRECISION,
    event_time      TIMESTAMP DEFAULT NOW(),
    source          VARCHAR(20) DEFAULT 'relay', -- 'relay', 'manual', 'sensor'
    priority        VARCHAR(10) DEFAULT 'medium', -- 'low', 'medium', 'high', 'critical'
    created_at      TIMESTAMP DEFAULT NOW()
);

-- ============================================================
-- audit_log: 변경 이력 (있으나 모니터링 안 함 — 설계적 취약)
-- ============================================================
CREATE TABLE IF NOT EXISTS audit_log (
    id              SERIAL PRIMARY KEY,
    table_name      VARCHAR(50),
    record_id       INTEGER,
    action          VARCHAR(10),                -- 'INSERT', 'UPDATE', 'DELETE'
    old_data        JSONB,
    new_data        JSONB,
    changed_by      VARCHAR(50),
    changed_at      TIMESTAMP DEFAULT NOW()
);

-- 인덱스
CREATE INDEX IF NOT EXISTS idx_map_objects_affiliation ON map_objects(affiliation);
CREATE INDEX IF NOT EXISTS idx_map_objects_type ON map_objects(obj_type);
CREATE INDEX IF NOT EXISTS idx_events_type ON events(event_type);
CREATE INDEX IF NOT EXISTS idx_events_time ON events(event_time);

-- ============================================================
-- 시드 데이터: 아군 부대 마커 (13개)
-- ============================================================
INSERT INTO map_objects (obj_type, sub_type, affiliation, label, position_lat, position_lng, color, icon, metadata, status) VALUES

-- 아군 보병
('unit', 'infantry', 'friendly', '제1보병사단 11연대', 37.8950, 126.7680, '#0066CC', 'infantry', '{"strength": "연대", "personnel": 3200, "equipment": "K2 소총, K201 유탄발사기"}', 'active'),
('unit', 'infantry', 'friendly', '제3보병사단 22연대', 38.1070, 127.0740, '#0066CC', 'infantry', '{"strength": "연대", "personnel": 2800, "equipment": "K2 소총, 81mm 박격포"}', 'active'),
('unit', 'infantry', 'friendly', '제5보병사단 35연대', 38.0550, 127.3600, '#0066CC', 'infantry', '{"strength": "연대", "personnel": 3000, "equipment": "K2 소총, TOW 대전차미사일"}', 'active'),
('unit', 'infantry', 'friendly', '제6보병사단 19연대', 38.2300, 127.5800, '#0066CC', 'infantry', '{"strength": "연대", "personnel": 2600, "equipment": "K2 소총, 클레이모어"}', 'active'),
('unit', 'infantry', 'friendly', '제9보병사단 29연대', 37.9500, 127.1200, '#0066CC', 'infantry', '{"strength": "연대", "personnel": 2900, "equipment": "K2 소총, 106mm 무반동포"}', 'active'),

-- 아군 기갑
('unit', 'armor', 'friendly', '제1기갑여단', 37.7600, 126.9300, '#0044AA', 'armor', '{"strength": "여단", "vehicles": 120, "equipment": "K1A2 전차, K21 장갑차"}', 'active'),
('unit', 'armor', 'friendly', '제3기갑여단', 38.0200, 127.0900, '#0044AA', 'armor', '{"strength": "여단", "vehicles": 95, "equipment": "K1A1 전차, K200 장갑차"}', 'active'),

-- 아군 포병
('unit', 'artillery', 'friendly', '제1포병여단', 37.6800, 126.8500, '#0088FF', 'artillery', '{"strength": "여단", "guns": 48, "equipment": "K9 자주포, MLRS"}', 'active'),
('unit', 'artillery', 'friendly', '제5포병여단', 38.1500, 127.2000, '#0088FF', 'artillery', '{"strength": "여단", "guns": 36, "equipment": "K55A1 자주포, 130mm 다연장"}', 'active'),

-- 아군 특수전
('unit', 'special', 'friendly', '특전사 제1공수특전여단', 37.5500, 127.0200, '#003399', 'special', '{"strength": "여단", "personnel": 1500, "equipment": "특수작전 장비"}', 'active'),

-- 아군 방공
('unit', 'air_defense', 'friendly', '제1방공여단', 37.7200, 127.0500, '#0055CC', 'air_defense', '{"strength": "여단", "systems": 24, "equipment": "천마, 비호, 신궁"}', 'active'),

-- 아군 공병
('unit', 'engineer', 'friendly', '제1공병여단', 37.8200, 126.9800, '#0066CC', 'engineer', '{"strength": "여단", "personnel": 800, "equipment": "교량장비, 지뢰제거기"}', 'active'),

-- 아군 지휘소
('unit', 'headquarters', 'friendly', '제1군단 전방지휘소', 37.9000, 127.0000, '#000099', 'headquarters', '{"strength": "군단", "type": "전방지휘소"}', 'active');

-- ============================================================
-- 시드 데이터: 적군 부대 마커 (7개)
-- ============================================================
INSERT INTO map_objects (obj_type, sub_type, affiliation, label, position_lat, position_lng, color, icon, metadata, status) VALUES

('unit', 'infantry', 'enemy', '적 제4보병군단', 38.4500, 126.9200, '#CC0000', 'infantry', '{"strength": "군단", "estimated_personnel": 45000}', 'active'),
('unit', 'armor', 'enemy', '적 제105기갑사단', 38.5200, 127.0500, '#CC0000', 'armor', '{"strength": "사단", "estimated_vehicles": 300}', 'active'),
('unit', 'armor', 'enemy', '적 제820기갑군단', 38.6000, 127.3000, '#CC0000', 'armor', '{"strength": "군단", "estimated_vehicles": 800}', 'active'),
('unit', 'artillery', 'enemy', '적 장사정포 여단', 38.4800, 127.1500, '#FF0000', 'artillery', '{"strength": "여단", "estimated_guns": 200, "range_km": 60}', 'active'),
('unit', 'special', 'enemy', '적 경보병사단', 38.5500, 126.8000, '#CC0000', 'special', '{"strength": "사단", "estimated_personnel": 8000}', 'active'),
('unit', 'infantry', 'enemy', '적 제2보병군단', 38.4200, 127.4500, '#CC0000', 'infantry', '{"strength": "군단", "estimated_personnel": 40000}', 'active'),
('unit', 'air_defense', 'enemy', '적 방공사단', 38.5800, 127.2000, '#FF3333', 'air_defense', '{"strength": "사단", "estimated_systems": 150}', 'active');

-- ============================================================
-- 시드 데이터: 방어선 (4개)
-- ============================================================
INSERT INTO map_objects (obj_type, sub_type, affiliation, label, position_lat, position_lng, positions_json, color, icon, metadata, status) VALUES

('line', 'defense_line', 'friendly', '주저항선 (FEBA)', NULL, NULL,
 '[{"lat":37.95,"lng":126.60},{"lat":37.98,"lng":126.80},{"lat":38.05,"lng":127.00},{"lat":38.10,"lng":127.20},{"lat":38.15,"lng":127.40},{"lat":38.12,"lng":127.60}]',
 '#00CC00', 'solid_line', '{"type": "FEBA", "priority": "primary"}', 'active'),

('line', 'defense_line', 'friendly', '차기 방어선 (NEXT)', NULL, NULL,
 '[{"lat":37.75,"lng":126.55},{"lat":37.80,"lng":126.80},{"lat":37.85,"lng":127.00},{"lat":37.90,"lng":127.20},{"lat":37.88,"lng":127.40}]',
 '#66CC66', 'dashed_line', '{"type": "next_defense", "priority": "secondary"}', 'active'),

('line', 'boundary', 'neutral', 'GOP/MDL (군사분계선)', NULL, NULL,
 '[{"lat":38.32,"lng":126.50},{"lat":38.35,"lng":126.80},{"lat":38.32,"lng":127.00},{"lat":38.30,"lng":127.20},{"lat":38.35,"lng":127.40},{"lat":38.40,"lng":127.60},{"lat":38.45,"lng":127.80}]',
 '#FF6600', 'thick_line', '{"type": "MDL", "description": "군사분계선"}', 'active'),

('line', 'defense_line', 'friendly', '전진 경계선 (FLET)', NULL, NULL,
 '[{"lat":38.10,"lng":126.65},{"lat":38.15,"lng":126.85},{"lat":38.20,"lng":127.05},{"lat":38.22,"lng":127.25},{"lat":38.25,"lng":127.45}]',
 '#33CC33', 'dotted_line', '{"type": "FLET", "priority": "forward"}', 'active');

-- ============================================================
-- 시드 데이터: 작전 구역 (3개)
-- ============================================================
INSERT INTO map_objects (obj_type, sub_type, affiliation, label, position_lat, position_lng, positions_json, color, icon, metadata, status) VALUES

('area', 'op_area', 'friendly', '제1군단 작전구역', NULL, NULL,
 '[{"lat":37.70,"lng":126.60},{"lat":38.20,"lng":126.60},{"lat":38.20,"lng":127.10},{"lat":37.70,"lng":127.10}]',
 '#0066CC33', 'area', '{"corps": "제1군단", "type": "AO"}', 'active'),

('area', 'op_area', 'friendly', '제3군단 작전구역', NULL, NULL,
 '[{"lat":37.70,"lng":127.10},{"lat":38.20,"lng":127.10},{"lat":38.20,"lng":127.60},{"lat":37.70,"lng":127.60}]',
 '#0044AA33', 'area', '{"corps": "제3군단", "type": "AO"}', 'active'),

('area', 'engagement', 'enemy', '적 예상 주공 축선', NULL, NULL,
 '[{"lat":38.35,"lng":126.85},{"lat":38.40,"lng":127.05},{"lat":38.20,"lng":127.15},{"lat":38.15,"lng":126.95}]',
 '#CC000033', 'area', '{"type": "expected_main_attack", "assessed_probability": "high"}', 'active');

-- ============================================================
-- 시드 데이터: 이벤트 타임라인 (최근 24시간, 15건)
-- ============================================================
INSERT INTO events (event_type, description, unit_name, location_lat, location_lng, event_time, source, priority) VALUES

('friendly_move', '제1보병사단 11연대 진지 전환 완료', '제1보병사단 11연대', 37.8950, 126.7680, NOW() - INTERVAL '23 hours', 'relay', 'medium'),
('enemy_advance', '적 제4보병군단 전초 활동 증가 감지', '적 제4보병군단', 38.4500, 126.9200, NOW() - INTERVAL '20 hours', 'sensor', 'high'),
('artillery_fire', '제1포병여단 사격 훈련 실시', '제1포병여단', 37.6800, 126.8500, NOW() - INTERVAL '18 hours', 'manual', 'low'),
('friendly_move', '제3기갑여단 전개 위치 도착', '제3기갑여단', 38.0200, 127.0900, NOW() - INTERVAL '16 hours', 'relay', 'medium'),
('enemy_advance', '적 제105기갑사단 야간 이동 포착', '적 제105기갑사단', 38.5200, 127.0500, NOW() - INTERVAL '14 hours', 'sensor', 'high'),
('air_support', '공군 KF-16 편대 초계 비행 실시', '공군 제20전투비행단', 37.5500, 126.7000, NOW() - INTERVAL '12 hours', 'manual', 'medium'),
('friendly_move', '제9보병사단 29연대 교대 이동', '제9보병사단 29연대', 37.9500, 127.1200, NOW() - INTERVAL '10 hours', 'relay', 'low'),
('enemy_advance', '적 장사정포 진지 이동 감지', '적 장사정포 여단', 38.4800, 127.1500, NOW() - INTERVAL '8 hours', 'sensor', 'critical'),
('friendly_move', '특전사 침투 조 귀환 완료', '특전사 제1공수특전여단', 37.5500, 127.0200, NOW() - INTERVAL '6 hours', 'manual', 'medium'),
('artillery_fire', '적 포병 시험 사격 감지', '적 장사정포 여단', 38.4800, 127.1500, NOW() - INTERVAL '5 hours', 'sensor', 'high'),
('friendly_move', '제1기갑여단 예비 진지 이동', '제1기갑여단', 37.7600, 126.9300, NOW() - INTERVAL '4 hours', 'relay', 'medium'),
('enemy_advance', '적 경보병사단 소규모 정찰 활동', '적 경보병사단', 38.5500, 126.8000, NOW() - INTERVAL '3 hours', 'sensor', 'medium'),
('friendly_move', '제5포병여단 사격 진지 전환', '제5포병여단', 38.1500, 127.2000, NOW() - INTERVAL '2 hours', 'relay', 'medium'),
('air_support', '육군 항공 AH-64 정찰 비행', '육군 항공사단', 38.0000, 127.0000, NOW() - INTERVAL '1 hour', 'manual', 'medium'),
('enemy_advance', '적 제820기갑군단 일부 부대 전방 이동', '적 제820기갑군단', 38.6000, 127.3000, NOW() - INTERVAL '30 minutes', 'sensor', 'high');
