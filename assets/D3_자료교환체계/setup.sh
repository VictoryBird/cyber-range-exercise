#!/bin/bash
# ============================================================
# D3 자료교환체계 — Nextcloud 원클릭 배포 스크립트
# 대상: 211.57.64.12 (share.mnd.valdoria.mil)
# ============================================================
set -e

# ── root 권한 확인 ──
if [ "$EUID" -ne 0 ]; then
    echo "[오류] root 권한으로 실행하세요: sudo $0"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "========================================="
echo " D3 자료교환체계 (Nextcloud) 배포 시작"
echo " IP: 211.57.64.12"
echo " 도메인: share.mnd.valdoria.mil"
echo "========================================="
echo ""

# ──────────────────────────────────────────────
echo "[1/7] 호스트명 설정..."
hostnamectl set-hostname mil-share

# ──────────────────────────────────────────────
echo "[2/7] Docker 설치..."
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
echo "[3/7] 환경변수 파일 준비..."
if [ ! -f "${SCRIPT_DIR}/.env" ]; then
    cp "${SCRIPT_DIR}/.env.example" "${SCRIPT_DIR}/.env"
    echo "  .env.example → .env 복사 완료"
else
    echo "  .env 파일 이미 존재"
fi

# ──────────────────────────────────────────────
echo "[4/7] UFW 방화벽 설정..."
if command -v ufw &> /dev/null; then
    ufw allow 22/tcp    comment "SSH 관리용"
    ufw allow 80/tcp    comment "Nextcloud HTTP"
    ufw allow 443/tcp   comment "Nextcloud HTTPS"
    ufw --force enable
    echo "  UFW 규칙 적용 완료"
else
    echo "  UFW 미설치 — 건너뜀"
fi

# ──────────────────────────────────────────────
echo "[5/7] Docker Compose 배포..."
cd "${SCRIPT_DIR}"
docker compose down --remove-orphans 2>/dev/null || true
docker compose up -d --build

echo "  컨테이너 기동 대기 중..."
sleep 10

# Nextcloud 초기 설치 완료 대기
echo "  Nextcloud 초기 설치 대기 중 (최대 120초)..."
for i in $(seq 1 24); do
    if docker exec nextcloud-app php occ status 2>/dev/null | grep -q "installed: true"; then
        echo "  Nextcloud 설치 완료"
        break
    fi
    sleep 5
done

# ──────────────────────────────────────────────
echo "[6/7] 문서 시드 실행..."
chmod +x "${SCRIPT_DIR}/seed/seed_documents.sh"
bash "${SCRIPT_DIR}/seed/seed_documents.sh"

# ──────────────────────────────────────────────
echo "[7/7] 배포 상태 확인..."
echo ""
docker compose ps
echo ""

echo "========================================="
echo " D3 자료교환체계 배포 완료"
echo "========================================="
echo ""
echo " 접속 URL:"
echo "   - http://211.57.64.12"
echo "   - http://share.mnd.valdoria.mil"
echo ""
echo " 관리자 계정:"
echo "   - admin / NCadmin@2024!"
echo ""
echo " 훈련용 취약점:"
echo "   - VULN-D3-01: GOV20190847 계정 크리덴셜 재사용"
echo "     (VPN 비밀번호 20190847890312 와 동일)"
echo "   - VULN-D3-02: WebDAV 대량 다운로드 제한 없음"
echo "     (PROPFIND Depth:infinity, wget -r 가능)"
echo ""
echo " WebDAV 테스트:"
echo "   curl -X PROPFIND -u GOV20190847:20190847890312 \\"
echo "     http://211.57.64.12/remote.php/dav/files/GOV20190847/"
echo ""
echo " 주의: 훈련 종료 후 모든 계정 비밀번호를 변경하거나 삭제하세요."
echo "========================================="
