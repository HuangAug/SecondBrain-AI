import json
import uuid
from datetime import datetime, timezone

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.llm.prompts import STUDY_PLAN_SYSTEM_PROMPT
from app.llm.provider import LLMProvider
from app.models.study_plan import PlanTask, StudyPlan
from app.models.user import User


async def generate_study_plan(
    db: AsyncSession,
    user: User,
    goal: str,
    level: str,
    duration_days: int,
    llm: LLMProvider,
) -> StudyPlan:
    user_prompt = (
        f"请为以下学习目标生成 {duration_days} 天的学习计划：\n"
        f"目标：{goal}\n"
        f"当前水平：{level}\n"
        f"请生成恰好 {duration_days} 天的任务。"
    )
    messages = [
        {"role": "system", "content": STUDY_PLAN_SYSTEM_PROMPT},
        {"role": "user", "content": user_prompt},
    ]
    raw = await llm.chat_completion(messages, temperature=0.5, json_mode=True)
    data = json.loads(raw)

    plan = StudyPlan(user_id=user.id, goal=goal, level=level, duration_days=duration_days)
    db.add(plan)
    await db.flush()

    for task_data in data.get("tasks", []):
        task = PlanTask(
            plan_id=plan.id,
            day_index=task_data["day_index"],
            title=task_data["title"],
            description=task_data.get("description", ""),
        )
        db.add(task)
    await db.flush()

    result = await db.execute(
        select(StudyPlan).options(selectinload(StudyPlan.tasks)).where(StudyPlan.id == plan.id)
    )
    return result.scalar_one()


async def list_plans(db: AsyncSession, user: User) -> list[StudyPlan]:
    result = await db.execute(
        select(StudyPlan)
        .options(selectinload(StudyPlan.tasks))
        .where(StudyPlan.user_id == user.id)
        .order_by(StudyPlan.created_at.desc())
    )
    return list(result.scalars().all())


async def get_plan(db: AsyncSession, user: User, plan_id: uuid.UUID) -> StudyPlan | None:
    result = await db.execute(
        select(StudyPlan)
        .options(selectinload(StudyPlan.tasks))
        .where(StudyPlan.id == plan_id, StudyPlan.user_id == user.id)
    )
    return result.scalar_one_or_none()


async def complete_task(
    db: AsyncSession,
    user: User,
    task_id: uuid.UUID,
    completed: bool,
) -> PlanTask | None:
    result = await db.execute(
        select(PlanTask)
        .join(StudyPlan)
        .where(PlanTask.id == task_id, StudyPlan.user_id == user.id)
    )
    task = result.scalar_one_or_none()
    if not task:
        return None
    task.completed = completed
    task.completed_at = datetime.now(timezone.utc) if completed else None
    await db.flush()
    return task


def calc_progress(plan: StudyPlan) -> dict:
    total = len(plan.tasks)
    completed = sum(1 for t in plan.tasks if t.completed)
    percent = (completed / total * 100) if total > 0 else 0.0

    # Day index based on creation date
    days_elapsed = (datetime.now(timezone.utc) - plan.created_at).days + 1
    today_tasks = [t for t in plan.tasks if t.day_index == days_elapsed]

    return {
        "plan_id": plan.id,
        "total_tasks": total,
        "completed_tasks": completed,
        "progress_percent": round(percent, 1),
        "today_tasks": today_tasks,
    }
