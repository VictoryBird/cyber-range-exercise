<?php

// ============================================================
// Roundcube 설정 — 웹메일 서버 (192.168.100.11)
// 훈련 환경용 (의도적 취약점 포함)
// ============================================================

// --- 데이터베이스 설정 ---
$config['db_dsnw'] = 'sqlite:////var/lib/roundcube/db/sqlite.db?mode=0646';

// --- IMAP 서버 설정 ---
$config['imap_host'] = 'localhost:143';
$config['imap_auth_type'] = 'PLAIN';
// [취약 설정] IMAP 평문 인증 (localhost이므로 실질적 위험은 낮으나 설정 자체가 취약)

$config['imap_conn_options'] = array(
    'ssl' => array(
        'verify_peer' => false,
        'verify_peer_name' => false,
    ),
);

// --- SMTP 서버 설정 ---
$config['smtp_host'] = 'localhost:25';
$config['smtp_auth_type'] = '';
// [취약 설정] SMTP 인증 미사용 → Roundcube에서 발송 시 SMTP AUTH 없이 전송
//   Postfix의 permit_mynetworks로 localhost 허용되므로 동작함

$config['smtp_conn_options'] = array();

// --- 일반 설정 ---
$config['product_name'] = 'MOIS 웹메일';
$config['des_key'] = 'K7xG2pQ9vB3nR1mD8wF5jL4a';
// [취약 설정] VULN-05-05: des_key가 약한 고정값 → 세션 쿠키 복호화 가능
//   → 정상 설정: 랜덤 24자 키, 배포 시마다 재생성

$config['support_url'] = '';
$config['skin'] = 'elastic';
$config['language'] = 'ko_KR';
$config['timezone'] = 'Asia/Seoul';

// --- 세션 설정 ---
$config['session_lifetime'] = 1440;
// [취약 설정] VULN-05-05: 세션 유효 시간 1440분 (24시간)
//   → 로그인 후 하루 종일 재인증 없이 사용 가능
//   → 세션 하이재킹 시 장시간 악용 가능
//   → 정상 설정: session_lifetime = 30 (30분)

$config['session_domain'] = '';
$config['session_name'] = 'roundcube_sessid';
// [취약 설정] 기본 세션 쿠키명 사용 → 웹메일 서비스 식별 용이
//   → 정상 설정: 커스텀 세션명 사용

$config['session_auth_name'] = 'roundcube_sessauth';

// --- 세션 쿠키 보안 ---
$config['use_https'] = false;
// [취약 설정] HTTPS 강제 비활성 → HTTP로 세션 쿠키 전송 가능
//   → 정상 설정: use_https = true

$config['login_autocomplete'] = 2;
// [취약 설정] 로그인 폼 자동완성 허용 → 브라우저에 크리덴셜 캐시
//   → 정상 설정: login_autocomplete = 0

// --- 로깅 설정 ---
$config['log_driver'] = 'file';
$config['log_dir'] = '/var/log/roundcube/';
$config['per_user_logging'] = false;
$config['smtp_log'] = true;
$config['log_logins'] = true;
$config['log_session'] = false;
// [참고] 로그인/SMTP 로그는 활성화 → 블루팀 분석 포인트

// --- 플러그인 설정 ---
$config['plugins'] = array(
    'archive',
    'zipdownload',
    'password',
    'managesieve',
    'emoticons',
    'vcard_attachments',
    'filesystem_attachments',
    'newmail_notifier',
    'attachment_reminder',
);
// [참고] filesystem_attachments 플러그인
//   → 첨부파일을 /tmp에 임시 저장 (디스크 기반)
//   → /tmp 접근 가능 시 다른 사용자 첨부파일 노출 가능성

// --- 첨부파일 설정 ---
$config['upload_max_filesize'] = '50M';
// [취약 설정] VULN-05-04: 대용량 첨부 허용 — Postfix message_size_limit과 동일하게 50MB
//   → 정상 설정: upload_max_filesize = '10M'

$config['max_message_size'] = '50M';

// --- 주소록 설정 ---
$config['autocomplete_addressbooks'] = array('sql', 'global_ldap_abook');
$config['ldap_public'] = array(
    'global_ldap_abook' => array(
        'name'          => 'MOIS 직원 주소록',
        'hosts'         => array('192.168.100.50'),
        'port'          => 389,
        'base_dn'       => 'ou=Users,dc=mois,dc=local',
        'bind_dn'       => 'cn=mail-service,ou=ServiceAccounts,dc=mois,dc=local',
        'bind_pass'     => 'MailSvc2026!',
        // [취약 설정] LDAP 바인드 비밀번호 평문 노출
        'search_fields' => array('cn', 'mail', 'uid'),
        'fieldmap'      => array(
            'name'    => 'cn',
            'email'   => 'mail',
            'department' => 'ou',
        ),
        'filter'        => '(objectClass=person)',
        'scope'         => 'sub',
        'writable'      => false,
    ),
);

// --- 메일 작성 설정 ---
$config['htmleditor'] = 1;
// HTML 에디터 기본 사용

$config['draft_autosave'] = 60;
$config['default_charset'] = 'UTF-8';
$config['mime_types'] = '/etc/roundcube/mime.types';

// --- 보안 설정 ---
$config['ip_check'] = false;
// [취약 설정] 세션 IP 검증 비활성 → 다른 IP에서 세션 토큰 재사용 가능
//   → 정상 설정: ip_check = true

$config['referer_check'] = false;
// [취약 설정] Referer 헤더 검증 비활성 → CSRF 공격에 취약
//   → 정상 설정: referer_check = true

$config['x_frame_options'] = false;
// [취약 설정] X-Frame-Options 미설정 → Clickjacking 가능
//   → 정상 설정: x_frame_options = 'sameorigin'

$config['request_token_secret'] = '';
// [취약 설정] CSRF 토큰 시크릿 비어있음 → 토큰 예측 가능성
//   → 정상 설정: 랜덤 시크릿 문자열 설정
