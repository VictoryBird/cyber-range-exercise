<?php
/**
 * 파일 업로드 처리
 * [취약점] VULN-I9-02: 업로드된 파일의 무결성 검증 없음 -- 악성 파일 교체 가능
 *   정상 구현: 코드 서명 검증, 관리자 2FA 인증 후 업로드 허용
 * [취약점] VULN-I9-03: 코드 서명 검증 없음
 *   정상 구현: 업로드 시 디지털 서명 첨부 필수, 다운로드 시 서명 검증
 */

require_once __DIR__ . '/auth.php';
check_auth();

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    header('Location: /admin/dashboard.php');
    exit;
}

if (!isset($_FILES['patch_file']) || $_FILES['patch_file']['error'] !== UPLOAD_ERR_OK) {
    header('Location: /admin/dashboard.php?error=upload_failed');
    exit;
}

$file = $_FILES['patch_file'];
$filename = basename($file['name']);
$dest = UPDATES_DIR . '/' . $filename;

// 파일 크기 확인
if ($file['size'] > MAX_UPLOAD_SIZE) {
    header('Location: /admin/dashboard.php?error=too_large');
    exit;
}

// [취약점] VULN-I9-02: 파일 무결성 검증 없음 -- 어떤 파일이든 업로드 가능
//   정상 구현: 허용된 확장자 목록 검증, 코드 서명 검증
// [취약점] VULN-I9-03: 코드 서명 없음 -- 디지털 서명 미검증
//   정상 구현: 업로드된 파일의 디지털 서명을 검증하고 서명되지 않은 파일 거부

move_uploaded_file($file['tmp_name'], $dest);

// 업로드 로그 기록
$log_entry = date('Y-m-d H:i:s') . " UPLOAD {$filename} by {$_SESSION['username']} from {$_SERVER['REMOTE_ADDR']}\n";
file_put_contents(DOWNLOAD_LOG, $log_entry, FILE_APPEND);

header('Location: /admin/dashboard.php?uploaded=' . urlencode($filename));
exit;
