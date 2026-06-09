import uuid
from datetime import datetime

from pydantic import BaseModel, Field


class StudyPlanCreate(BaseModel):
    goal: str = Field(..., min_length=2, max_length=500)
    level: str = Field(default="beginner", pattern=r"^(beginner|intermediate|advanced)$")
    duration_days: int = Field(..., ge=1, le=90)


class PlanTaskResponse(BaseModel):
    id: uuid.UUID
    day_index: int
    title: str
    description: str
    completed: bool
    completed_at: datetime | None = None

    model_config = {"from_attributes": True}


class StudyPlanResponse(BaseModel):
    id: uuid.UUID
    goal: str
    level: str
    duration_days: int
    status: str
    created_at: datetime
    tasks: list[PlanTaskResponse] = []

    model_config = {"from_attributes": True}


class PlanProgressResponse(BaseModel):
    plan_id: uuid.UUID
    total_tasks: int
    completed_tasks: int
    progress_percent: float
    today_tasks: list[PlanTaskResponse] = []


class TaskCompleteRequest(BaseModel):
    completed: bool = True
