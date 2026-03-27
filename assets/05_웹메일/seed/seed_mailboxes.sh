#!/bin/bash
# ============================================================
# 사용자별 Maildir 디렉토리 생성
# ============================================================

VHOST_DIR="/var/mail/vhosts/mois.local"
USERS=(
  hong.gildong kim.chulsoo lee.younghee park.minsoo choi.jihye
  jung.dongwook yoon.sera kang.jiwon shin.hyunwoo han.minji
  seo.junhyuk admin helpdesk
)

for user in "${USERS[@]}"; do
  mkdir -p "${VHOST_DIR}/${user}/{cur,new,tmp}"
  mkdir -p "${VHOST_DIR}/${user}/.Sent/{cur,new,tmp}"
  mkdir -p "${VHOST_DIR}/${user}/.Drafts/{cur,new,tmp}"
  mkdir -p "${VHOST_DIR}/${user}/.Trash/{cur,new,tmp}"
  mkdir -p "${VHOST_DIR}/${user}/.Junk/{cur,new,tmp}"
done

chown -R vmail:vmail "${VHOST_DIR}"
echo "메일박스 생성 완료: ${#USERS[@]}개 계정"
