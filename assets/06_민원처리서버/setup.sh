#!/usr/bin/env bash
# =============================================================================
# 민원 처리 서버 원클릭 배포 스크립트 (자산 06)
# IP: 192.168.100.12 | OS: Ubuntu 22.04
# =============================================================================
# 이 스크립트는 다음을 설치/구성한다:
#   - Python 3.11 + 가상환경
#   - Redis 7.x (무인증) [취약 설정]
#   - LibreOffice 6.4.7 (구버전, 매크로 보안 비활성화) [취약 설정]
#   - Celery 워커 + Supervisor
#   - UFW 방화벽
# =============================================================================

set -e

# --- 루트 권한 확인 ---
if [ "$EUID" -ne 0 ]; then
    echo "[오류] 이 스크립트는 root 권한으로 실행해야 합니다."
    echo "  사용법: sudo bash setup.sh"
    exit 1
fi

TOTAL_STEPS=11
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
INSTALL_DIR="/opt/complaint-worker"
SERVICE_USER="complaint-worker"
LIBREOFFICE_VERSION="6.4.7"
LIBREOFFICE_DEB_URL="https://downloadarchive.documentfoundation.org/libreoffice/old/${LIBREOFFICE_VERSION}/deb/x86_64/LibreOffice_${LIBREOFFICE_VERSION}_Linux_x86-64_deb.tar.gz"

echo "============================================="
echo " 민원 처리 서버 (자산 06) 배포 시작"
echo " IP: 192.168.100.12"
echo "============================================="
echo ""

# =========================================================================
# [1/11] 시스템 패키지 업데이트 및 기본 도구 설치
# =========================================================================
echo "[1/${TOTAL_STEPS}] 시스템 패키지 업데이트 및 기본 도구 설치..."
apt-get update -qq
apt-get install -y -qq \
    software-properties-common \
    curl wget gnupg2 \
    build-essential \
    libmagic1 \
    poppler-utils \
    supervisor \
    ufw \
    > /dev/null 2>&1
echo "  -> 기본 패키지 설치 완료"

# =========================================================================
# [2/11] Python 3.11 설치
# =========================================================================
echo "[2/${TOTAL_STEPS}] Python 3.11 설치..."
add-apt-repository -y ppa:deadsnakes/ppa > /dev/null 2>&1
apt-get update -qq
apt-get install -y -qq \
    python3.11 \
    python3.11-venv \
    python3.11-dev \
    python3-pip \
    > /dev/null 2>&1
echo "  -> Python $(python3.11 --version 2>&1) 설치 완료"

# =========================================================================
# [3/11] Redis 7.x 설치 및 구성
# =========================================================================
echo "[3/${TOTAL_STEPS}] Redis 설치 및 구성..."
apt-get install -y -qq redis-server > /dev/null 2>&1

# [취약 설정] VULN-06-03: Redis 무인증, 전체 바인딩, 보호 모드 비활성화
# 올바른 구현: requirepass 설정, bind 127.0.0.1, protected-mode yes
cp "${SCRIPT_DIR}/conf/redis/redis.conf" /etc/redis/redis.conf
chown redis:redis /etc/redis/redis.conf
mkdir -p /var/log/redis
chown redis:redis /var/log/redis

systemctl restart redis-server
systemctl enable redis-server
echo "  -> Redis 설치 완료 (무인증, bind 0.0.0.0)"
echo "  -> [취약 설정] VULN-06-03: 인증 없음, 보호 모드 비활성화"

# =========================================================================
# [4/11] LibreOffice 6.4.7 설치 (의도적 구버전)
# =========================================================================
echo "[4/${TOTAL_STEPS}] LibreOffice ${LIBREOFFICE_VERSION} 설치 (의도적 구버전)..."
echo "  -> [취약 설정] VULN-06-01: 최신 버전(24.x) 대신 6.4.7 설치"

# 기존 LibreOffice 제거
apt-get remove -y -qq libreoffice* > /dev/null 2>&1 || true

# LibreOffice 6.4.7 아카이브 다운로드 및 설치
TMPDIR_LO=$(mktemp -d)
cd "${TMPDIR_LO}"

echo "  -> 아카이브 다운로드 중..."
wget -q "${LIBREOFFICE_DEB_URL}" -O libreoffice.tar.gz || {
    echo "  -> [대체] 아카이브 다운로드 실패, 저장소 버전 설치..."
    apt-get install -y -qq \
        libreoffice-writer \
        libreoffice-calc \
        libreoffice-impress \
        > /dev/null 2>&1
}

if [ -f libreoffice.tar.gz ]; then
    tar xzf libreoffice.tar.gz
    cd LibreOffice_*/DEBS/
    dpkg -i *.deb > /dev/null 2>&1 || apt-get install -f -y -qq > /dev/null 2>&1
fi

