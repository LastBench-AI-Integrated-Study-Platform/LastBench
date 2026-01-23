from fastapi import APIRouter, HTTPException
import requests

router = APIRouter(prefix="/insights", tags=["Insights"])

@router.get("/daily")
def get_daily_insight():
    try:
        url = "https://zenquotes.io/api/random"
        r = requests.get(url, timeout=10)

        if r.status_code != 200:
            raise HTTPException(status_code=500, detail=f"Quotes API failed: {r.status_code}")

        data = r.json()  # list
        quote = data[0]["q"]
        author = data[0]["a"]

        return {
            "type": "Motivation ✨",
            "insight": f"{quote} — {author}"
        }

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
