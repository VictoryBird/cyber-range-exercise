<?php
/**
 * 관리자 로그아웃
 */
session_start();
session_destroy();
header('Location: /admin/login.php');
exit;
