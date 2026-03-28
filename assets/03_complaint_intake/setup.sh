#!/usr/bin/env bash
# =============================================================================
# Asset 03 - MinWon Complaint Intake Server Setup Script
# Domain : minwon.mois.valdoria.gov
# IP     : 192.168.92.203
# Deploy : /opt/minwon
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# ---------------------------------------------------------------------------
# Root check
# ---------------------------------------------------------------------------
if [[ "$EUID" -ne 0 ]]; then
    echo "[ERROR] This script must be run as root (sudo)."
    exit 1
fi

# ---------------------------------------------------------------------------
# Source file existence checks (fail fast before any changes are made)
# ---------------------------------------------------------------------------
[ -d "${SCRIPT_DIR}/src/backend" ]                          || { echo "[ERROR] src/backend directory not found."; exit 1; }
[ -d "${SCRIPT_DIR}/src/frontend" ]                         || { echo "[ERROR] src/frontend directory not found."; exit 1; }
[ -f "${SCRIPT_DIR}/conf/nginx/minwon.conf" ]               || { echo "[ERROR] conf/nginx/minwon.conf not found."; exit 1; }
[ -f "${SCRIPT_DIR}/conf/systemd/minwon-api.service" ]      || { echo "[ERROR] conf/systemd/minwon-api.service not found."; exit 1; }
[ -f "${SCRIPT_DIR}/conf/systemd/minio.service" ]           || { echo "[ERROR] conf/systemd/minio.service not found."; exit 1; }
[ -f "${SCRIPT_DIR}/conf/minio/minio.env" ]                 || { echo "[ERROR] conf/minio/minio.env not found."; exit 1; }
[ -f "${SCRIPT_DIR}/.env.example" ]                         || { echo "[ERROR] .env.example not found."; exit 1; }

TOTAL_STEPS=15

# =============================================================================
# [1/15] System update + set hostname
# =============================================================================
echo "[1/${TOTAL_STEPS}] Updating system packages and setting hostname..."
apt-get update -y
apt-get upgrade -y
hostnamectl set-hostname complaint-intake
if ! grep -q "192.168.92.203" /etc/hosts; then
    echo "192.168.92.203  complaint-intake minwon.mois.valdoria.gov" >> /etc/hosts
fi

# =============================================================================
# [2/15] Install Python 3.11, Node.js 20, Nginx
# =============================================================================
echo "[2/${TOTAL_STEPS}] Installing Python 3.11, Node.js 20, Nginx, and dependencies..."
apt-get install -y software-properties-common curl wget gnupg2 ufw openssl

# Python 3.11
add-apt-repository -y ppa:deadsnakes/ppa
apt-get update -y
apt-get install -y python3.11 python3.11-venv python3.11-dev python3-pip build-essential

# Node.js 20 via NodeSource
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt-get install -y nodejs

# Nginx
apt-get install -y nginx

echo "    Python: $(python3.11 --version)"
echo "    Node  : $(node --version)"
echo "    npm   : $(npm --version)"
echo "    Nginx : $(nginx -v 2>&1)"

# =============================================================================
# [3/15] Create service users
# =============================================================================
echo "[3/${TOTAL_STEPS}] Creating service users (minwon, minio-user)..."

# minwon - application user with login shell
if ! id minwon &>/dev/null; then
    useradd -r -m -d /opt/minwon -s /bin/bash -c "MinWon App User" minwon
    echo "    Created user: minwon"
else
    echo "    User minwon already exists, skipping."
fi

# minio-user - storage daemon user, no login shell
if ! id minio-user &>/dev/null; then
    useradd -r -s /usr/sbin/nologin -c "MinIO Daemon User" minio-user
    echo "    Created user: minio-user"
else
    echo "    User minio-user already exists, skipping."
fi

# =============================================================================
# [4/15] Install MinIO binary
# =============================================================================
echo "[4/${TOTAL_STEPS}] Downloading and installing MinIO server binary..."
mkdir -p /opt/minio
wget -q https://dl.min.io/server/minio/release/linux-amd64/minio -O /opt/minio/minio
chmod +x /opt/minio/minio
echo "    MinIO version: $(/opt/minio/minio --version)"

# MinIO data directory
mkdir -p /var/lib/minio
chown -R minio-user:minio-user /var/lib/minio /opt/minio

# =============================================================================
# [5/15] Copy backend source to /opt/minwon/backend
# =============================================================================
echo "[5/${TOTAL_STEPS}] Deploying backend source to /opt/minwon/backend..."
mkdir -p /opt/minwon/backend
rsync -a --delete "${SCRIPT_DIR}/src/backend/" /opt/minwon/backend/

