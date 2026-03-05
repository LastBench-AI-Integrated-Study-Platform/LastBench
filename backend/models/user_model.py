from db.connection import db
from pydantic import BaseModel
from typing import Optional

# ── MongoDB collection ────────────────────────────────────────────────────────
user_collection = db["users"]

# ── Pydantic schemas (kept here so auth_routes imports don't break) ───────────
class UserSignup(BaseModel):
    name:     str
    email:    str
    password: str
    exam:     Optional[str] = None

class UserLogin(BaseModel):
    email:    str
    password: str