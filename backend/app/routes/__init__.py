from fastapi import APIRouter

from .ai_routes import router as ai_router
from .business_routes import router as business_router
from .notification_routes import router as notification_router
from .rag_routes import router as rag_router
from .voice_routes import router as voice_router

router = APIRouter()
router.include_router(ai_router)
router.include_router(business_router)
router.include_router(notification_router)
router.include_router(rag_router)
router.include_router(voice_router)
