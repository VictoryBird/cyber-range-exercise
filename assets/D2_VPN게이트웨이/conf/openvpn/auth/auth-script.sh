#!/bin/bash
# ============================================================
# D2 VPN 게이트웨이 — OpenVPN 인증 스크립트
# users.txt 기반 평문 패스워드 인증
# 사이버 훈련 전용 — 실제 운영 환경 사용 금지
# ============================================================
#
# [취약점] VULN-D2-01: MFA 미적용 — 패스워드만으로 인증 완료
# [올바른 설정] TOTP/RADIUS 등 2차 인증 요소 추가 필요
#
# [취약점] VULN-D2-02: 로그인 실패 횟수 제한/계정 잠금 없음
# [올바른 설정] 실패 카운터 관리 및 N회 초과 시 계정 잠금 필요
#   예: FAIL_COUNT_FILE="/var/run/openvpn/fail_${username}"
#       MAX_FAILURES=5; LOCKOUT_DURATION=300

USERS_FILE="/etc/openvpn/server/auth/users.txt"
LOG_FILE="/var/log/openvpn/auth.log"

# OpenVPN은 via-env 모드에서 환경변수로 자격증명 전달
username="${username}"
password="${password}"

# 타임스탬프
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# 입력 검증
if [ -z "$username" ] || [ -z "$password" ]; then
    echo "${TIMESTAMP} [AUTH] FAIL - empty credentials" >> "$LOG_FILE"
    exit 1
fi

if [ ! -f "$USERS_FILE" ]; then
    echo "${TIMESTAMP} [AUTH] ERROR - users file not found: ${USERS_FILE}" >> "$LOG_FILE"
    exit 1
fi

# 사용자 인증 (평문 비교)
# [취약점] 평문 패스워드 파일 사용 — 해시(bcrypt/argon2) 비교로 교체 필요
while IFS=: read -r stored_user stored_pass; do
    # 주석 및 빈 줄 무시
    [[ "$stored_user" =~ ^#.*$ ]] && continue
    [[ -z "$stored_user" ]] && continue

    if [ "$username" = "$stored_user" ] && [ "$password" = "$stored_pass" ]; then
        echo "${TIMESTAMP} [AUTH] SUCCESS - user '${username}' authenticated from ${untrusted_ip:-unknown}" >> "$LOG_FILE"
        exit 0
    fi
done < "$USERS_FILE"

# 인증 실패
# [취약점] VULN-D2-02: 실패 로그만 기록하고 잠금 처리 없음
echo "${TIMESTAMP} [AUTH] FAIL - user '${username}' invalid credentials from ${untrusted_ip:-unknown}" >> "$LOG_FILE"
exit 1
