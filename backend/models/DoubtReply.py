#Doubt section reply model
from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime

class DoubtReplyModel(BaseModel):
    doubt_id: Optional[str] = Field(
        None,
        description="MongoDB ObjectId reference to Doubt"
    )
    user_id: Optional[str] = Field(
        None,
        description="MongoDB ObjectId reference to User"
    )
    reply: Optional[str] = None
    image_url: Optional[str] = None
    upvotes: int = 0
    created_at: Optional[datetime] = None

    class Config:
        orm_mode = True
