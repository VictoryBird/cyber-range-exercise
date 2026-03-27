<?php
/**
 * manifest.json 편집기
 * [취약점] VULN-I9-02: 관리자가 해시를 직접 수정 가능 -- 악성 파일의 해시로 교체 가능
 *   정상 구현: 해시는 서버 측에서 자동 계산, 수동 편집 불가
 *   정상 구현: manifest 변경 시 별도 승인 프로세스 필요
 */

require_once __DIR__ . '/auth.php';
check_auth();

$manifest_content = '';
if (file_exists(MANIFEST_FILE)) {
    $manifest_content = file_get_contents(MANIFEST_FILE);
}

$error = '';
$success = false;

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $new_content = $_POST['manifest'] ?? '';

    // JSON 유효성만 검사
    $parsed = json_decode($new_content);
    if ($parsed === null && json_last_error() !== JSON_ERROR_NONE) {
        $error = 'JSON 형식이 올바르지 않습니다: ' . json_last_error_msg();
    } else {
        // [취약점] VULN-I9-02: 해시 값 수동 편집 허용 -- 공격자가 악성 파일 해시로 교체 가능
        //   정상 구현: 해시는 서버 측에서 실제 파일의 SHA256을 자동 계산하여 삽입
        //   정상 구현: 수동 해시 수정 차단
        file_put_contents(MANIFEST_FILE, json_encode($parsed, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE));

        $log_entry = date('Y-m-d H:i:s') . " MANIFEST_UPDATED by {$_SESSION['username']} from {$_SERVER['REMOTE_ADDR']}\n";
        file_put_contents(DOWNLOAD_LOG, $log_entry, FILE_APPEND);

        header('Location: /admin/dashboard.php?manifest_updated=1');
        exit;
    }
}
?>
<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>패치 관리 서버 - Manifest 편집</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet">
    <style>
        body { background-color: #1a1a2e; color: #e0e0e0; }
        .card { background-color: #16213e; border: 1px solid #0f3460; }
        textarea { font-family: monospace; background-color: #0d1117; color: #c9d1d9; border: 1px solid #30363d; }
    </style>
</head>
<body>
    <nav class="navbar navbar-dark bg-dark">
        <div class="container-fluid">
            <span class="navbar-brand">manifest.json 편집</span>
            <a href="/admin/dashboard.php" class="btn btn-outline-light btn-sm">대시보드로 돌아가기</a>
        </div>
    </nav>

    <div class="container mt-4">
        <?php if ($error): ?>
            <div class="alert alert-danger"><?= htmlspecialchars($error) ?></div>
        <?php endif; ?>

        <div class="alert alert-warning">
            <strong>주의:</strong> manifest.json을 직접 편집합니다.
            파일명과 SHA256 해시가 실제 파일과 일치하는지 확인하세요.
        </div>

        <form method="POST">
            <textarea name="manifest" class="form-control mb-3" rows="30"><?= htmlspecialchars($manifest_content) ?></textarea>
            <div class="d-flex gap-2">
                <button type="submit" class="btn btn-warning">저장</button>
                <a href="/admin/dashboard.php" class="btn btn-secondary">취소</a>
            </div>
        </form>
    </div>
</body>
</html>
