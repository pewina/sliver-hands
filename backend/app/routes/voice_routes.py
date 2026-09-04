from pathlib import Path
import re

from fastapi import APIRouter, Depends, File, Form, HTTPException, UploadFile
import httpx

from app.auth import current_user
from app.config import settings
from app.services.ai_service import get_ai
from app.services.whisper_service import get_whisper


router = APIRouter(
    dependencies=[Depends(current_user)],
    tags=["voice"],
)

# The voice route never injects a hardcoded transcript.
# Every transcript shown to the user must come from the recorded audio.

@router.post("/voice/transcribe")
async def transcribe_voice(
    audio: UploadFile = File(...),
    language: str = Form("English"),
):
    # ---------------------------------------------------------
    # 1. Validate audio
    # ---------------------------------------------------------

    if not audio.content_type:
        raise HTTPException(
            status_code=400,
            detail="Audio content type is missing.",
        )

    if not (
        audio.content_type.startswith("audio/")
        or audio.content_type == "application/octet-stream"
    ):
        raise HTTPException(
            status_code=400,
            detail=f"Unsupported audio type: {audio.content_type}",
        )

    data = await audio.read()

    print("VOICE DEBUG:")
    print(f"  filename={audio.filename}")
    print(f"  content_type={audio.content_type}")
    print(f"  bytes={len(data)}")
    print(f"  first_16_bytes={data[:16]}")

    if not data:
        raise HTTPException(
            status_code=400,
            detail="Uploaded audio is empty.",
        )

    if len(data) > 15 * 1024 * 1024:
        raise HTTPException(
            status_code=413,
            detail="Audio file is too large.",
        )

    suffix = path_suffix(audio.filename)

    # ---------------------------------------------------------
    # 2. REAL ElevenLabs Scribe v2 transcription
    # ---------------------------------------------------------
    transcript = ""
    detected_language = language
    transcription_engine = ""

    if settings.elevenlabs_api_key:
        try:
            language_code = {
                "tamil": "ta", "ta": "ta",
                "english": "en", "en": "en",
                "hindi": "hi", "hi": "hi",
                "telugu": "te", "te": "te",
                "malayalam": "ml", "ml": "ml",
                "kannada": "kn", "kn": "kn",
                "marathi": "mr", "mr": "mr",
                "bengali": "bn", "bn": "bn",
                "gujarati": "gu", "gu": "gu",
                "punjabi": "pa", "pa": "pa",
                "odia": "or", "or": "or",
            }.get(language.lower().strip())

            data_fields = {"model_id": "scribe_v2"}
            if language_code:
                data_fields["language_code"] = language_code

            async with httpx.AsyncClient(timeout=90.0) as client:
                response = await client.post(
                    "https://api.elevenlabs.io/v1/speech-to-text",
                    headers={"xi-api-key": settings.elevenlabs_api_key},
                    data=data_fields,
                    files={
                        "file": (
                            audio.filename or f"audio{suffix}",
                            data,
                            audio.content_type or "audio/wav",
                        )
                    },
                )

            if response.status_code >= 400:
                raise RuntimeError(
                    f"ElevenLabs returned {response.status_code}: {response.text[:500]}"
                )

            result = response.json()
            transcript = str(result.get("text") or result.get("transcript") or "").strip()
            detected_language = str(result.get("language_code") or language_code or language).strip()
            transcription_engine = "elevenlabs-scribe-v2"
            print(f"🎙️ ElevenLabs transcript: {transcript}")
            print(f"🎙️ ElevenLabs language: {detected_language}")

        except Exception as exc:
            print("ELEVENLABS ERROR:", repr(exc))

    if not settings.elevenlabs_api_key:
        print("⚠️ ELEVENLABS_API_KEY is not configured. Add it to backend/.env for real Scribe v2 transcription.")

    # ---------------------------------------------------------
    # 3. Whisper fallback when ElevenLabs is unavailable
    # ---------------------------------------------------------
    if not transcript:
        try:
            whisper_result = get_whisper().transcribe(
                audio_bytes=data,
                filename=f"audio{suffix}",
                language=language,
            )
            transcript = (whisper_result.get("transcript", "") if whisper_result else "").strip()
            detected_language = (whisper_result.get("language", language) if whisper_result else language)
            transcription_engine = "faster-whisper"
        except Exception as exc:
            print("VOICE WHISPER ERROR:", repr(exc))

    # ---------------------------------------------------------
    # 4. Gemini audio fallback when ElevenLabs/Whisper cannot
    #    transcribe. This uses the same microphone WAV, so it
    #    still reflects what the user actually said.
    # ---------------------------------------------------------
    if not transcript or len(transcript.strip()) < 5:
        try:
            if settings.gemini_api_key:
                print("🎙️ ElevenLabs/Whisper produced no transcript; trying Gemini audio...")
                ai_audio = get_ai().transcribe_and_extract(
                    audio_bytes=data,
                    suffix=suffix,
                    language=language,
                )
                transcript = (ai_audio.transcript or "").strip()
                if transcript:
                    detected_language = ai_audio.languages[0] if ai_audio.languages else language
                    transcription_engine = "gemini-audio-fallback"
                    print(f"🎙️ Gemini audio transcript: {transcript}")
        except Exception as exc:
            print("GEMINI AUDIO ERROR:", repr(exc))

    # ---------------------------------------------------------
    # 5. Never inject an unrelated hardcoded transcript. If every
    #    real transcription provider fails, return an empty result
    #    so the Flutter UI can ask the user to try again.
    # ---------------------------------------------------------
    if not transcript or len(transcript.strip()) < 5:
        print("❌ NO REAL TRANSCRIPT AVAILABLE")
        return {
            "transcript": "",
            "language": normalize_language(detected_language, language),
            "skills": [],
            "experience_years": 0,
            "languages": [normalize_language(detected_language, language)],
            "is_mock": False,
            "transcription_engine": "unavailable",
            "error": "No usable transcription was produced. Please try again.",
        }

    # ---------------------------------------------------------
    # 6. AI skill extraction from the ACTUAL transcript
    # ---------------------------------------------------------
    # Always run deterministic extraction first. This guarantees that the
    # prototype can identify common livelihood skills even when Gemini is
    # unavailable, slow, or returns an empty list. AI results are then merged
    # on top instead of replacing the reliable local detections.
    local_skills = extract_skills_locally(transcript)
    skills: list[str] = list(local_skills)
    experience_years = extract_experience(transcript)
    detected_language = normalize_language(detected_language, language)
    extracted_languages = [normalize_language(detected_language, language)]

    try:
        if settings.gemini_api_key and is_unreliable_transcript(transcript) is False:
            ai_result = get_ai().extract_skills_from_text(
                transcript,
                language=language,
            )

            # Merge AI skills with deterministic keyword detections.
            for skill in ai_result.skills:
                if skill and skill not in skills:
                    skills.append(skill)

            if ai_result.experience_years:
                experience_years = ai_result.experience_years

            if ai_result.languages:
                extracted_languages = [
                    normalize_language(item, language)
                    for item in ai_result.languages
                ]
    except Exception as exc:
        print("AI SKILL EXTRACTION ERROR:", repr(exc))
        # Keep the local detections; do not wipe them out.

    # Never let a language code such as 'tam' leak into the senior-facing UI.
    extracted_languages = list(dict.fromkeys(
        x for x in extracted_languages if x
    ))

    print(f"VOICE: engine={transcription_engine}")
    print(f"VOICE: transcript={transcript}")
    print(f"VOICE: local_skills={local_skills}")
    print(f"VOICE: final_skills={skills}")
    print(f"VOICE: experience={experience_years}")
    print(f"VOICE: languages={extracted_languages}")

    return {
        "transcript": transcript,
        "language": detected_language,
        "skills": skills,
        "experience_years": experience_years,
        "languages": extracted_languages,
        "is_mock": transcription_engine == "demo-fallback",
        "transcription_engine": transcription_engine,
    }


