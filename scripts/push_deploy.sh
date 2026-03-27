#!/bin/bash
# ============================================================
# push_deploy.sh — deploy 브랜치에 주석 제거 버전 푸시
#
# 사용법: bash scripts/push_deploy.sh
#
# 동작:
#   1. main 브랜치에서 build_deploy.py 실행 → deploy/ 생성
#   2. deploy 브랜치로 전환 (없으면 orphan 생성)
#   3. deploy/ 내용을 assets/로 복사 + VM_설정_가이드.md 포함
#   4. 커밋 & 푸시
#   5. main 브랜치로 복귀
# ============================================================
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "$PROJECT_ROOT"

# ── 사전 확인 ──
if [ -n "$(git status --porcelain)" ]; then
    echo "[WARN] 커밋되지 않은 변경사항이 있습니다."
    echo "       먼저 main 브랜치의 변경사항을 커밋해주세요."
    git status --short
    exit 1
fi

CURRENT_BRANCH=$(git branch --show-current)
if [ "$CURRENT_BRANCH" != "main" ]; then
    echo "[ERROR] main 브랜치에서 실행해주세요. (현재: $CURRENT_BRANCH)"
    exit 1
fi

# ── Step 1: 주석 제거 빌드 ──
echo "═══════════════════════════════════════"
echo " Step 1: 주석 제거 빌드 실행"
echo "═══════════════════════════════════════"
python3 scripts/build_deploy.py --report

# deploy/ 디렉토리 확인
if [ ! -d "deploy" ] || [ -z "$(ls -A deploy/ 2>/dev/null)" ]; then
    echo "[ERROR] deploy/ 디렉토리가 비어있습니다."
    exit 1
fi

# ── Step 2: deploy 브랜치 준비 ──
echo ""
echo "═══════════════════════════════════════"
echo " Step 2: deploy 브랜치 준비"
echo "═══════════════════════════════════════"

# 임시 디렉토리에 deploy 내용 복사
TEMP_DIR=$(mktemp -d)
cp -r deploy/* "$TEMP_DIR/"
# VM 설정 가이드 복사
[ -f "VM_설정_가이드.md" ] && cp "VM_설정_가이드.md" "$TEMP_DIR/"

# deploy 브랜치 존재 여부 확인
if git rev-parse --verify deploy >/dev/null 2>&1; then
    git checkout deploy
else
    git checkout --orphan deploy
    git rm -rf . >/dev/null 2>&1 || true
    echo "  새 orphan 브랜치 'deploy' 생성"
fi

# ── Step 3: 파일 교체 ──
echo ""
echo "═══════════════════════════════════════"
echo " Step 3: 파일 교체"
echo "═══════════════════════════════════════"

# 기존 파일 정리 (.git 제외)
find . -maxdepth 1 -not -name '.git' -not -name '.' -exec rm -rf {} + 2>/dev/null || true

# deploy 내용을 assets/로 복사
mkdir -p assets
cp -r "$TEMP_DIR"/* .
# deploy의 자산 폴더들을 assets/ 아래로 이동
for dir in */; do
    dirname=$(basename "$dir")
    # assets, .git, VM_설정_가이드.md는 건너뜀
    if [ "$dirname" != "assets" ] && [ "$dirname" != ".git" ] && [ -d "$dir" ]; then
        mv "$dir" "assets/" 2>/dev/null || true
    fi
done

# .strip-report.txt 제거 (deploy 브랜치에 불필요)
rm -f assets/.strip-report.txt

# README.md 생성
cat > README.md << 'EOF'
# 사이버 훈련 자산 (배포용)

이 브랜치는 VM 배포용으로 취약점 관련 주석이 제거된 버전입니다.

## 사용 방법

1. 이 브랜치를 다운로드합니다 (Download ZIP)
2. 해당 자산 폴더로 이동합니다
3. setup.sh를 실행합니다

```bash
cd assets/01_외부포털서버/
sudo bash setup.sh
```

## 자산 목록

각 자산의 IP, 호스트명, 계정 정보는 `VM_설정_가이드.md`를 참고하세요.
EOF

echo "  파일 교체 완료"

# ── Step 4: 커밋 & 푸시 ──
echo ""
echo "═══════════════════════════════════════"
echo " Step 4: 커밋 & 푸시"
echo "═══════════════════════════════════════"

git add -A
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
git commit -m "Deploy: 주석 제거 빌드 (${TIMESTAMP})" || {
    echo "[INFO] 변경사항 없음 — 커밋 건너뜀"
}

git push origin deploy --force
echo "  deploy 브랜치 푸시 완료"

# ── Step 5: main으로 복귀 ──
echo ""
echo "═══════════════════════════════════════"
echo " Step 5: main 브랜치로 복귀"
echo "═══════════════════════════════════════"

git checkout main
rm -rf "$TEMP_DIR"

echo ""
echo "═══════════════════════════════════════"
echo " 완료!"
echo "═══════════════════════════════════════"
echo ""
echo " deploy 브랜치가 업데이트되었습니다."
echo " GitHub에서 'deploy' 브랜치 → Download ZIP으로"
echo " VM에 배포할 수 있습니다."
echo ""
echo " URL: https://github.com/VictoryBird/cyber-range-exercise/tree/deploy"
echo "═══════════════════════════════════════"
