<?php
/**
 * 관리자 대시보드 -- 패치 파일 관리
 */

require_once __DIR__ . '/auth.php';
check_auth();

// manifest.json 로드
$manifest = [];
if (file_exists(MANIFEST_FILE)) {
    $manifest = json_decode(file_get_contents(MANIFEST_FILE), true);
}

$updates = $manifest['updates'] ?? [];
$version = $manifest['version'] ?? 'N/A';
$last_updated = $manifest['last_updated'] ?? 'N/A';

// 업로드 성공 메시지
$upload_msg = $_GET['uploaded'] ?? '';
$manifest_msg = $_GET['manifest_updated'] ?? '';
?>
<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>패치 관리 서버 - 대시보드</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="/admin/assets/style.css" rel="stylesheet">
</head>
<body>
    <nav class="navbar navbar-dark bg-dark">
        <div class="container-fluid">
            <span class="navbar-brand">국방부 패치 관리 시스템</span>
            <div>
                <span class="text-light me-3">관리자: <?= htmlspecialchars($_SESSION['username']) ?></span>
                <a href="/admin/logout.php" class="btn btn-outline-light btn-sm">로그아웃</a>
            </div>
        </div>
    </nav>

    <div class="container mt-4">
        <?php if ($upload_msg): ?>
            <div class="alert alert-success">파일이 업로드되었습니다: <?= htmlspecialchars($upload_msg) ?></div>
        <?php endif; ?>
        <?php if ($manifest_msg): ?>
            <div class="alert alert-success">manifest.json이 업데이트되었습니다.</div>
        <?php endif; ?>

        <div class="row mb-4">
            <div class="col-md-4">
                <div class="card bg-dark text-light">
                    <div class="card-body">
                        <h5>Manifest 버전</h5>
                        <p class="display-6"><?= htmlspecialchars($version) ?></p>
                    </div>
                </div>
            </div>
            <div class="col-md-4">
                <div class="card bg-dark text-light">
                    <div class="card-body">
                        <h5>등록된 패치</h5>
                        <p class="display-6"><?= count($updates) ?>개</p>
                    </div>
                </div>
            </div>
            <div class="col-md-4">
                <div class="card bg-dark text-light">
                    <div class="card-body">
                        <h5>마지막 업데이트</h5>
                        <p class="lead"><?= htmlspecialchars($last_updated) ?></p>
                    </div>
                </div>
            </div>
        </div>

        <!-- 패치 파일 목록 -->
        <h4>등록된 패치 목록</h4>
        <table class="table table-striped table-hover">
            <thead class="table-dark">
                <tr>
                    <th>ID</th>
                    <th>파일명</th>
                    <th>버전</th>
                    <th>심각도</th>
                    <th>크기</th>
                    <th>SHA256</th>
                    <th>자동설치</th>
                </tr>
            </thead>
            <tbody>
                <?php foreach ($updates as $u): ?>
                <tr>
                    <td><?= htmlspecialchars($u['id']) ?></td>
                    <td><?= htmlspecialchars($u['filename']) ?></td>
                    <td><?= htmlspecialchars($u['version']) ?></td>
                    <td>
                        <span class="badge bg-<?= $u['severity'] === 'critical' ? 'danger' : ($u['severity'] === 'high' ? 'warning' : 'info') ?>">
                            <?= htmlspecialchars($u['severity']) ?>
                        </span>
                    </td>
                    <td><?= number_format($u['size'] / 1024 / 1024, 1) ?> MB</td>
                    <td><code><?= substr($u['sha256'], 0, 16) ?>...</code></td>
                    <td><?= $u['auto_install'] ? 'Y' : 'N' ?></td>
                </tr>
                <?php endforeach; ?>
            </tbody>
        </table>

        <hr>

        <!-- 파일 업로드 -->
        <h4>패치 파일 업로드</h4>
        <form action="/admin/upload.php" method="POST" enctype="multipart/form-data" class="mb-4">
            <div class="row">
                <div class="col-md-8">
                    <input type="file" class="form-control" name="patch_file" required>
                </div>
                <div class="col-md-4">
                    <button type="submit" class="btn btn-primary w-100">업로드</button>
                </div>
            </div>
            <small class="text-muted">최대 100MB. 업로드 후 manifest.json을 수동으로 업데이트하세요.</small>
        </form>

        <hr>

        <!-- Manifest 편집 링크 -->
        <div class="d-flex gap-2">
            <a href="/admin/manifest_editor.php" class="btn btn-warning">manifest.json 편집</a>
            <a href="/admin/logs.php" class="btn btn-secondary">다운로드 로그</a>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
