# SecondBrain Mobile

Flutter 客户端。

## 环境

- Flutter 3.x SDK
- Android Studio / Xcode（真机调试）

## 运行

```bash
flutter pub get

# Android 模拟器（API 地址 10.0.2.2 指向本机）
flutter run

# iOS 模拟器
flutter run --dart-define=API_BASE_URL=http://localhost:8000/api/v1

# 指定后端地址
flutter run --dart-define=API_BASE_URL=https://api.yourdomain.com/api/v1
```

## 首次使用

1. 确保后端已启动（见根目录 README）
2. 使用任意手机号登录
3. 开发模式验证码：`123456`

## 目录结构

```
lib/
├── core/           # 主题、路由、网络、存储
├── features/
│   ├── auth/       # 登录
│   ├── chat/       # AI 对话
│   ├── study_plan/ # 学习计划
│   ├── knowledge/  # 文档 RAG
│   ├── home/       # 首页
│   └── profile/    # 我的
└── main.dart
```
