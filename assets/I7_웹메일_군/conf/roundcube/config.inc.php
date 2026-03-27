<?php

// ============================================================
// Roundcube 설정 -- 군 웹메일 서버 (192.168.110.11)
// [취약점] VULN-I7-01: CVE-2025-49113 취약 버전 (Roundcube 1.6.6)
// 훈련 환경용 (의도적 취약점 포함)
// ============================================================

// --- 데이터베이스 설정 ---
$config['db_dsnw'] = 'sqlite:////var/lib/roundcube/db/sqlite.db?mode=0646';

// --- IMAP 서버 설정 ---
$config['imap_host'] = 'localhost:143';
$config['imap_auth_type'] = 'PLAIN';

$config['imap_conn_options'] = array(
    'ssl' => array(
        'verify_peer' => false,
        'verify_peer_name' => false,
    ),
);

// --- SMTP 서버 설정 ---
$config['smtp_host'] = 'localhost:25';
$config['smtp_auth_type'] = '';

$config['smtp_conn_options'] = array();

// --- 일반 설정 ---
$config['product_name'] = 'MND 웹메일';
$config['des_key'] = 'M7nD3pQ9vB3nR1mD8wF5jL4a';

$config['support_url'] = '';
$config['skin'] = 'elastic';
$config['language'] = 'ko_KR';
$config['timezone'] = 'Asia/Seoul';

// --- 세션 설정 ---
$config['session_lifetime'] = 1440;
$config['session_domain'] = '';
$config['session_name'] = 'roundcube_sessid';
$config['session_auth_name'] = 'roundcube_sessauth';

// --- 세션 쿠키 보안 ---
$config['use_https'] = false;
$config['login_autocomplete'] = 2;

// --- 로깅 설정 ---
$config['log_driver'] = 'file';
$config['log_dir'] = '/var/log/roundcube/';
$config['per_user_logging'] = false;
$config['smtp_log'] = true;
$config['log_logins'] = true;
$config['log_session'] = false;

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

// --- 첨부파일 설정 ---
$config['upload_max_filesize'] = '50M';
$config['max_message_size'] = '50M';

// --- 주소록 설정 ---
$config['autocomplete_addressbooks'] = array('sql', 'global_ldap_abook');
$config['ldap_public'] = array(
    'global_ldap_abook' => array(
        'name'          => 'MND 직원 주소록',
        'hosts'         => array('192.168.110.50'),
        'port'          => 389,
        'base_dn'       => 'ou=Users,dc=corp,dc=mnd,dc=local',
        'bind_dn'       => 'cn=mail-service,ou=ServiceAccounts,dc=corp,dc=mnd,dc=local',
        'bind_pass'     => 'MailSvc2026!',
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
$config['draft_autosave'] = 60;
$config['default_charset'] = 'UTF-8';
$config['mime_types'] = '/etc/roundcube/mime.types';

// --- 보안 설정 ---
$config['ip_check'] = false;
$config['referer_check'] = false;
$config['x_frame_options'] = false;
$config['request_token_secret'] = '';
