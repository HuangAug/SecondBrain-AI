# Prompt 版本管理

所有 Prompt 定义在 `backend/app/llm/prompts.py`。

## v0.1 — AI 辅导人设（TUTOR_SYSTEM_PROMPT）

- **角色**：SecondBrain AI 学习导师「小脑」
- **风格**：分步讲解、苏格拉底引导、举例说明、鼓励为主
- **格式**：Markdown + LaTeX 公式
- **安全**：拒绝有害内容、拒绝考试作弊、作业引导思路不代写

## v0.1 — 学习计划生成（STUDY_PLAN_SYSTEM_PROMPT）

- **输出**：严格 JSON，`tasks` 数组含 `day_index`、`title`、`description`
- **约束**：天数与用户输入一致，难度循序渐进

## v0.1 — 文档 RAG（RAG_SYSTEM_PROMPT）

- **规则**：仅基于文档片段回答
- **无结果**：明确告知「资料中未找到」
- **引用**：`[来源: 第X页]` 格式

## 变更记录

| 版本 | 日期 | 变更 |
|------|------|------|
| v0.1 | 2026-06-09 | 初始三版 Prompt |
