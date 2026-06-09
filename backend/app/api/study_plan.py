import uuid

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.llm.provider import get_llm_provider
from app.models.user import User
from app.schemas.study_plan import (
    PlanProgressResponse,
    PlanTaskResponse,
    StudyPlanCreate,
    StudyPlanResponse,
    TaskCompleteRequest,
)
from app.services import study_plan_service
from app.utils.auth import get_current_user

router = APIRouter(prefix="/plans", tags=["学习计划"])


@router.post("", response_model=StudyPlanResponse)
async def create_plan(
    req: StudyPlanCreate,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    llm = get_llm_provider()
    plan = await study_plan_service.generate_study_plan(
        db, user, req.goal, req.level, req.duration_days, llm
    )
    return plan


@router.get("", response_model=list[StudyPlanResponse])
async def list_plans(
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await study_plan_service.list_plans(db, user)


@router.get("/{plan_id}", response_model=StudyPlanResponse)
async def get_plan(
    plan_id: uuid.UUID,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    plan = await study_plan_service.get_plan(db, user, plan_id)
    if not plan:
        raise HTTPException(status_code=404, detail="计划不存在")
    return plan


@router.get("/{plan_id}/progress", response_model=PlanProgressResponse)
async def get_progress(
    plan_id: uuid.UUID,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    plan = await study_plan_service.get_plan(db, user, plan_id)
    if not plan:
        raise HTTPException(status_code=404, detail="计划不存在")
    progress = study_plan_service.calc_progress(plan)
    return PlanProgressResponse(
        plan_id=progress["plan_id"],
        total_tasks=progress["total_tasks"],
        completed_tasks=progress["completed_tasks"],
        progress_percent=progress["progress_percent"],
        today_tasks=[PlanTaskResponse.model_validate(t) for t in progress["today_tasks"]],
    )


@router.patch("/tasks/{task_id}", response_model=PlanTaskResponse)
async def complete_task(
    task_id: uuid.UUID,
    req: TaskCompleteRequest,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    task = await study_plan_service.complete_task(db, user, task_id, req.completed)
    if not task:
        raise HTTPException(status_code=404, detail="任务不存在")
    return task
