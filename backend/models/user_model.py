from pydantic import BaseModel, EmailStr
from typing import List, Optional
from datetime import datetime

class UserSignup(BaseModel):
    name: str
    email: EmailStr
    password: str
    exam: str

class UserLogin(BaseModel):
    email: EmailStr
    password: str

class UserStreak(BaseModel):
    current_streak: int = 0
    last_study_date: Optional[str] = None
    study_dates: List[str] = []
