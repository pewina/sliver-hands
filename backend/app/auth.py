from fastapi import Depends, Header, HTTPException

from app.config import settings
from app.database.supabase_client import get_supabase

async def current_user(authorization: str | None = Header(default=None)) -> dict:
    if not settings.require_auth:
        return {"id": "demo-user"}

    if not authorization or not authorization.lower().startswith("bearer "):
        raise HTTPException(status_code=401, detail="Authentication required.")

    token = authorization.split(" ", 1)[1].strip()
    if not token:
        raise HTTPException(status_code=401, detail="Invalid access token.")

    try:
        user_response = get_supabase().auth.get_user(token)
        user = getattr(user_response, "user", None)
        if user is None:
            raise ValueError("No user")
        return {"id": user.id, "email": user.email}
    except Exception as exc:
        raise HTTPException(status_code=401, detail="Invalid or expired session.") from exc
