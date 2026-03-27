#!/bin/bash
# ============================================================
# AI 어시스턴트 — 원클릭 배포 스크립트
# 자산 07 — 192.168.100.13 (ai.mois.local)
# ============================================================
set -e

# --- 색상 정의 ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

INSTALL_DIR="/opt/ai-assistant"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo -e "${BLUE}============================================================${NC}"
echo -e "${BLUE}  AI 어시스턴트 배포 스크립트 (자산 07)${NC}"
echo -e "${BLUE}  IP: 192.168.100.13 | 도메인: ai.mois.local${NC}"
echo -e "${BLUE}============================================================${NC}"
echo ""

# --- [0/8] root 권한 확인 ---
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}[오류] root 권한으로 실행해 주세요: sudo bash setup.sh${NC}"
    exit 1
fi

# --- [1/8] 시스템 패키지 업데이트 ---
echo -e "${GREEN}[1/8] 시스템 패키지 업데이트...${NC}"
apt-get update -qq
apt-get install -y -qq curl wget gnupg2 software-properties-common \
    python3 python3-pip python3-venv ca-certificates lsb-release > /dev/null 2>&1
echo -e "${GREEN}  ✓ 시스템 패키지 설치 완료${NC}"

# --- [2/8] Docker 설치 ---
echo -e "${GREEN}[2/8] Docker 설치...${NC}"
if command -v docker &> /dev/null; then
    echo -e "${YELLOW}  → Docker 이미 설치됨: $(docker --version)${NC}"
else
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] \
        https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list
    apt-get update -qq
    apt-get install -y -qq docker-ce docker-ce-cli containerd.io docker-compose-plugin > /dev/null 2>&1
    systemctl enable docker
    systemctl start docker
    echo -e "${GREEN}  ✓ Docker 설치 완료${NC}"
fi

# Docker Compose 확인
if ! docker compose version &> /dev/null; then
    echo -e "${RED}[오류] Docker Compose v2를 찾을 수 없습니다.${NC}"
    exit 1
fi

# --- [3/8] 디렉토리 구조 생성 ---
echo -e "${GREEN}[3/8] 디렉토리 구조 생성...${NC}"
mkdir -p "$INSTALL_DIR"/{data/chromadb,data/document_cache,logs,rag,seed}

# 파일 복사
cp "$SCRIPT_DIR/docker-compose.yml" "$INSTALL_DIR/"
cp "$SCRIPT_DIR/.env.example" "$INSTALL_DIR/.env"
cp -r "$SCRIPT_DIR/rag/"* "$INSTALL_DIR/rag/"
cp -r "$SCRIPT_DIR/seed/" "$INSTALL_DIR/"

echo -e "${GREEN}  ✓ 디렉토리 구조 및 파일 복사 완료${NC}"

# --- [4/8] Python 가상환경 및 의존성 설치 ---
echo -e "${GREEN}[4/8] Python 가상환경 설정...${NC}"
python3 -m venv "$INSTALL_DIR/rag/venv"
source "$INSTALL_DIR/rag/venv/bin/activate"
pip install --quiet --upgrade pip
pip install --quiet -r "$INSTALL_DIR/rag/requirements.txt"
deactivate
echo -e "${GREEN}  ✓ Python 의존성 설치 완료${NC}"

# --- [5/8] Docker Compose 실행 ---
echo -e "${GREEN}[5/8] Docker Compose 서비스 시작...${NC}"
cd "$INSTALL_DIR"
docker compose up -d

echo -e "${YELLOW}  → Ollama 서비스 준비 대기 중...${NC}"
for i in $(seq 1 60); do
    if curl -sf http://localhost:11434/api/tags > /dev/null 2>&1; then
        echo -e "${GREEN}  ✓ Ollama 서비스 준비 완료${NC}"
        break
    fi
    if [ "$i" -eq 60 ]; then
        echo -e "${RED}  [경고] Ollama 시작 시간 초과 — 수동 확인 필요${NC}"
    fi
    sleep 5
