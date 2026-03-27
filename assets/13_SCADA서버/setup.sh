#!/bin/bash
# ============================================================
# Asset #13 SCADA 서버 - 원클릭 배포 스크립트
# 대상: 192.168.201.10 (Rocky Linux 9, OT Zone)
# 구성: SCADA-LTS (Tomcat 9) + Node-RED + MySQL
# ============================================================
set -e

# --- Root 권한 확인 ---
if [ "$EUID" -ne 0 ]; then
    echo "[ERROR] 이 스크립트는 root 권한으로 실행해야 합니다."
    echo "  사용법: sudo bash setup.sh"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TOMCAT_VER="9.0.85"
SCADALTS_VER="2.7.7"

echo "============================================================"
echo " Asset #13 SCADA 서버 배포 시작"
echo " IP: 192.168.201.10 | OS: Rocky Linux 9"
echo "============================================================"
echo ""

# ============================================================
# [1/9] 호스트명 및 기본 설정
# ============================================================
echo "[1/9] 호스트명 및 기본 설정..."
hostnamectl set-hostname scada-server

# /etc/hosts 에 로컬 엔트리 추가
if ! grep -q "scada-server" /etc/hosts; then
    echo "192.168.201.10  scada-server scada-server.ot.local" >> /etc/hosts
fi

# 필수 패키지 설치
dnf install -y epel-release > /dev/null 2>&1
dnf install -y curl wget tar unzip firewalld > /dev/null 2>&1

echo "  호스트명: scada-server"

# ============================================================
# [2/9] 방화벽 설정 (firewalld — Rocky Linux 기본)
# ============================================================
echo "[2/9] 방화벽(firewalld) 설정..."
systemctl enable --now firewalld

firewall-cmd --permanent --add-port=8080/tcp    # SCADA-LTS 웹 인터페이스
# [취약점] VULN-13-02: Node-RED 포트를 외부에 개방 (인증 없이 접근 가능)
# [올바른 설정] Node-RED 포트를 개방하지 않거나, 특정 IP만 허용해야 한다.
#   예: firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="192.168.201.0/24" port port="1880" protocol="tcp" accept'
firewall-cmd --permanent --add-port=1880/tcp    # [취약 설정] Node-RED (무인증)
firewall-cmd --permanent --add-port=22/tcp      # SSH
firewall-cmd --reload

echo "  개방 포트: 8080(SCADA-LTS), 1880(Node-RED), 22(SSH)"

# ============================================================
# [3/9] Java 11 (OpenJDK) 설치
# ============================================================
echo "[3/9] Java 11 설치..."
dnf install -y java-11-openjdk java-11-openjdk-devel > /dev/null 2>&1
JAVA_VER=$(java -version 2>&1 | head -1)
echo "  ${JAVA_VER}"

# ============================================================
# [4/9] MySQL 8.0 설치 및 DB 구성
# ============================================================
echo "[4/9] MySQL 8.0 설치 및 SCADA-LTS DB 구성..."
dnf install -y mysql-server > /dev/null 2>&1
systemctl enable --now mysqld

# SCADA-LTS 데이터베이스 및 사용자 생성
mysql -u root <<'SQLEOF'
CREATE DATABASE IF NOT EXISTS scadalts
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

CREATE USER IF NOT EXISTS 'scadalts'@'localhost'
    IDENTIFIED BY 'ScadaLTS_2026!';

GRANT ALL PRIVILEGES ON scadalts.* TO 'scadalts'@'localhost';
FLUSH PRIVILEGES;
SQLEOF

echo "  DB: scadalts / User: scadalts@localhost"

# ============================================================
# [5/9] Apache Tomcat 9 설치
# ============================================================
echo "[5/9] Apache Tomcat 9.0 설치..."

# Tomcat 서비스 유저 생성
if ! id "tomcat" &>/dev/null; then
    useradd -r -M -U -d /opt/tomcat -s /bin/false tomcat
fi

cd /opt
if [ ! -f "apache-tomcat-${TOMCAT_VER}.tar.gz" ]; then
    curl -sLO "https://archive.apache.org/dist/tomcat/tomcat-9/v${TOMCAT_VER}/bin/apache-tomcat-${TOMCAT_VER}.tar.gz"
