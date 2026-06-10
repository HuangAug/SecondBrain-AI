import json
import uuid

from fastapi import APIRouter, Depends, HTTPException
from fastapi.responses import StreamingResponse
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import async_session, get_db
from app.llm.provider import get_llm_provider
from app.models.user import User
from app.schemas.chat import (
    ChatRequest,
    ConversationCreate,
    ConversationListItem,
    ConversationResponse,
    MessageResponse,
)
from app.services import chat_service, rag_service
from app.utils.auth import get_current_user

router = APIRouter(tags=["对话"])


@router.get("/conversations", response_model=list[ConversationListItem])
async def list_conversations(
    type: str | None = None,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    convs = await chat_service.list_conversations(db, user, type)
    return convs


@router.post("/conversations", response_model=ConversationResponse)
async def create_conversation(
    req: ConversationCreate,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    if req.document_id:
        doc = await rag_service.get_document(db, user, req.document_id)
        if not doc:
            raise HTTPException(status_code=404, detail="文档不存在")
        if doc.status != "ready":
            raise HTTPException(status_code=400, detail="文档尚未处理完成")

    conv = await chat_service.create_conversation(
        db, user, req.type, req.title, req.document_id
    )
    return ConversationResponse(
        id=conv.id,
        type=conv.type,
        title=conv.title,
        document_id=conv.document_id,
        created_at=conv.created_at,
        updated_at=conv.updated_at,
        messages=[],
    )


@router.get("/conversations/{conversation_id}", response_model=ConversationResponse)
async def get_conversation(
    conversation_id: uuid.UUID,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    conv = await chat_service.get_conversation(db, user, conversation_id)
    if not conv:
        raise HTTPException(status_code=404, detail="对话不存在")
    return conv


@router.post("/chat/stream")
async def chat_stream(
    req: ChatRequest,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    safety = chat_service.check_message_safety(req.message)
    if safety:
        async def blocked_stream():
            yield f"data: {json.dumps({'content': safety, 'done': True}, ensure_ascii=False)}\n\n"

        return StreamingResponse(blocked_stream(), media_type="text/event-stream")

    history: list = []
    if req.conversation_id:
        conv = await chat_service.get_conversation(db, user, req.conversation_id)
        if not conv:
            raise HTTPException(status_code=404, detail="对话不存在")
        history = list(conv.messages)
    else:
        title = req.message[:30] + ("..." if len(req.message) > 30 else "")
        conv = await chat_service.create_conversation(db, user, "chat", title)

    await chat_service.save_message(db, conv.id, "user", req.message)

    conv_id = conv.id

    if conv.type == "rag" and not conv.document_id:
        has_documents = await rag_service.user_has_ready_documents(db, user)
        if not has_documents:
            empty_response = rag_service.EMPTY_KNOWLEDGE_BASE_RESPONSE

            async def empty_kb_stream():
                async with async_session() as stream_db:
                    await chat_service.save_message(stream_db, conv_id, "assistant", empty_response, [])
                    await stream_db.commit()

                payload = {
                    "content": empty_response,
                    "done": True,
                    "conversation_id": str(conv_id),
                    "citations": [],
                }
                yield f"data: {json.dumps(payload, ensure_ascii=False)}\n\n"

            return StreamingResponse(empty_kb_stream(), media_type="text/event-stream")

    llm = get_llm_provider()

    if conv.type == "rag":
        if conv.document_id:
            messages, citations = await rag_service.build_rag_messages(
                db, conv.document_id, req.message, llm, history
            )
        else:
            messages, citations = await rag_service.build_user_kb_rag_messages(
                db, user, req.message, llm, history
            )
    else:
        messages = chat_service.build_chat_messages(history, req.message)
        citations = None

    async def event_stream():
        full_response = ""
        try:
            async for chunk in llm.chat_completion_stream(messages):
                full_response += chunk
                yield f"data: {json.dumps({'content': chunk, 'done': False}, ensure_ascii=False)}\n\n"
        except Exception as e:
            error_msg = f"AI 服务暂时不可用：{e}"
            yield f"data: {json.dumps({'content': error_msg, 'done': True, 'error': True}, ensure_ascii=False)}\n\n"
            return

        async with async_session() as stream_db:
            await chat_service.save_message(stream_db, conv_id, "assistant", full_response, citations)
            await stream_db.commit()

        yield f"data: {json.dumps({'content': '', 'done': True, 'conversation_id': str(conv_id), 'citations': citations}, ensure_ascii=False)}\n\n"

    return StreamingResponse(event_stream(), media_type="text/event-stream")
