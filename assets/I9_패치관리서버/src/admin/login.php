<?php
/**
 * 관리자 로그인 페이지
 */

require_once __DIR__ . '/auth.php';

$error = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $username = $_POST['username'] ?? '';
    $password = $_POST['password'] ?? '';

    if (authenticate($username, $password)) {
        header('Location: /admin/dashboard.php');
        exit;
    } else {
        $error = '사용자명 또는 비밀번호가 올바르지 않습니다.';
    }
}

$timeout = isset($_GET['timeout']) ? true : false;
?>
<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>패치 관리 서버 - 관리자 로그인</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet">
    <style>
        body { background-color: #1a1a2e; color: #e0e0e0; }
        .login-card { max-width: 400px; margin: 100px auto; }
        .card { background-color: #16213e; border: 1px solid #0f3460; }
        .card-header { background-color: #0f3460; border-bottom: 1px solid #0f3460; }
    </style>
</head>
<body>
    <div class="container">
        <div class="login-card">
            <div class="card">
                <div class="card-header text-center">
                    <h4>국방부 패치 관리 시스템</h4>
                    <small>관리자 전용</small>
                </div>
                <div class="card-body">
                    <?php if ($error): ?>
                        <div class="alert alert-danger"><?= htmlspecialchars($error) ?></div>
                    <?php endif; ?>
                    <?php if ($timeout): ?>
                        <div class="alert alert-warning">세션이 만료되었습니다. 다시 로그인하세요.</div>
                    <?php endif; ?>

                    <form method="POST" action="">
                        <div class="mb-3">
                            <label class="form-label">사용자명</label>
                            <input type="text" class="form-control" name="username" required autofocus>
                        </div>
                        <div class="mb-3">
                            <label class="form-label">비밀번호</label>
                            <input type="password" class="form-control" name="password" required>
                        </div>
                        <button type="submit" class="btn btn-primary w-100">로그인</button>
                    </form>
                </div>
            </div>
        </div>
    </div>
</body>
</html>
