from zipfile import ZipFile

import pytest

from app.rag.chunker import detect_file_type, extract_text_from_file


def test_detect_word_file_types():
    assert detect_file_type("notes.docx") == "docx"
    assert detect_file_type("legacy.DOC") == "doc"


def test_extract_docx_text(tmp_path):
    file_path = tmp_path / "notes.docx"
    document_xml = """<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:body>
    <w:p><w:r><w:t>第一段内容</w:t></w:r></w:p>
    <w:p><w:r><w:t>第二段内容</w:t></w:r></w:p>
  </w:body>
</w:document>
"""

    with ZipFile(file_path, "w") as archive:
        archive.writestr("word/document.xml", document_xml)

    pages = extract_text_from_file(str(file_path), "docx")

    assert pages == [{"content": "第一段内容\n第二段内容", "page_number": None}]


def test_extract_invalid_docx_raises_value_error(tmp_path):
    file_path = tmp_path / "broken.docx"
    file_path.write_bytes(b"not a zip")

    with pytest.raises(ValueError, match="无法解析 Word 文档"):
        extract_text_from_file(str(file_path), "docx")
