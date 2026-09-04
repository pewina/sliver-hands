from fastapi import FastAPI, Request
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from app.config import settings
from app.routes import router

app = FastAPI(
    title="SilverHands API",
    version="1.0.0",
    description="AI-powered livelihood marketplace backend.",
)

# Local development CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=list(settings.cors_origins),
    allow_origin_regex=r"https?://(localhost|127\.0\.0\.1)(:\d+)?$",
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(router, prefix="/api")


@app.get("/health", tags=["health"])
async def health_check():
    return {
        "status": "ok",
        "gemini_configured": bool(settings.gemini_api_key),
        "elevenlabs_configured": bool(settings.elevenlabs_api_key),
        "supabase_configured": bool(
            settings.supabase_url and settings.supabase_service_role_key
        ),
    }


@app.exception_handler(RequestValidationError)
async def validation_error_handler(_: Request, exc: RequestValidationError):
    return JSONResponse(
        status_code=422,
        content={
            "detail": "Please check the information you entered.",
            "errors": exc.errors(),
        },
    )


@app.exception_handler(Exception)
async def unhandled_error_handler(_: Request, __: Exception):
    return JSONResponse(
        status_code=500,
        content={
            "detail": "Something went wrong. Please check the server logs."
        },
    )