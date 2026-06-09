# SecondBrain 本地开发环境初始化脚本
param(
    [switch]$SkipDocker
)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot

Write-Host "==> SecondBrain 开发环境初始化" -ForegroundColor Cyan

if (-not $SkipDocker) {
    Write-Host "==> 启动 Docker 服务 (PostgreSQL + Redis)..."
    Push-Location "$Root\backend"
    docker compose up -d
    Pop-Location
    Start-Sleep -Seconds 5
}

Write-Host "==> 安装 Python 依赖..."
Push-Location "$Root\backend"
if (-not (Test-Path ".env")) {
    Copy-Item ".env.example" ".env"
    Write-Host "    已创建 backend/.env，请填入 AI API Key"
}
python -m pip install -r requirements.txt
Pop-Location

if (Get-Command flutter -ErrorAction SilentlyContinue) {
    Write-Host "==> 安装 Flutter 依赖..."
    Push-Location "$Root\mobile"
    flutter pub get
    Pop-Location
} else {
    Write-Host "==> Flutter 未安装，跳过 mobile 依赖。请从 https://flutter.dev 安装后运行 flutter pub get" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "完成！启动后端：" -ForegroundColor Green
Write-Host "  cd backend && uvicorn app.main:app --reload --port 8000"
Write-Host ""
Write-Host "启动移动端（需 Flutter）："
Write-Host "  cd mobile && flutter run"
