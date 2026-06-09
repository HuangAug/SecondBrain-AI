from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.schemas.auth import SendCodeRequest, TokenResponse, VerifyCodeRequest
from app.services import auth_service

router = APIRouter(prefix="/auth", tags=["认证"])


@router.post("/send-code")
async def send_code(req: SendCodeRequest):
    await auth_service.send_verification_code(req.phone)
    return {"message": "验证码已发送", "dev_hint": "开发模式下验证码为 123456"}


@router.post("/verify", response_model=TokenResponse)
async def verify_code(req: VerifyCodeRequest, db: AsyncSession = Depends(get_db)):
    try:
        result = await auth_service.verify_code_and_login(req.phone, req.code, db)
        return result
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
