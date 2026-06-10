import uuid

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.llm.provider import LLMProvider
from app.models.document import DocChunk, Document


async def retrieve_chunks(
    db: AsyncSession,
    document_id: uuid.UUID,
    query: str,
    llm: LLMProvider,
    top_k: int = 5,
) -> list[DocChunk]:
    embeddings = await llm.embed([query])
    query_vector = embeddings[0]

    # pgvector cosine distance search
    result = await db.execute(
        select(DocChunk)
        .options(selectinload(DocChunk.document))
        .where(DocChunk.document_id == document_id, DocChunk.embedding.isnot(None))
        .order_by(DocChunk.embedding.cosine_distance(query_vector))
        .limit(top_k)
    )
    return list(result.scalars().all())


async def retrieve_user_chunks(
    db: AsyncSession,
    user_id: uuid.UUID,
    query: str,
    llm: LLMProvider,
    top_k: int = 5,
) -> list[DocChunk]:
    embeddings = await llm.embed([query])
    query_vector = embeddings[0]

    result = await db.execute(
        select(DocChunk)
        .join(DocChunk.document)
        .options(selectinload(DocChunk.document))
        .where(
            Document.user_id == user_id,
            Document.status == "ready",
            DocChunk.embedding.isnot(None),
        )
        .order_by(DocChunk.embedding.cosine_distance(query_vector))
        .limit(top_k)
    )
    return list(result.scalars().all())


async def has_ready_documents(db: AsyncSession, user_id: uuid.UUID) -> bool:
    result = await db.execute(
        select(Document.id)
        .where(Document.user_id == user_id, Document.status == "ready")
        .limit(1)
    )
    return result.scalar_one_or_none() is not None


def format_context(chunks: list[DocChunk]) -> tuple[str, list[dict]]:
    if not chunks:
        return "", []

    context_parts = []
    citations = []
    for i, chunk in enumerate(chunks):
        location = (
            f"第{chunk.page_number}页" if chunk.page_number else f"片段{chunk.chunk_index + 1}"
        )
        document = getattr(chunk, "document", None)
        source = f"{document.filename} · {location}" if document else location
        context_parts.append(f"[{source}]\n{chunk.content}")
        citations.append({
            "index": i + 1,
            "source": source,
            "chunk_id": str(chunk.id),
            "document_id": str(chunk.document_id),
        })

    return "\n\n---\n\n".join(context_parts), citations
