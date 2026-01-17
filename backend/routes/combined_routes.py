from fastapi import APIRouter, UploadFile, File, HTTPException
from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime
from services.combined_services import (
    extract_text_from_pdf,
    extract_text_from_image,
    aggressive_ocr_cleanup,
    generate_mcq_quiz,
    generate_flashcards
)

router = APIRouter()

# In-memory storage
quiz_sessions = {}
flashcard_sessions = {}
quiz_attempts = {}


# ============================================================================
# REQUEST/RESPONSE MODELS
# ============================================================================

class GenerateRequest(BaseModel):
    text: str
    count: int = 10


class QuestionAnswer(BaseModel):
    question_id: int
    question: str
    user_answer: str
    correct_answer: str
    is_correct: bool
    options: List[str]


class QuizAttemptRequest(BaseModel):
    session_id: str
    answers: List[QuestionAnswer]
    score: int
    total_questions: int


# ============================================================================
# FILE UPLOAD ENDPOINTS
# ============================================================================

@router.post("/upload")
async def upload_and_generate(
    file: UploadFile = File(...), 
    num_questions: int = 3, 
    num_flashcards: int = 3
):
    """
    Upload file, extract text, and generate both quiz and flashcards.
    Returns session IDs for quiz and flashcard data.
    """
    try:
        print(f"📤 Uploading file: {file.filename}")
        data = await file.read()
        
        # Extract text
        if file.filename.endswith(".pdf"):
            print("📄 Extracting text from PDF...")
            text = extract_text_from_pdf(data)
        else:
            print("🖼️ Extracting text from image...")
            text = extract_text_from_image(data)
        
        if not text or len(text.strip()) < 20:
            raise HTTPException(
                status_code=400, 
                detail="Could not extract sufficient text from file"
            )
        
        print(f"✅ Extracted {len(text)} characters")
        
        # Clean OCR text
        print("🧹 Cleaning text...")
        final_text = aggressive_ocr_cleanup(text)
        
        # Generate quiz
        print(f"🧠 Generating {num_questions} quiz questions...")
        quiz_data = generate_mcq_quiz(final_text, num_questions)
        
        # Generate flashcards
        print(f"📚 Generating {num_flashcards} flashcards...")
        flashcard_data = generate_flashcards(final_text, num_flashcards)
        
        # Store in session
        session_id = str(datetime.now().timestamp()).replace(".", "")
        
        # FIXED: Process quiz data properly
        processed_quiz = []
        questions_list = quiz_data.get("questions", [])
        
        for idx, q in enumerate(questions_list):
            # Handle both string and int correct_answer
            correct_ans = q.get("correct_answer", 0)
            if isinstance(correct_ans, str):
                # If it's a string, find its index in options
                options = q.get("options", [])
                try:
                    correct_ans = options.index(correct_ans)
                except ValueError:
                    correct_ans = 0
            
            processed_quiz.append({
                "id": idx,
                "question": q.get("question", ""),
                "options": q.get("options", []),
                "correct_answer": correct_ans,  # Now always an index
                "explanation": q.get("explanation", "")
            })
        
        # FIXED: Process flashcard data properly
        processed_flashcards = []
        flashcards_list = flashcard_data.get("flashcards", [])
        
        for idx, card in enumerate(flashcards_list):
            processed_flashcards.append({
                "id": idx,
                "question": card.get("front", card.get("question", "")),
                "answer": card.get("back", card.get("answer", "")),
                "card_order": idx
            })
        
        # Store sessions
        quiz_sessions[session_id] = {
            "questions": processed_quiz,
            "text": final_text,
            "created_at": datetime.now().isoformat()
        }
        
        flashcard_sessions[session_id] = {
            "cards": processed_flashcards,
            "text": final_text,
            "created_at": datetime.now().isoformat()
        }
        
        print(f"✅ Generation complete! Session ID: {session_id}")
        
        return {
            "session_id": session_id,
            "extracted_text": final_text[:500],
            "quiz": {
                "total_questions": len(processed_quiz),
                "questions": processed_quiz
            },
            "flashcards": {
                "total_cards": len(processed_flashcards),
                "cards": processed_flashcards
            }
        }
    
    except HTTPException:
        raise
    except Exception as e:
        print(f"❌ Error: {e}")
        import traceback
        traceback.print_exc()
        raise HTTPException(
            status_code=500, 
            detail=f"Error processing file: {str(e)}"
        )


@router.post("/file")
async def upload(file: UploadFile = File(...)):
    """Legacy endpoint: Upload and process a file."""
    data = await file.read()

    if file.filename.endswith(".pdf"):
        text = extract_text_from_pdf(data)
    else:
        text = extract_text_from_image(data)

    final = aggressive_ocr_cleanup(text)
    return {"text": final}


# ============================================================================
# QUIZ ENDPOINTS
# ============================================================================

@router.get("/quiz/{session_id}")
def get_quiz(session_id: str):
    if session_id not in quiz_sessions:
        raise HTTPException(status_code=404, detail="Session not found")
    
    return {
        "session_id": session_id,
        "quiz": quiz_sessions[session_id]
    }


@router.post("/quiz/attempt")
def submit_quiz_attempt(attempt: QuizAttemptRequest):
    if attempt.session_id not in quiz_sessions:
        raise HTTPException(status_code=404, detail="Session not found")
    
    attempt_id = str(datetime.now().timestamp()).replace(".", "")
    
    quiz_attempts[attempt_id] = {
        "session_id": attempt.session_id,
        "answers": [answer.dict() for answer in attempt.answers],
        "score": attempt.score,
        "total_questions": attempt.total_questions,
        "accuracy": (
            (attempt.score / attempt.total_questions * 100) 
            if attempt.total_questions > 0 else 0
        ),
        "submitted_at": datetime.now().isoformat()
    }
    
    return {
        "attempt_id": attempt_id,
        "score": attempt.score,
        "total_questions": attempt.total_questions,
        "accuracy": quiz_attempts[attempt_id]["accuracy"],
        "message": "Quiz attempt saved successfully"
    }


@router.get("/quiz/attempt/{attempt_id}")
def get_quiz_attempt(attempt_id: str):
    if attempt_id not in quiz_attempts:
        raise HTTPException(status_code=404, detail="Attempt not found")
    
    return quiz_attempts[attempt_id]


@router.post("/quiz")
def quiz(req: GenerateRequest):
    return generate_mcq_quiz(req.text, req.count)


# ============================================================================
# FLASHCARD ENDPOINTS
# ============================================================================

@router.get("/flashcards/{session_id}")
def get_flashcards(session_id: str):
    if session_id not in flashcard_sessions:
        raise HTTPException(status_code=404, detail="Session not found")
    
    return {
        "session_id": session_id,
        "flashcards": flashcard_sessions[session_id]
    }


@router.post("/flashcards/progress")
def save_flashcard_progress(session_id: str, card_id: int, is_known: bool):
    if session_id not in flashcard_sessions:
        raise HTTPException(status_code=404, detail="Session not found")
    
    if "progress" not in flashcard_sessions[session_id]:
        flashcard_sessions[session_id]["progress"] = {}
    
    flashcard_sessions[session_id]["progress"][str(card_id)] = {
        "is_known": is_known,
        "studied_at": datetime.now().isoformat()
    }
    
    return {"message": "Progress saved successfully"}


@router.post("/flashcards")
def flashcards(req: GenerateRequest):
    return generate_flashcards(req.text, req.count)