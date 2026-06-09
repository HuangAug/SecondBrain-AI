import uuid

from sqlalchemy import select, text
from sqlalchemy.ext.asyncio import AsyncSession

from app.llm.provider import LLMProvider
from app.models.document import DocChunk


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
        .where(DocChunk.document_id == document_id, DocChunk.embedding.isnot(None))
        .order_by(DocChunk.embedding.cosine_distance(query_vector))
        .limit(top_k)
    )
    return list(result.scalars().all())


def format_context(chunks: list[DocChunk]) -> tuple[str, list[dict]]:
    if not chunks:
        return "", []

    context_parts = []
    citations = []
    for i, chunk in enumerate(chunks):
        source = f"第{chunk.page_number}页" if chunk.page_number else f"片段{chunk.chunk_index + 1}"
        context_parts.append(f"[{source}]\n{chunk.content}")
        citations.append({
            "index": i + 1,
            "source": source,
            "chunk_id": str(chunk.id),
        })

    return "\n\n---\n\n".join(context_parts), citations
