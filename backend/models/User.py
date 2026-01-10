from pydantic import BaseModel, EmailStr, Field
from typing import Optional, Literal
from datetime import datetime

class UserModel(BaseModel):
    name: Optional[str] = None
    email: EmailStr
    password: Optional[str] = None
    provider: Optional[Literal["email", "google", "github"]] = "email"
    study_streak: Optional[int] = 0
    created_at: Optional[datetime] = None

    class Config:
        orm_mode = True
