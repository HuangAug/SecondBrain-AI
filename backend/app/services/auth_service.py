import random

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import settings
from app.models.user import User
from app.utils.auth import create_access_token
from app.utils.redis_client import get_redis

DEV_CODE = "123456"


async def send_verification_code(phone: str) -> None:
    redis = await get_redis()
    if settings.dev_mode:
        code = DEV_CODE
    else:
        code = f"{random.randint(100000, 999999)}"
        # TODO: integrate Aliyun SMS in production
    await redis.setex(f"sms:{phone}", 300, code)


async def verify_code_and_login(phone: str, code: str, db: AsyncSession) -> dict:
    redis = await get_redis()
    stored = await redis.get(f"sms:{phone}")

    if settings.dev_mode and code == DEV_CODE:
        pass
    elif stored != code:
        raise ValueError("验证码错误或已过期")

    result = await db.execute(select(User).where(User.phone == phone))
    user = result.scalar_one_or_none()
    if not user:
        user = User(phone=phone, nickname=f"用户{phone[-4:]}")
        db.add(user)
        await db.flush()

    token = create_access_token(user.id)
    return {
        "access_token": token,
        "token_type": "bearer",
        "user_id": str(user.id),
        "nickname": user.nickname,
    }
