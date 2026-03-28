#!/usr/bin/env bash
# =============================================================
# setup.sh — Asset 01: 외부 포털 서버 (192.168.92.201)
# One-click deployment for Ubuntu 22.04
# =============================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPLOY_DIR="/opt/mois-portal"
SERVICE_USER="portaladm"
HOSTNAME_NEW="ext-portal"
TOTAL_STEPS=15

# ---------- Helper ----------
step() {
    echo ""
    echo "========================================"
    echo "[$1/${TOTAL_STEPS}] $2"
    echo "========================================"
}

# ---------- Root check ----------
if [[ "${EUID}" -ne 0 ]]; then
    echo "ERROR: This script must be run as root (sudo)."
    exit 1
fi

echo "============================================="
echo " MOIS External Portal Server — Deployment"
echo " Target: ${DEPLOY_DIR}"
echo " Hostname: ${HOSTNAME_NEW}"
echo "============================================="

# =============================================================
step 1 "System update + set hostname"
# =============================================================
hostnamectl set-hostname "${HOSTNAME_NEW}"
apt-get update -y
apt-get upgrade -y

# =============================================================
step 2 "Install Python 3.11, Node.js 20 LTS, Nginx, postgresql-client"
# =============================================================
apt-get install -y software-properties-common curl gnupg2

# Python 3.11
add-apt-repository -y ppa:deadsnakes/ppa
apt-get update -y
apt-get install -y python3.11 python3.11-venv python3.11-dev

# Node.js 20 LTS
if ! command -v node &>/dev/null || [[ "$(node --version | cut -d. -f1 | tr -d 'v')" -lt 20 ]]; then
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
    apt-get install -y nodejs
fi

# Nginx
apt-get install -y nginx

# PostgreSQL client (do NOT hardcode version)
apt-get install -y postgresql-client

echo "Python: $(python3.11 --version)"
echo "Node:   $(node --version)"
echo "npm:    $(npm --version)"
echo "Nginx:  $(nginx -v 2>&1)"

# =============================================================
step 3 "Create service user: ${SERVICE_USER}"
# =============================================================
if ! id "${SERVICE_USER}" &>/dev/null; then
    useradd --system --shell /usr/sbin/nologin --home-dir "${DEPLOY_DIR}" "${SERVICE_USER}"
    echo "User ${SERVICE_USER} created."
else
    echo "User ${SERVICE_USER} already exists."
fi

# =============================================================
step 4 "Copy backend + frontend to ${DEPLOY_DIR}"
# =============================================================
mkdir -p "${DEPLOY_DIR}"

# Backend
if [[ ! -d "${SCRIPT_DIR}/src/backend" ]]; then
    echo "ERROR: ${SCRIPT_DIR}/src/backend not found."
    exit 1
fi
cp -r "${SCRIPT_DIR}/src/backend" "${DEPLOY_DIR}/backend"

# Frontend
if [[ ! -d "${SCRIPT_DIR}/src/frontend" ]]; then
    echo "ERROR: ${SCRIPT_DIR}/src/frontend not found."
    exit 1
fi
cp -r "${SCRIPT_DIR}/src/frontend" "${DEPLOY_DIR}/frontend"

# Static files directory
mkdir -p "${DEPLOY_DIR}/static"

# =============================================================
step 5 "Deploy .env file"
# =============================================================
if [[ ! -f "${DEPLOY_DIR}/.env" ]]; then
    if [[ ! -f "${SCRIPT_DIR}/.env.example" ]]; then
        echo "ERROR: ${SCRIPT_DIR}/.env.example not found."
        exit 1
    fi
    cp "${SCRIPT_DIR}/.env.example" "${DEPLOY_DIR}/.env"
    echo ".env created from .env.example — review and adjust if needed."
else
    echo ".env already exists — skipping."
fi

# =============================================================
step 6 "Python venv + install dependencies"
# =============================================================
python3.11 -m venv "${DEPLOY_DIR}/backend/venv"
"${DEPLOY_DIR}/backend/venv/bin/pip" install --upgrade pip

if [[ ! -f "${DEPLOY_DIR}/backend/requirements.txt" ]]; then
    echo "ERROR: ${DEPLOY_DIR}/backend/requirements.txt not found."
    exit 1
fi
"${DEPLOY_DIR}/backend/venv/bin/pip" install -r "${DEPLOY_DIR}/backend/requirements.txt"

# Verify critical dependencies
echo "Verifying Python dependencies..."
"${DEPLOY_DIR}/backend/venv/bin/python" -c "
import fastapi, databases, sqlalchemy, uvicorn, pydantic
print('  fastapi:', fastapi.__version__)
print('  databases:', databases.__version__)
print('  sqlalchemy:', sqlalchemy.__version__)
print('  uvicorn:', uvicorn.__version__)
print('  pydantic:', pydantic.__version__)
print('All critical dependencies OK.')
"

# =============================================================
step 7 "npm install + Next.js production build"
# =============================================================
cd "${DEPLOY_DIR}/frontend"
npm install
npm run build
cd "${SCRIPT_DIR}"
echo "Next.js production build complete."

# =============================================================
step 8 "Generate self-signed TLS certificate"
# =============================================================
mkdir -p /etc/nginx/ssl

