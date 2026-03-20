import re
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from bson import ObjectId
from db.connection import db
from models.call_model import get_call_history
from services.call_service import generate_agora_token
from socket_manager import online_users

router = APIRouter(prefix="/call", tags=["call"])


class TokenRequest(BaseModel):
    channel: str
    uid: int = 0


# ── Search users by username OR name OR email prefix ─────────────────────────
@router.get("/users/search")
async def search_users(q: str = "", current_user_id: str = ""):
    if not q.strip():
        return []
    try:
        pattern = re.compile(q.strip(), re.IGNORECASE)

        # Search across username, name, and email — so old users show up too
        query: dict = {
            "$or": [
                {"username": {"$regex": pattern}},
                {"name":     {"$regex": pattern}},
                {"email":    {"$regex": pattern}},
            ]
        }

        # Exclude the searching user themselves
        if current_user_id:
            try:
                query["_id"] = {"$ne": ObjectId(current_user_id)}
            except Exception:
                pass

        users = list(db.users.find(
            query,
            {"_id": 1, "username": 1, "name": 1, "email": 1, "is_online": 1}
        ).limit(10))

        results = []

        for user in users:
            user_id_str = str(user["_id"])

            results.append({
                "_id": user_id_str,
                "username": user.get("username"),
                "name": user.get("name"),
                "email": user.get("email"),
                "isOnline": user_id_str in online_users
            })

        return results

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# ── Generate Agora token ──────────────────────────────────────────────────────
@router.post("/token")
async def get_token(body: TokenRequest):
    if not body.channel:
        raise HTTPException(status_code=400, detail="channel is required")
    try:
        return generate_agora_token(body.channel, body.uid)
    except ValueError as e:
        raise HTTPException(status_code=500, detail=str(e))


# ── Call history ──────────────────────────────────────────────────────────────
@router.get("/history/{user_id}")
async def call_history(user_id: str):
    try:
        return get_call_history(db, user_id)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))