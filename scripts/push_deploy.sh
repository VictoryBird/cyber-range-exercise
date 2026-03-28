#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "$PROJECT_ROOT"

if [ -n "$(git status --porcelain)" ]; then
    echo "[WARN] Uncommitted changes exist. Commit first."
    git status --short
    exit 1
fi

CURRENT_BRANCH=$(git branch --show-current)
if [ "$CURRENT_BRANCH" != "main" ]; then
    echo "[ERROR] Run from main branch. (current: $CURRENT_BRANCH)"
    exit 1
fi

echo "=== Step 1: Build (strip all comments) ==="
python3 scripts/build_deploy.py --report

if [ ! -d "deploy" ] || [ -z "$(ls -A deploy/ 2>/dev/null)" ]; then
    echo "[ERROR] deploy/ is empty."
    exit 1
fi

echo ""
echo "=== Step 2: Prepare deploy branch ==="
TEMP_DIR=$(mktemp -d)
cp -r deploy/* "$TEMP_DIR/"
[ -f "VM_설정_가이드.md" ] && cp "VM_설정_가이드.md" "$TEMP_DIR/"

if git rev-parse --verify deploy >/dev/null 2>&1; then
    git checkout deploy
else
    git checkout --orphan deploy
    git rm -rf . >/dev/null 2>&1 || true
fi

echo ""
echo "=== Step 3: Replace files ==="
find . -maxdepth 1 -not -name '.git' -not -name '.' -exec rm -rf {} + 2>/dev/null || true

mkdir -p assets
cp -r "$TEMP_DIR"/* .
for dir in */; do
    dirname=$(basename "$dir")
    if [ "$dirname" != "assets" ] && [ "$dirname" != ".git" ] && [ -d "$dir" ]; then
        mv "$dir" "assets/" 2>/dev/null || true
    fi
done
rm -f assets/.strip-report.txt

cat > README.md << 'EOF'
# Cyber Exercise Assets (Deploy)

This branch contains source code with all comments stripped for blue team deployment.

## Usage
```bash
cd assets/<asset_folder>/
sudo bash setup.sh
```

See `VM_설정_가이드.md` for IP addresses and credentials.
EOF

echo "  Files replaced"

echo ""
echo "=== Step 4: Commit & Push ==="
git add -A
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
git commit -m "Deploy: comment-stripped build (${TIMESTAMP})" || echo "[INFO] No changes"
git push origin deploy --force
echo "  deploy branch pushed"

echo ""
echo "=== Step 5: Back to main ==="
git checkout main
rm -rf "$TEMP_DIR"

echo ""
echo "=== Done ==="
