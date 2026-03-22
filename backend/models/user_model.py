from db.connection import db
from pydantic import BaseModel, EmailStr
from typing import Optional, List

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

class UserStreak(BaseModel):
    current_streak: int = 0
    last_study_date: Optional[str] = None
    study_dates: List[str] = []

class UserProfile(BaseModel):
    email: EmailStr
    name: Optional[str] = None
    bio: Optional[str] = None
    education: Optional[str] = None
    internship: Optional[str] = None
    job: Optional[str] = None
    skills: Optional[str] = None
    profile_image_base64: Optional[str] = None