fi
tar xzf "apache-tomcat-${TOMCAT_VER}.tar.gz"
ln -sf "/opt/apache-tomcat-${TOMCAT_VER}" /opt/tomcat

# Tomcat 설정 파일 배포
[ -f "${SCRIPT_DIR}/conf/tomcat/server.xml" ] || { echo "[ERROR] 파일 없음: conf/tomcat/server.xml"; exit 1; }
[ -f "${SCRIPT_DIR}/conf/tomcat/tomcat-users.xml" ] || { echo "[ERROR] 파일 없음: conf/tomcat/tomcat-users.xml"; exit 1; }
[ -f "${SCRIPT_DIR}/conf/systemd/tomcat.service" ] || { echo "[ERROR] 파일 없음: conf/systemd/tomcat.service"; exit 1; }
cp "${SCRIPT_DIR}/conf/tomcat/server.xml" /opt/tomcat/conf/server.xml

# [취약점] VULN-13-01: 기본 인증 정보 admin/admin으로 Tomcat Manager 접근 가능
# [올바른 설정] 강력한 비밀번호를 사용하고 manager-gui 접근을 제한해야 한다.
cp "${SCRIPT_DIR}/conf/tomcat/tomcat-users.xml" /opt/tomcat/conf/tomcat-users.xml

# 소유권 설정
chown -R tomcat:tomcat /opt/tomcat /opt/apache-tomcat-${TOMCAT_VER}

# systemd 서비스 등록
cp "${SCRIPT_DIR}/conf/systemd/tomcat.service" /etc/systemd/system/tomcat.service

echo "  Tomcat ${TOMCAT_VER} -> /opt/tomcat"

# ============================================================
# [6/9] SCADA-LTS WAR 배포
# ============================================================
echo "[6/9] SCADA-LTS ${SCADALTS_VER} WAR 배포..."

cd /opt/tomcat/webapps
if [ ! -f "ScadaLTS.war" ]; then
    echo "  SCADA-LTS WAR 다운로드 중..."
    curl -sLO "https://github.com/SCADA-LTS/Scada-LTS/releases/download/v${SCADALTS_VER}/ScadaLTS.war" || {
        echo "  [WARN] WAR 다운로드 실패. 수동 배포 필요:"
        echo "    curl -LO https://github.com/SCADA-LTS/Scada-LTS/releases/download/v${SCADALTS_VER}/ScadaLTS.war"
        echo "    cp ScadaLTS.war /opt/tomcat/webapps/"
    }
fi

# SCADA-LTS DB 설정 파일
cat > /opt/scada-lts-env.properties <<'PROPEOF'
db.type=mysql
db.url=jdbc:mysql://localhost:3306/scadalts?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=Asia/Seoul
db.username=scadalts
db.password=ScadaLTS_2026!
db.driver=com.mysql.cj.jdbc.Driver
PROPEOF

chown tomcat:tomcat /opt/scada-lts-env.properties
chown -R tomcat:tomcat /opt/tomcat/webapps

# Tomcat 시작
systemctl daemon-reload
systemctl enable --now tomcat

echo "  SCADA-LTS WAR -> /opt/tomcat/webapps/ScadaLTS.war"
# [취약점] VULN-13-01: SCADA-LTS 기본 계정 admin/admin
# [올바른 설정] 초기 배포 후 반드시 관리자 비밀번호를 변경해야 한다.
echo "  [취약 설정] SCADA-LTS 기본 계정: admin / admin"

# ============================================================
# [7/9] Node.js 18 + Node-RED 설치
# ============================================================
echo "[7/9] Node.js 18 LTS + Node-RED 설치..."

# Node.js 18 LTS (NodeSource)
if ! command -v node &>/dev/null; then
    curl -fsSL https://rpm.nodesource.com/setup_18.x | bash - > /dev/null 2>&1
    dnf install -y nodejs > /dev/null 2>&1
fi

# Node-RED 및 대시보드 모듈 설치
npm install -g --unsafe-perm node-red > /dev/null 2>&1
npm install -g --unsafe-perm node-red-dashboard > /dev/null 2>&1

NODE_VER=$(node -v)
echo "  Node.js ${NODE_VER}, Node-RED $(node-red --version 2>/dev/null || echo '3.x')"

