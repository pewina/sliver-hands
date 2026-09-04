# SilverHands API

This backend now supports the real Gemini + Supabase integration layer.

## Local setup

```powershell
cd backend
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
Copy-Item .env.example .env
```

Set `GEMINI_API_KEY`, `SUPABASE_URL`, and `SUPABASE_SERVICE_ROLE_KEY` in `.env`.

Run:

```powershell
uvicorn app.main:app --reload
```

Health check:

```text
http://127.0.0.1:8000/health
```

RAG indexing:

```powershell
python scripts/index_knowledge.py
```

Never put the Supabase service-role key or Gemini API key in Flutter. The Flutter app uses the Supabase publishable key; privileged database and AI operations stay on FastAPI.
