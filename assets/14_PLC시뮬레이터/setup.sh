#!/bin/bash
# =============================================================================
# PLC 시뮬레이터 원클릭 배포 스크립트
# 대상: 192.168.201.11 (Ubuntu 22.04, OT 존)
# 서비스: Flask + Gunicorn (TCP 5000)
# =============================================================================

set -e

# ── root 권한 확인 ──
if [ "$EUID" -ne 0 ]; then
    echo "[오류] root 권한으로 실행하세요: sudo bash setup.sh"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "============================================================"
echo " PLC 시뮬레이터 배포 시작"
echo " 대상: 192.168.201.11:5000"
echo "============================================================"

# ── [1/6] 시스템 기본 설정 ──
echo ""
echo "[1/6] 시스템 기본 설정..."
hostnamectl set-hostname plc-simulator

cat > /etc/netplan/01-static.yaml << 'NETEOF'
network:
  version: 2
  renderer: networkd
  ethernets:
    ens192:
      addresses:
        - 192.168.201.11/24
      routes:
        - to: default
          via: 192.168.201.1
      nameservers:
        addresses:
          - 192.168.201.1
NETEOF
netplan apply || true

# ── [2/6] Python 3.11 설치 ──
echo ""
echo "[2/6] Python 3.11 설치..."
apt-get update -qq
apt-get install -y -qq python3.11 python3.11-venv python3-pip > /dev/null

# ── [3/6] 애플리케이션 배포 ──
echo ""
echo "[3/6] 애플리케이션 배포..."
mkdir -p /opt/plc-simulator
[ -f "$SCRIPT_DIR/src/plc_simulator.py" ] || { echo "[ERROR] 파일 없음: src/plc_simulator.py"; exit 1; }
[ -f "$SCRIPT_DIR/src/requirements.txt" ] || { echo "[ERROR] 파일 없음: src/requirements.txt"; exit 1; }
[ -f "$SCRIPT_DIR/.env.example" ] || { echo "[ERROR] 파일 없음: .env.example"; exit 1; }
cp "$SCRIPT_DIR/src/plc_simulator.py" /opt/plc-simulator/plc_simulator.py
cp "$SCRIPT_DIR/src/requirements.txt" /opt/plc-simulator/requirements.txt
cp "$SCRIPT_DIR/.env.example" /opt/plc-simulator/.env

# 가상환경 생성 및 패키지 설치
python3.11 -m venv /opt/plc-simulator/venv
/opt/plc-simulator/venv/bin/pip install --upgrade pip -q
/opt/plc-simulator/venv/bin/pip install -r /opt/plc-simulator/requirements.txt -q
/opt/plc-simulator/venv/bin/python -c "import flask; print('Dependencies OK')" || { echo "[ERROR] 의존성 설치 실패"; exit 1; }

# ── [4/6] 로그 디렉토리 생성 ──
echo ""
echo "[4/6] 로그 디렉토리 생성..."
mkdir -p /var/log/plc-simulator

# ── [5/6] systemd 서비스 등록 ──
echo ""
echo "[5/6] systemd 서비스 등록..."
[ -f "$SCRIPT_DIR/conf/systemd/plc-simulator.service" ] || { echo "[ERROR] 파일 없음: conf/systemd/plc-simulator.service"; exit 1; }
cp "$SCRIPT_DIR/conf/systemd/plc-simulator.service" /etc/systemd/system/plc-simulator.service
systemctl daemon-reload
systemctl enable --now plc-simulator

# ── [6/6] 방화벽 설정 ──
echo ""
echo "[6/6] 방화벽 설정..."
# [취약 설정] VULN-14-01: 포트 5000이 인증 없이 전체 OT 대역에 개방됨
# 올바른 설정: ufw allow from 192.168.201.10 to any port 5000 proto tcp (SCADA만 허용)
ufw allow 5000/tcp
ufw allow 22/tcp
ufw --force enable

echo ""
echo "============================================================"
echo " PLC 시뮬레이터 배포 완료"
echo "============================================================"
echo ""
echo "  PLC API:     http://192.168.201.11:5000"
echo "  상태 확인:   curl http://192.168.201.11:5000/api/health"
echo "  센서 데이터: curl http://192.168.201.11:5000/api/status"
echo "  설정 조회:   curl http://192.168.201.11:5000/api/config"
echo "  이력 조회:   curl http://192.168.201.11:5000/api/history?sensor=temperature&count=10"
echo ""
echo "  서비스 관리:"
echo "    systemctl status plc-simulator"
echo "    journalctl -u plc-simulator -f"
echo "    tail -f /var/log/plc-simulator/access.log"
echo ""
echo "  [주의] 모든 API 엔드포인트가 인증 없이 접근 가능합니다 (훈련용)"
echo "============================================================"
