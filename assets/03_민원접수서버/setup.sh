#!/bin/bash
# ============================================================
# 민원 접수 서버 — 원클릭 배포 스크립트
# 대상 OS: Ubuntu 22.04 LTS
# IP: 203.238.140.12
# 도메인: minwon.mois.valdoria.gov
#
# 사용법: sudo bash setup.sh
#
# 취약점 내장:
#   VULN-03-01: 파일 업로드 확장자 우회 (이중 확장자)
#   VULN-03-02: Content-Type 클라이언트 신뢰
#   VULN-03-03: IDOR (순차적 민원 ID로 타인 민원 조회)
#   VULN-03-04: 하드코딩 관리자 토큰
# ============================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
IP="203.238.140.12"
DOMAIN="minwon.mois.valdoria.gov"

echo "=========================================="
echo " 민원 접수 서버 배포 시작"
echo " IP: ${IP}"
echo " 도메인: ${DOMAIN}"
echo "=========================================="

if [ "$EUID" -ne 0 ]; then
    echo "[ERROR] root 권한으로 실행하세요: sudo bash setup.sh"
    exit 1
fi

# ===== [1] 시스템 패키지 =====
echo "[1/8] 시스템 패키지 설치..."
apt-get update -qq
apt-get install -y -qq python3 python3-pip python3-venv nginx curl wget ufw

# Node.js 20 (프론트엔드 빌드)
if ! command -v node &> /dev/null; then
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
    apt-get install -y -qq nodejs
fi

# ===== [2] 사용자 생성 =====
echo "[2/8] 사용자 생성..."
id minwon &>/dev/null || useradd -r -m -d /opt/minwon -s /bin/bash minwon
id minio-user &>/dev/null || useradd -r -M -d /opt/minio -s /usr/sbin/nologin minio-user

# ===== [3] MinIO 설치 =====
echo "[3/8] MinIO 설치..."
mkdir -p /opt/minio /var/lib/minio
if [ ! -f /opt/minio/minio ]; then
    wget -q https://dl.min.io/server/minio/release/linux-amd64/minio -O /opt/minio/minio
    chmod +x /opt/minio/minio
fi
[ -f "${SCRIPT_DIR}/conf/minio/minio.env" ] || { echo "[ERROR] 파일 없음: conf/minio/minio.env"; exit 1; }
cp ${SCRIPT_DIR}/conf/minio/minio.env /opt/minio/minio.env
chown -R minio-user:minio-user /opt/minio /var/lib/minio

[ -f "${SCRIPT_DIR}/conf/systemd/minio.service" ] || { echo "[ERROR] 파일 없음: conf/systemd/minio.service"; exit 1; }
cp ${SCRIPT_DIR}/conf/systemd/minio.service /etc/systemd/system/
systemctl daemon-reload
systemctl enable --now minio

# ===== [4] 백엔드 배포 =====
echo "[4/8] 백엔드 배포..."
mkdir -p /opt/minwon/{backend,data} /var/log/minwon
cp -r ${SCRIPT_DIR}/src/backend/* /opt/minwon/backend/
cp ${SCRIPT_DIR}/.env.example /opt/minwon/.env

python3 -m venv /opt/minwon/venv
/opt/minwon/venv/bin/pip install --quiet --upgrade pip
/opt/minwon/venv/bin/pip install --quiet -r /opt/minwon/backend/requirements.txt
/opt/minwon/venv/bin/python -c "import fastapi; import uvicorn; print('Dependencies OK')" || { echo "[ERROR] 의존성 설치 실패"; exit 1; }

chown -R minwon:minwon /opt/minwon /var/log/minwon

[ -f "${SCRIPT_DIR}/conf/systemd/minwon-api.service" ] || { echo "[ERROR] 파일 없음: conf/systemd/minwon-api.service"; exit 1; }
cp ${SCRIPT_DIR}/conf/systemd/minwon-api.service /etc/systemd/system/
systemctl daemon-reload
systemctl enable --now minwon-api

# ===== [5] 프론트엔드 빌드 =====
echo "[5/8] 프론트엔드 빌드..."
mkdir -p /var/www/minwon
cp -r ${SCRIPT_DIR}/src/frontend /tmp/minwon-frontend
cd /tmp/minwon-frontend
npm install --silent 2>/dev/null
npm run build 2>/dev/null
cp -r dist/* /var/www/minwon/
rm -rf /tmp/minwon-frontend

# ===== [6] Nginx 설정 =====
echo "[6/8] Nginx 설정..."
[ -f "${SCRIPT_DIR}/conf/nginx/minwon.conf" ] || { echo "[ERROR] 파일 없음: conf/nginx/minwon.conf"; exit 1; }
cp ${SCRIPT_DIR}/conf/nginx/minwon.conf /etc/nginx/sites-available/
ln -sf /etc/nginx/sites-available/minwon.conf /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
nginx -t && systemctl restart nginx
systemctl enable nginx

# ===== [7] 시드 데이터 삽입 =====
echo "[7/8] 시드 데이터 삽입..."
sleep 2
for i in $(seq 0 4); do
    TITLE=$(python3 -c "import json; d=json.load(open('${SCRIPT_DIR}/data/sample_complaints.json')); print(d[$i]['title'])")
    CATEGORY=$(python3 -c "import json; d=json.load(open('${SCRIPT_DIR}/data/sample_complaints.json')); print(d[$i]['category'])")
    CONTENT=$(python3 -c "import json; d=json.load(open('${SCRIPT_DIR}/data/sample_complaints.json')); print(d[$i]['content'])")
    NAME=$(python3 -c "import json; d=json.load(open('${SCRIPT_DIR}/data/sample_complaints.json')); print(d[$i]['submitter_name'])")
    PHONE=$(python3 -c "import json; d=json.load(open('${SCRIPT_DIR}/data/sample_complaints.json')); print(d[$i]['submitter_phone'])")
    EMAIL=$(python3 -c "import json; d=json.load(open('${SCRIPT_DIR}/data/sample_complaints.json')); print(d[$i]['submitter_email'])")

    curl -s -X POST "http://localhost:8000/api/complaint/submit" \
        -F "title=${TITLE}" \
        -F "category=${CATEGORY}" \
        -F "content=${CONTENT}" \
        -F "submitter_name=${NAME}" \
        -F "submitter_phone=${PHONE}" \
        -F "submitter_email=${EMAIL}" > /dev/null 2>&1 || true
done

# ===== [8] 방화벽 =====
echo "[8/8] 방화벽 설정..."
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow from 192.168.100.0/24 to any port 9000 proto tcp
ufw allow 22/tcp
ufw --force enable

echo ""
echo "=========================================="
echo " 민원 접수 서버 배포 완료!"
echo "=========================================="
echo ""
echo " 웹사이트: http://${IP}"
echo " API:      http://${IP}:8000/api/health"
echo " MinIO:    http://${IP}:9000 (minio_access / minio_secret123)"
echo ""
echo " 취약점 테스트:"
echo "   # 파일 업로드 확장자 우회"
echo "   curl -X POST http://${IP}/api/complaint/upload -F 'complaint_id=COMP-2026-00001' -F 'file=@shell.pdf.py'"
echo "   # IDOR (타인 민원 조회)"
echo "   curl http://${IP}/api/complaint/COMP-2026-00001"
echo "=========================================="
