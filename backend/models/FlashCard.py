#FlashCards
from pydantic import BaseModel, Field
from typing import Optional

class FlashcardModel(BaseModel):
    deck_id: Optional[str] = Field(
        None,
        description="MongoDB ObjectId reference to FlashcardDeck"
    )
    question: Optional[str] = None
    answer: Optional[str] = None
    card_order: Optional[int] = None

    class Config:
        orm_mode = True
