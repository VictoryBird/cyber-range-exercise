#!/bin/bash
# ============================================================
# C15 상황 요약 AI 서버 설치 스크립트
# 호스트: summary.c4i.local (192.168.130.13)
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
echo "C15 상황 요약 AI 서버 설치 시작"
echo "호스트: summary.c4i.local (192.168.130.13)"
echo "=========================================="

# [1/10] 시스템 업데이트
echo "[1/10] 시스템 업데이트..."
apt-get update && apt-get upgrade -y

# [2/10] Python 설치
echo "[2/10] Python 설치..."
apt-get install -y python3 python3-pip python3-venv curl

# [3/10] Ollama 설치
echo "[3/10] Ollama 설치..."
curl -fsSL https://ollama.com/install.sh | sh

# [4/10] Ollama 서비스 시작 및 모델 다운로드
echo "[4/10] Ollama 서비스 시작 및 LLaMA 3 8B 모델 다운로드..."
systemctl enable ollama
systemctl start ollama

# LLaMA 3 8B 모델 다운로드 (약 4.7GB)
echo "  LLaMA 3 8B 모델 다운로드 중... (시간이 소요될 수 있습니다)"
ollama pull llama3:8b

# [5/10] 디렉토리 구조 생성
echo "[5/10] 디렉토리 구조 생성..."
mkdir -p /opt/summary-ai/{app,scripts,data/briefings,logs,config}

# [6/10] Python 가상 환경
echo "[6/10] Python 가상 환경 설정..."
python3 -m venv /opt/summary-ai/venv
source /opt/summary-ai/venv/bin/activate
pip install fastapi uvicorn requests python-dotenv
/opt/summary-ai/venv/bin/python -c "import fastapi; import uvicorn; print('Dependencies OK')" || { echo "[ERROR] 의존성 설치 실패"; exit 1; }

# [7/10] 소스 배포
echo "[7/10] 소스 배포..."
[ -f "${SCRIPT_DIR}/src/summary_pipeline.py" ] || { echo "[ERROR] 파일 없음: src/summary_pipeline.py"; exit 1; }
[ -f "${SCRIPT_DIR}/src/prompt_template.txt" ] || { echo "[ERROR] 파일 없음: src/prompt_template.txt"; exit 1; }
[ -f "${SCRIPT_DIR}/src/summary_api.py" ] || { echo "[ERROR] 파일 없음: src/summary_api.py"; exit 1; }
cp "${SCRIPT_DIR}/src/summary_pipeline.py" /opt/summary-ai/scripts/
cp "${SCRIPT_DIR}/src/prompt_template.txt" /opt/summary-ai/scripts/
cp "${SCRIPT_DIR}/src/summary_api.py" /opt/summary-ai/app/

# [8/10] systemd 서비스 등록
echo "[8/10] systemd 서비스 등록..."

# 요약 API 서비스
cat > /etc/systemd/system/summary-api.service << 'SVCFILE'
[Unit]
Description=C4I Summary AI API Server
After=network-online.target ollama.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/summary-ai/app
ExecStart=/opt/summary-ai/venv/bin/uvicorn summary_api:app --host 0.0.0.0 --port 8001 --log-level info
Restart=always
RestartSec=5
Environment=PYTHONUNBUFFERED=1
Environment=C4I_API_URL=http://192.168.130.12:8000
Environment=C4I_API_KEY=dev-key-12345
Environment=SUMMARY_OLLAMA_URL=http://localhost:11434
Environment=PIPELINE_DIR=/opt/summary-ai/scripts

[Install]
WantedBy=multi-user.target
SVCFILE

# 브리핑 생성 서비스 + 타이머
[ -f "${SCRIPT_DIR}/conf/systemd/summary-timer.service" ] || { echo "[ERROR] 파일 없음: conf/systemd/summary-timer.service"; exit 1; }
[ -f "${SCRIPT_DIR}/conf/systemd/summary-timer.timer" ] || { echo "[ERROR] 파일 없음: conf/systemd/summary-timer.timer"; exit 1; }
cp "${SCRIPT_DIR}/conf/systemd/summary-timer.service" /etc/systemd/system/summary-gen.service
cp "${SCRIPT_DIR}/conf/systemd/summary-timer.timer" /etc/systemd/system/summary-gen.timer

# [9/10] 서비스 활성화
echo "[9/10] 서비스 활성화..."
systemctl daemon-reload
systemctl enable summary-api
systemctl start summary-api
systemctl enable summary-gen.timer
systemctl start summary-gen.timer

# [10/10] 호스트명 및 방화벽 설정
echo "[10/10] 호스트명 및 방화벽 설정..."
hostnamectl set-hostname summary-c4i

if command -v ufw &> /dev/null; then
    ufw allow 8001/tcp   # FastAPI (브리핑 API)
    ufw allow 11434/tcp  # Ollama (LLM API)
    ufw --force enable
fi

# 초기 브리핑 생성 시도
echo ""
echo "초기 브리핑 생성 시도..."
/opt/summary-ai/venv/bin/python /opt/summary-ai/scripts/summary_pipeline.py || echo "  (C14가 아직 준비되지 않았을 수 있습니다)"

echo "=========================================="
echo "C15 상황 요약 AI 서버 설치 완료"
echo "=========================================="
echo ""
echo "  브리핑 API: http://summary.c4i.local:8001"
echo "  Ollama:     http://summary.c4i.local:11434"
echo ""
echo "  엔드포인트:"
echo "    GET  /api/summary/latest   — 최신 브리핑"
echo "    GET  /api/summary/history  — 브리핑 이력"
echo "    POST /api/summary/generate — 수동 브리핑 생성"
echo ""
echo "  브리핑 생성 주기: 15분 (summary-gen.timer)"
echo "  데이터 소스: C14 (http://192.168.130.12:8000)"
echo ""
echo "  ※ 이 자산에는 직접적 취약점이 없습니다."
echo "    C14 데이터가 오염되면 허위 브리핑이 자동 생성됩니다."
echo "=========================================="
