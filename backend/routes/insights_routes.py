from fastapi import APIRouter, HTTPException
import requests
import random

router = APIRouter(prefix="/insights", tags=["Insights"])

@router.get("/daily")
def get_daily_insight():
    try:
        res = requests.get("https://zenquotes.io/api/quotes")

        if res.status_code != 200:
            raise HTTPException(status_code=500, detail="Quotes API failed")

        data = res.json()

        keywords = ["study", "education", "learning", "success", "hard work", "focus", "goal"]

        filtered = []
        for q in data:
            quote_text = q.get("q", "").lower()
            if any(k in quote_text for k in keywords):
                filtered.append(q.get("q"))

        if not filtered:
            return {"insight": random.choice(data).get("q", "Stay motivated!")}

        return {"insight": random.choice(filtered)}

    except Exception:
        raise HTTPException(status_code=500, detail="Error fetching insight")
