#!/bin/bash
# ============================================================
# C15 정상 브리핑 vs 오염 브리핑 비교 스크립트
#
# 이 스크립트는 C14 데이터 변조 전후의 AI 브리핑을 비교한다.
# 실행: bash compare_normal_vs_corrupted.sh [SUMMARY_API_URL]
# ============================================================

SUMMARY_API="${1:-http://192.168.130.13:8001}"
DATA_API="${2:-http://192.168.130.12:8000}"

echo "============================================================"
echo "C15 AI 브리핑 비교: 정상 vs 오염"
echo "============================================================"

# ──────────────────────────────────────────────
# 1단계: 정상 상태 브리핑 생성
# ──────────────────────────────────────────────
echo ""
echo "[1/4] 현재 C14 데이터 통계 (정상 상태)..."
NORMAL_STATS=$(curl -s -H "X-API-Key: dev-key-12345" "$DATA_API/api/stats")
echo "$NORMAL_STATS" | python3 -m json.tool 2>/dev/null

echo ""
echo "[2/4] 정상 상태 브리핑 생성 중..."
NORMAL_BRIEFING=$(curl -s -X POST "$SUMMARY_API/api/summary/generate")

echo ""
echo "=== 정상 상태 브리핑 ==="
echo "$NORMAL_BRIEFING" | python3 -c "
import sys, json
data = json.load(sys.stdin)
print(f'생성 시각: {data.get(\"generated_at\", \"N/A\")}')
print(f'분석 이벤트: {data.get(\"total_events_analyzed\", 0)}건')
print(f'아군 이벤트: {data.get(\"friendly_event_count\", 0)}건')
print(f'적군 이벤트: {data.get(\"enemy_event_count\", 0)}건')
print()
print(data.get('summary_text', '(요약 없음)'))
" 2>/dev/null

# ──────────────────────────────────────────────
# 3단계: 오염 후 브리핑 생성 안내
# ──────────────────────────────────────────────
echo ""
echo "============================================================"
echo "[3/4] C14 데이터 오염을 실행하세요:"
echo "  bash /opt/datacollector/scripts/attack_demo.sh"
echo ""
echo "  오염 후 Enter를 눌러 계속..."
read -r

echo ""
echo "[4/4] 오염 상태 브리핑 생성 중..."
CORRUPTED_STATS=$(curl -s -H "X-API-Key: dev-key-12345" "$DATA_API/api/stats")
echo "오염 후 C14 통계:"
echo "$CORRUPTED_STATS" | python3 -m json.tool 2>/dev/null

CORRUPTED_BRIEFING=$(curl -s -X POST "$SUMMARY_API/api/summary/generate")

echo ""
echo "=== 오염 상태 브리핑 ==="
echo "$CORRUPTED_BRIEFING" | python3 -c "
import sys, json
data = json.load(sys.stdin)
print(f'생성 시각: {data.get(\"generated_at\", \"N/A\")}')
print(f'분석 이벤트: {data.get(\"total_events_analyzed\", 0)}건')
print(f'아군 이벤트: {data.get(\"friendly_event_count\", 0)}건')
print(f'적군 이벤트: {data.get(\"enemy_event_count\", 0)}건')
print()
print(data.get('summary_text', '(요약 없음)'))
" 2>/dev/null

echo ""
echo "============================================================"
echo "비교 완료"
echo ""
echo "핵심 차이점:"
echo "  - 정상: 아군 이벤트 다수, 적 이벤트 소수 -> STABLE/ELEVATED"
echo "  - 오염: 아군 이벤트 0건, 적 이벤트 다수 -> CRITICAL"
echo "  -> AI가 허위 데이터 기반으로 긴급 경보 브리핑 생성"
echo "============================================================"
