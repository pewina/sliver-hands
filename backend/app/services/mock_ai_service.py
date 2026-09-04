from app.schemas.api import (
    CollaborationSuggestRequest,
    CollaborationSuggestResponse,
    ContentGenerateRequest,
    ContentGenerateResponse,
    DemandAnalyzeRequest,
    DemandAnalyzeResponse,
    DemandInsight,
    MatchRequest,
    MatchResponse,
    ProfileGenerateRequest,
    ProfileGenerateResponse,
    RecommendationRequest,
    RecommendationResponse,
    OpportunityRecommendation,
    SellerAllocation,
    SkillsExtractRequest,
    SkillsExtractResponse,
    VoiceTranscribeRequest,
    VoiceTranscribeResponse,
)


class MockAIService:
    """Deterministic demo results. Swap this class for server-side provider adapters later."""

    async def transcribe(self, request: VoiceTranscribeRequest) -> VoiceTranscribeResponse:
        return VoiceTranscribeResponse(transcript="I have been stitching blouses and teaching tailoring for 25 years.", language=request.language)

    async def extract_skills(self, _: SkillsExtractRequest) -> SkillsExtractResponse:
        return SkillsExtractResponse(skills=["Tailoring", "Blouse Making", "Tailoring Training"], experience_years=25, languages=["Tamil", "English"])

    async def generate_profile(self, request: ProfileGenerateRequest) -> ProfileGenerateResponse:
        skill_text = ", ".join(request.skills[:2])
        return ProfileGenerateResponse(headline=f"Experienced {skill_text} specialist in {request.location}", bio=f"{request.name} brings {request.experience_years} years of experience and a warm, reliable approach to every order.")

    async def recommendations(self, _: RecommendationRequest) -> RecommendationResponse:
        return RecommendationResponse(recommendations=[OpportunityRecommendation(opportunity_id="festival-hampers-001", title="Traditional Festival Gift Hampers", match_percentage=94, explanation="Matches your cooking skills, strong local demand, and a nearby delivery area.")])

    async def match(self, request: MatchRequest) -> MatchResponse:
        matched = request.interested and request.opportunity_id == "festival-hampers-001"
        return MatchResponse(mutual_match=matched, match_percentage=94 if matched else 0, business_name="Anand Celebrations" if matched else None)

    async def generate_content(self, request: ContentGenerateRequest) -> ContentGenerateResponse:
        name = request.product_name
        return ContentGenerateResponse(
            whatsapp_status=f"Handmade {name}\nMade with care and tradition.\n\nMessage me on WhatsApp to enquire or order.",
            instagram_caption=f"Handmade {name}, made with care and tradition. ✨\n\nMessage SilverHands to order. #SilverHands #SupportLocal",
            facebook_post=f"Discover handmade {name}, lovingly prepared by a SilverHands creator. Message us to enquire or order.",
            poster_headline="Freshly Made. Just for You." if "cook" in name.lower() or "food" in name.lower() else name,
            poster_subheadline="Made with skill • Local • Trusted",
            poster_cta="ORDER NOW" if "food" in name.lower() or "pickle" in name.lower() else "VIEW PROFILE",
        )

    async def suggest_collaboration(self, request: CollaborationSuggestRequest) -> CollaborationSuggestResponse:
        base = [SellerAllocation(seller_name="Lakshmi", contribution=150, skills=["Traditional cooking", "Laddoos"], location="Mylapore, Chennai", reliability_score=98), SellerAllocation(seller_name="Meena", contribution=100, skills=["Savouries", "Packaging"], location="Adyar, Chennai", reliability_score=96), SellerAllocation(seller_name="Revathi", contribution=100, skills=["Gift packing", "Crafts"], location="T. Nagar, Chennai", reliability_score=94), SellerAllocation(seller_name="Shanthi", contribution=150, skills=["Traditional cooking", "Snacks"], location="Velachery, Chennai", reliability_score=97)]
        if request.units_required == 500:
            sellers = base
        else:
            sellers = [SellerAllocation(seller_name="Lakshmi", contribution=request.units_required, skills=request.required_skills, location="Chennai", reliability_score=98)]
        return CollaborationSuggestResponse(sellers=sellers, allocated_units=sum(seller.contribution for seller in sellers), units_required=request.units_required)

    async def analyze_demand(self, _: DemandAnalyzeRequest) -> DemandAnalyzeResponse:
        return DemandAnalyzeResponse(trends=[DemandInsight(category="Millet Snacks", increase_percentage=42, note="Growing neighbourhood demand."), DemandInsight(category="Handmade Bags", increase_percentage=35, note="Popular for gifting."), DemandInsight(category="Festival Hampers", increase_percentage=28, note="Seasonal demand is increasing.")])
