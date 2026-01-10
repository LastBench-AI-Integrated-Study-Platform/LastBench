# used to calc total score
from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime

class QuizAttemptModel(BaseModel):
    quiz_id: Optional[str] = Field(
        None,
        description="MongoDB ObjectId reference to Quiz"
    )
    user_id: Optional[str] = Field(
        None,
        description="MongoDB ObjectId reference to User"
    )
    score: Optional[int] = None
    total_questions: Optional[int] = None
    started_at: Optional[datetime] = None
    completed_at: Optional[datetime] = None

    class Config:
        orm_mode = True
