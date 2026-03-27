#!/bin/bash
# ============================================================
# C14 데이터 수집·관리 서버 설치 스크립트
# 호스트: data.c4i.local (192.168.130.12)
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
echo "C14 데이터 수집·관리 서버 설치 시작"
echo "호스트: data.c4i.local (192.168.130.12)"
echo "=========================================="

# [1/9] 시스템 업데이트
echo "[1/9] 시스템 업데이트..."
apt-get update && apt-get upgrade -y

# [2/9] Python 및 PostgreSQL 설치
echo "[2/9] Python 및 PostgreSQL 설치..."
apt-get install -y python3 python3-pip python3-venv postgresql postgresql-contrib

# [3/9] PostgreSQL 설정
echo "[3/9] PostgreSQL 설정..."
systemctl enable postgresql
systemctl start postgresql

sudo -u postgres psql << 'DBSETUP'
CREATE USER events_user WITH PASSWORD 'Ev3nts!C4I#2024';
CREATE DATABASE events_db OWNER events_user;
DBSETUP

# [4/9] 디렉토리 구조 생성
echo "[4/9] 디렉토리 구조 생성..."
mkdir -p /opt/datacollector/{app,app/routers,logs,config}

# [5/9] Python 가상 환경
echo "[5/9] Python 가상 환경 설정..."
python3 -m venv /opt/datacollector/venv
source /opt/datacollector/venv/bin/activate
pip install -r "${SCRIPT_DIR}/requirements.txt"
/opt/datacollector/venv/bin/python -c "import fastapi; import uvicorn; print('Dependencies OK')" || { echo "[ERROR] 의존성 설치 실패"; exit 1; }

# [6/9] 애플리케이션 배포
echo "[6/9] 애플리케이션 배포..."
cp "${SCRIPT_DIR}/src/backend/main.py" /opt/datacollector/app/
cp "${SCRIPT_DIR}/src/backend/config.py" /opt/datacollector/app/
cp "${SCRIPT_DIR}/src/backend/database.py" /opt/datacollector/app/
cp "${SCRIPT_DIR}/src/backend/routers/__init__.py" /opt/datacollector/app/routers/
cp "${SCRIPT_DIR}/src/backend/routers/events.py" /opt/datacollector/app/routers/

# [7/9] 시드 데이터 적용
echo "[7/9] 시드 데이터 적용..."
[ -f "${SCRIPT_DIR}/sql/init.sql" ] || { echo "[ERROR] SQL 파일 없음: sql/init.sql"; exit 1; }
sudo -u postgres psql -d events_db -f "${SCRIPT_DIR}/sql/init.sql"

# [8/9] systemd 서비스 등록
echo "[8/9] systemd 서비스 등록..."
[ -f "${SCRIPT_DIR}/conf/systemd/datacollector.service" ] || { echo "[ERROR] 파일 없음: conf/systemd/datacollector.service"; exit 1; }
cp "${SCRIPT_DIR}/conf/systemd/datacollector.service" /etc/systemd/system/
systemctl daemon-reload
systemctl enable datacollector
systemctl start datacollector

# [9/9] 호스트명 및 방화벽 설정
echo "[9/9] 호스트명 및 방화벽 설정..."
hostnamectl set-hostname data-c4i

if command -v ufw &> /dev/null; then
    ufw allow 8000/tcp  # FastAPI (★ 공격 대상 API)
    ufw --force enable
fi

echo "=========================================="
echo "C14 데이터 수집·관리 서버 설치 완료"
echo "=========================================="
echo ""
echo "  API: http://data.c4i.local:8000"
echo "  문서: http://data.c4i.local:8000/docs"
echo "  헬스: http://data.c4i.local:8000/health"
echo ""
echo "  ★ 주의: /api/config가 API 키를 노출합니다 (VULN-C14-01)"
echo "  ★ 주의: DELETE 엔드포인트에 인증이 없습니다 (VULN-C14-02)"
echo "  ★ 주의: 레이트 리밋이 없습니다 (VULN-C14-03)"
echo "  ★ 주의: 입력 검증이 없습니다 (VULN-C14-04)"
echo ""
echo "  DB 정보:"
echo "    호스트: localhost:5432"
echo "    데이터베이스: events_db"
echo "    사용자: events_user / Ev3nts!C4I#2024"
echo "=========================================="
