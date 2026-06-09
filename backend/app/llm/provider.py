from abc import ABC, abstractmethod
from collections.abc import AsyncGenerator
from typing import Any

import httpx

from app.config import settings


class LLMProvider(ABC):
    @abstractmethod
    async def chat_completion(
        self,
        messages: list[dict[str, str]],
        temperature: float = 0.7,
        json_mode: bool = False,
    ) -> str:
        pass

    @abstractmethod
    async def chat_completion_stream(
        self,
        messages: list[dict[str, str]],
        temperature: float = 0.7,
    ) -> AsyncGenerator[str, None]:
        pass

    @abstractmethod
    async def embed(self, texts: list[str]) -> list[list[float]]:
        pass


class OpenAICompatibleProvider(LLMProvider):
    def __init__(self, api_key: str, base_url: str, model: str, embedding_model: str | None = None):
        self.api_key = api_key
        self.base_url = base_url.rstrip("/")
        self.model = model
        self.embedding_model = embedding_model

    def _headers(self) -> dict[str, str]:
        return {
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json",
        }

    async def chat_completion(
        self,
        messages: list[dict[str, str]],
        temperature: float = 0.7,
        json_mode: bool = False,
    ) -> str:
        payload: dict[str, Any] = {
            "model": self.model,
            "messages": messages,
            "temperature": temperature,
        }
        if json_mode:
            payload["response_format"] = {"type": "json_object"}

        async with httpx.AsyncClient(timeout=120.0) as client:
            resp = await client.post(
                f"{self.base_url}/chat/completions",
                headers=self._headers(),
                json=payload,
            )
            resp.raise_for_status()
            data = resp.json()
            return data["choices"][0]["message"]["content"]

    async def chat_completion_stream(
        self,
        messages: list[dict[str, str]],
        temperature: float = 0.7,
    ) -> AsyncGenerator[str, None]:
        payload = {
            "model": self.model,
            "messages": messages,
            "temperature": temperature,
            "stream": True,
        }

        async with httpx.AsyncClient(timeout=120.0) as client:
            async with client.stream(
                "POST",
                f"{self.base_url}/chat/completions",
                headers=self._headers(),
                json=payload,
            ) as response:
                response.raise_for_status()
                async for line in response.aiter_lines():
                    if not line.startswith("data: "):
                        continue
                    data_str = line[6:]
                    if data_str.strip() == "[DONE]":
                        break
                    import json

                    chunk = json.loads(data_str)
                    delta = chunk.get("choices", [{}])[0].get("delta", {})
                    content = delta.get("content")
                    if content:
                        yield content

    async def embed(self, texts: list[str]) -> list[list[float]]:
        if not self.embedding_model:
            raise ValueError("Embedding model not configured for this provider")

        async with httpx.AsyncClient(timeout=60.0) as client:
            resp = await client.post(
                f"{self.base_url}/embeddings",
                headers=self._headers(),
                json={"model": self.embedding_model, "input": texts},
            )
            resp.raise_for_status()
            data = resp.json()
            return [item["embedding"] for item in data["data"]]


class MockLLMProvider(LLMProvider):
    """Fallback when no API key is configured (local dev)."""

    async def chat_completion(
        self,
        messages: list[dict[str, str]],
        temperature: float = 0.7,
        json_mode: bool = False,
    ) -> str:
        if json_mode:
            return (
                '{"tasks": [{"day_index": 1, "title": "了解基础概念", "description": "阅读入门资料"}, '
                '{"day_index": 2, "title": "动手练习", "description": "完成练习题"}]}'
            )
        last = messages[-1]["content"] if messages else ""
        return f"（模拟回复）这是一个很好的问题！关于「{last[:50]}」，让我为你分步讲解……"

    async def chat_completion_stream(
        self,
        messages: list[dict[str, str]],
        temperature: float = 0.7,
    ) -> AsyncGenerator[str, None]:
        text = await self.chat_completion(messages, temperature)
        for char in text:
            yield char

    async def embed(self, texts: list[str]) -> list[list[float]]:
        import hashlib

        def pseudo_embed(text: str) -> list[float]:
            h = hashlib.sha256(text.encode()).digest()
            vec = []
            for i in range(1024):
                vec.append((h[i % len(h)] / 255.0) * 2 - 1)
            return vec

        return [pseudo_embed(t) for t in texts]


def get_llm_provider(provider_name: str | None = None) -> LLMProvider:
    name = provider_name or settings.default_llm_provider

    if name == "deepseek" and settings.deepseek_api_key:
        return OpenAICompatibleProvider(
            api_key=settings.deepseek_api_key,
            base_url=settings.deepseek_base_url,
            model=settings.deepseek_model,
        )
    if name == "qwen" and settings.qwen_api_key:
        return OpenAICompatibleProvider(
            api_key=settings.qwen_api_key,
            base_url=settings.qwen_base_url,
            model=settings.qwen_model,
            embedding_model=settings.qwen_embedding_model,
        )

    return MockLLMProvider()


def get_embedding_provider() -> LLMProvider:
    if settings.qwen_api_key:
        return OpenAICompatibleProvider(
            api_key=settings.qwen_api_key,
            base_url=settings.qwen_base_url,
            model=settings.qwen_model,
            embedding_model=settings.qwen_embedding_model,
        )
    return MockLLMProvider()
