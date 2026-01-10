#Doubt section reply model
from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime

class DoubtModel(BaseModel):
    user_id: Optional[str] = Field(
        None,
        description="MongoDB ObjectId reference to User"
    )
    title: Optional[str] = None
    description: Optional[str] = None
    image_url: Optional[str] = None
    ai_answer: Optional[str] = None
    is_resolved: bool = False
    created_at: Optional[datetime] = None

    class Config:
        orm_mode = True
