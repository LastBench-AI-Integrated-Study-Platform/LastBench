# for Bot interviewer option
from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime

class PlacementBotConversationModel(BaseModel):
    session_id: Optional[str] = Field(
        None,
        description="MongoDB ObjectId reference to PlacementBotSession"
    )
    question: Optional[str] = None
    user_answer: Optional[str] = None
    correct_answer: Optional[str] = None
    is_correct: Optional[bool] = None
    createdAt: Optional[datetime] = None
    updatedAt: Optional[datetime] = None

    class Config:
        orm_mode = True
