#Flashcard decks
from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime

class FlashcardDeckModel(BaseModel):
    content_id: Optional[str] = Field(
        None,
        description="MongoDB ObjectId reference to QuizContent"
    )
    user_id: Optional[str] = Field(
        None,
        description="MongoDB ObjectId reference to User"
    )
    deck_name: Optional[str] = None
    total_cards: Optional[int] = None
    created_at: Optional[datetime] = None

    class Config:
        orm_mode = True
