# contains questions with 4 options
from pydantic import BaseModel, Field
from typing import Optional, Literal

class QuizQuestionModel(BaseModel):
    quiz_id: Optional[str] = Field(
        None,
        description="MongoDB ObjectId reference to Quiz"
    )
    question: Optional[str] = None
    option_a: Optional[str] = None
    option_b: Optional[str] = None
    option_c: Optional[str] = None
    option_d: Optional[str] = None
    correct_answer: Optional[Literal["A", "B", "C", "D"]] = None
    explanation: Optional[str] = None

    class Config:
        orm_mode = True
