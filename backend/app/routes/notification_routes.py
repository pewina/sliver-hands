from fastapi import APIRouter, Depends, HTTPException

from app.auth import current_user
from app.schemas.api import NotificationRegisterRequest
from app.database.supabase_client import get_supabase

router = APIRouter(dependencies=[Depends(current_user)], tags=["notifications"])

@router.post("/notifications/register")
async def register(request: NotificationRegisterRequest):
    try:
        get_supabase().table("device_tokens").upsert({
            "token": request.token,
            "platform": request.platform,
        }, on_conflict="token").execute()
        return {"ok": True}
    except Exception as exc:
        raise HTTPException(status_code=502, detail="Notification registration failed.") from exc
