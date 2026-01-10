# For AI ask questions from notes bot
from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime

class NotesConversationModel(BaseModel):
    session_id: Optional[str] = Field(
        None,
        description="MongoDB ObjectId reference to NotesChatSession"
    )
    user_question: Optional[str] = None
    ai_answer: Optional[str] = None
    createdAt: Optional[datetime] = None
    updatedAt: Optional[datetime] = None

    class Config:
        orm_mode = True
