# SecondBrain

双端（iOS / Android）AI 学习助手，基于 Flutter + FastAPI。

## 功能模块

- **AI 对话辅导** — 多轮答疑、分步讲解、苏格拉底式引导
- **学习计划** — AI 生成计划、每日打卡、进度追踪
- **文档 RAG** — 上传 PDF/笔记，基于个人资料智能问答

## 项目结构

```
SecondBrain/
├── mobile/     # Flutter 客户端
├── backend/    # FastAPI 后端
└── docs/       # API 文档、Prompt、合规清单
```

## 快速开始

### 后端

```bash
cd backend
cp .env.example .env   # 填入 API Key
docker compose up -d   # 启动 PostgreSQL + Redis
pip install -r requirements.txt
uvicorn app.main:app --reload --port 8000
```

API 文档：http://localhost:8000/docs

### 移动端

```bash
cd mobile
flutter pub get
flutter run
```

## 环境要求

- Python 3.11+
- Flutter 3.x
- Docker & Docker Compose
- DeepSeek / 通义千问 API Key