# =========================================================
# TRANSCRIPT QUALITY CHECK
# =========================================================

def is_unreliable_transcript(text: str) -> bool:
    text = text.strip()

    # Empty response
    if not text:
        return True

    # Too short to be useful
    if len(text) < 8:
        return True

    text_lower = text.lower()

    # Known kinds of hallucinated/noisy output from the
    # current microphone setup.
    unreliable_phrases = [
        "it's a very sad memory of you",
        "oh no, it's my first soul",
        "thank you for watching",
        "thanks for watching",
        "outro jingle",
        "intro jingle",
        "background music",
        "music",
        "applause",
        "you",
    ]

    # Scribe can legitimately return bracketed non-speech labels such as
    # [outro jingle]. Those are not user speech and must never be sent into
    # skill extraction.
    if (text_lower.startswith("[") and text_lower.endswith("]")):
        return True

    for phrase in unreliable_phrases:
        if text_lower == phrase or phrase in text_lower:
            return True

    return False


# =========================================================
# LANGUAGE NORMALIZATION
# =========================================================

def normalize_language(value: str | None, fallback: str = "English") -> str:
    raw = (value or fallback or "English").strip().lower()
    codes = {
        "ta": "Tamil", "tam": "Tamil", "tamil": "Tamil",
        "en": "English", "eng": "English", "english": "English",
        "hi": "Hindi", "hin": "Hindi", "hindi": "Hindi",
        "te": "Telugu", "tel": "Telugu", "telugu": "Telugu",
        "ml": "Malayalam", "mal": "Malayalam", "malayalam": "Malayalam",
        "kn": "Kannada", "kan": "Kannada", "kannada": "Kannada",
        "mr": "Marathi", "mar": "Marathi", "marathi": "Marathi",
        "bn": "Bengali", "ben": "Bengali", "bengali": "Bengali",
        "gu": "Gujarati", "guj": "Gujarati", "gujarati": "Gujarati",
        "pa": "Punjabi", "pan": "Punjabi", "punjabi": "Punjabi",
        "or": "Odia", "ori": "Odia", "odia": "Odia",
    }
    return codes.get(raw, value.strip() if value and value.strip() else fallback)


