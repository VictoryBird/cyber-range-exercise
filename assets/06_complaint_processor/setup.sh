#!/usr/bin/env bash
# Asset 06 - Complaint Processing Server (192.168.92.206)
# 원클릭 배포 스크립트
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DEPLOY_DIR="/opt/complaint-worker"
SERVICE_USER="complaint-worker"

# ─── Root 권한 확인 ────────────────────────────────────────────────────────────
if [ "$EUID" -ne 0 ]; then
    echo "[ERROR] root 권한으로 실행하세요: sudo $0"
    exit 1
fi

echo "======================================================"
echo " Asset 06 - Complaint Processing Server 배포 시작"
echo " 서버: 192.168.92.206 (complaint-processor)"
echo "======================================================"

# ─── [1/15] 시스템 업데이트 + 호스트명 설정 ──────────────────────────────────
echo "[1/15] 시스템 업데이트 및 호스트명 설정..."
hostnamectl set-hostname complaint-processor
apt-get update -qq
apt-get upgrade -y -qq

# ─── [2/15] Python 3.11, Redis, Supervisor, libmagic 설치 ────────────────────
echo "[2/15] Python 3.11, Redis, Supervisor, libmagic, poppler-utils 설치..."
apt-get install -y \
    python3.11 \
    python3.11-venv \
    python3.11-dev \
    python3-pip \
    redis-server \
    supervisor \
    libmagic1 \
    libmagic-dev \
    poppler-utils \
    gcc \
    libc6-dev \
    libjpeg-dev \
    zlib1g-dev \
    libtiff-dev \
    libfreetype-dev \
    liblcms2-dev \
    libwebp-dev \
    curl \
    wget \
    gnupg \
    software-properties-common \
    ufw

# ─── [3/15] LibreOffice 6.4.7 설치 ──────────────────────────────────────────
# [취약 설정] VULN-08: LibreOffice 6.4.7은 CVE-2021-25631/CVE-2022-26305 등
#            다수의 매크로 실행 취약점을 포함한 버전이다.
# 올바른 설정: 최신 보안 패치 버전의 LibreOffice를 사용해야 한다.
echo "[3/15] LibreOffice 6.4.7 설치 (의도적 취약 버전)..."

LO_VERSION="6.4.7"
LO_INSTALLED=false

# Ubuntu 22.04에서 6.4.7 직접 다운로드 시도
LO_DEB_URL="https://downloadarchive.documentfoundation.org/libreoffice/old/${LO_VERSION}.2/deb/x86_64"
LO_ARCHIVE="LibreOffice_${LO_VERSION}.2_Linux_x86-64_deb.tar.gz"
LO_TMP=$(mktemp -d)

