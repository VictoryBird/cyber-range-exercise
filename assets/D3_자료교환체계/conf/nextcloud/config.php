<?php
/**
 * Nextcloud 커스텀 설정 오버라이드
 * D3 자료교환체계 (211.57.64.12) — share.mnd.valdoria.mil
 *
 * 이 파일은 Nextcloud 기본 config.php에 병합됩니다.
 */
$CONFIG = array (

  /* ── 도메인 및 URL ── */
  'trusted_domains' => array (
    0 => '211.57.64.12',
    1 => 'share.mnd.valdoria.mil',
    2 => 'localhost',
  ),
  'overwrite.cli.url' => 'http://share.mnd.valdoria.mil',

  /* ── 데이터베이스 ── */
  'dbtype' => 'mysql',
  'dbname' => 'nextcloud',
  'dbhost' => 'localhost',
  'dbtableprefix' => 'oc_',
  'mysql.utf8mb4' => true,

  /* ── 캐시 (Redis) ── */
  'memcache.local' => '\\OC\\Memcache\\APCu',
  'memcache.distributed' => '\\OC\\Memcache\\Redis',
  'memcache.locking' => '\\OC\\Memcache\\Redis',
  'redis' => array (
    'host' => 'localhost',
    'port' => 6379,
  ),

  /* ── 지역 설정 ── */
  'default_language' => 'ko',
  'default_locale' => 'ko_KR',
  'default_phone_region' => 'KR',

  /* ── 로깅 ── */
  'loglevel' => 2,
  'logfile' => '/var/www/html/data/nextcloud.log',
  'log_type' => 'file',

  // [취약 설정] VULN-D3-02: WebDAV 대량 다운로드에 대한 속도/건수 제한 없음
  // Nextcloud는 기본적으로 WebDAV rate limiting이 없다.
  // 올바른 구현: 'ratelimit.protection' => true 설정 및
  //   Apache/Nginx에서 PROPFIND, GET 요청에 대한 rate limit 적용
  //   예: mod_ratelimit 또는 limit_req_zone (nginx)
  'ratelimit.protection' => false,

  // [취약 설정] VULN-D3-01: IP 기반 접근 제한 없음
  // 어떤 IP에서든 로그인 가능 (trusted_proxies 미설정)
  // 올바른 구현: VPN 대역(172.20.100.0/24)만 허용하도록
  //   Apache Allow/Deny 또는 Nextcloud brute_force_protection 활성화
);
