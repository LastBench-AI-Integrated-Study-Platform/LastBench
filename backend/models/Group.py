#each study group
from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime

class GroupModel(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    creator_id: Optional[str] = Field(
        None,
        description="MongoDB ObjectId reference to User"
    )
    is_private: bool = False
    created_at: Optional[datetime] = None

    class Config:
        orm_mode = True
