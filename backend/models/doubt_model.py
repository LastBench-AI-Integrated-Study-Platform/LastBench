"""
Doubt section models for Q&A functionality
Includes: Doubt, Comment, Reply, DoubtCreate, CommentCreate
"""

from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime


# ============================================================================
# REPLY MODEL
# ============================================================================

class ReplyModel(BaseModel):
    """Reply to a comment on a doubt"""
    id: Optional[str] = Field(None, description="MongoDB ObjectId")
    author: str
    authorAvatar: Optional[str] = None
    content: str
    createdAt: Optional[datetime] = None

    class Config:
        orm_mode = True


class ReplyCreate(BaseModel):
    """Create reply request"""
    content: str
    author: str
    authorAvatar: Optional[str] = None


# ============================================================================
# COMMENT MODEL
# ============================================================================

class CommentModel(BaseModel):
    """Comment/Answer on a doubt"""
    id: Optional[str] = Field(None, description="MongoDB ObjectId")
    doubt_id: Optional[str] = Field(
        None,
        description="MongoDB ObjectId reference to Doubt"
    )
    author: str
    authorAvatar: Optional[str] = None
    content: str
    imageUrls: Optional[List[str]] = None  # URLs of uploaded images
    createdAt: Optional[datetime] = None
    replies: Optional[List[ReplyModel]] = None

    class Config:
        orm_mode = True


class CommentCreate(BaseModel):
    """Create comment request"""
    content: str
    author: str
    authorAvatar: Optional[str] = None
    imageUrls: Optional[List[str]] = None


class CommentUpdate(BaseModel):
    """Update comment request"""
    content: Optional[str] = None
    imageUrls: Optional[List[str]] = None


# ============================================================================
# DOUBT MODEL
# ============================================================================

class DoubtModel(BaseModel):
    """Doubt/Question model"""
    id: Optional[str] = Field(None, description="MongoDB ObjectId")
    user_id: Optional[str] = Field(
        None,
        description="MongoDB ObjectId reference to User"
    )
    title: str
    content: str
    subject: Optional[str] = None
    imageUrls: Optional[List[str]] = None  # URLs of uploaded images
    author: str
    authorAvatar: Optional[str] = None
    tags: Optional[List[str]] = None
    createdAt: Optional[datetime] = None
    updatedAt: Optional[datetime] = None
    comments: Optional[List[CommentModel]] = None

    class Config:
        orm_mode = True


class DoubtCreate(BaseModel):
    """Create doubt request"""
    title: str
    content: str
    subject: Optional[str] = None
    author: str
    authorAvatar: Optional[str] = None
    imageUrls: Optional[List[str]] = None
    tags: Optional[List[str]] = None


class DoubtUpdate(BaseModel):
    """Update doubt request"""
    title: Optional[str] = None
    content: Optional[str] = None
    subject: Optional[str] = None
    imageUrls: Optional[List[str]] = None
    tags: Optional[List[str]] = None
