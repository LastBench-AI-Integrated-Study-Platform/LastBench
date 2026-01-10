# each study group
from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime

class GroupMessageModel(BaseModel):
    group_id: Optional[str] = Field(
        None,
        description="MongoDB ObjectId reference to Group"
    )
    user_id: Optional[str] = Field(
        None,
        description="MongoDB ObjectId reference to User"
    )
    message: Optional[str] = None
    created_at: Optional[datetime] = None

    class Config:
        orm_mode = True
