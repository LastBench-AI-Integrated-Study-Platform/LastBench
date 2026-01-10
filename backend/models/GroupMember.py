# each study group
from pydantic import BaseModel, Field
from typing import Optional, Literal
from datetime import datetime

class GroupMemberModel(BaseModel):
    group_id: Optional[str] = Field(
        None,
        description="MongoDB ObjectId reference to Group"
    )
    user_id: Optional[str] = Field(
        None,
        description="MongoDB ObjectId reference to User"
    )
    role: Literal["admin", "member"] = "member"
    joined_at: Optional[datetime] = None

    class Config:
        orm_mode = True
