# ======================================================================
# 同步前端构建产物到本仓库（deploy-site/jarod-site）的 dist/，
# 供 .github/workflows/deploy.yml 上传到 GitHub Pages。
#
# 用法（在本仓库根目录执行）：
#   .\sync-to-pages.ps1            # 仅拷贝（需先在前端仓库构建好）
#   $env:BUILD=1; .\sync-to-pages.ps1   # 先在前端仓库 npm run build，再拷贝
#
# 说明：GitHub Pages 不会做 SPA 兜底，深链接（如 /jarod-site/data-screen）
#       依赖产物里的 404.html 与 data-screen/index.html。务必「整目录」拷贝，
#       保证这些兜底文件一并进来（部分覆盖会漏掉它们）。
# ======================================================================
$ErrorActionPreference = 'Stop'

$ScriptDir   = Split-Path -Parent $MyInvocation.MyCommand.Definition
$Frontend    = Resolve-Path (Join-Path $ScriptDir '..\..\frontend\my-site')
$FrontendDist = Join-Path $Frontend 'dist'
$Target      = Join-Path $ScriptDir 'dist'

if ($env:BUILD -eq '1') {
  Write-Host "→ 在前端仓库构建（使用仓库自带 .env.production：base=/jarod-site/、Mock=true）"
  Push-Location $Frontend
  try {
    npm install
    npm run build
  } finally {
    Pop-Location
  }
}

if (-not (Test-Path $FrontendDist)) {
  Write-Error "未找到构建产物：$FrontendDist；请先在 frontend/my-site 执行 npm install && npm run build，或用 `$env:BUILD=1 自动构建"
  exit 1
}

Write-Host "→ 清空 $Target"
if (Test-Path $Target) { Remove-Item $Target -Recurse -Force }
New-Item -ItemType Directory -Path $Target | Out-Null

Write-Host "→ 整目录拷贝 $FrontendDist → $Target"
Copy-Item (Join-Path $FrontendDist '*') $Target -Recurse -Force

Write-Host "✓ 同步完成"
Write-Host "  后续：git add dist; git commit -m 'deploy'; git push（推 main 触发 deploy.yml 发布）"
