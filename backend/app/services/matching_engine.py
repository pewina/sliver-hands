from math import asin, cos, radians, sin, sqrt

from app.database.supabase_client import get_supabase

def _distance_km(lat1, lon1, lat2, lon2):
    if None in (lat1, lon1, lat2, lon2):
        return None
    r = 6371.0
    dlat = radians(lat2 - lat1)
    dlon = radians(lon2 - lon1)
    a = sin(dlat / 2) ** 2 + cos(radians(lat1)) * cos(radians(lat2)) * sin(dlon / 2) ** 2
    return r * 2 * asin(sqrt(a))

def score_opportunity(user_skills, user_lat, user_lon, opportunity):
    wanted = {s.strip().lower() for s in opportunity.get("skills", [])}
    have = {s.strip().lower() for s in user_skills}
    skill_score = 50 * (len(wanted & have) / max(len(wanted), 1))

    distance = _distance_km(
        user_lat, user_lon, opportunity.get("latitude"), opportunity.get("longitude")
    )
    distance_score = 15 if distance is None else max(0, 15 - min(distance, 15))

    demand_score = min(15, max(0, int(opportunity.get("demand_score", 0))))
    seasonal_score = min(10, max(0, int(opportunity.get("seasonal_score", 0))))
    verified_score = 5 if opportunity.get("verified") else 0
    total = round(min(100, skill_score + distance_score + demand_score + seasonal_score + verified_score))
    return total, distance

def recommend(user_skills, location, user_lat=None, user_lon=None, limit=10):
    rows = (
        get_supabase()
        .table("opportunities")
        .select("*")
        .eq("is_active", True)
        .limit(100)
        .execute()
        .data
    )
    scored = []
    for row in rows:
        score, distance = score_opportunity(user_skills, user_lat, user_lon, row)
        scored.append((score, distance, row))
    scored.sort(key=lambda x: x[0], reverse=True)
    return scored[:limit]
