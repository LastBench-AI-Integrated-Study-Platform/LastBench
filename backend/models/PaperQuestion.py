# geneate question papers - implement in future if needed
from pydantic import BaseModel, Field
from typing import Optional

class PaperQuestionModel(BaseModel):
    paper_id: Optional[str] = Field(
        None,
        description="MongoDB ObjectId reference to QuestionPaper"
    )
    question_type: Optional[str] = None
    question: Optional[str] = None
    marks: Optional[int] = None
    answer: Optional[str] = None
    question_order: Optional[int] = None

    class Config:
        orm_mode = True
