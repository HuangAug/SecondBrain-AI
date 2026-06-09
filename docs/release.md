# 发布指南

## 后端部署（腾讯云轻量服务器）

```bash
# 服务器上
git clone <repo-url> secondbrain
cd secondbrain/backend
cp .env.example .env   # 填入生产配置
docker compose up -d
docker build -t secondbrain-api .
docker run -d --name api --env-file .env -p 8000:8000 \
  --network host secondbrain-api
```

配置 Nginx 反向代理 + HTTPS（Let's Encrypt 或腾讯云 SSL）。

## Sentry 监控

在 `backend/.env` 设置：

```
SENTRY_DSN=https://xxx@sentry.io/xxx
```

移动端二期可接入 `sentry_flutter` 包。

## Android 打包

```bash
cd mobile
flutter build apk --release \
  --dart-define=API_BASE_URL=https://api.yourdomain.com/api/v1
```

产出：`build/app/outputs/flutter-apk/app-release.apk`

上架：华为应用市场、小米应用商店、应用宝

## iOS 打包

```bash
cd mobile
flutter build ipa --release \
  --dart-define=API_BASE_URL=https://api.yourdomain.com/api/v1
```

需 Apple Developer 账号，通过 Xcode 或 Transporter 上传 TestFlight。

## 上架检查清单

- [ ] ICP 备案完成
- [ ] 隐私政策与用户协议 URL 可访问
- [ ] App 内举报入口
- [ ] 年龄分级填写
- [ ] 截图与描述准备（中英文）
- [ ] 测试账号提供给审核人员
