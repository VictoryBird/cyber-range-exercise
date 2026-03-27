#!/bin/bash
# ============================================================
# D4-D5 허니팟 원클릭 배포 스크립트
# D4: Cowrie SSH 허니팟 (211.57.64.13)
# D5: SNARE/Tanner Web 허니팟 (211.57.64.14)
#
# 참고: 이 스크립트는 단일 VM에서 두 허니팟을 모두 배포한다.
# 실제 운영 시에는 D4/D5 각각 별도 VM에서 실행한다.
# ============================================================
set -e

# ── root 권한 확인 ──
if [ "$EUID" -ne 0 ]; then
    echo "[오류] root 권한으로 실행하세요: sudo $0"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "========================================="
echo " D4-D5 허니팟 배포 시작"
echo " D4: Cowrie SSH  (211.57.64.13:22)"
echo " D5: SNARE Web   (211.57.64.14:80/443)"
echo "========================================="
echo ""

# ──────────────────────────────────────────────
echo "[1/5] 호스트명 설정..."
# 단일 VM 테스트 시에는 하나만 설정
hostnamectl set-hostname mil-hp-ssh

# ──────────────────────────────────────────────
echo "[2/5] Docker 설치..."
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com | sh
    systemctl enable docker
    systemctl start docker
else
    echo "  Docker 이미 설치됨"
fi

if ! docker compose version &> /dev/null; then
    apt-get update
    apt-get install -y docker-compose-plugin
fi

# ──────────────────────────────────────────────
echo "[3/5] 실제 SSH 포트 변경 (관리용 → 2200)..."
if grep -q "^Port 22$" /etc/ssh/sshd_config 2>/dev/null || ! grep -q "^Port " /etc/ssh/sshd_config 2>/dev/null; then
    sed -i 's/^#\?Port .*/Port 2200/' /etc/ssh/sshd_config
    systemctl restart sshd
    echo "  실제 SSH → 포트 2200으로 이동 완료"
    echo "  [주의] 이후 관리 접속은 ssh -p 2200 사용"
else
    echo "  SSH 포트 이미 변경됨"
fi

# ──────────────────────────────────────────────
echo "[4/5] UFW 방화벽 설정..."
if command -v ufw &> /dev/null; then
    ufw allow 2200/tcp  comment "SSH 관리용 (실제 SSH)"
    ufw allow 22/tcp    comment "Cowrie 허니팟 SSH (D4)"
    ufw allow 80/tcp    comment "SNARE 허니팟 HTTP (D5)"
    ufw allow 443/tcp   comment "SNARE 허니팟 HTTPS (D5)"
    ufw --force enable
    echo "  UFW 규칙 적용 완료"
else
    echo "  UFW 미설치 — 건너뜀"
fi

# ──────────────────────────────────────────────
echo "[5/5] Docker Compose 배포..."
cd "${SCRIPT_DIR}"

# 환경변수 파일 준비
if [ ! -f "${SCRIPT_DIR}/.env" ]; then
    cp "${SCRIPT_DIR}/.env.example" "${SCRIPT_DIR}/.env"
    echo "  .env.example → .env 복사 완료"
fi

docker compose down --remove-orphans 2>/dev/null || true
docker compose up -d

echo ""
echo "  컨테이너 기동 대기 중..."
sleep 10

echo ""
docker compose ps
echo ""

echo "========================================="
echo " D4-D5 허니팟 배포 완료"
echo "========================================="
echo ""
echo " D4 — Cowrie SSH 허니팟 (211.57.64.13)"
echo "   포트 22 → Cowrie (가짜 SSH 셸)"
echo "   포트 2200 → 실제 SSH (관리용)"
echo "   테스트: ssh root@211.57.64.13  (비밀번호: admin)"
echo "   로그:   docker logs -f cowrie-ssh"
echo "   JSON:   docker exec cowrie-ssh cat var/log/cowrie/cowrie.json"
echo ""
echo " D5 — SNARE/Tanner Web 허니팟 (211.57.64.14)"
echo "   포트 80/443 → SNARE (가짜 관리 포털)"
echo "   테스트: curl http://211.57.64.14/"
echo "   SQLi:   curl 'http://211.57.64.14/admin/config.php?id=1%27OR%271%27=%271'"
echo "   로그:   docker logs -f snare"
echo "   분석:   docker logs -f tanner"
echo ""
echo " 블루팀 분석 포인트:"
echo "   - 모든 SSH 접속 시도는 공격 징후 (정상 사용자 접근 불가)"
echo "   - 웹 허니팟 접근 시도 = 네트워크 정찰 행위"
echo "   - Cowrie JSON 로그를 SIEM에 연동하여 실시간 모니터링"
echo ""
echo " 주의:"
echo "   - 관리 SSH는 반드시 포트 2200 사용: ssh -p 2200 user@host"
echo "   - 실제 운영 시 D4(211.57.64.13)와 D5(211.57.64.14)는 별도 VM"
echo "========================================="
