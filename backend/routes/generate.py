from fastapi import APIRouter
from pydantic import BaseModel
from services.combined_services import generate_mcq_quiz, generate_flashcards

router = APIRouter()

class GenerateRequest(BaseModel):
    text: str
    count: int = 10

@router.post("/quiz")
def quiz(req: GenerateRequest):
    return generate_mcq_quiz(req.text, req.count)

@router.post("/flashcards")
def flashcards(req: GenerateRequest):
    return generate_flashcards(req.text, req.count)
