from fastapi import APIRouter, Depends, HTTPException

from app.auth import current_user
from app.schemas.api import RagAskRequest
from app.services.rag_service import get_rag

router = APIRouter(dependencies=[Depends(current_user)], tags=["rag"])

@router.post("/rag/ask")
async def ask(request: RagAskRequest):
    try:
        answer, sources = get_rag().ask(request.question, request.language)
        return {"answer": answer, "sources": sources}
    except Exception as exc:
        raise HTTPException(status_code=502, detail="RAG service failed.") from exc
