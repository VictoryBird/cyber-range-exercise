#!/bin/bash
# ============================================================
# 군 내부 업무 포털 원클릭 배포 스크립트 (PLACEHOLDER)
# 대상: 192.168.110.10 / intranet.mnd.local
# OS: Rocky Linux 9
# 실행: sudo bash setup.sh
#
# TODO: eGovframework 기반 구현 -- 마지막 구현 예정
# 상세 설계: 자산설계_I6_내부업무포털_군.md 참조
# ============================================================

set -e

# --- Root 권한 확인 ---
if [ "$EUID" -ne 0 ]; then
  echo "[오류] root 권한으로 실행하세요: sudo bash setup.sh"
  exit 1
fi

echo "============================================================"
echo " [안내] I6 군 내부 업무 포털은 아직 구현되지 않았습니다."
echo ""
echo " 이 자산은 eGovframework 4.x + Spring Boot 3.x 기반으로"
echo " 구현 난이도가 높아 마지막에 구현할 예정입니다."
echo ""
echo " 상세 설계: 자산설계_I6_내부업무포털_군.md"
echo ""
echo " 기술 스택:"
echo "   - OS: Rocky Linux 9"
echo "   - JDK: OpenJDK 17"
echo "   - Framework: eGovframework 4.x + Spring Boot 3.x"
echo "   - DB: PostgreSQL 15"
echo "   - Web Server: Nginx 1.24.x"
echo "   - Auth: Spring LDAP (AD 연동)"
echo ""
echo " TODO:"
echo "   1. eGovframework 프로젝트 구조 생성"
echo "   2. Spring Boot 컨트롤러/서비스 구현"
echo "   3. Thymeleaf 또는 JSP 템플릿 작성"
echo "   4. AD LDAP 인증 연동"
echo "   5. 의도적 취약점 삽입 (SQL Injection, 인증 우회 등)"
echo "   6. Nginx 리버스 프록시 설정"
echo "   7. systemd 서비스 등록"
echo "============================================================"

exit 0