# =============================================================================
# [6/15] Deploy .env from .env.example
# =============================================================================
echo "[6/${TOTAL_STEPS}] Deploying environment configuration..."
if [ ! -f /opt/minwon/.env ]; then
    cp "${SCRIPT_DIR}/.env.example" /opt/minwon/.env
    echo "    .env created from .env.example — review and update credentials before production use."
else
    echo "    /opt/minwon/.env already exists, skipping to preserve custom values."
fi
chmod 640 /opt/minwon/.env
chown minwon:minwon /opt/minwon/.env

# =============================================================================
# [7/15] Python venv + pip install
# =============================================================================
echo "[7/${TOTAL_STEPS}] Creating Python virtual environment and installing dependencies..."
python3.11 -m venv /opt/minwon/backend/venv
/opt/minwon/backend/venv/bin/pip install --upgrade pip wheel

if [ -f /opt/minwon/backend/requirements.txt ]; then
    /opt/minwon/backend/venv/bin/pip install -r /opt/minwon/backend/requirements.txt
else
    echo "    [WARN] requirements.txt not found — skipping pip install."
fi

chown -R minwon:minwon /opt/minwon/backend

# =============================================================================
# [8/15] Frontend: npm install + build + deploy to /var/www/minwon
# =============================================================================
echo "[8/${TOTAL_STEPS}] Building frontend and deploying to /var/www/minwon..."
mkdir -p /var/www/minwon

# Build as non-root to avoid npm permission issues
FRONTEND_TMP=$(mktemp -d)
cp -r "${SCRIPT_DIR}/src/frontend/." "${FRONTEND_TMP}/"
chown -R minwon:minwon "${FRONTEND_TMP}"

if [ -f "${FRONTEND_TMP}/package.json" ]; then
    sudo -u minwon bash -c "cd '${FRONTEND_TMP}' && npm install && npm run build"

    # Determine build output directory (Vite -> dist, CRA -> build)
    if [ -d "${FRONTEND_TMP}/dist" ]; then
        rsync -a --delete "${FRONTEND_TMP}/dist/" /var/www/minwon/
    elif [ -d "${FRONTEND_TMP}/build" ]; then
        rsync -a --delete "${FRONTEND_TMP}/build/" /var/www/minwon/
    else
        echo "    [WARN] Could not find dist/ or build/ directory — copying source as-is."
        rsync -a --delete "${FRONTEND_TMP}/" /var/www/minwon/
    fi
else
    echo "    [WARN] package.json not found — copying frontend source as-is."
    rsync -a --delete "${SCRIPT_DIR}/src/frontend/" /var/www/minwon/
fi

rm -rf "${FRONTEND_TMP}"
chown -R www-data:www-data /var/www/minwon

# =============================================================================
# [9/15] Generate self-signed TLS certificate
# =============================================================================
echo "[9/${TOTAL_STEPS}] Generating self-signed TLS certificate..."
mkdir -p /etc/nginx/ssl
openssl req -x509 -nodes -days 3650 -newkey rsa:2048 \
    -keyout /etc/nginx/ssl/minwon.key \
    -out    /etc/nginx/ssl/minwon.crt \
    -subj   "/C=KR/ST=Seoul/L=Jongno/O=MOIS Valdoria/CN=minwon.mois.valdoria.gov" \
    -addext "subjectAltName=DNS:minwon.mois.valdoria.gov,IP:192.168.92.203"
chmod 600 /etc/nginx/ssl/minwon.key
chmod 644 /etc/nginx/ssl/minwon.crt
echo "    TLS certificate generated (valid 10 years, self-signed)."

# =============================================================================
# [10/15] Deploy Nginx config
# =============================================================================
echo "[10/${TOTAL_STEPS}] Deploying Nginx site configuration..."
cp "${SCRIPT_DIR}/conf/nginx/minwon.conf" /etc/nginx/sites-available/minwon.conf

# Enable site, disable default
ln -sf /etc/nginx/sites-available/minwon.conf /etc/nginx/sites-enabled/minwon.conf
rm -f /etc/nginx/sites-enabled/default

nginx -t
systemctl enable nginx
systemctl restart nginx
echo "    Nginx configured and restarted."

# =============================================================================
# [11/15] Deploy systemd services, start MinIO, configure bucket, start API
# =============================================================================
echo "[11/${TOTAL_STEPS}] Deploying systemd services..."

