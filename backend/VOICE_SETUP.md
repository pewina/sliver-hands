# SilverHands Voice Demo — FINAL setup

## 1. Create `backend/.env`

Copy `.env.example` to `.env` and set:

```env
SILVERHANDS_REQUIRE_AUTH=false
ELEVENLABS_API_KEY=YOUR_REAL_ELEVENLABS_API_KEY
GEMINI_API_KEY=YOUR_REAL_GEMINI_API_KEY
GEMINI_MODEL=gemini-3.6-flash
```

**Do not paste API keys into Flutter/Dart files.**

## 2. Start FastAPI from the backend folder

```powershell
cd backend
python -m pip install -r requirements.txt
uvicorn app.main:app --reload --port 8000
```

At startup, the voice endpoint uses this order:

1. ElevenLabs Scribe v2 (real recorded audio)
2. Faster-Whisper fallback
3. Gemini audio fallback (same recorded audio)
4. No fake transcript — if all providers fail, the UI asks you to retry

There is intentionally **no hardcoded Tailoring/Handicrafts transcript anymore**.

## 3. Start Flutter in another terminal

```powershell
cd silverhands
flutter clean
flutter pub get
flutter run -d chrome
```

## 4. What you should see in the backend terminal

For a successful ElevenLabs call:

```text
🎙️ ElevenLabs transcript: ...
🎙️ ElevenLabs language: ta
VOICE: engine=elevenlabs-scribe-v2
VOICE: local_skills=['Cooking', 'Pickle Making']
VOICE: final_skills=['Cooking', 'Pickle Making']
VOICE: experience=10
VOICE: languages=['Tamil']
```

If you see:

```text
⚠️ ELEVENLABS_API_KEY is not configured
```

stop and add the key to `backend/.env`. Do not keep testing the Flutter UI until this is fixed.

## 5. Test sentence

Say in Tamil:

`எனக்கு 10 வருடங்களாக சமையல் அனுபவம் உள்ளது. நான் பாரம்பரிய உணவுகள் மற்றும் ஊறுகாய் தயாரிப்பதில் சிறந்து விளங்குகிறேன்.`

Expected skills:

- Cooking
- Pickle Making

Expected experience:

- 10 years

Expected language:

- Tamil