if [[ ! -f /etc/nginx/ssl/mois-portal.crt ]]; then
    openssl req -x509 -nodes -days 365 \
        -newkey rsa:2048 \
        -keyout /etc/nginx/ssl/mois-portal.key \
        -out /etc/nginx/ssl/mois-portal.crt \
        -subj "/C=VD/ST=Valdoria/L=Valdoria City/O=MOIS/CN=www.mois.valdoria.gov"
    echo "Self-signed TLS certificate generated."
else
    echo "TLS certificate already exists — skipping."
fi

# =============================================================
step 9 "Deploy Nginx configuration"
# =============================================================
if [[ ! -f "${SCRIPT_DIR}/src/config/nginx/mois-portal.conf" ]]; then
    echo "ERROR: ${SCRIPT_DIR}/src/config/nginx/mois-portal.conf not found."
    exit 1
fi

cp "${SCRIPT_DIR}/src/config/nginx/mois-portal.conf" /etc/nginx/sites-available/mois-portal

# Remove default site if present
rm -f /etc/nginx/sites-enabled/default

# Create symlink
ln -sf /etc/nginx/sites-available/mois-portal /etc/nginx/sites-enabled/mois-portal

# Test configuration
nginx -t
echo "Nginx configuration deployed and validated."

# =============================================================
step 10 "Deploy systemd services + enable + start"
# =============================================================
if [[ ! -f "${SCRIPT_DIR}/src/config/systemd/mois-portal-api.service" ]]; then
    echo "ERROR: ${SCRIPT_DIR}/src/config/systemd/mois-portal-api.service not found."
    exit 1
fi
if [[ ! -f "${SCRIPT_DIR}/src/config/systemd/mois-portal-web.service" ]]; then
    echo "ERROR: ${SCRIPT_DIR}/src/config/systemd/mois-portal-web.service not found."
    exit 1
fi

cp "${SCRIPT_DIR}/src/config/systemd/mois-portal-api.service" /etc/systemd/system/
cp "${SCRIPT_DIR}/src/config/systemd/mois-portal-web.service" /etc/systemd/system/

systemctl daemon-reload
systemctl enable --now mois-portal-api.service
systemctl enable --now mois-portal-web.service
systemctl restart nginx

echo "Services enabled and started."

# =============================================================
step 11 "Create log directory"
# =============================================================
mkdir -p /var/log/mois-portal
chown "${SERVICE_USER}:${SERVICE_USER}" /var/log/mois-portal

# =============================================================
step 12 "Deploy robots.txt"
# =============================================================
cat > "${DEPLOY_DIR}/static/robots.txt" <<'ROBOTS'
User-agent: *
Disallow: /api/
Disallow: /admin/
Disallow: /docs
Disallow: /redoc
ROBOTS
echo "robots.txt deployed."

# =============================================================
step 13 "Configure UFW firewall"
# =============================================================
ufw --force reset
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp    comment "SSH"
ufw allow 80/tcp    comment "HTTP"
ufw allow 443/tcp   comment "HTTPS"

# [취약점] VULN-WEB-04: FastAPI 포트가 직접 외부에 노출됨
# 올바른 설정: 이 규칙을 제거하고 Nginx 리버스 프록시만 사용해야 함
ufw allow 8000/tcp  comment "FastAPI Direct (VULN-WEB-04)"

ufw --force enable
ufw status verbose
echo "Firewall configured."

# =============================================================
step 14 "Set file ownership"
# =============================================================
chown -R "${SERVICE_USER}:${SERVICE_USER}" "${DEPLOY_DIR}"
echo "Ownership set to ${SERVICE_USER}."

# =============================================================
step 15 "Deployment complete"
# =============================================================
echo ""
echo "============================================="
echo " DEPLOYMENT COMPLETE"
echo "============================================="
echo ""
echo " Hostname:   ${HOSTNAME_NEW}"
echo " Deploy dir: ${DEPLOY_DIR}"
echo " Service user: ${SERVICE_USER}"
echo ""
echo " URLs:"
echo "   https://www.mois.valdoria.gov"
echo "   https://192.168.92.201"
echo "   http://192.168.92.201 (redirects to HTTPS)"
echo ""
echo " Services:"
echo "   systemctl status mois-portal-api"
echo "   systemctl status mois-portal-web"
echo "   systemctl status nginx"
echo ""
echo " Logs:"
echo "   journalctl -u mois-portal-api -f"
echo "   journalctl -u mois-portal-web -f"
echo "   tail -f /var/log/nginx/mois-portal-access.log"
echo "   tail -f /var/log/mois-portal/app.log"
echo ""
echo " IMPORTANT — Database:"
echo "   This server connects to PostgreSQL at 192.168.92.208."
echo "   Ensure the DB server (Asset 08) is deployed first and"
echo "   the mois_portal database + portal_app role exist."
echo "   Run the init SQL on the DB server:"
echo "     psql -h 192.168.92.208 -U postgres -f sql/init.sql"
echo ""
echo " WARNING — Intentional vulnerabilities:"
echo "   - Port 8000 is open in UFW (direct API access)"
echo "   - FastAPI binds to 0.0.0.0 (not 127.0.0.1)"
echo "   - /docs and /openapi.json are publicly accessible"
echo "============================================="