# =========================================================
# LOCAL SKILL EXTRACTION
# =========================================================

def extract_skills_locally(text: str) -> list[str]:
    text_lower = text.lower()

    skill_map = {
        "Baking": [
            "baking",
            "bake",
            "baker",
            "பேக்கிங்",
            "பேக்கரி",
        ],
        "Cake Making": [
            "cake",
            "cakes",
            "cake making",
            "கேக்",
            "கேக் செய்வது",
        ],
        "Brownie Making": [
            "brownie",
            "brownies",
            "பிரவுனி",
        ],
        "Cooking": [
            "cooking",
            "cook",
            "சமையல்",
            "சமைத்தல்",
            "சமைக்க",
            "சமைக்கிறேன்",
            "சமைப்பது",
            "சமையல் செய்வது",
            "சமையல் செய்கிறேன்",
            "சமைப்பேன்",
            "சமையல் அனுபவம்",
            "உணவு தயாரித்தல்",
            "உணவு தயாரிப்பது",
        ],
        "Tailoring": [
            "tailoring",
            "tailor",
            "stitching",
            "sewing",
            "தையல்",
            "தையல் வேலை",
            "துணி தைத்தல்",
            "துணி தைப்பது",
        ],
        "Blouse Making": [
            "blouse",
            "blouse making",
            "பிளவுஸ்",
            "ரவிக்கை",
            "ரவிக்கை தைத்தல்",
        ],
        "Embroidery": [
            "embroidery",
            "embroider",
            "எம்பிராய்டரி",
            "பூ வேலை",
            "கைத்தையல்",
        ],
        "Handicrafts": [
            "handicraft",
            "handicrafts",
            "craft",
            "கைவினை",
            "கைவினைப்பொருட்கள்",
            "கைவினைப் பொருட்கள்",
            "கைவினை பொருட்கள்",
            "கைவினை வேலை",
            "கைவினை செய்வது",
        ],
        "Pickle Making": [
            "pickle", "pickles", "pickle making",
            "ஊறுகாய்", "ஊறுகாய் செய்வது", "ஊறுகாய் தயாரித்தல்",
            "ஊறுகாய் செய்கிறேன்", "ஊறுகாய் செய்வேன்",
        ],
        "Sweets Making": [
            "sweets", "sweet making", "sweets making",
            "இனிப்பு", "இனிப்புகள்", "இனிப்பு செய்வது",
            "இனிப்பு தயாரித்தல்",
        ],
        "Gardening": [
            "gardening", "garden", "gardener",
            "தோட்டக்கலை", "தோட்டம்", "செடிகள் வளர்ப்பது",
            "செடிகளை பராமரித்தல்",
        ],
        "Teaching": [
            "teaching",
            "teacher",
            "teach",
            "பாடம்",
            "பாடம் நடத்துதல்",
            "கற்பித்தல்",
            "கற்பிக்க",
            "ஆசிரியர்",
        ],
        "Mehendi": [
            "mehendi",
            "henna",
            "மெஹந்தி",
            "மருதாணி",
        ],
        "Beauty Services": [
            "beauty",
            "salon",
            "makeup",
            "அழகு",
            "அழகு சேவை",
            "மேக்கப்",
            "சலூன்",
        ],
        "Photography": [
            "photography",
            "photographer",
            "புகைப்படம்",
            "புகைப்படம் எடுத்தல்",
            "புகைப்படக்கலை",
        ],
    }

    skills: list[str] = []

    for skill, keywords in skill_map.items():
        if any(keyword in text_lower for keyword in keywords):
            skills.append(skill)

    return skills


