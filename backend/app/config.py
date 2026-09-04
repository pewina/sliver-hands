import os
from dataclasses import dataclass
from pathlib import Path
from dotenv import load_dotenv

# Always load the backend/.env file, regardless of the directory from which
# uvicorn is launched. Existing process environment variables take priority.
BACKEND_DIR = Path(__file__).resolve().parents[1]
ENV_FILE = BACKEND_DIR / ".env"
load_dotenv(dotenv_path=ENV_FILE, override=False)
print(f"CONFIG: backend env file = {ENV_FILE}")
print(f"CONFIG: .env exists = {ENV_FILE.exists()}")
print(f"CONFIG: ElevenLabs configured = {bool(os.getenv('ELEVENLABS_API_KEY'))}")

# Gemini 2.5 Flash is retired for this project environment. If an older
# local .env still contains it, automatically move to the current stable model.
_configured_gemini_model = os.getenv("GEMINI_MODEL", "").strip()
if not _configured_gemini_model or _configured_gemini_model in {
    "gemini-2.5-flash",
    "gemini-2.5-flash-001",
}:
    _configured_gemini_model = "gemini-3.6-flash"

@dataclass(frozen=True)
class Settings:
    environment: str = os.getenv("SILVERHANDS_ENV", "development")
    require_auth: bool = os.getenv("SILVERHANDS_REQUIRE_AUTH", "false").lower() == "true"
    gemini_api_key: str | None = os.getenv("GEMINI_API_KEY")
    elevenlabs_api_key: str | None = os.getenv("ELEVENLABS_API_KEY")
    gemini_model: str = _configured_gemini_model
    embedding_model: str = os.getenv("GEMINI_EMBEDDING_MODEL", "gemini-embedding-2")
    embedding_dim: int = int(os.getenv("GEMINI_EMBEDDING_DIM", "768"))
    supabase_url: str | None = os.getenv("SUPABASE_URL")
    supabase_service_role_key: str | None = os.getenv("SUPABASE_SERVICE_ROLE_KEY")
    cors_origins: tuple[str, ...] = tuple(
        x.strip() for x in os.getenv("CORS_ORIGINS", "").split(",") if x.strip()
    )
    firebase_service_account_json: str | None = os.getenv("FIREBASE_SERVICE_ACCOUNT_JSON")

settings = Settings()
