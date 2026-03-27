#!/bin/bash
# ============================================================
# 군 문서 저장 서버 원클릭 배포 스크립트
# 대상: 192.168.110.12 / docs.mnd.local
# OS: Ubuntu 22.04 LTS
# 실행: sudo bash setup.sh
# ============================================================

set -e

# --- Root 권한 확인 ---
if [ "$EUID" -ne 0 ]; then
  echo "[오류] root 권한으로 실행하세요: sudo bash setup.sh"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "${SCRIPT_DIR}"

# --- 환경변수 로드 ---
if [ -f .env ]; then
  source .env
elif [ -f .env.example ]; then
  echo "[안내] .env 파일이 없어 .env.example을 사용합니다."
  cp .env.example .env
  source .env
else
  echo "[오류] .env 또는 .env.example 파일이 필요합니다."
  exit 1
fi

TOTAL_STEPS=11

# ==========================================================
echo "[1/${TOTAL_STEPS}] 시스템 업데이트 및 기본 패키지 설치..."
# ==========================================================
apt-get update && apt-get upgrade -y
apt-get install -y curl wget python3 python3-pip python3-venv nginx postgresql postgresql-contrib

# ==========================================================
echo "[2/${TOTAL_STEPS}] 서비스 계정 생성..."
# ==========================================================
id -u docstorage &>/dev/null || useradd -r -m -d /opt/docstorage -s /bin/bash docstorage

# ==========================================================
echo "[3/${TOTAL_STEPS}] PostgreSQL 설정..."
# ==========================================================
systemctl enable --now postgresql

sudo -u postgres psql -c "CREATE USER docstorage WITH PASSWORD 'DocStore2026!';" 2>/dev/null || true
sudo -u postgres psql -c "CREATE DATABASE mil_docstorage OWNER docstorage;" 2>/dev/null || true

# ==========================================================
echo "[4/${TOTAL_STEPS}] 애플리케이션 디렉토리 구성..."
# ==========================================================
APP_DIR=/opt/docstorage
mkdir -p ${APP_DIR}/{files/{작전계획,군수보급,인사명령,통신보안,일반행정},static/css,templates,routes}

