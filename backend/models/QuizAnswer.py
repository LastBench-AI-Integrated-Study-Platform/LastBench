# stores users answers and bool to store iscorrect
from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime

class QuizAnswerModel(BaseModel):
    attempt_id: Optional[str] = Field(
        None,
        description="MongoDB ObjectId reference to QuizAttempt"
    )
    question_id: Optional[str] = Field(
        None,
        description="MongoDB ObjectId reference to QuizQuestion"
    )
    user_answer: Optional[str] = None
    is_correct: Optional[bool] = None

    class Config:
        orm_mode = True
