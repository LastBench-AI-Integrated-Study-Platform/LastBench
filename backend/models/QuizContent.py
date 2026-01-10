# For quiz section - eg: Tutorial1/semester1/Subject name
from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime

class QuizContentModel(BaseModel):
    user_id: Optional[str] = Field(
        None,
        description="MongoDB ObjectId reference to User"
    )
    title: Optional[str] = None
    content_text: Optional[str] = None
    file_url: Optional[str] = None
    createdAt: Optional[datetime] = None
    updatedAt: Optional[datetime] = None

    class Config:
        orm_mode = True
