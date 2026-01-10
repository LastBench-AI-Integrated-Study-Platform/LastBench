# geneate question papers - implement in future if needed
from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime

class QuestionPaperModel(BaseModel):
    content_id: Optional[str] = Field(
        None,
        description="MongoDB ObjectId reference to QuizContent"
    )
    user_id: Optional[str] = Field(
        None,
        description="MongoDB ObjectId reference to User"
    )
    paper_name: Optional[str] = None
    total_marks: Optional[int] = None
    duration_minutes: Optional[int] = None
    createdAt: Optional[datetime] = None
    updatedAt: Optional[datetime] = None

    class Config:
        orm_mode = True
