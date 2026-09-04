from fastapi import APIRouter, Depends, HTTPException

from app.auth import current_user
from app.schemas.api import CollaborationSuggestRequest, MatchRequest
from app.services.matching_engine import score_opportunity
from app.database.supabase_client import get_supabase

router = APIRouter(dependencies=[Depends(current_user)], tags=["business"])

@router.post("/match")
async def create_match(request: MatchRequest):
    try:
        row = (
            get_supabase().table("opportunities").select("*")
            .eq("id", request.opportunity_id).single().execute().data
        )
        score, _ = score_opportunity([], None, None, row)
        business_name = row.get("business_name")
        if request.interested:
            get_supabase().table("matches").upsert({
                "user_id": request.user_id,
                "opportunity_id": request.opportunity_id,
                "interested": True,
            }, on_conflict="user_id,opportunity_id").execute()
        mutual = bool(request.interested and row.get("buyer_interested", True))
        return {
            "mutual_match": mutual,
            "match_percentage": score,
            "business_name": business_name if mutual else None,
            "is_mock": False,
        }
    except Exception as exc:
        raise HTTPException(status_code=502, detail="Match service failed.") from exc

@router.post("/collaboration/suggest")
async def suggest_collaboration(request: CollaborationSuggestRequest):
    try:
        sellers = (
            get_supabase().table("seller_profiles").select("*")
            .order("reliability_score", desc=True)
            .limit(20).execute().data
        )

        # A small verified partner directory keeps the hackathon collaboration
        # demo useful even when the Supabase project has only one real user.
        partners = (
            get_supabase().table("collaboration_partners").select("*")
            .eq("active", True)
            .order("reliability_score", desc=True)
            .limit(20).execute().data
        )
        sellers = list(sellers) + list(partners)
        remaining = request.units_required
        result = []
        for seller in sellers:
            if remaining <= 0:
                break
            seller_skills = {x.lower() for x in seller.get("skills", [])}
            if not seller_skills.intersection({x.lower() for x in request.required_skills}):
                continue
            contribution = min(remaining, int(seller.get("capacity_units", 0)))
            if contribution <= 0:
                continue
            remaining -= contribution
            result.append({
                "seller_name": seller.get("display_name", "SilverHands seller"),
                "contribution": contribution,
                "skills": seller.get("skills", []),
                "location": seller.get("location", "Nearby"),
                "reliability_score": int(seller.get("reliability_score", 0)),
            })
        return {
            "sellers": result,
            "allocated_units": request.units_required - remaining,
            "units_required": request.units_required,
            "is_mock": False,
        }
    except Exception as exc:
        raise HTTPException(status_code=502, detail="Collaboration engine failed.") from exc
