<?php
// 가짜 관리 페이지 — Tanner가 SQLi/LFI 에뮬레이션 처리
// 공격자의 SQLi, LFI 시도를 Tanner가 분석/기록한다.
$id = $_GET['id'] ?? '';
// Tanner가 취약 응답 시뮬레이션
echo "Configuration for system: " . $id;
?>