cd /
rm -rf "${TMPDIR_LO}"

echo "  -> LibreOffice 설치 완료"

# =========================================================================
# [5/11] LibreOffice 매크로 보안 비활성화
# =========================================================================
echo "[5/${TOTAL_STEPS}] LibreOffice 매크로 보안 비활성화..."
echo "  -> [취약 설정] VULN-06-01: MacroSecurityLevel=0, /tmp를 신뢰 경로에 추가"

# 서비스 사용자용 LibreOffice 설정 디렉토리 생성
mkdir -p /home/${SERVICE_USER}/.config/libreoffice/4/user/
cp "${SCRIPT_DIR}/conf/libreoffice/disable_macro_security.xcu" \
   /home/${SERVICE_USER}/.config/libreoffice/4/user/registrymodifications.xcu

# root용도 동일 설정 (systemd에서 root로 supervisor 실행 시)
mkdir -p /root/.config/libreoffice/4/user/
cp "${SCRIPT_DIR}/conf/libreoffice/disable_macro_security.xcu" \
   /root/.config/libreoffice/4/user/registrymodifications.xcu

echo "  -> 매크로 보안 비활성화 완료"

# =========================================================================
# [6/11] 서비스 사용자 생성
# =========================================================================
echo "[6/${TOTAL_STEPS}] 서비스 사용자 생성 (${SERVICE_USER})..."

if ! id "${SERVICE_USER}" &>/dev/null; then
    # [취약점] VULN-06-05: /bin/bash 셸 허용 — RCE 후 대화형 셸 사용 가능
    # 올바른 구현: useradd --shell /usr/sbin/nologin
    useradd --system \
            --uid 1001 \
            --shell /bin/bash \
            --home-dir /home/${SERVICE_USER} \
            --create-home \
            ${SERVICE_USER}
    echo "  -> 사용자 ${SERVICE_USER} 생성 완료 (셸: /bin/bash)"
else
    echo "  -> 사용자 ${SERVICE_USER} 이미 존재"
fi

# [취약점] VULN-06-05: sudoers에 비밀번호 없는 명령 허용
# 올바른 구현: sudo 권한 미부여 또는 최소 권한만 부여
cat > /etc/sudoers.d/${SERVICE_USER} << 'SUDOERS'
# [취약 설정] VULN-06-05: apt, pip3, systemctl을 비밀번호 없이 실행 가능
# 올바른 구현: sudo 권한 미부여
complaint-worker ALL=(ALL) NOPASSWD: /usr/bin/apt, /usr/bin/pip3, /bin/systemctl restart supervisor
SUDOERS
chmod 440 /etc/sudoers.d/${SERVICE_USER}
echo "  -> [취약 설정] VULN-06-05: sudo 권한 설정 (apt, pip3, systemctl)"

# =========================================================================
# [7/11] 워커 서비스 디렉토리 구성
# =========================================================================
echo "[7/${TOTAL_STEPS}] 워커 서비스 디렉토리 구성..."

mkdir -p ${INSTALL_DIR}/logs
mkdir -p /tmp/processing

