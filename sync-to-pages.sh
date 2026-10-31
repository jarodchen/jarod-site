#!/usr/bin/env bash
# ======================================================================
# 同步前端构建产物到本仓库（deploy-site/jarod-site）的 dist/，
# 供 .github/workflows/deploy.yml 上传到 GitHub Pages。
#
# 用法（在本仓库根目录执行）：
#   ./sync-to-pages.sh            # 仅拷贝（需先在前端仓库构建好）
#   BUILD=1 ./sync-to-pages.sh    # 先在前端仓库 npm run build，再拷贝
#
# 说明：GitHub Pages 不会做 SPA 兜底，深链接（如 /jarod-site/data-screen）
#       依赖产物里的 404.html 与 data-screen/index.html。务必「整目录」拷贝，
#       保证这些兜底文件一并进来（部分覆盖会漏掉它们）。
# ======================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
FRONTEND="$(cd "$SCRIPT_DIR/../../frontend/my-site" && pwd)"
FRONTEND_DIST="$FRONTEND/dist"
TARGET="$SCRIPT_DIR/dist"

if [ "${BUILD:-0}" = "1" ]; then
  echo "→ 在前端仓库构建（使用仓库自带 .env.production：base=/jarod-site/、Mock=true）"
  cd "$FRONTEND"
  npm install
  npm run build
fi

if [ ! -d "$FRONTEND_DIST" ]; then
  echo "✗ 未找到构建产物：$FRONTEND_DIST"
  echo "  请先在 frontend/my-site 执行 npm install && npm run build，或用 BUILD=1 自动构建"
  exit 1
fi

echo "→ 清空 $TARGET"
rm -rf "$TARGET"
mkdir -p "$TARGET"

echo "→ 整目录拷贝 $FRONTEND_DIST → $TARGET"
cp -r "$FRONTEND_DIST/." "$TARGET/"

echo "✓ 同步完成"
echo "  后续：git add dist && git commit -m 'deploy' && git push"
echo "  （推到 main 分支会触发 deploy.yml 发布到 GitHub Pages）"