# =========================================================
# EXPERIENCE EXTRACTION
# =========================================================

def extract_experience(text: str) -> int:
    text_lower = text.lower()

    patterns = [
        r"(\d+)\s*(?:years?|yrs?)\s*(?:of)?\s*experience",
        r"experience\s*(?:of)?\s*(\d+)\s*(?:years?|yrs?)",
        r"(\d+)\s*(?:years?|yrs?)",
    ]

    for pattern in patterns:
        match = re.search(pattern, text_lower)

        if match:
            years = int(match.group(1))

            if 0 <= years <= 100:
                return years

    # Tamil experience phrasing, e.g. "15 வருட அனுபவம்" / "15 வருடமாக".
    tamil_patterns = [
        r"(\d+)\s*வருட(?:ம்|ங்கள்|மாக)?",
        r"(\d+)\s*ஆண்டு(?:கள்|மாக)?",
        r"(\d+)\s*ஆண்டுகள்?\s*அனுபவம்",
    ]
    for pattern in tamil_patterns:
        tamil_match = re.search(pattern, text)
        if tamil_match:
            years = int(tamil_match.group(1))
            if 0 <= years <= 100:
                return years

    # Common Tamil number words used with phrases such as
    # "பத்து வருடங்களாக" (for ten years) or "ஐந்து ஆண்டுகள்".
    tamil_number_words = {
        "ஒன்று": 1,
        "இரண்டு": 2,
        "மூன்று": 3,
        "நான்கு": 4,
        "ஐந்து": 5,
        "ஆறு": 6,
        "ஏழு": 7,
        "எட்டு": 8,
        "ஒன்பது": 9,
        "பத்து": 10,
        "பதினொன்று": 11,
        "பன்னிரண்டு": 12,
        "பதின்மூன்று": 13,
        "பதினான்கு": 14,
        "பதினைந்து": 15,
        "பதினாறு": 16,
        "பதினேழு": 17,
        "பதினெட்டு": 18,
        "பத்தொன்பது": 19,
        "இருபது": 20,
        "முப்பது": 30,
        "நாற்பது": 40,
        "ஐம்பது": 50,
        "அறுபது": 60,
        "எழுபது": 70,
        "எண்பது": 80,
        "தொண்ணூறு": 90,
    }

    for word, value in tamil_number_words.items():
        if re.search(rf"{re.escape(word)}\s*(?:வருட|ஆண்டு)", text):
            return value

    number_words = {
        "one": 1,
        "two": 2,
        "three": 3,
        "four": 4,
        "five": 5,
        "six": 6,
        "seven": 7,
        "eight": 8,
        "nine": 9,
        "ten": 10,
        "eleven": 11,
        "twelve": 12,
        "thirteen": 13,
        "fourteen": 14,
        "fifteen": 15,
        "sixteen": 16,
        "seventeen": 17,
        "eighteen": 18,
        "nineteen": 19,
        "twenty": 20,
        "thirty": 30,
        "forty": 40,
        "fifty": 50,
        "sixty": 60,
        "seventy": 70,
        "eighty": 80,
        "ninety": 90,
    }

    for word, value in number_words.items():
        pattern = rf"\b{word}\s+(?:years?|yrs?)\b"

        if re.search(pattern, text_lower):
            return value

    for tens_word, tens_value in [
        ("twenty", 20),
        ("thirty", 30),
        ("forty", 40),
        ("fifty", 50),
        ("sixty", 60),
        ("seventy", 70),
        ("eighty", 80),
        ("ninety", 90),
    ]:
        for ones_word, ones_value in [
            ("one", 1),
            ("two", 2),
            ("three", 3),
            ("four", 4),
            ("five", 5),
            ("six", 6),
            ("seven", 7),
            ("eight", 8),
            ("nine", 9),
        ]:
            pattern = (
                rf"\b{tens_word}\s+{ones_word}"
                rf"\s+(?:years?|yrs?)\b"
            )

            if re.search(pattern, text_lower):
                return tens_value + ones_value

    return 0


# =========================================================
# FILE EXTENSION
# =========================================================

def path_suffix(filename: str | None) -> str:
    if filename and "." in filename:
        return "." + filename.rsplit(".", 1)[1].lower()

    return ".wav"