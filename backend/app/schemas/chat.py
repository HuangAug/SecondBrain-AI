import uuid
from datetime import datetime

from pydantic import BaseModel, Field


class ConversationCreate(BaseModel):
    type: str = Field(default="chat", pattern=r"^(chat|rag)$")
    title: str = Field(default="新对话", max_length=200)
    document_id: uuid.UUID | None = None


class MessageResponse(BaseModel):
    id: uuid.UUID
    role: str
    content: str
    citations: list | None = None
    created_at: datetime

    model_config = {"from_attributes": True}


class ConversationResponse(BaseModel):
    id: uuid.UUID
    type: str
    title: str
    document_id: uuid.UUID | None = None
    created_at: datetime
    updated_at: datetime
    messages: list[MessageResponse] = []

    model_config = {"from_attributes": True}


class ConversationListItem(BaseModel):
    id: uuid.UUID
    type: str
    title: str
    created_at: datetime
    updated_at: datetime

    model_config = {"from_attributes": True}


class ChatRequest(BaseModel):
    message: str = Field(..., min_length=1, max_length=4000)
    conversation_id: uuid.UUID | None = None
