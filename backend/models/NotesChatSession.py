# For AI ask questions from notes bot
from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime

class NotesChatSessionModel(BaseModel):
    user_id: Optional[str] = Field(
        None,
        description="MongoDB ObjectId reference to User"
    )
    note_id: Optional[str] = Field(
        None,
        description="MongoDB ObjectId reference to UserNote"
    )
    session_name: Optional[str] = None
    started_at: Optional[datetime] = None

    class Config:
        orm_mode = True