# 소스코드 배포
cp src/backend/main.py ${APP_DIR}/
cp src/backend/config.py ${APP_DIR}/
cp src/backend/database.py ${APP_DIR}/
cp src/backend/models.py ${APP_DIR}/
cp src/backend/auth.py ${APP_DIR}/
cp src/backend/routes/*.py ${APP_DIR}/routes/
cp src/backend/templates/*.html ${APP_DIR}/templates/
cp src/backend/static/css/*.css ${APP_DIR}/static/css/
cp .env ${APP_DIR}/.env

# ==========================================================
echo "[5/${TOTAL_STEPS}] Python 가상환경 및 패키지 설치..."
# ==========================================================
python3 -m venv ${APP_DIR}/venv
${APP_DIR}/venv/bin/pip install --upgrade pip
${APP_DIR}/venv/bin/pip install -r requirements.txt
${APP_DIR}/venv/bin/python -c "import fastapi; import uvicorn; print('Dependencies OK')" || { echo "[ERROR] 의존성 설치 실패"; exit 1; }

# ==========================================================
echo "[6/${TOTAL_STEPS}] 시드 문서 배치..."
# ==========================================================
# 14개 군사 문서 플레이스홀더 생성
for f in seed/files/*.txt; do
  if [ -f "$f" ]; then
    BASENAME=$(basename "$f" .txt)
    # 파일명에서 카테고리 추출하여 적절한 디렉토리에 복사
    cp "$f" ${APP_DIR}/files/ 2>/dev/null || true
  fi
done

# 시드 문서 플레이스홀더 (실제 파일 크기 시뮬레이션)
dd if=/dev/urandom of=${APP_DIR}/files/작전계획/2026년_상반기_작전계획\(초안\).pdf bs=1024 count=2400 2>/dev/null
dd if=/dev/urandom of=${APP_DIR}/files/작전계획/합동작전_수행지침_v3.2.pdf bs=1024 count=1800 2>/dev/null
dd if=/dev/urandom of=${APP_DIR}/files/통신보안/전술통신망_구성도_2026.pdf bs=1024 count=3072 2>/dev/null
dd if=/dev/urandom of=${APP_DIR}/files/군수보급/군수물자_수급현황_3월.xlsx bs=1024 count=512 2>/dev/null
dd if=/dev/urandom of=${APP_DIR}/files/군수보급/탄약_재고관리_현황.xlsx bs=1024 count=700 2>/dev/null
dd if=/dev/urandom of=${APP_DIR}/files/인사명령/2026년_인사명령_제12호.pdf bs=1024 count=200 2>/dev/null
dd if=/dev/urandom of=${APP_DIR}/files/인사명령/간부_전보발령_목록.xlsx bs=1024 count=150 2>/dev/null
dd if=/dev/urandom of=${APP_DIR}/files/통신보안/암호체계_운용지침_개정.pdf bs=1024 count=1024 2>/dev/null
dd if=/dev/urandom of=${APP_DIR}/files/통신보안/보안점검_결과보고_2026Q1.pdf bs=1024 count=800 2>/dev/null
dd if=/dev/urandom of=${APP_DIR}/files/작전계획/부대_이동계획_4월.pdf bs=1024 count=1200 2>/dev/null
dd if=/dev/urandom of=${APP_DIR}/files/일반행정/업무보고_정보통신과_3월.docx bs=1024 count=300 2>/dev/null
dd if=/dev/urandom of=${APP_DIR}/files/일반행정/출장명령서_2026-0312.pdf bs=1024 count=100 2>/dev/null
dd if=/dev/urandom of=${APP_DIR}/files/통신보안/네트워크_접근통제_정책.pdf bs=1024 count=600 2>/dev/null
dd if=/dev/urandom of=${APP_DIR}/files/작전계획/예비군_훈련계획_2026.pdf bs=1024 count=400 2>/dev/null

# ==========================================================
echo "[7/${TOTAL_STEPS}] DB 초기 데이터 적용..."
# ==========================================================
# FastAPI 앱 시작 시 테이블 자동 생성 (lifespan)
# 시드 데이터는 별도 적용
cd ${APP_DIR}
${APP_DIR}/venv/bin/python -c "
from database import engine, Base
from models import User, Document, AuditLog
Base.metadata.create_all(bind=engine)
print('테이블 생성 완료')
"
[ -f "${SCRIPT_DIR}/sql/init.sql" ] || { echo "[ERROR] SQL 파일 없음: sql/init.sql"; exit 1; }
sudo -u postgres psql -d mil_docstorage -f ${SCRIPT_DIR}/sql/init.sql || true

# ==========================================================
echo "[8/${TOTAL_STEPS}] 파일 권한 설정..."
# ==========================================================
chown -R docstorage:docstorage ${APP_DIR}
chmod -R 755 ${APP_DIR}/files

# ==========================================================
echo "[9/${TOTAL_STEPS}] systemd 서비스 등록..."
# ==========================================================
[ -f "${SCRIPT_DIR}/conf/systemd/docstorage.service" ] || { echo "[ERROR] 파일 없음: conf/systemd/docstorage.service"; exit 1; }
cp ${SCRIPT_DIR}/conf/systemd/docstorage.service /etc/systemd/system/
systemctl daemon-reload
systemctl enable --now docstorage

# ==========================================================
echo "[10/${TOTAL_STEPS}] Nginx 설정..."
# ==========================================================
[ -f "${SCRIPT_DIR}/conf/nginx/docstorage.conf" ] || { echo "[ERROR] 파일 없음: conf/nginx/docstorage.conf"; exit 1; }
cp ${SCRIPT_DIR}/conf/nginx/docstorage.conf /etc/nginx/sites-available/docstorage
ln -sf /etc/nginx/sites-available/docstorage /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
nginx -t && systemctl reload nginx

# ==========================================================
echo "[11/${TOTAL_STEPS}] UFW 방화벽 설정..."
# ==========================================================
ufw allow 22/tcp comment "SSH"
ufw allow 80/tcp comment "HTTP (Nginx)"
# [취약 설정] 8000 포트 직접 노출 (Nginx 바이패스 가능)
ufw allow 8000/tcp comment "FastAPI Direct Access"
ufw --force enable

echo ""
echo "============================================================"
echo " 문서 저장 서버 배포 완료"
echo "============================================================"
echo " URL:   http://docs.mnd.local (Nginx)"
echo "        http://192.168.110.12 (Nginx)"
echo "        http://192.168.110.12:8000 (FastAPI 직접)"
echo " API:   http://192.168.110.12/docs (Swagger UI)"
echo ""
echo " [주의사항]"
echo "  - /etc/hosts 에 '192.168.110.12 docs.mnd.local' 추가 필요"
echo "  - DB 시드: sql/init.sql (자동 적용됨)"
echo "  - 파일 저장소: /opt/docstorage/files/"
echo "============================================================"
