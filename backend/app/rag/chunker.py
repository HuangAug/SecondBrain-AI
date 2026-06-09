import os
from pathlib import Path

import fitz  # PyMuPDF


def extract_text_from_file(file_path: str, file_type: str) -> list[dict]:
    """Extract text pages/chunks from supported file types."""
    if file_type == "pdf":
        return _extract_pdf(file_path)
    if file_type in ("txt", "md", "markdown"):
        return _extract_text(file_path)
    raise ValueError(f"Unsupported file type: {file_type}")


def _extract_pdf(file_path: str) -> list[dict]:
    pages = []
    doc = fitz.open(file_path)
    for i, page in enumerate(doc):
        text = page.get_text().strip()
        if text:
            pages.append({"content": text, "page_number": i + 1})
    doc.close()
    return pages


def _extract_text(file_path: str) -> list[dict]:
    with open(file_path, encoding="utf-8", errors="ignore") as f:
        content = f.read().strip()
    if not content:
        return []
    return [{"content": content, "page_number": None}]


def chunk_text(
    pages: list[dict],
    chunk_size: int = 500,
    overlap: int = 50,
) -> list[dict]:
    """Split pages into overlapping chunks."""
    chunks = []
    chunk_index = 0

    for page in pages:
        text = page["content"]
        page_number = page.get("page_number")
        start = 0
        while start < len(text):
            end = start + chunk_size
            chunk_content = text[start:end].strip()
            if chunk_content:
                chunks.append({
                    "content": chunk_content,
                    "page_number": page_number,
                    "chunk_index": chunk_index,
                })
                chunk_index += 1
            start = end - overlap
            if start >= len(text):
                break

    return chunks


def detect_file_type(filename: str) -> str:
    ext = Path(filename).suffix.lower().lstrip(".")
    mapping = {"pdf": "pdf", "txt": "txt", "md": "md", "markdown": "markdown"}
    return mapping.get(ext, "unknown")
