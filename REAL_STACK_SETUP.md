# SilverHands — real AI/backend stack

The current ZIP was a polished Flutter demo. It already contained a FastAPI mock backend, but the AI/database/voice/auth integrations were not actually connected.

This version adds the real integration layer.

## Architecture

Flutter
  -> Supabase Auth / Storage / Postgres
  -> FastAPI
      -> Gemini
      -> Python matching engine
      -> Supabase Postgres + pgvector
      -> Firebase registration
  -> Google Maps / device location

## 1. Flutter

From the project root:

```powershell
flutter pub get
```

Run with your Supabase project:

```powershell
flutter run -d chrome `
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co `
  --dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLISHABLE_KEY `
  --dart-define=SILVERHANDS_BACKEND_URL=http://localhost:8000
```

For Android emulator, use:

```text
SILVERHANDS_BACKEND_URL=http://10.0.2.2:8000
```

For a physical phone, replace the URL with your laptop's LAN IP, e.g.:

```text
http://192.168.1.20:8000
```

Do not put a Supabase service-role key or Gemini API key in Flutter.

## 2. Supabase

Create a Supabase project and run:

```text
supabase/migrations/001_silverhands.sql
```

The migration creates:
- profiles
- opportunities
- seller_profiles
- matches
- device_tokens
- knowledge_documents
- pgvector similarity RPC
- product-images Storage bucket
- RLS policies
- seed opportunities and RAG knowledge

Use the Supabase publishable key in Flutter. Keep the service-role key only on FastAPI.

## 3. FastAPI

```powershell
cd backend
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
Copy-Item .env.example .env
```

Set these values in `backend/.env`:

```text
GEMINI_API_KEY=...
GEMINI_MODEL=gemini-3.5-flash
GEMINI_EMBEDDING_MODEL=gemini-embedding-2
GEMINI_EMBEDDING_DIM=768

SUPABASE_URL=https://YOUR_PROJECT.supabase.co
SUPABASE_SERVICE_ROLE_KEY=...

SILVERHANDS_REQUIRE_AUTH=false
```

Start:

```powershell
uvicorn app.main:app --reload
```

Test:

```text
http://127.0.0.1:8000/health
```

## 4. Voice -> text -> skills

The onboarding microphone records a short `.m4a` clip.

Flow:

```text
Flutter microphone
    ↓
FastAPI multipart upload
    ↓
Gemini audio understanding
    ↓
transcript + skills + years + languages
    ↓
Flutter skill review screen
```

The selected language is sent to Gemini, so Tamil/Hindi/English voice can be processed without hardcoding one transcript.

## 5. AI skill extraction

Do not ask Gemini for free-form prose and then regex it.

Use structured output:

```text
{
  transcript,
  skills[],
  experience_years,
  languages[]
}
```

That is what `AIService.transcribe_and_extract()` does.

## 6. Matching

The Python engine scores:
- skill overlap
- distance
- local demand
- seasonal demand
- verification

The final score is 0–100.

The database stores opportunity coordinates, so the score can use real distance.

## 7. RAG

`knowledge_documents.embedding` is a pgvector column.

The pipeline is:

```text
User question
   ↓
Gemini Embedding 2
   ↓
768-dimensional vector
   ↓
Supabase pgvector RPC
   ↓
top relevant SilverHands documents
   ↓
Gemini answer using retrieved context
```

Endpoint:

```text
POST /api/rag/ask
```

## 8. Build the RAG index

After running the SQL migration:

```powershell
cd backend
python scripts/index_knowledge.py
```

This generates Gemini embeddings and writes them into Supabase `pgvector`.

## 9. Product images

Use Supabase Storage bucket:

```text
product-images
```

Upload from Flutter with `supabase.storage.from('product-images')`.

Store only the resulting object path/URL in Postgres.

For production, keep the bucket private and issue signed URLs.

## 10. Google Maps

Add your Google Maps Android key as a Gradle property:

```powershell
cd android
.\gradlew -PMAPS_API_KEY=YOUR_MAPS_KEY
```

For a real Android build, add the key through your CI/Gradle secret system instead of committing it.

The app already has location permissions prepared.

## 11. Firebase notifications

Create a Firebase project and register the Android/iOS apps.

Run FlutterFire configuration:

```powershell
dart pub global activate flutterfire_cli
flutterfire configure
```

Then rebuild:

```powershell
flutter clean
flutter pub get
flutter run
```

FCM registration is implemented in `NotificationService`.

For Android/iOS production, use the Firebase-generated native configuration files. Do not commit private server credentials.

## 12. Multilingual strategy

There are two separate concerns:

1. **AI multilingual** — already wired through the selected language.
2. **UI localization** — should be moved to Flutter `gen_l10n`/ARB files next.

Recommended locales:

```text
en
ta
hi
mr
te
kn
ml
```

Do not translate the UI dynamically with Gemini. Keep UI strings in localization resources so accessibility, buttons and error messages remain deterministic.

## 13. GitHub

Commit source code only:

```powershell
git init
git add .
git commit -m "feat: SilverHands real AI stack"
git branch -M main
git remote add origin YOUR_GITHUB_REPO
git push -u origin main
```

Never commit:

```text
backend/.env
google-services.json
GoogleService-Info.plist
service-account.json
API keys
Supabase service-role keys
```

## Important

The code is integration-ready, but cloud services cannot become live until your team creates the Supabase, Gemini, Firebase and Google Maps projects and supplies their credentials.

That is deliberate: credentials must not be embedded in the ZIP or source code.