# ============================================================
# [8/9] Node-RED 설정 및 플로우 배포
# ============================================================
echo "[8/9] Node-RED 설정 및 플로우 배포..."

# Node-RED 서비스 유저 생성
if ! id "nodered" &>/dev/null; then
    useradd -r -m -U -d /home/nodered -s /bin/false nodered
fi

# Node-RED 사용자 디렉토리 구성
NODERED_DIR="/home/nodered/.node-red"
mkdir -p "${NODERED_DIR}"

# node-red-dashboard 로컬 설치
cd "${NODERED_DIR}"
npm init -y > /dev/null 2>&1
npm install --save node-red-dashboard > /dev/null 2>&1

# [취약점] VULN-13-02: Node-RED 인증 비활성화 설정 배포
# [올바른 설정] adminAuth를 활성화해야 한다.
[ -f "${SCRIPT_DIR}/conf/nodered/settings.js" ] || { echo "[ERROR] 파일 없음: conf/nodered/settings.js"; exit 1; }
[ -f "${SCRIPT_DIR}/conf/nodered/flows.json" ] || { echo "[ERROR] 파일 없음: conf/nodered/flows.json"; exit 1; }
[ -f "${SCRIPT_DIR}/conf/systemd/nodered.service" ] || { echo "[ERROR] 파일 없음: conf/systemd/nodered.service"; exit 1; }
cp "${SCRIPT_DIR}/conf/nodered/settings.js" "${NODERED_DIR}/settings.js"

# Node-RED 플로우 배포 (PLC 폴링 → SCADA-LTS 전달)
cp "${SCRIPT_DIR}/conf/nodered/flows.json" "${NODERED_DIR}/flows.json"

# 소유권 설정
chown -R nodered:nodered "${NODERED_DIR}"
chown -R nodered:nodered /home/nodered

# systemd 서비스 등록 및 시작
cp "${SCRIPT_DIR}/conf/systemd/nodered.service" /etc/systemd/system/nodered.service
systemctl daemon-reload
systemctl enable --now nodered

echo "  Node-RED 플로우 배포 완료 (PLC 5초 폴링)"
echo "  [취약 설정] Node-RED 인증 비활성화 (포트 1880 무인증 접근)"

# ============================================================
# [9/9] 서비스 상태 확인
# ============================================================
echo "[9/9] 서비스 상태 확인..."
echo ""

# Tomcat 시작 대기 (WAR 배포 시간 필요)
echo "  Tomcat WAR 배포 대기 중 (최대 30초)..."
for i in $(seq 1 30); do
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:8080 2>/dev/null | grep -q "200\|302"; then
        echo "  Tomcat: 정상 (${i}초)"
        break
    fi
    sleep 1
done

# Node-RED 시작 대기
for i in $(seq 1 15); do
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:1880 2>/dev/null | grep -q "200"; then
        echo "  Node-RED: 정상 (${i}초)"
        break
    fi
    sleep 1
done

echo ""
echo "============================================================"
echo " Asset #13 SCADA 서버 배포 완료"
echo "============================================================"
echo ""
echo " 접속 정보:"
echo "  - SCADA-LTS HMI:   http://192.168.201.10:8080/ScadaLTS/"
echo "  - SCADA-LTS API:   http://192.168.201.10:8080/api/"
echo "  - Node-RED Editor: http://192.168.201.10:1880/"
echo "  - Node-RED UI:     http://192.168.201.10:1880/ui/"
echo ""
echo " 의도적 취약점 (훈련용):"
echo "  - VULN-13-01: SCADA-LTS 기본 인증 admin/admin"
echo "  - VULN-13-02: Node-RED 인증 비활성화 (포트 1880)"
echo "  - VULN-13-03: SCADA REST API 태그 값 조작 가능"
echo "  - VULN-13-04: 알람 임계값 API를 통한 변경 가능"
echo ""
echo " 주의사항:"
echo "  - PLC 시뮬레이터(192.168.201.11:5000)가 구동 중이어야"
echo "    Node-RED 데이터 폴링이 정상 작동합니다."
echo "  - SCADA-LTS WAR 최초 배포 시 DB 초기화에 1~2분 소요됩니다."
echo "  - MySQL은 localhost(3306)에서만 접근 가능합니다."
echo "============================================================"
