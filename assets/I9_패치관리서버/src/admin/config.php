<?php
/**
 * 패치 관리 서버 설정
 * [취약점] VULN-I9-01: 관리자 비밀번호가 소스코드에 하드코딩, 약한 비밀번호
 *   정상 구현: 환경변수 또는 별도 설정 파일에서 읽어오고, 강력한 비밀번호 사용
 *   정상 구현: password_hash()로 해시 저장, password_verify()로 검증
 */

define('ADMIN_USERNAME', 'admin');
define('ADMIN_PASSWORD', 'admin123');     // [취약점] VULN-I9-01: 약한 비밀번호 (브루트포스 가능)
define('UPDATES_DIR', '/var/www/update-server/updates');
define('MANIFEST_FILE', UPDATES_DIR . '/manifest.json');
define('LOG_DIR', '/var/www/update-server/logs');
define('DOWNLOAD_LOG', LOG_DIR . '/download.log');
define('MAX_UPLOAD_SIZE', 100 * 1024 * 1024); // 100MB
define('SESSION_TIMEOUT', 3600); // 1시간
