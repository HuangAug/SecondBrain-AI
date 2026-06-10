import uuid

from fastapi import APIRouter, BackgroundTasks, Depends, File, HTTPException, UploadFile
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import settings
from app.database import async_session, get_db
from app.models.user import User
from app.schemas.document import DocumentDeleteRequest, DocumentResponse, DocumentUploadResponse
from app.services import rag_service
from app.utils.auth import get_current_user

router = APIRouter(prefix="/documents", tags=["知识库"])


async def _process_in_background(document_id: uuid.UUID) -> None:
    async with async_session() as db:
        try:
            await rag_service.process_document(db, document_id)
            await db.commit()
        except Exception:
            await db.rollback()


@router.get("", response_model=list[DocumentResponse])
async def list_documents(
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await rag_service.list_documents(db, user)


@router.get("/{document_id}", response_model=DocumentResponse)
async def get_document(
    document_id: uuid.UUID,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    doc = await rag_service.get_document(db, user, document_id)
    if not doc:
        raise HTTPException(status_code=404, detail="文档不存在")
    return doc


@router.delete("/{document_id}", status_code=204)
async def delete_document(
    document_id: uuid.UUID,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    deleted = await rag_service.delete_document(db, user, document_id)
    if not deleted:
        raise HTTPException(status_code=404, detail="文档不存在")


@router.post("/bulk-delete")
async def bulk_delete_documents(
    req: DocumentDeleteRequest,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    deleted_count = await rag_service.delete_documents(db, user, req.ids)
    return {"deleted_count": deleted_count}


@router.post("/upload", response_model=DocumentUploadResponse)
async def upload_document(
    background_tasks: BackgroundTasks,
    file: UploadFile = File(...),
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    if not file.filename:
        raise HTTPException(status_code=400, detail="文件名不能为空")

    content = await file.read()
    max_bytes = settings.max_upload_size_mb * 1024 * 1024
    if len(content) > max_bytes:
        raise HTTPException(status_code=400, detail=f"文件大小不能超过 {settings.max_upload_size_mb}MB")

    try:
        doc = await rag_service.save_upload(db, user, file.filename, content)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))

    background_tasks.add_task(_process_in_background, doc.id)

    return DocumentUploadResponse(
        id=doc.id,
        filename=doc.filename,
        status=doc.status,
        message="文件上传成功，正在后台处理",
    )
