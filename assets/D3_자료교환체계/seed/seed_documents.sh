#!/bin/bash
# seed_documents.sh — D3 자료교환체계 Nextcloud 문서 시드 (네이티브)
# Nextcloud occ 명령으로 사용자/그룹/문서를 생성한다.
set -e

OCC="sudo -u www-data php /var/www/nextcloud/occ"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "[1/6] Nextcloud 설치 상태 확인..."
if ! ${OCC} status 2>/dev/null | grep -q "installed: true"; then
    echo "[오류] Nextcloud가 설치되지 않았습니다. setup.sh를 먼저 실행하세요."
    exit 1
fi
echo "  Nextcloud 준비 완료"

# ──────────────────────────────────────────────
echo "[2/6] 그룹 생성..."
for group in military external it; do
    ${OCC} group:add "${group}" 2>/dev/null || true
done

# ──────────────────────────────────────────────
echo "[3/6] 사용자 생성..."

create_user() {
    local user="$1" pass="$2" display="$3" groups="$4"
    local group_args=""
    IFS=',' read -ra G <<< "$groups"
    for g in "${G[@]}"; do
        group_args="${group_args} --group=${g}"
    done
    OC_PASS="${pass}" ${OCC} user:add --password-from-env ${group_args} --display-name="${display}" "${user}" 2>/dev/null || true
}

# [취약점] VULN-D3-01: VPN과 동일한 크리덴셜 (GOV20190847 / 20190847890312)
# 올바른 구현: 서비스별 개별 비밀번호 사용, MFA 적용 필수
create_user "GOV20190847"  "20190847890312"  "행안부 협력관"         "external"
create_user "MIL_ADMIN01"  "Mil@Adm!n2024"   "군 관리자"             "military"
create_user "MIL_USER01"   "SecurePass!01"    "사이버작전사 김대위"    "military"
create_user "MIL_USER02"   "SecurePass!02"    "합참 J6 박소령"        "military"
create_user "MIL_USER03"   "SecurePass!03"    "방사청 이사무관"       "military"
create_user "MIL_USER04"   "MilPatch@2024"    "정보체계 최주무관"     "military,it"
create_user "MIL_USER05"   "DefNet!Sec05"     "국방망관리 정상사"     "military"
create_user "CONTRACTOR01" "Cont@ct2024!"     "(주)보안테크 담당자"   "external"

# ──────────────────────────────────────────────
echo "[4/6] 문서 업로드 (WebDAV)..."

NEXTCLOUD_URL="http://localhost"
WEBDAV_BASE="${NEXTCLOUD_URL}/remote.php/dav/files/MIL_ADMIN01"

# MIL_ADMIN01 계정으로 폴더 생성
create_folder() {
    curl -s -X MKCOL -u "MIL_ADMIN01:Mil@Adm!n2024" "${WEBDAV_BASE}/$1" -o /dev/null || true
}

upload_file() {
    local remote_path="$1" local_file="$2"
    curl -s -T "${local_file}" -u "MIL_ADMIN01:Mil@Adm!n2024" "${WEBDAV_BASE}/${remote_path}" -o /dev/null
}

create_folder "군사자료"
create_folder "공유문서"
create_folder "내부규정"

# 군사자료 업로드 (5개 문서)
if [ -d "${SCRIPT_DIR}/documents/군사자료" ]; then
    for f in "${SCRIPT_DIR}/documents/군사자료/"*; do
        [ -f "$f" ] || continue
        fname=$(basename "$f")
        upload_file "군사자료/${fname}" "$f"
        echo "  업로드: 군사자료/${fname}"
    done
fi

# 공유문서 업로드 (3개 문서)
if [ -d "${SCRIPT_DIR}/documents/공유문서" ]; then
    for f in "${SCRIPT_DIR}/documents/공유문서/"*; do
        [ -f "$f" ] || continue
        fname=$(basename "$f")
        upload_file "공유문서/${fname}" "$f"
        echo "  업로드: 공유문서/${fname}"
    done
fi

# ──────────────────────────────────────────────
echo "[5/6] 폴더 공유 설정..."

# OCS Share API로 공유 설정
share_folder() {
    local path="$1" share_type="$2" share_with="$3" permissions="$4"
    curl -s -X POST \
        -u "MIL_ADMIN01:Mil@Adm!n2024" \
        -H "OCS-APIREQUEST: true" \
        -d "path=/${path}&shareType=${share_type}&shareWith=${share_with}&permissions=${permissions}" \
        "${NEXTCLOUD_URL}/ocs/v2.php/apps/files_sharing/api/v1/shares" \
        -o /dev/null
}

# shareType: 0=user, 1=group  |  permissions: 1=read, 15=read+write+create+delete
# 군사자료 → military 그룹 (읽기)
share_folder "군사자료" 1 "military" 1
# 군사자료 → GOV20190847 (읽기 — 크리덴셜 재사용으로 접근 가능)
share_folder "군사자료" 0 "GOV20190847" 1
# 공유문서 → 전체 사용자: military 그룹 (읽기/쓰기)
share_folder "공유문서" 1 "military" 15
# 공유문서 → external 그룹 (읽기/쓰기)
share_folder "공유문서" 1 "external" 15

# ──────────────────────────────────────────────
echo "[6/6] 파일 스캔..."
${OCC} files:scan --all

echo ""
echo "========================================="
echo "  D3 Nextcloud 문서 시드 완료"
echo "========================================="
echo "  군사자료: 5개 문서"
echo "  공유문서: 3개 문서"
echo "  사용자:   9명 (admin 포함)"
echo ""
echo "  [취약점 확인]"
echo "  - VULN-D3-01: GOV20190847 계정은 VPN과 동일 비밀번호"
echo "  - VULN-D3-02: WebDAV 대량 다운로드 제한 없음"
echo "========================================="
