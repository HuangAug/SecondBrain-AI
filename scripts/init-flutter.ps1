# 在 mobile/ 目录生成 Android/iOS 平台文件
$ErrorActionPreference = "Stop"
$MobileDir = Join-Path (Split-Path -Parent $PSScriptRoot) "mobile"

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    Write-Host "请先安装 Flutter SDK: https://docs.flutter.dev/get-started/install" -ForegroundColor Red
    exit 1
}

Push-Location $MobileDir

if (Test-Path "android") {
    Write-Host "平台目录已存在，跳过 flutter create"
} else {
    Write-Host "生成 Flutter 平台文件..."
    flutter create --project-name secondbrain --org com.secondbrain .
}

flutter pub get
Write-Host "完成！运行: flutter run" -ForegroundColor Green
Pop-Location