echo "  LibreOffice ${LO_VERSION} 다운로드 시도 중..."
if curl -fsSL --connect-timeout 30 --retry 3 \
        "${LO_DEB_URL}/${LO_ARCHIVE}" -o "${LO_TMP}/${LO_ARCHIVE}" 2>/dev/null; then
    echo "  다운로드 성공 — 설치 중..."
    tar -xzf "${LO_TMP}/${LO_ARCHIVE}" -C "${LO_TMP}"
    LO_DEB_DIR=$(find "${LO_TMP}" -type d -name "DEBS" | head -1)
    if [ -n "${LO_DEB_DIR}" ]; then
        dpkg -i "${LO_DEB_DIR}"/*.deb 2>/dev/null || apt-get install -f -y
        LO_INSTALLED=true
        echo "  LibreOffice ${LO_VERSION} 설치 완료."
    fi
fi
rm -rf "${LO_TMP}"

if [ "${LO_INSTALLED}" = false ]; then
    echo "  [주의] LibreOffice ${LO_VERSION} 아카이브 다운로드 실패."
    echo "  기본 리포지토리 버전을 설치합니다 (버전 차이 발생 가능)."
    echo "  훈련 환경에서는 수동으로 LibreOffice 6.4.7 .deb 패키지를 설치하세요."
    apt-get install -y libreoffice --no-install-recommends
fi

# LibreOffice 경로 확인
if command -v libreoffice >/dev/null 2>&1; then
    LO_ACTUAL_VER=$(libreoffice --version 2>/dev/null | head -1 || echo "version unknown")
    echo "  설치된 LibreOffice: ${LO_ACTUAL_VER}"
elif command -v soffice >/dev/null 2>&1; then
    LO_ACTUAL_VER=$(soffice --version 2>/dev/null | head -1 || echo "version unknown")
    echo "  설치된 LibreOffice (soffice): ${LO_ACTUAL_VER}"
else
    echo "  [경고] LibreOffice 실행 파일을 찾을 수 없습니다."
fi

# ─── [4/15] 서비스 사용자 생성 ───────────────────────────────────────────────
echo "[4/15] 서비스 사용자 생성..."
# [취약 설정] VULN-09: complaint-worker 계정에 /bin/bash 쉘 부여
# 공격자가 워커 프로세스를 통해 원격 코드 실행 시 인터랙티브 쉘 획득 가능
# 올바른 설정: useradd --shell /usr/sbin/nologin complaint-worker
if id "${SERVICE_USER}" &>/dev/null; then
    echo "  사용자 ${SERVICE_USER} 이미 존재 — 건너뜀"
else
    useradd --system \
        --shell /bin/bash \
        --home-dir "/home/${SERVICE_USER}" \
        --create-home \
        "${SERVICE_USER}"
    echo "  사용자 ${SERVICE_USER} 생성 완료."
fi

# [취약 설정] VULN-10: complaint-worker에 과도한 sudo 권한 부여
# apt, pip3, systemctl restart supervisor 명령을 비밀번호 없이 실행 가능
# 공격자가 apt/pip3를 통해 악의적 패키지 설치 가능
# 올바른 설정: sudo 권한을 부여하지 않거나, 매우 제한적인 명령만 허용
SUDOERS_FILE="/etc/sudoers.d/complaint-worker"
cat > "${SUDOERS_FILE}" << 'SUDOERS'
# [취약 설정] complaint-worker has excessive sudo privileges
# 올바른 설정: Remove this file entirely or restrict to specific safe commands
complaint-worker ALL=(ALL) NOPASSWD: /usr/bin/apt, /usr/bin/pip3, /bin/systemctl restart supervisor
SUDOERS
chmod 440 "${SUDOERS_FILE}"
echo "  sudoers 설정 완료 (취약 설정 — 훈련용)."

# ─── [5/15] 워커 소스 복사 ───────────────────────────────────────────────────
echo "[5/15] 워커 소스 복사..."
[ -d "${SCRIPT_DIR}/worker" ] || { echo "[ERROR] ${SCRIPT_DIR}/worker 디렉토리가 없습니다."; exit 1; }

mkdir -p "${DEPLOY_DIR}"
cp -r "${SCRIPT_DIR}/worker/"* "${DEPLOY_DIR}/"
echo "  소스 복사 완료: ${DEPLOY_DIR}"

# ─── [6/15] .env 배포 ────────────────────────────────────────────────────────
echo "[6/15] .env 파일 배포..."
[ -f "${SCRIPT_DIR}/.env.example" ] || { echo "[ERROR] ${SCRIPT_DIR}/.env.example 파일이 없습니다."; exit 1; }

cp "${SCRIPT_DIR}/.env.example" "${DEPLOY_DIR}/.env"
# [취약 설정] VULN-11: .env 파일 권한이 644 — 모든 사용자가 읽기 가능
# DB 비밀번호, MinIO 시크릿 키 등 민감 정보 노출
# 올바른 설정: chmod 600 "${DEPLOY_DIR}/.env"
chmod 644 "${DEPLOY_DIR}/.env"
echo "  .env 배포 완료 (권한: 644 — 취약 설정, 훈련용)."

# ─── [7/15] Python 가상환경 + 의존성 설치 ────────────────────────────────────
echo "[7/15] Python 가상환경 생성 및 패키지 설치..."
[ -f "${DEPLOY_DIR}/requirements.txt" ] || { echo "[ERROR] requirements.txt 가 없습니다."; exit 1; }

python3.11 -m venv "${DEPLOY_DIR}/venv"
"${DEPLOY_DIR}/venv/bin/pip" install --upgrade pip -q
"${DEPLOY_DIR}/venv/bin/pip" install -r "${DEPLOY_DIR}/requirements.txt" -q
echo "  Python 의존성 설치 완료."

# ─── [8/15] Redis 설정 배포 ──────────────────────────────────────────────────
echo "[8/15] Redis 설정 배포..."
[ -f "${SCRIPT_DIR}/conf/redis/redis.conf" ] || { echo "[ERROR] ${SCRIPT_DIR}/conf/redis/redis.conf 파일이 없습니다."; exit 1; }

# Redis 로그 디렉토리
mkdir -p /var/log/redis
chown redis:redis /var/log/redis

cp "${SCRIPT_DIR}/conf/redis/redis.conf" /etc/redis/redis.conf
chown redis:redis /etc/redis/redis.conf
chmod 640 /etc/redis/redis.conf

systemctl enable redis-server
systemctl restart redis-server
echo "  Redis 설정 완료 및 재시작."

# ─── [9/15] Supervisor 설정 배포 ─────────────────────────────────────────────
echo "[9/15] Supervisor 설정 배포..."
[ -f "${SCRIPT_DIR}/conf/supervisor/complaint-worker.conf" ] || \
    { echo "[ERROR] ${SCRIPT_DIR}/conf/supervisor/complaint-worker.conf 파일이 없습니다."; exit 1; }

cp "${SCRIPT_DIR}/conf/supervisor/complaint-worker.conf" \
    /etc/supervisor/conf.d/complaint-worker.conf

echo "  Supervisor 설정 복사 완료."

# ─── [10/15] 로그 디렉토리 + 임시 처리 디렉토리 생성 ─────────────────────────
echo "[10/15] 로그 디렉토리 및 임시 처리 디렉토리 생성..."
mkdir -p "${DEPLOY_DIR}/logs"
mkdir -p /tmp/processing
chmod 1777 /tmp/processing

# logrotate 설정
[ -f "${SCRIPT_DIR}/conf/logrotate/complaint-worker" ] || \
    { echo "[ERROR] ${SCRIPT_DIR}/conf/logrotate/complaint-worker 파일이 없습니다."; exit 1; }
cp "${SCRIPT_DIR}/conf/logrotate/complaint-worker" /etc/logrotate.d/complaint-worker
echo "  로그 디렉토리 및 logrotate 설정 완료."

# ─── [11/15] UFW 방화벽 설정 ─────────────────────────────────────────────────
echo "[11/15] UFW 방화벽 설정..."
ufw --force reset
ufw default deny incoming
ufw default allow outgoing

# SSH 허용
ufw allow 22/tcp comment "SSH"

# [취약 설정] Redis를 서브넷 전체에 개방 — 인증 없는 Redis와 결합하면 심각한 취약점
# 올바른 설정: ufw allow from 192.168.92.203 to any port 6379 (인테이크 서버만 허용)
ufw allow from 192.168.92.0/24 to any port 6379 proto tcp \
    comment "[취약 설정] Redis open to entire INT subnet (no auth)"

# 아웃바운드 MinIO (인테이크 서버)
ufw allow out to 192.168.92.203 port 9000 proto tcp \
    comment "Outbound MinIO - complaint intake server"

# 아웃바운드 PostgreSQL (DB 서버)
ufw allow out to 192.168.92.208 port 5432 proto tcp \
    comment "Outbound PostgreSQL - DB server"

# [취약 설정] INT 서브넷 전체 아웃바운드 허용
# 올바른 설정: 필요한 IP/포트만 명시적으로 허용
ufw allow out to 192.168.92.0/24 \
    comment "[취약 설정] Outbound to entire INT subnet allowed"

ufw --force enable
echo "  UFW 방화벽 설정 완료."

# ─── [12/15] LibreOffice 매크로 보안 설정 ────────────────────────────────────
echo "[12/15] LibreOffice 매크로 보안 설정 (의도적 취약 설정)..."
# [취약 설정] VULN-08 (연계): 매크로 보안 수준을 Medium(1)으로 설정
# 서명되지 않은 매크로 실행 가능 — 악의적 .odt/.doc 파일이 매크로를 통해 코드 실행 가능
# 올바른 설정: MacroSecurityLevel=3 (Very High), 신뢰 경로 없음

LO_USER_DIR="/home/${SERVICE_USER}/.config/libreoffice/4/user"
mkdir -p "${LO_USER_DIR}"

cat > "${LO_USER_DIR}/registrymodifications.xcu" << 'LOCONF'
<?xml version="1.0" encoding="UTF-8"?>
<oor:items xmlns:oor="http://openoffice.org/2001/registry" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <!-- [취약 설정] Macro security set to Medium (1) - unsigned macros can execute -->
  <!-- 올바른 설정: MacroSecurityLevel should be 3 (Very High) -->
  <item oor:path="/org.openoffice.Office.Common/Security/Scripting"><prop oor:name="MacroSecurityLevel" oor:op="fuse"><value>1</value></prop></item>
  <!-- [취약 설정] /tmp added as trusted macro execution path -->
  <!-- 올바른 설정: No paths should be trusted for macro execution -->
  <item oor:path="/org.openoffice.Office.Common/Security/Scripting"><prop oor:name="SecureURL" oor:op="fuse"><value>/tmp</value></prop></item>
</oor:items>
LOCONF

chown -R "${SERVICE_USER}:${SERVICE_USER}" "/home/${SERVICE_USER}/.config"
echo "  LibreOffice 매크로 보안 설정 완료 (Medium, /tmp 신뢰 경로 추가 — 취약 설정)."

# ─── [13/15] 파일 소유권 설정 ────────────────────────────────────────────────
echo "[13/15] 파일 소유권 설정..."
chown -R "${SERVICE_USER}:${SERVICE_USER}" "${DEPLOY_DIR}"
# .env는 이미 644로 설정됨 (취약 설정)
echo "  소유권 설정 완료."

# ─── [14/15] 서비스 시작 ─────────────────────────────────────────────────────
echo "[14/15] 서비스 시작..."
# Redis 상태 확인
if systemctl is-active --quiet redis-server; then
    echo "  Redis 동작 중."
else
    systemctl start redis-server
    echo "  Redis 시작."
fi

# Supervisor 활성화 및 재로드
systemctl enable supervisor
systemctl restart supervisor
sleep 2

# Celery 워커 상태 확인
if supervisorctl status complaint-worker 2>/dev/null | grep -q "RUNNING"; then
    echo "  Celery 워커(complaint-worker) 동작 중."
else
    supervisorctl reread
    supervisorctl update
    supervisorctl start complaint-worker 2>/dev/null || true
    sleep 2
    supervisorctl status complaint-worker || true
fi

# ─── [15/15] 배포 완료 ───────────────────────────────────────────────────────
echo "[15/15] 배포 완료."

echo ""
echo "======================================================"
echo " Asset 06 - Complaint Processing Server 배포 완료"
echo "======================================================"
echo ""
echo " 서버 정보:"
echo "   호스트명: complaint-processor"
echo "   IP:       192.168.92.206"
echo "   배포 경로: ${DEPLOY_DIR}"
echo ""
echo " 서비스 상태 확인:"
echo "   sudo supervisorctl status complaint-worker"
echo "   sudo systemctl status redis-server"
echo ""
echo " Redis 연결 테스트:"
echo "   redis-cli -h 192.168.92.206 ping"
echo ""
echo " [!] 의도적 취약점 목록 (훈련용):"
echo "   VULN-06: PostgreSQL app_service 계정 SUPERUSER 권한"
echo "            (${DEPLOY_DIR}/.env — DB_USER=app_service)"
echo "   VULN-07: Redis 인증 없음 + protected-mode 비활성화"
echo "            (/etc/redis/redis.conf)"
echo "   VULN-08: LibreOffice 6.4.7 취약 버전 + 매크로 보안 Medium"
echo "            (~/.config/libreoffice/4/user/registrymodifications.xcu)"
echo "   VULN-09: complaint-worker 계정 /bin/bash 쉘 허용"
echo "   VULN-10: complaint-worker sudo apt/pip3/systemctl 권한"
echo "            (/etc/sudoers.d/complaint-worker)"
echo "   VULN-11: .env 파일 권한 644 (모든 사용자 읽기 가능)"
echo "            (${DEPLOY_DIR}/.env)"
echo "======================================================"
