<?php
/**
 * 다운로드/활동 로그 뷰어
 */

require_once __DIR__ . '/auth.php';
check_auth();

$log_content = '';
if (file_exists(DOWNLOAD_LOG)) {
    $log_content = file_get_contents(DOWNLOAD_LOG);
}
?>
<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>패치 관리 서버 - 로그</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet">
    <style>
        body { background-color: #1a1a2e; color: #e0e0e0; }
        pre { background-color: #0d1117; color: #c9d1d9; padding: 15px; border-radius: 5px; max-height: 600px; overflow-y: auto; }
    </style>
</head>
<body>
    <nav class="navbar navbar-dark bg-dark">
        <div class="container-fluid">
            <span class="navbar-brand">활동 로그</span>
            <a href="/admin/dashboard.php" class="btn btn-outline-light btn-sm">대시보드로 돌아가기</a>
        </div>
    </nav>

    <div class="container mt-4">
        <pre><?= htmlspecialchars($log_content ?: '(로그가 없습니다)') ?></pre>
    </div>
</body>
</html>
