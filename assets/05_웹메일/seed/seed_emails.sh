#!/bin/bash
# ============================================================
# 초기 메일 데이터 삽입 스크립트
# seed/emails/ 디렉토리의 .eml 파일을 각 사용자 Maildir/new/ 에 복사
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
EML_DIR="${SCRIPT_DIR}/emails"
VHOST_DIR="/var/mail/vhosts/mois.local"
TIMESTAMP=$(date +%s)
COUNTER=0

# 메일을 Maildir/new/ 에 삽입하는 함수
deliver_eml() {
  local user="$1"
  local eml_file="$2"
  local target_dir="${VHOST_DIR}/${user}/new"

  if [ ! -d "${target_dir}" ]; then
    echo "  [경고] ${user} Maildir 없음, 건너뜀: ${eml_file}"
    return
  fi

  COUNTER=$((COUNTER + 1))
  local filename="${TIMESTAMP}.${COUNTER}.mail.mois.local"
  cp "${eml_file}" "${target_dir}/${filename}"
  chown vmail:vmail "${target_dir}/${filename}"
  echo "  배달: $(basename ${eml_file}) → ${user}"
}

echo "=== 초기 메일 데이터 삽입 시작 ==="

# 전체 직원 배달 메일 (01, 03, 05, 06)
ALL_STAFF_MAILS=("01" "03" "05" "06")
ALL_USERS=(
  hong.gildong kim.chulsoo lee.younghee park.minsoo choi.jihye
  jung.dongwook yoon.sera kang.jiwon shin.hyunwoo han.minji
  seo.junhyuk
)

for mid in "${ALL_STAFF_MAILS[@]}"; do
  eml_file=$(ls "${EML_DIR}"/${mid}_*.eml 2>/dev/null | head -1)
  if [ -z "${eml_file}" ]; then
    echo "  [경고] ${mid}_*.eml 파일 없음"
    continue
  fi
  for user in "${ALL_USERS[@]}"; do
    deliver_eml "${user}" "${eml_file}"
  done
done

# 개별 배달 메일
# 02: 회의일정 → hong.gildong, kim.chulsoo, park.minsoo
for user in hong.gildong kim.chulsoo park.minsoo; do
  deliver_eml "${user}" "${EML_DIR}/02_회의일정_안내.eml"
done

# 04: 비밀번호 초기화 → park.minsoo, helpdesk
for user in park.minsoo helpdesk; do
  deliver_eml "${user}" "${EML_DIR}/04_IT헬프데스크_비번초기화.eml"
done

# 07: 업무보고 → hong.gildong, kang.jiwon
for user in hong.gildong kang.jiwon; do
  deliver_eml "${user}" "${EML_DIR}/07_업무보고_제출.eml"
done

# 08: 내부시스템 접속안내 → han.minji, helpdesk
for user in han.minji helpdesk; do
  deliver_eml "${user}" "${EML_DIR}/08_내부시스템_접속안내.eml"
done

# 09: 예산검토 → lee.younghee, hong.gildong
for user in lee.younghee hong.gildong; do
  deliver_eml "${user}" "${EML_DIR}/09_예산검토_요청.eml"
done

# 10: VPN 안내 → seo.junhyuk, helpdesk
for user in seo.junhyuk helpdesk; do
  deliver_eml "${user}" "${EML_DIR}/10_IT헬프데스크_VPN안내.eml"
done

echo "=== 초기 메일 데이터 삽입 완료 (${COUNTER}건) ==="
