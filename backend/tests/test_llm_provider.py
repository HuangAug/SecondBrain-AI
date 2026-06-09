import asyncio

import pytest

from app.llm.provider import MockLLMProvider


@pytest.mark.asyncio
async def test_mock_chat_completion():
    llm = MockLLMProvider()
    result = await llm.chat_completion([{"role": "user", "content": "你好"}])
    assert "模拟回复" in result


@pytest.mark.asyncio
async def test_mock_chat_stream():
    llm = MockLLMProvider()
    chunks = []
    async for chunk in llm.chat_completion_stream([{"role": "user", "content": "你好"}]):
        chunks.append(chunk)
    assert len(chunks) > 0
    assert "模拟回复" in "".join(chunks)


@pytest.mark.asyncio
async def test_mock_embed():
    llm = MockLLMProvider()
    vectors = await llm.embed(["hello", "world"])
    assert len(vectors) == 2
    assert len(vectors[0]) == 1024
