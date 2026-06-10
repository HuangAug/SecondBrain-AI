import uuid

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.llm.prompts import TUTOR_SYSTEM_PROMPT
from app.llm.provider import LLMProvider
from app.models.conversation import Conversation, Message
from app.models.user import User
from app.utils.content_filter import SENSITIVE_RESPONSE, is_content_safe


async def list_conversations(db: AsyncSession, user: User, conv_type: str | None = None) -> list[Conversation]:
    query = select(Conversation).where(Conversation.user_id == user.id)
    if conv_type:
        query = query.where(Conversation.type == conv_type)
    query = query.order_by(Conversation.updated_at.desc())
    result = await db.execute(query)
    return list(result.scalars().all())


async def get_conversation(db: AsyncSession, user: User, conversation_id: uuid.UUID) -> Conversation | None:
    result = await db.execute(
        select(Conversation)
        .options(selectinload(Conversation.messages))
        .where(Conversation.id == conversation_id, Conversation.user_id == user.id)
    )
    return result.scalar_one_or_none()


async def delete_conversation(db: AsyncSession, user: User, conversation_id: uuid.UUID) -> bool:
    conv = await get_conversation(db, user, conversation_id)
    if not conv:
        return False
    await db.delete(conv)
    await db.flush()
    return True


async def delete_conversations(
    db: AsyncSession,
    user: User,
    conversation_ids: list[uuid.UUID],
) -> int:
    result = await db.execute(
        select(Conversation)
        .options(selectinload(Conversation.messages))
        .where(Conversation.id.in_(conversation_ids), Conversation.user_id == user.id)
    )
    conversations = list(result.scalars().all())
    for conv in conversations:
        await db.delete(conv)
    await db.flush()
    return len(conversations)


async def create_conversation(
    db: AsyncSession,
    user: User,
    conv_type: str = "chat",
    title: str = "新对话",
    document_id: uuid.UUID | None = None,
) -> Conversation:
    conv = Conversation(user_id=user.id, type=conv_type, title=title, document_id=document_id)
    db.add(conv)
    await db.flush()
    return conv


def build_chat_messages(history: list[Message], user_message: str) -> list[dict[str, str]]:
    messages: list[dict[str, str]] = [{"role": "system", "content": TUTOR_SYSTEM_PROMPT}]
    for msg in history:
        if msg.role in ("user", "assistant"):
            messages.append({"role": msg.role, "content": msg.content})
    messages.append({"role": "user", "content": user_message})
    return messages


async def save_message(
    db: AsyncSession,
    conversation_id: uuid.UUID,
    role: str,
    content: str,
    citations: list | None = None,
) -> Message:
    msg = Message(conversation_id=conversation_id, role=role, content=content, citations=citations)
    db.add(msg)
    await db.flush()
    return msg


def check_message_safety(content: str) -> str | None:
    if not is_content_safe(content):
        return SENSITIVE_RESPONSE
    return None
