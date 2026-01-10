# For quiz section eg:quiz1 , quiz2 under each Quizcontent
from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime

class QuizModel(BaseModel):
    content_id: Optional[str] = Field(
        None,
        description="MongoDB ObjectId reference to QuizContent"
    )
    user_id: Optional[str] = Field(
        None,
        description="MongoDB ObjectId reference to User"
    )
    quiz_name: Optional[str] = None
    total_questions: Optional[int] = None
    created_at: Optional[datetime] = None

    class Config:
        orm_mode = True