# Deploy MinIO environment file
cp "${SCRIPT_DIR}/conf/minio/minio.env" /etc/default/minio
chmod 640 /etc/default/minio

# Deploy service unit files
cp "${SCRIPT_DIR}/conf/systemd/minio.service"     /etc/systemd/system/minio.service
cp "${SCRIPT_DIR}/conf/systemd/minwon-api.service" /etc/systemd/system/minwon-api.service
systemctl daemon-reload

# Start MinIO first
systemctl enable minio
systemctl restart minio
echo "    MinIO service started. Waiting for it to become ready..."
sleep 8

# Install MinIO client (mc) and configure bucket
echo "    Installing MinIO client (mc)..."
wget -q https://dl.min.io/client/mc/release/linux-amd64/mc -O /usr/local/bin/mc
chmod +x /usr/local/bin/mc

echo "    Configuring mc alias and creating complaints bucket..."
mc alias set local http://127.0.0.1:9000 minio_access minio_secret123
mc mb local/complaints --ignore-existing
echo "    MinIO bucket 'complaints' is ready."

# Start the API
systemctl enable minwon-api
systemctl restart minwon-api
echo "    MinWon API service started."

# =============================================================================
# [12/15] Create log directory
# =============================================================================
echo "[12/${TOTAL_STEPS}] Creating application log directory..."
mkdir -p /var/log/minwon
chown minwon:minwon /var/log/minwon
chmod 750 /var/log/minwon

# =============================================================================
# [13/15] Configure UFW firewall
# =============================================================================
echo "[13/${TOTAL_STEPS}] Configuring UFW firewall rules..."
ufw --force enable

# SSH (always allow to prevent lockout)
ufw allow 22/tcp comment "SSH"

# HTTP redirect
ufw allow 80/tcp comment "HTTP -> HTTPS redirect"

# HTTPS - MinWon web portal
ufw allow 443/tcp comment "HTTPS MinWon portal"

# MinIO API - restrict to internal 192.168.92.0/24 subnet
# [취약 설정] 9000 포트는 내부망으로 제한 — 외부 노출 시 인증 없는 버킷 접근 가능
ufw allow from 192.168.92.0/24 to any port 9000 proto tcp comment "MinIO API (internal only)"

# MinIO Console - restrict to internal subnet only
ufw allow from 192.168.92.0/24 to any port 9001 proto tcp comment "MinIO Console (internal only)"

# Deny everything else
ufw default deny incoming
ufw default allow outgoing

ufw status verbose
echo "    UFW firewall configured."

# =============================================================================
# [14/15] Set final file ownership
# =============================================================================
echo "[14/${TOTAL_STEPS}] Setting file ownership..."
chown -R minwon:minwon /opt/minwon
# Re-apply .env permissions after chown
chmod 640 /opt/minwon/.env
# Backend venv stays owned by minwon
chown -R minwon:minwon /opt/minwon/backend
# MinIO binary/data
chown -R minio-user:minio-user /opt/minio /var/lib/minio
# Web root
chown -R www-data:www-data /var/www/minwon

# =============================================================================
# [15/15] Deployment complete
# =============================================================================
echo ""
echo "=================================================================="
echo " Asset 03 - MinWon Complaint Intake Server — Setup Complete"
echo "=================================================================="
echo ""
echo " Service URLs:"
echo "   Web Portal   : https://minwon.mois.valdoria.gov"
echo "                : https://192.168.92.203"
echo "   API (local)  : http://127.0.0.1:8000/api/"
echo "   MinIO API    : http://192.168.92.203:9000  (내부망 전용)"
echo "   MinIO Console: http://192.168.92.203:9001  (내부망 전용)"
echo ""
echo " Service Status:"
echo "   $(systemctl is-active nginx)      nginx"
echo "   $(systemctl is-active minio)      minio"
echo "   $(systemctl is-active minwon-api) minwon-api"
echo ""
echo " Important Notes:"
echo "   - TLS certificate is self-signed (10yr). Replace with proper cert for production."
echo "   - Edit /opt/minwon/.env with actual DB/Redis credentials before testing."
echo "   - MinIO console credentials: minio_access / minio_secret123"
echo "   - Log locations:"
echo "       Application : /var/log/minwon/"
echo "       Nginx access: /var/log/nginx/minwon_access.log"
echo "       Nginx error : /var/log/nginx/minwon_error.log"
echo "   - MinIO data   : /var/lib/minio/"
echo ""
echo " To check logs:"
echo "   journalctl -u minwon-api -f"
echo "   journalctl -u minio -f"
echo "=================================================================="
