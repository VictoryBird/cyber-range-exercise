#!/bin/bash
# ============================================================
# C12 망 연동 서버 설치 스크립트
# 호스트: relay.c4i.local (192.168.130.10)
# OS: Ubuntu 22.04 LTS
# ============================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# root 권한 확인
if [ "$EUID" -ne 0 ]; then
    echo "[오류] root 권한으로 실행하세요: sudo bash setup.sh"
    exit 1
fi

echo "=========================================="
echo "C12 망 연동 서버 설치 시작"
echo "호스트: relay.c4i.local (192.168.130.10)"
echo "=========================================="

# [1/8] 시스템 업데이트
echo "[1/8] 시스템 업데이트..."
apt-get update && apt-get upgrade -y

# [2/8] Python 및 의존성 설치
echo "[2/8] Python 및 의존성 설치..."
apt-get install -y python3 python3-pip python3-venv openssh-server

# [3/8] 디렉토리 구조 생성
echo "[3/8] 디렉토리 구조 생성..."
mkdir -p /opt/relay/{scripts,data,logs,config}

# [4/8] Python 가상 환경 및 패키지 설치
echo "[4/8] Python 가상 환경 설정..."
python3 -m venv /opt/relay/venv
source /opt/relay/venv/bin/activate
[ -f "${SCRIPT_DIR}/src/requirements.txt" ] || { echo "[ERROR] 파일 없음: src/requirements.txt"; exit 1; }
pip install -r "${SCRIPT_DIR}/src/requirements.txt"

# [5/8] 소스 배포
echo "[5/8] 소스 배포..."
[ -f "${SCRIPT_DIR}/src/sync_events.py" ] || { echo "[ERROR] 파일 없음: src/sync_events.py"; exit 1; }
cp "${SCRIPT_DIR}/src/sync_events.py" /opt/relay/scripts/
chmod +x /opt/relay/scripts/sync_events.py

# [6/8] systemd 서비스 등록
echo "[6/8] systemd 서비스 등록..."
[ -f "${SCRIPT_DIR}/conf/systemd/relay-sync.service" ] || { echo "[ERROR] 파일 없음: conf/systemd/relay-sync.service"; exit 1; }
[ -f "${SCRIPT_DIR}/conf/systemd/relay-sync.timer" ] || { echo "[ERROR] 파일 없음: conf/systemd/relay-sync.timer"; exit 1; }
cp "${SCRIPT_DIR}/conf/systemd/relay-sync.service" /etc/systemd/system/
cp "${SCRIPT_DIR}/conf/systemd/relay-sync.timer" /etc/systemd/system/
systemctl daemon-reload
systemctl enable relay-sync.timer
systemctl start relay-sync.timer

# [7/8] 호스트명 및 SSH 설정
echo "[7/8] 호스트명 설정..."
hostnamectl set-hostname relay-c4i

# SSH 서비스 활성화 (★ 공격자 접근 경로)
systemctl enable ssh
systemctl start ssh

# [8/8] 방화벽 설정
echo "[8/8] 방화벽 설정..."
if command -v ufw &> /dev/null; then
    ufw allow 22/tcp    # SSH (★ 공격 경로: relay-admin / R3lay!Sync#2024)
    ufw --force enable
fi

echo "=========================================="
echo "C12 망 연동 서버 설치 완료"
echo "=========================================="
echo ""
echo "  동기화 스크립트: /opt/relay/scripts/sync_events.py"
echo "  동기화 주기: 30초 (relay-sync.timer)"
echo "  로그: /opt/relay/logs/sync.log"
echo ""
echo "  ★ 주의: sync_events.py는 root로 실행됩니다 (VULN-C12-02)"
echo "  ★ 주의: SSH 크리덴셜이 스크립트에 하드코딩됨 (VULN-C12-01)"
echo "  ★ 주의: 스크립트 무결성 검증 없음 (VULN-C12-03)"
echo ""
echo "  타이머 상태 확인: systemctl list-timers relay-sync.timer"
echo "=========================================="
