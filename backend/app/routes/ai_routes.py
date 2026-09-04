from fastapi import APIRouter, Depends, HTTPException

from app.auth import current_user
from app.schemas.api import (
    ContentGenerateRequest,
    ContentGenerateResponse,
    DemandAnalyzeRequest,
    DemandAnalyzeResponse,
    ProfileGenerateRequest,
    ProfileGenerateResponse,
    RecommendationRequest,
    RecommendationResponse,
    SkillsExtractRequest,
    SkillsExtractResponse,
)
from app.services.ai_service import get_ai
from app.services.matching_engine import recommend


router = APIRouter(
    dependencies=[Depends(current_user)],
    tags=["ai"],
)


# ============================================================
# Skill Extraction
# ============================================================

@router.post(
    "/skills/extract",
    response_model=SkillsExtractResponse,
)
async def extract_skills(request: SkillsExtractRequest):
    """
    Extract livelihood skills, experience and languages from
    user-provided text using Gemini.
    """

    try:
        result = get_ai().extract_skills_from_text(
            request.text,
            request.language,
        )

        return SkillsExtractResponse(
            skills=result.skills,
            experience_years=result.experience_years,
            languages=result.languages,
            is_mock=False,
        )

    except Exception as exc:
        raise HTTPException(
            status_code=502,
            detail="Skill extraction failed.",
        ) from exc


# ============================================================
# Profile Generation
# ============================================================

@router.post(
    "/profile/generate",
    response_model=ProfileGenerateResponse,
)
async def generate_profile(request: ProfileGenerateRequest):
    try:
        result = get_ai().generate_profile(
            request.name,
            request.skills,
            request.location,
            request.experience_years,
            request.language,
        )

        return ProfileGenerateResponse(
            **result.model_dump()
        )

    except Exception as exc:
        raise HTTPException(
            status_code=502,
            detail="Profile generation failed.",
        ) from exc


# ============================================================
# Marketing Content Generation
# ============================================================

@router.post(
    "/content/generate",
    response_model=ContentGenerateResponse,
)
async def generate_content(request: ContentGenerateRequest):
    try:
        result = get_ai().generate_content(
            request.product_name,
            request.product_description,
            request.language,
        )

        return ContentGenerateResponse(
            **result.model_dump()
        )

    except Exception as exc:
        raise HTTPException(
            status_code=502,
            detail="Content generation failed.",
        ) from exc


# ============================================================
# AI Recommendations
# ============================================================

@router.post(
    "/recommendations",
    response_model=RecommendationResponse,
)
async def recommendations(request: RecommendationRequest):
    try:
        rows = recommend(
            request.skills,
            request.location,
            request.latitude,
            request.longitude,
        )

        result = []

        for score, distance, row in rows:
            explanation = await _explain(
                request,
                row,
                score,
            )

            result.append(
                {
                    "opportunity_id": str(row["id"]),
                    "title": row["title"],
                    "match_percentage": score,
                    "explanation": explanation,
                }
            )

        return RecommendationResponse(
            recommendations=result,
        )

    except Exception as exc:
        raise HTTPException(
            status_code=502,
            detail="Recommendation engine failed.",
        ) from exc


# ============================================================
# Recommendation Explanation
# ============================================================

async def _explain(
    request: RecommendationRequest,
    row: dict,
    score: int,
) -> str:

    try:
        return get_ai().explain_match(
            request.skills,
            row,
            score,
            "English",
        )

    except Exception:
        return (
            "This opportunity matches your skills, "
            "demand and location."
        )