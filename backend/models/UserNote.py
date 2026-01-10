# For AI ask questions from notes bot
from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime

class UserNoteModel(BaseModel):
    user_id: Optional[str] = Field(
        None,
        description="MongoDB ObjectId reference to User"
    )
    title: Optional[str] = None
    file_url: Optional[str] = None
    createdAt: Optional[datetime] = None
    updatedAt: Optional[datetime] = None

    class Config:
        orm_mode = True
