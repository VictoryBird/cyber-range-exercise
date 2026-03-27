#!/bin/bash
# =============================================================================
# Historian 서버 (자산 #12) 원클릭 배포 스크립트
# IP: 192.168.200.10 | Industrial DMZ
# 구성: InfluxDB 2.7 + FastAPI REST API (uvicorn)
# =============================================================================
set -e

# ---------- root 권한 확인 ----------
if [ "$EUID" -ne 0 ]; then
    echo "[!] root 권한이 필요합니다. sudo로 실행하세요."
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
INSTALL_DIR="/opt/historian"
APP_DIR="${INSTALL_DIR}/app"
LOG_DIR="${INSTALL_DIR}/logs"

echo "============================================="
echo " Historian 서버 (자산 #12) 배포 시작"
echo " IP: 192.168.200.10"
echo "============================================="

# ---------- [1/9] 시스템 패키지 업데이트 ----------
echo ""
echo "[1/9] 시스템 패키지 업데이트..."
apt-get update -qq
apt-get install -y -qq python3 python3-pip python3-venv curl wget gnupg2 apt-transport-https > /dev/null

# ---------- [2/9] InfluxDB 2.7 설치 ----------
echo "[2/9] InfluxDB 2.7 설치..."
if ! command -v influxd &> /dev/null; then
    wget -q https://repos.influxdata.com/influxdata-archive.key
    echo '943666881a1b8d9b849b74caebf02d3465d6beb716510d86a39f6c8e8dac7515  influxdata-archive.key' | sha256sum -c - > /dev/null 2>&1 || true
    cat influxdata-archive.key | gpg --dearmor | tee /etc/apt/trusted.gpg.d/influxdata-archive.gpg > /dev/null
    echo 'deb [signed-by=/etc/apt/trusted.gpg.d/influxdata-archive.gpg] https://repos.influxdata.com/debian stable main' | tee /etc/apt/sources.list.d/influxdata.list > /dev/null
    apt-get update -qq
    apt-get install -y -qq influxdb2 > /dev/null
    rm -f influxdata-archive.key
    echo "  [+] InfluxDB 설치 완료"
else
    echo "  [=] InfluxDB 이미 설치됨"
fi

# ---------- [3/9] InfluxDB 시작 및 초기 설정 ----------
echo "[3/9] InfluxDB 시작 및 초기 설정..."
systemctl enable influxdb --quiet
systemctl start influxdb

# 시작 대기
for i in $(seq 1 30); do
    if influx ping &> /dev/null; then
        break
    fi
    sleep 1
done

# 초기 설정 (이미 설정되어 있으면 무시)
influx setup \
    --username admin \
    --password historian-admin-2024 \
    --org ot-org \
    --bucket ot_data \
    --retention 720h \
    --token historian-dev-token-2024 \
    --force 2>/dev/null || echo "  [=] InfluxDB 이미 초기화됨"

echo "  [+] InfluxDB 설정 완료 (org=ot-org, bucket=ot_data)"

# ---------- [4/9] 서비스 계정 생성 ----------
echo "[4/9] 서비스 계정 생성..."
if ! id historian &> /dev/null 2>&1; then
    useradd -r -m -s /bin/bash -d /home/historian historian
    echo "historian:hist-service-2024" | chpasswd
    echo "  [+] historian 계정 생성 완료"
else
    echo "  [=] historian 계정 이미 존재"
fi

# ---------- [5/9] 디렉토리 구조 생성 및 소스 복사 ----------
echo "[5/9] 디렉토리 구조 생성 및 소스 복사..."
mkdir -p "${APP_DIR}" "${LOG_DIR}" "${INSTALL_DIR}/scripts" "${INSTALL_DIR}/config"

# 소스 복사
cp "${SCRIPT_DIR}/src/backend/main.py" "${APP_DIR}/"
cp "${SCRIPT_DIR}/src/backend/config.py" "${APP_DIR}/"
cp "${SCRIPT_DIR}/src/backend/requirements.txt" "${APP_DIR}/"
cp -r "${SCRIPT_DIR}/src/backend/routers" "${APP_DIR}/"