done

# --- [6/8] Ollama 모델 다운로드 ---
echo -e "${GREEN}[6/8] Ollama 모델 다운로드...${NC}"
echo -e "${YELLOW}  → llama3:8b 다운로드 중 (약 4.7GB, 시간 소요)...${NC}"
docker exec ai-ollama ollama pull llama3
echo -e "${GREEN}  ✓ llama3:8b 다운로드 완료${NC}"

echo -e "${YELLOW}  → nomic-embed-text 다운로드 중 (약 274MB)...${NC}"
docker exec ai-ollama ollama pull nomic-embed-text
echo -e "${GREEN}  ✓ nomic-embed-text 다운로드 완료${NC}"

# --- [7/8] RAG 인덱싱 실행 ---
echo -e "${GREEN}[7/8] RAG 문서 인덱싱 실행...${NC}"
cd "$INSTALL_DIR"
source "$INSTALL_DIR/rag/venv/bin/activate"
DOCUMENT_BASE_PATH="$INSTALL_DIR/seed/documents" \
CHROMA_PERSIST_DIR="$INSTALL_DIR/data/chromadb" \
OLLAMA_URL="http://localhost:11434" \
    python3 -m rag.indexer
deactivate
echo -e "${GREEN}  ✓ RAG 문서 인덱싱 완료${NC}"

# --- [8/8] UFW 방화벽 설정 ---
echo -e "${GREEN}[8/8] UFW 방화벽 설정...${NC}"
ufw --force reset > /dev/null 2>&1
ufw default deny incoming
ufw default allow outgoing

# SSH 접속 허용
ufw allow 22/tcp

# OpenWebUI — 내부망에서 접근 허용
ufw allow from 192.168.100.0/24 to any port 3000 proto tcp

# Ollama API — 외부 접근 차단 (Docker 내부 통신만 허용)
# [취약점] VULN-07-01 관련: Ollama API가 11434 포트로 노출되어 있으나
# 방화벽에서 외부 접근은 차단. 다만 내부망에서는 접근 가능.
# ufw allow from 192.168.100.0/24 to any port 11434 proto tcp

ufw --force enable
echo -e "${GREEN}  ✓ UFW 방화벽 설정 완료${NC}"

# --- 완료 ---
echo ""
echo -e "${BLUE}============================================================${NC}"
echo -e "${BLUE}  AI 어시스턴트 배포 완료${NC}"
echo -e "${BLUE}============================================================${NC}"
echo ""
echo -e "  OpenWebUI:  ${GREEN}http://192.168.100.13:3000${NC}"
echo -e "  Ollama API: ${GREEN}http://localhost:11434${NC}"
echo -e "  도메인:      ${GREEN}ai.mois.local${NC}"
echo ""
echo -e "${YELLOW}[주의사항]${NC}"
echo -e "  1. OpenWebUI 최초 접속 시 관리자 계정 생성 필요"
echo -e "  2. LDAP 인증 설정은 AD 서버(192.168.100.10)가 구동된 후 확인"
echo -e "  3. llama3 모델 첫 추론은 로딩 시간이 소요될 수 있음 (약 30초)"
echo -e "  4. RAG 색인 재실행: cd $INSTALL_DIR && source rag/venv/bin/activate && python3 -m rag.indexer"
echo ""
echo -e "${RED}[알려진 취약점 — 훈련용]${NC}"
echo -e "  VULN-07-01: 시스템 프롬프트 우회 가능 (프롬프트 인젝션)"
echo -e "  VULN-07-02: 군 협력 문서가 RAG 색인에 포함됨"
echo -e "  VULN-07-03: 질의 필터링/키워드 차단 없음"
echo -e "  VULN-07-04: AD 자격증명으로 직접 로그인 가능"
echo ""
