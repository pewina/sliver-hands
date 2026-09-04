# SilverHands

SilverHands is an AI-powered matchmaking and collaboration platform built with Flutter, FastAPI, Supabase, and Gemini. It empowers skilled workers by connecting them with opportunities based on AI-extracted skills, real-world distance, and verified profiles. It also features a "Family Guide" trusted assistance workflow, enabling family members to safely assist users in managing their profiles and opportunities.

## 🌟 Architecture & Tech Stack

- **Frontend:** Flutter (Mobile/Web)
- **Backend:** FastAPI (Python)
- **Database & Services:** Supabase (PostgreSQL, Auth, Storage, pgvector)
- **AI & ML:** Google Gemini (Voice understanding, skill extraction, embeddings, RAG) + ElevenLabs (Voice)
- **Other Integrations:** Firebase (Notifications), Google Maps (Location scoring)

---

## 🧠 Retrieval-Augmented Generation (RAG) in SilverHands

### Where is RAG Used?
RAG is integrated deeply into the backend through the FastAPI `rag_service`. 
- **Database:** Supabase uses `pgvector` to store vector embeddings in the `knowledge_documents.embedding` column.
- **Backend:** The script `backend/scripts/seed_knowledge.py` handles generating Gemini embeddings and indexing them into Supabase `pgvector`.
- **API Endpoint:** The backend exposes `POST /api/rag/ask` which powers the frontend's conversational capabilities.

### What is the Purpose of RAG Here?
The purpose of RAG in SilverHands is to allow the application to intelligently answer user questions using *dynamic, domain-specific context* rather than relying solely on the LLM's baseline knowledge. 
1. **Embedding Generation:** When knowledge documents (e.g., job criteria, support articles, platform rules) are added, Gemini Embedding 2 (`gemini-embedding-2`) converts the text into 768-dimensional vectors.
2. **Context Retrieval:** When a user asks a question, their query is also embedded. Supabase runs a `pgvector` similarity search (RPC) to retrieve the top relevant documents.
3. **Augmented Answer:** The retrieved context is bundled with the original prompt and sent to Gemini, which generates a highly accurate, context-aware answer for the user.

---

## 🚀 Key Features

### 1. Voice-to-Skills AI Extraction
Instead of relying on manual text entry, workers can record a short audio clip. The `m4a` file is sent via multipart upload to FastAPI, where Gemini understands the transcript, extracts structured data (skills, experience, languages), and returns it to Flutter for the user to review. 

### 2. Intelligent Matching Engine
The matching engine scores opportunities based on:
- Skill overlap
- Geographical distance (using coordinates)
- Local & seasonal demand
- Profile verification status

### 3. Family Guide System
SilverHands allows users to generate a secure, temporary 6-digit code for a trusted family member. The family member (Guide) gets a specialized dashboard with read-only access to the worker's profile and the ability to review opportunities, draft customer replies, and request assistance approvals. 

---

## 🛠️ Setup & Installation

### Flutter Setup
```bash
flutter pub get
flutter run -d chrome \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLISHABLE_KEY \
  --dart-define=SILVERHANDS_BACKEND_URL=http://localhost:8000
```

### Backend (FastAPI) Setup
```bash
cd backend
python -m venv .venv
source .venv/bin/activate  # Or .venv\Scripts\Activate.ps1 on Windows
pip install -r requirements.txt
# Configure .env with GEMINI_API_KEY, SUPABASE_URL, etc.
uvicorn app.main:app --reload
```

### Supabase Migrations
Run the SQL files located in `supabase/migrations/` sequentially in your Supabase SQL Editor to initialize schemas, `pgvector`, policies, and the Family Guide RPCs.

---

## ⚠️ Security Notes
- Never commit `backend/.env`, Google Maps API keys, or Supabase Service Role Keys.
- The Family Guide workflow enforces permissions via Supabase Row Level Security (RLS) policies, ensuring guides cannot change sensitive identity or financial information without the owner's authorization.
