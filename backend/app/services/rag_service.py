import os
import uuid

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import settings
from app.llm.prompts import RAG_SYSTEM_PROMPT
from app.llm.provider import LLMProvider, get_embedding_provider
from app.models.conversation import Conversation, Message
from app.models.document import DocChunk, Document
from app.models.user import User
from app.rag.chunker import chunk_text, detect_file_type, extract_text_from_file
from app.rag.retriever import (
    format_context,
    has_ready_documents,
    retrieve_chunks,
    retrieve_user_chunks,
)


EMPTY_KNOWLEDGE_BASE_RESPONSE = "当前知识库还没有可用文档。请先上传文档，并等待处理完成后再提问。"


async def save_upload(
    db: AsyncSession,
    user: User,
    filename: str,
    file_bytes: bytes,
) -> Document:
    file_type = detect_file_type(filename)
    if file_type == "unknown":
        raise ValueError("仅支持 PDF、TXT、Markdown、Word 文件")

    os.makedirs(settings.upload_dir, exist_ok=True)
    doc_id = uuid.uuid4()
    safe_name = f"{doc_id}_{filename}"
    file_path = os.path.join(settings.upload_dir, safe_name)

    with open(file_path, "wb") as f:
        f.write(file_bytes)

    doc = Document(
        id=doc_id,
        user_id=user.id,
        filename=filename,
        file_type=file_type,
        file_path=file_path,
        status="pending",
    )
    db.add(doc)
    await db.flush()
    return doc


async def process_document(db: AsyncSession, document_id: uuid.UUID) -> None:
    result = await db.execute(select(Document).where(Document.id == document_id))
    doc = result.scalar_one_or_none()
    if not doc:
        return

    doc.status = "processing"
    await db.flush()

    try:
        pages = extract_text_from_file(doc.file_path, doc.file_type)
        chunks_data = chunk_text(pages)
        if not chunks_data:
            doc.status = "failed"
            doc.error_message = "未能从文件中提取文本内容"
            await db.flush()
            return

        embedder = get_embedding_provider()
        texts = [c["content"] for c in chunks_data]
        batch_size = 20
        all_embeddings: list[list[float]] = []
        for i in range(0, len(texts), batch_size):
            batch = texts[i : i + batch_size]
            embeddings = await embedder.embed(batch)
            all_embeddings.extend(embeddings)

        for chunk_data, embedding in zip(chunks_data, all_embeddings):
            chunk = DocChunk(
                document_id=doc.id,
                content=chunk_data["content"],
                page_number=chunk_data.get("page_number"),
                chunk_index=chunk_data["chunk_index"],
                embedding=embedding,
            )
            db.add(chunk)

        doc.status = "ready"
        doc.chunk_count = len(chunks_data)
        await db.flush()
    except Exception as e:
        doc.status = "failed"
        doc.error_message = str(e)
        await db.flush()


async def list_documents(db: AsyncSession, user: User) -> list[Document]:
    result = await db.execute(
        select(Document).where(Document.user_id == user.id).order_by(Document.created_at.desc())
    )
    return list(result.scalars().all())


async def get_document(db: AsyncSession, user: User, document_id: uuid.UUID) -> Document | None:
    result = await db.execute(
        select(Document).where(Document.id == document_id, Document.user_id == user.id)
    )
    return result.scalar_one_or_none()


async def delete_document(db: AsyncSession, user: User, document_id: uuid.UUID) -> bool:
    doc = await get_document(db, user, document_id)
    if not doc:
        return False

    result = await db.execute(
        select(Conversation).where(
            Conversation.user_id == user.id,
            Conversation.document_id == document_id,
        )
    )
    for conv in result.scalars().all():
        conv.document_id = None

    file_path = doc.file_path
    await db.delete(doc)
    await db.flush()

    if file_path and os.path.exists(file_path):
        os.remove(file_path)

    return True


async def delete_documents(
    db: AsyncSession,
    user: User,
    document_ids: list[uuid.UUID],
) -> int:
    deleted_count = 0
    for document_id in document_ids:
        deleted = await delete_document(db, user, document_id)
        if deleted:
            deleted_count += 1
    return deleted_count


async def build_rag_messages(
    db: AsyncSession,
    document_id: uuid.UUID,
    user_message: str,
    llm: LLMProvider,
    history: list[Message] | None = None,
) -> tuple[list[dict[str, str]], list[dict]]:
    chunks = await retrieve_chunks(db, document_id, user_message, llm)
    context, citations = format_context(chunks)

    if not context:
        system = RAG_SYSTEM_PROMPT + "\n\n注意：未检索到相关文档片段。"
        user_content = user_message
    else:
        system = RAG_SYSTEM_PROMPT
        user_content = f"参考文档片段：\n\n{context}\n\n用户问题：{user_message}"

    messages: list[dict[str, str]] = [{"role": "system", "content": system}]
    if history:
        for msg in history:
            if msg.role in ("user", "assistant"):
                messages.append({"role": msg.role, "content": msg.content})
    messages.append({"role": "user", "content": user_content})
    return messages, citations


async def build_user_kb_rag_messages(
    db: AsyncSession,
    user: User,
    user_message: str,
    llm: LLMProvider,
    history: list[Message] | None = None,
) -> tuple[list[dict[str, str]], list[dict]]:
    chunks = await retrieve_user_chunks(db, user.id, user_message, llm)
    context, citations = format_context(chunks)

    if not context:
        system = RAG_SYSTEM_PROMPT + "\n\n注意：当前账号知识库未检索到相关文档片段。"
        user_content = user_message
    else:
        system = RAG_SYSTEM_PROMPT
        user_content = f"参考知识库片段：\n\n{context}\n\n用户问题：{user_message}"

    messages: list[dict[str, str]] = [{"role": "system", "content": system}]
    if history:
        for msg in history:
            if msg.role in ("user", "assistant"):
                messages.append({"role": msg.role, "content": msg.content})
    messages.append({"role": "user", "content": user_content})
    return messages, citations


async def user_has_ready_documents(db: AsyncSession, user: User) -> bool:
    return await has_ready_documents(db, user.id)
