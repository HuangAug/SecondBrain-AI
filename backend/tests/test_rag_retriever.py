import uuid
from types import SimpleNamespace

import pytest
from sqlalchemy.dialects import postgresql

from app.rag.retriever import format_context, retrieve_user_chunks


class FakeLLM:
    async def embed(self, texts: list[str]) -> list[list[float]]:
        return [[0.1] * 1024 for _ in texts]


class FakeScalars:
    def all(self) -> list:
        return []


class FakeResult:
    def scalars(self) -> FakeScalars:
        return FakeScalars()


class FakeSession:
    def __init__(self) -> None:
        self.statement = None

    async def execute(self, statement):
        self.statement = statement
        return FakeResult()


@pytest.mark.asyncio
async def test_retrieve_user_chunks_scopes_query_to_current_user_ready_documents():
    db = FakeSession()
    user_id = uuid.uuid4()

    chunks = await retrieve_user_chunks(db, user_id, "线性代数怎么复习？", FakeLLM())

    assert chunks == []
    assert db.statement is not None
    compiled = str(db.statement.compile(dialect=postgresql.dialect()))
    assert "JOIN documents" in compiled
    assert "documents.user_id" in compiled
    assert "documents.status" in compiled
    assert "doc_chunks.embedding IS NOT NULL" in compiled


def test_format_context_includes_document_filename_in_citations():
    document_id = uuid.uuid4()
    chunk = SimpleNamespace(
        id=uuid.uuid4(),
        document_id=document_id,
        document=SimpleNamespace(filename="math-notes.pdf"),
        page_number=3,
        chunk_index=0,
        content="矩阵乘法需要满足前一矩阵列数等于后一矩阵行数。",
    )

    context, citations = format_context([chunk])

    assert "[math-notes.pdf · 第3页]" in context
    assert citations == [
        {
            "index": 1,
            "source": "math-notes.pdf · 第3页",
            "chunk_id": str(chunk.id),
            "document_id": str(document_id),
        }
    ]
