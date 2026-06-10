import os
from pathlib import Path
from zipfile import BadZipFile, ZipFile
import xml.etree.ElementTree as ET

import fitz  # PyMuPDF


def extract_text_from_file(file_path: str, file_type: str) -> list[dict]:
    """Extract text pages/chunks from supported file types."""
    if file_type == "pdf":
        return _extract_pdf(file_path)
    if file_type in ("txt", "md", "markdown"):
        return _extract_text(file_path)
    if file_type == "docx":
        return _extract_docx(file_path)
    if file_type == "doc":
        return _extract_doc(file_path)
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


def _extract_docx(file_path: str) -> list[dict]:
    try:
        with ZipFile(file_path) as archive:
            xml_bytes = archive.read("word/document.xml")
    except (BadZipFile, KeyError) as e:
        raise ValueError("无法解析 Word 文档，请确认文件是有效的 .docx") from e

    root = ET.fromstring(xml_bytes)
    namespace = {"w": "http://schemas.openxmlformats.org/wordprocessingml/2006/main"}
    paragraphs = []

    for paragraph in root.findall(".//w:body/w:p", namespace):
        parts = []
        for node in paragraph.iter():
            tag = node.tag.rsplit("}", 1)[-1]
            if tag == "t" and node.text:
                parts.append(node.text)
            elif tag == "tab":
                parts.append("\t")
            elif tag in ("br", "cr"):
                parts.append("\n")
        text = "".join(parts).strip()
        if text:
            paragraphs.append(text)

    content = "\n".join(paragraphs).strip()
    if not content:
        return []
    return [{"content": content, "page_number": None}]


def _extract_doc(file_path: str) -> list[dict]:
    with open(file_path, "rb") as f:
        data = f.read()

    # Legacy .doc is a binary format. This best-effort pass recovers readable text
    # without requiring system tools such as antiword/catdoc.
    candidates = [
        data.decode("utf-16le", errors="ignore"),
        data.decode("latin-1", errors="ignore"),
    ]
    content = max((_clean_binary_text(text) for text in candidates), key=len).strip()
    if not content:
        return []
    return [{"content": content, "page_number": None}]


def _clean_binary_text(text: str) -> str:
    lines = []
    for line in text.splitlines():
        cleaned = "".join(ch for ch in line if ch == "\t" or ch == " " or ch.isprintable())
        cleaned = " ".join(cleaned.split())
        if len(cleaned) >= 2:
            lines.append(cleaned)
    return "\n".join(lines)


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
    mapping = {
        "pdf": "pdf",
        "txt": "txt",
        "md": "md",
        "markdown": "markdown",
        "docx": "docx",
        "doc": "doc",
    }
    return mapping.get(ext, "unknown")
