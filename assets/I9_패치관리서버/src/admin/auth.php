<?php
/**
 * 인증 함수
 * [취약점] VULN-I9-01: 단순 문자열 비교, 계정 잠금 없음, 지연 없음
 *   정상 구현: password_verify() 사용, 5회 실패 시 계정 잠금, 실패 시 지연(sleep) 추가
 */

require_once __DIR__ . '/config.php';

session_start();

function authenticate($username, $password) {
    // [취약점] VULN-I9-01: 단순 문자열 비교, 계정 잠금 없음, 지연 없음
    //   정상 구현: password_verify($password, $stored_hash) 사용
    //   정상 구현: 실패 횟수 카운트 + 잠금 메커니즘 추가
    if ($username === ADMIN_USERNAME && $password === ADMIN_PASSWORD) {
        $_SESSION['authenticated'] = true;
        $_SESSION['username'] = $username;
        $_SESSION['login_time'] = time();

        // 로그인 기록
        $log_entry = date('Y-m-d H:i:s') . " LOGIN_SUCCESS {$username} from {$_SERVER['REMOTE_ADDR']}\n";
        file_put_contents(DOWNLOAD_LOG, $log_entry, FILE_APPEND);

        return true;
    }

    // 로그인 실패 기록 (계정 잠금 없음 -- 브루트포스 가능)
    $log_entry = date('Y-m-d H:i:s') . " LOGIN_FAILED {$username} from {$_SERVER['REMOTE_ADDR']}\n";
    file_put_contents(DOWNLOAD_LOG, $log_entry, FILE_APPEND);

    return false;
}

function check_auth() {
    if (!isset($_SESSION['authenticated']) || !$_SESSION['authenticated']) {
        header('Location: /admin/login.php');
        exit;
    }

    // 세션 타임아웃 확인
    if (time() - $_SESSION['login_time'] > SESSION_TIMEOUT) {
        session_destroy();
        header('Location: /admin/login.php?timeout=1');
        exit;
    }
}
