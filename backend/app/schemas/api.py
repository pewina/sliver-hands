from pydantic import BaseModel, Field


# ============================================================
# AI - Voice Transcription
# ============================================================

class VoiceTranscribeRequest(BaseModel):
    language: str = "English"


class VoiceTranscribeResponse(BaseModel):
    transcript: str
    language: str
    is_mock: bool = False


# ============================================================
# AI - Skill Extraction
# ============================================================

class SkillsExtractRequest(BaseModel):
    text: str = Field(min_length=1, max_length=5000)
    language: str = "English"


class SkillsExtractResponse(BaseModel):
    skills: list[str]
    experience_years: int = Field(ge=0)
    languages: list[str]
    is_mock: bool = False


# ============================================================
# AI - Voice Extraction Response
# ============================================================

class VoiceResponse(BaseModel):
    transcript: str
    language: str
    skills: list[str]
    experience_years: int = Field(ge=0)
    languages: list[str]
    is_mock: bool = False


# ============================================================
# AI - Profile Generation
# ============================================================

class ProfileGenerateRequest(BaseModel):
    name: str = Field(min_length=2, max_length=100)
    skills: list[str] = Field(min_length=1)
    location: str = Field(min_length=2, max_length=120)
    experience_years: int = Field(ge=0, le=100)
    language: str = "English"


class ProfileGenerateResponse(BaseModel):
    headline: str
    bio: str
    is_mock: bool = False


# ============================================================
# AI - Recommendations
# ============================================================

class RecommendationRequest(BaseModel):
    user_id: str = Field(min_length=1)
    skills: list[str] = Field(default_factory=list)
    location: str = Field(min_length=2)
    latitude: float | None = None
    longitude: float | None = None


class OpportunityRecommendation(BaseModel):
    opportunity_id: str
    title: str
    match_percentage: int = Field(ge=0, le=100)
    explanation: str


class RecommendationResponse(BaseModel):
    recommendations: list[OpportunityRecommendation]
    is_mock: bool = False


# ============================================================
# Matching
# ============================================================

class MatchRequest(BaseModel):
    user_id: str = Field(min_length=1)
    opportunity_id: str = Field(min_length=1)
    interested: bool


class MatchResponse(BaseModel):
    mutual_match: bool
    match_percentage: int = Field(ge=0, le=100)
    business_name: str | None = None
    is_mock: bool = False


# ============================================================
# AI - Marketing Content Generation
# ============================================================

class ContentGenerateRequest(BaseModel):
    product_name: str = Field(min_length=2, max_length=160)
    product_description: str = Field(default="", max_length=1200)
    image_reference: str | None = None
    language: str = "English"


class ContentGenerateResponse(BaseModel):
    whatsapp_status: str
    instagram_caption: str
    facebook_post: str
    poster_headline: str
    poster_subheadline: str
    poster_cta: str
    is_mock: bool = False


# ============================================================
# AI - Collaboration Suggestions
# ============================================================

class CollaborationSuggestRequest(BaseModel):
    opportunity_id: str = Field(min_length=1)
    units_required: int = Field(gt=0, le=100000)
    required_skills: list[str] = Field(min_length=1)


class SellerAllocation(BaseModel):
    seller_name: str
    contribution: int = Field(gt=0)
    skills: list[str]
    location: str
    reliability_score: int = Field(ge=0, le=100)


class CollaborationSuggestResponse(BaseModel):
    sellers: list[SellerAllocation]
    allocated_units: int
    units_required: int
    is_mock: bool = False


# ============================================================
# AI - Demand Analysis
# ============================================================

class DemandAnalyzeRequest(BaseModel):
    location: str = Field(min_length=2, max_length=120)
    categories: list[str] = Field(min_length=1)
    language: str = "English"


class DemandInsight(BaseModel):
    category: str
    increase_percentage: int
    note: str


class DemandAnalyzeResponse(BaseModel):
    trends: list[DemandInsight]
    is_mock: bool = False


# ============================================================
# Firebase / Notifications
# ============================================================

class NotificationRegisterRequest(BaseModel):
    token: str = Field(min_length=10)
    platform: str = Field(min_length=2, max_length=30)


# ============================================================
# RAG / Knowledge Base
# ============================================================

class RagAskRequest(BaseModel):
    question: str = Field(min_length=3, max_length=2000)
    language: str = "English"


class RagAskResponse(BaseModel):
    answer: str
    sources: list[str]