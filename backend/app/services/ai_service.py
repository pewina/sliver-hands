import tempfile
from pathlib import Path
from typing import Any

from google import genai
from google.genai import types
from pydantic import BaseModel, Field

from app.config import settings


class VoiceExtraction(BaseModel):
    transcript: str
    skills: list[str]
    experience_years: int = Field(ge=0)
    languages: list[str]


class ProfileOutput(BaseModel):
    headline: str
    bio: str


class ContentOutput(BaseModel):
    whatsapp_status: str
    instagram_caption: str
    facebook_post: str
    poster_headline: str
    poster_subheadline: str
    poster_cta: str


class AIService:
    def __init__(self) -> None:
        if not settings.gemini_api_key:
            raise RuntimeError("GEMINI_API_KEY is not configured.")

        self.client = genai.Client(
            api_key=settings.gemini_api_key
        )

    # ---------------------------------------------------------
    # Common Gemini structured-output helper
    # ---------------------------------------------------------
    def _json(
        self,
        model: type[BaseModel],
        prompt: str,
        contents: Any,
    ):
        response = self.client.models.generate_content(
            model=settings.gemini_model,
            contents=contents,
            config=types.GenerateContentConfig(
                response_mime_type="application/json",
                response_schema=model,
                system_instruction=(
                    "You are SilverHands AI, an inclusive livelihood assistant "
                    "for Indian senior citizens and homemakers. "
                    "Never invent experience, skills, prices, certifications, "
                    "ingredients, qualifications, or other personal information. "
                    "Prefer simple, respectful language. "
                    "Return only the requested structure."
                ),
            ),
        )

        if not response.text:
            raise RuntimeError("Gemini returned an empty response.")

        return model.model_validate_json(response.text)

    # ---------------------------------------------------------
    # Voice transcription + skill extraction
    # ---------------------------------------------------------
    def transcribe_and_extract(
        self,
        audio_bytes: bytes,
        suffix: str,
        language: str,
    ) -> VoiceExtraction:

        with tempfile.NamedTemporaryFile(
            delete=False,
            suffix=suffix,
        ) as temp:
            temp.write(audio_bytes)
            path = Path(temp.name)

        try:
            mime_types = {
                   ".wav": "audio/wav",
                     ".mp3": "audio/mpeg",
                     ".m4a": "audio/mp4",
                     ".webm": "audio/webm",
                     ".ogg": "audio/ogg",
            }

            mime_type = mime_types.get(
                  suffix.lower(),
                  "application/octet-stream",
            )

            uploaded = self.client.files.upload(
                 file=path,
                   config={
                            "mime_type": mime_type,
 },
 )

            prompt = f"""
Listen to this audio spoken in or around {language}.

First, transcribe the audio faithfully.

Then extract:

- practical skills the speaker explicitly mentions
- total years of experience if explicitly stated; otherwise 0
- languages explicitly mentioned or clearly spoken

Important rules:

1. Never invent a skill.
2. Never infer a skill from age, gender, occupation, location,
   religion, community, or background.
3. Never invent years of experience.
4. Do not assume a hobby is a professional skill unless the speaker
   describes it as a skill or experience.
5. Keep skills short and useful for livelihood opportunities.
6. Remove duplicate skills.
7. If no skills are mentioned, return an empty skills list.
8. Return the transcript faithfully.

Return only the requested JSON structure.
"""

            return self._json(
                VoiceExtraction,
                prompt,
                [uploaded, prompt],
            )

        finally:
            path.unlink(missing_ok=True)

    # ---------------------------------------------------------
    # Text-based skill extraction
    # ---------------------------------------------------------
    def extract_skills_from_text(
        self,
        text: str,
        language: str = "English",
    ) -> VoiceExtraction:

        prompt = f"""
Analyze the following user-provided text.

Language:
{language}

User text:
{text}

Extract only information explicitly stated by the user.

Return:

- transcript: the original user text
- skills: practical skills explicitly mentioned by the user
- experience_years: total years of experience if explicitly stated;
  otherwise 0
- languages: languages explicitly mentioned by the user

Important rules:

1. Never infer skills from age, gender, occupation, location,
   religion, community, or background.
2. Never invent experience.
3. Do not treat hobbies as professional skills unless the user
   describes them as a skill or experience.
4. Keep skills short and useful for livelihood opportunities.
5. Remove duplicate skills.
6. If no skills are mentioned, return an empty skills list.
7. If experience is not explicitly stated, use 0.
8. Preserve the user's original text in transcript.
9. Return only the requested JSON structure.

Example:

User:
"I have been making homemade pickles for 8 years.
I also know cooking and food packaging."

Expected structure:

{{
    "transcript": "I have been making homemade pickles for 8 years. I also know cooking and food packaging.",
    "skills": [
        "Pickle making",
        "Cooking",
        "Food packaging"
    ],
    "experience_years": 8,
    "languages": []
}}
"""

        return self._json(
            VoiceExtraction,
            prompt,
            prompt,
        )

    # ---------------------------------------------------------
    # AI-generated user profile
    # ---------------------------------------------------------
    def generate_profile(
        self,
        name: str,
        skills: list[str],
        location: str,
        years: int,
        language: str,
    ) -> ProfileOutput:

        prompt = f"""
Create a short SilverHands user profile.

Name:
{name}

Skills:
{", ".join(skills)}

Experience:
{years} years

Location:
{location}

Language:
{language}

Create:

1. A short professional headline.
2. A warm, simple and professional bio.

Rules:

- Use only the information provided above.
- Do not invent qualifications.
- Do not invent achievements.
- Do not invent businesses.
- Do not invent certifications.
- Keep the language easy to understand.
- Make the profile suitable for a livelihood platform.
"""

        return self._json(
            ProfileOutput,
            prompt,
            prompt,
        )

    # ---------------------------------------------------------
    # Marketing content generation
    # ---------------------------------------------------------
    def generate_content(
        self,
        product_name: str,
        description: str,
        language: str,
    ) -> ContentOutput:

        prompt = f"""
Create premium, customer-ready marketing content in {language} for a SilverHands individual creator.

BUSINESS INPUT
Product / offering:
{product_name}

Profile / skill description:
{description}

First infer the most appropriate business category from the information provided. Possible categories include Food / Culinary, Tailoring / Fashion, Handicrafts / Art, Tutoring / Education, Beauty / Salon, Gardening / Plants, Home Services, Creative Services, Traditional Arts, or another appropriate niche.

Create:

1. A short WhatsApp message specifically written to be forwarded to local customers.
2. An Instagram caption with a few relevant hashtags.
3. A Facebook post.
4. A memorable poster headline (maximum 8 words) that fits the category.
5. A concise poster subheadline (maximum 14 words) communicating the offering and trust/value.
6. A clear poster call-to-action such as ORDER NOW, BOOK NOW, ENQUIRE NOW, CONTACT NOW, SHOP NOW or VIEW PROFILE.

Poster copy requirements:
- The poster will be rendered by the SilverHands app as a premium 4:5 social advertisement.
- Make the headline category-specific, not generic.
- Keep text highly readable at mobile size.
- Make the creator feel like a real skilled individual, not a corporation.
- Emphasize craftsmanship, experience, local trust or authenticity only when supported by the input.
- The app will add the profile QR code separately; never invent or print a QR code.

Important rules:

- Do not invent prices.
- Do not invent certifications.
- Do not invent ingredients.
- Do not invent health benefits.
- Do not invent awards.
- Do not make unsupported claims.
- Use only the product/skill information provided.
- Keep the language simple and appealing for senior citizens and homemakers.
- Make the WhatsApp version concise, personal and easy to forward.
- Do not mention Instagram or Facebook inside the WhatsApp message.
- Make the poster copy readable at a glance.
- If the input contains multiple skills, combine them naturally instead of inventing a new skill.
"""

        return self._json(
            ContentOutput,
            prompt,
            prompt,
        )

    # ---------------------------------------------------------
    # AI explanation for opportunity matching
    # ---------------------------------------------------------
    def explain_match(
        self,
        skills: list[str],
        opportunity: dict,
        score: int,
        language: str,
    ) -> str:

        prompt = f"""
Explain in {language}, in 2 short sentences, why this opportunity
matches the seller.

Seller skills:
{skills}

Opportunity title:
{opportunity.get("title")}

Opportunity skills:
{opportunity.get("skills")}

Match score:
{score}

Important rules:

- Use only the facts provided above.
- Do not invent qualifications.
- Do not invent experience.
- Do not invent location information.
- Do not make unsupported claims.
- Keep the explanation simple and respectful.
"""

        response = self.client.models.generate_content(
            model=settings.gemini_model,
            contents=prompt,
            config=types.GenerateContentConfig(),
        )

        return (response.text or "").strip()


# -------------------------------------------------------------
# Singleton AI service
# -------------------------------------------------------------

_ai: AIService | None = None


def get_ai() -> AIService:
    global _ai

    if _ai is None:
        _ai = AIService()

    return _ai