# 소스 코드 복사
cp "${SCRIPT_DIR}"/src/worker/*.py ${INSTALL_DIR}/
cp "${SCRIPT_DIR}"/src/worker/requirements.txt ${INSTALL_DIR}/

# 환경변수 파일 배포
# [취약점] VULN-06-04: 자격증명이 평문으로 저장, 파일 권한 644
# 올바른 구현: 600 권한, 시크릿 관리 시스템 사용
cp "${SCRIPT_DIR}/.env.example" "${INSTALL_DIR}/.env"
# [취약 설정] VULN-06-04: 과도한 읽기 권한 (644)
# 올바른 구현: chmod 600
chmod 644 "${INSTALL_DIR}/.env"

# 디렉토리 소유권 설정
chown -R ${SERVICE_USER}:${SERVICE_USER} ${INSTALL_DIR}
chown -R ${SERVICE_USER}:${SERVICE_USER} /tmp/processing
chown -R ${SERVICE_USER}:${SERVICE_USER} /home/${SERVICE_USER}

echo "  -> 서비스 디렉토리 구성 완료: ${INSTALL_DIR}"

# =========================================================================
# [8/11] Python 가상환경 및 패키지 설치
# =========================================================================
echo "[8/${TOTAL_STEPS}] Python 가상환경 및 패키지 설치..."

sudo -u ${SERVICE_USER} python3.11 -m venv ${INSTALL_DIR}/venv
sudo -u ${SERVICE_USER} ${INSTALL_DIR}/venv/bin/pip install --upgrade pip > /dev/null 2>&1

# [취약점] VULN-06-02: Pillow==8.4.0 고정 (CVE-2022-22815/16/17)
# 올바른 구현: Pillow>=10.0.0
sudo -u ${SERVICE_USER} ${INSTALL_DIR}/venv/bin/pip install \
    -r ${INSTALL_DIR}/requirements.txt > /dev/null 2>&1

echo "  -> Python 패키지 설치 완료"
echo "  -> [취약 설정] VULN-06-02: Pillow==8.4.0 (CVE-2022-22815/16/17)"

# =========================================================================
# [9/11] Supervisor 설정 배포
# =========================================================================
echo "[9/${TOTAL_STEPS}] Supervisor 설정 배포..."

cp "${SCRIPT_DIR}/conf/supervisor/celery-worker.conf" \
   /etc/supervisor/conf.d/complaint-worker.conf

# systemd 유닛 배포
cp "${SCRIPT_DIR}/conf/systemd/complaint-worker.service" \
   /etc/systemd/system/complaint-worker.service

# Redis systemd 오버라이드
mkdir -p /etc/systemd/system/redis-server.service.d/
cp "${SCRIPT_DIR}/conf/systemd/redis.service" \
   /etc/systemd/system/redis-server.service.d/override.conf

systemctl daemon-reload

# Supervisor 시작
supervisorctl reread > /dev/null 2>&1 || true
supervisorctl update > /dev/null 2>&1 || true

systemctl enable complaint-worker
systemctl start complaint-worker || true

echo "  -> Supervisor 및 systemd 설정 완료"

# =========================================================================
# [10/11] UFW 방화벽 설정
# =========================================================================
echo "[10/${TOTAL_STEPS}] UFW 방화벽 설정..."

ufw --force reset > /dev/null 2>&1
ufw default deny incoming
ufw default allow outgoing

# SSH
ufw allow 22/tcp

# [취약 설정] VULN-06-03/06-06: Redis를 INT 서브넷 전체에 개방
# 올바른 구현: ufw allow from 203.238.140.12 to any port 6379 proto tcp (특정 호스트만)
ufw allow from 192.168.100.0/24 to any port 6379 proto tcp

# 아웃바운드 — 과도한 허용
# [취약 설정] VULN-06-06: INT 전체 서브넷 무제한 아웃바운드
# 올바른 구현: 필요한 대상(MinIO, DB)만 허용
ufw allow out to 203.238.140.12 port 9000 proto tcp   # MinIO S3 API
ufw allow out to 192.168.100.20 port 5432 proto tcp    # PostgreSQL DB
ufw allow out to 192.168.100.0/24                      # [취약 설정] INT 전체 서브넷

ufw --force enable
echo "  -> 방화벽 설정 완료"
echo "  -> [취약 설정] VULN-06-03: Redis 6379/tcp가 INT 서브넷 전체에 개방"
echo "  -> [취약 설정] VULN-06-06: INT 전체 서브넷으로 아웃바운드 무제한"

# =========================================================================
# [11/11] 서비스 상태 확인
# =========================================================================
echo "[11/${TOTAL_STEPS}] 서비스 상태 확인..."

echo ""
echo "  Redis:    $(systemctl is-active redis-server)"
echo "  Celery:   $(supervisorctl status complaint-worker 2>/dev/null | awk '{print $2}' || echo 'checking...')"
echo ""

# =========================================================================
# 배포 완료
# =========================================================================
echo "============================================="
echo " 민원 처리 서버 (자산 06) 배포 완료"
echo "============================================="
echo ""
echo " 서버 IP:     192.168.100.12"
echo " Redis:       redis://192.168.100.12:6379"
echo " 워커 로그:   ${INSTALL_DIR}/logs/worker.log"
echo " 설정 파일:   ${INSTALL_DIR}/.env"
echo ""
echo " --- 의도적 취약점 ---"
echo " VULN-06-01: LibreOffice ${LIBREOFFICE_VERSION} (CVE-2021-25631 등) + 매크로 보안 비활성화"
echo " VULN-06-02: Pillow 8.4.0 (CVE-2022-22815/16/17)"
echo " VULN-06-03: Redis 무인증 (bind 0.0.0.0, protected-mode no)"
echo " VULN-06-04: DB 자격증명 하드코딩 (app_service / Sup3rS3cr3t!)"
echo " VULN-06-05: 파일 처리 샌드박싱 없음 (서비스 사용자 + sudo 권한)"
echo " VULN-06-06: INT 전체 서브넷 과도한 네트워크 접근"
echo ""
echo " --- DB 서버 (192.168.100.20) 사전 작업 필요 ---"
echo " PostgreSQL에 complaints DB 및 app_service 계정이 필요합니다."
echo " 자산 08 (DB 서버) 또는 별도 SQL 스크립트로 생성하세요."
echo ""
echo " --- 테스트 ---"
echo " redis-cli -h 192.168.100.12 PING"
echo " supervisorctl status complaint-worker"
echo " tail -f ${INSTALL_DIR}/logs/worker.log"
echo ""
