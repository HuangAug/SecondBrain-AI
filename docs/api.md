# SecondBrain API 文档

Base URL: `http://localhost:8000/api/v1`

交互式文档：http://localhost:8000/docs

## 认证

### POST /auth/send-code

发送手机验证码。

```json
{ "phone": "13800138000" }
```

开发模式固定验证码：`123456`

### POST /auth/verify

验证码登录，返回 JWT。

```json
{ "phone": "13800138000", "code": "123456" }
```

响应：

```json
{
  "access_token": "eyJ...",
  "token_type": "bearer",
  "user_id": "uuid",
  "nickname": "用户8000"
}
```

## 对话辅导

所有接口需 Header：`Authorization: Bearer <token>`

### GET /conversations

获取对话列表。Query: `type=chat|rag`

### POST /conversations

创建对话。

```json
{ "type": "chat", "title": "新对话", "document_id": null }
```

### GET /conversations/{id}

获取对话详情（含消息历史）。

### POST /chat/stream

SSE 流式对话。

```json
{ "message": "什么是微积分？", "conversation_id": "uuid或null" }
```

SSE 事件格式：

```
data: {"content": "片段", "done": false}
data: {"content": "", "done": true, "conversation_id": "uuid", "citations": null}
```

## 学习计划

### POST /plans

AI 生成学习计划。

```json
{ "goal": "掌握 Python 基础", "level": "beginner", "duration_days": 7 }
```

### GET /plans

计划列表。

### GET /plans/{id}

计划详情（含任务列表）。

### GET /plans/{id}/progress

进度统计与今日任务。

### PATCH /plans/tasks/{task_id}

打卡/取消打卡。

```json
{ "completed": true }
```

## 知识库（RAG）

### GET /documents

文档列表。

### GET /documents/{id}

文档详情与处理状态。

### POST /documents/upload

multipart/form-data 上传文件。支持 PDF、TXT、Markdown，最大 20MB。

处理完成后通过 `POST /conversations` 创建 `type=rag` 对话，再调用 `/chat/stream` 提问。