# .env 생성
cat > "${APP_DIR}/.env" << 'ENVEOF'
HISTORIAN_API=http://192.168.200.10:8000
INFLUXDB_URL=http://127.0.0.1:8086
INFLUXDB_TOKEN=historian-dev-token-2024
INFLUXDB_ORG=ot-org
INFLUXDB_BUCKET=ot_data
SCADA_HOST=192.168.201.10
SCADA_PORT=502
ENVEOF

# 시드 스크립트 복사
cp "${SCRIPT_DIR}/scripts/seed_data.py" "${INSTALL_DIR}/scripts/"

chown -R historian:historian "${INSTALL_DIR}"
echo "  [+] 소스 복사 완료"

# ---------- [6/9] Python 가상환경 및 패키지 설치 ----------
echo "[6/9] Python 가상환경 및 패키지 설치..."
python3 -m venv "${INSTALL_DIR}/venv"
"${INSTALL_DIR}/venv/bin/pip" install --quiet --upgrade pip
"${INSTALL_DIR}/venv/bin/pip" install --quiet -r "${APP_DIR}/requirements.txt"
chown -R historian:historian "${INSTALL_DIR}/venv"
echo "  [+] Python 패키지 설치 완료"

# ---------- [7/9] systemd 서비스 등록 ----------
echo "[7/9] systemd 서비스 등록..."
cp "${SCRIPT_DIR}/conf/systemd/historian-api.service" /etc/systemd/system/
systemctl daemon-reload
systemctl enable historian-api --quiet
systemctl start historian-api
echo "  [+] historian-api 서비스 시작"

# 서비스 시작 대기
sleep 3
for i in $(seq 1 15); do
    if curl -s http://127.0.0.1:8000/api/health > /dev/null 2>&1; then
        break
    fi
    sleep 1
done

# ---------- [8/9] 시드 데이터 삽입 ----------
echo "[8/9] 시드 데이터 삽입 (24시간 분량)..."
"${INSTALL_DIR}/venv/bin/python" "${INSTALL_DIR}/scripts/seed_data.py"
echo "  [+] 시드 데이터 삽입 완료"

# ---------- [9/9] 방화벽 설정 ----------
echo "[9/9] 방화벽(ufw) 설정..."
ufw --force enable > /dev/null 2>&1 || true

# SSH 허용
ufw allow 22/tcp > /dev/null 2>&1

# [취약 설정] INT 서브넷 전체에서 REST API 접근 허용
# 올바른 설정: ufw allow from 192.168.100.12 to any port 8000 proto tcp
ufw allow from 192.168.100.0/24 to any port 8000 proto tcp > /dev/null 2>&1  # [취약 설정] 서브넷 전체 허용

# SCADA → InfluxDB 쓰기 허용
ufw allow from 192.168.201.10/32 to any port 8086 proto tcp > /dev/null 2>&1

# 로컬 API → InfluxDB 허용
ufw allow from 127.0.0.1 to any port 8086 proto tcp > /dev/null 2>&1

echo "  [+] 방화벽 설정 완료"

# ---------- 배포 완료 ----------
echo ""
echo "============================================="
echo " Historian 서버 배포 완료!"
echo "============================================="
echo ""
echo " REST API:   http://192.168.200.10:8000"
echo " InfluxDB:   http://192.168.200.10:8086"
echo ""
echo " 엔드포인트:"
echo "   GET  /api/health    — 헬스체크"
echo "   GET  /api/tags      — 센서 태그 목록"
echo "   GET  /api/query     — 시계열 데이터 조회"
echo "   POST /api/write     — 데이터 삽입"
echo "   DELETE /api/data    — 데이터 삭제"
echo "   GET  /api/config    — 시스템 설정 (★ 취약)"
echo ""
echo " ⚠ 주의사항:"
echo "   - 모든 API 엔드포인트에 인증이 없습니다 (훈련용 의도적 취약점)"
echo "   - /api/config 엔드포인트가 InfluxDB 토큰을 노출합니다"
echo "   - DELETE /api/data 에 인가 통제가 없습니다"
echo "============================================="
