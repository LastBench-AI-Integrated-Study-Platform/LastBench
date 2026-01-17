"""
Combined models for Quiz and Flashcard functionality
Includes: Quiz, QuizAnswer, QuizAttempt, QuizContent, QuizQuestion, Flashcard, FlashcardDeck
"""

from pydantic import BaseModel, Field
from typing import Optional, Literal
from datetime import datetime


# ============================================================================
# QUIZ CONTENT MODELS
# ============================================================================

class QuizContentModel(BaseModel):
    """Quiz content section - e.g: Tutorial1/semester1/Subject name"""
    user_id: Optional[str] = Field(
        None,
        description="MongoDB ObjectId reference to User"
    )
    title: Optional[str] = None
    content_text: Optional[str] = None
    file_url: Optional[str] = None
    createdAt: Optional[datetime] = None
    updatedAt: Optional[datetime] = None

    class Config:
        orm_mode = True


# ============================================================================
# QUIZ MODELS
# ============================================================================

class QuizModel(BaseModel):
    """Quiz model - e.g: quiz1, quiz2 under each QuizContent"""
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


class QuizQuestionModel(BaseModel):
    """Quiz question model with 4 options"""
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


class QuizAnswerModel(BaseModel):
    """Stores user's answers and whether they are correct"""
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


class QuizAttemptModel(BaseModel):
    """Stores quiz attempts and calculates total score"""
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


# ============================================================================
# FLASHCARD MODELS
# ============================================================================

class FlashcardDeckModel(BaseModel):
    """Flashcard deck model"""
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


class FlashcardModel(BaseModel):
    """Individual flashcard model"""
    deck_id: Optional[str] = Field(
        None,
        description="MongoDB ObjectId reference to FlashcardDeck"
    )
    question: Optional[str] = None
    answer: Optional[str] = None
    card_order: Optional[int] = None

    class Config:
        orm_mode = True
