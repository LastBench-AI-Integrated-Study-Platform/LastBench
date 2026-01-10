# for Bot interviewer option
from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime

class PlacementBotSessionModel(BaseModel):
    user_id: Optional[str] = Field(
        None,
        description="MongoDB ObjectId reference to User"
    )
    resource_id: Optional[str] = Field(
        None,
        description="MongoDB ObjectId reference to PlacementResource"
    )
    session_name: Optional[str] = None
    interview_type: Optional[str] = None
    started_at: Optional[datetime] = None
    ended_at: Optional[datetime] = None

    class Config:
        orm_mode = True
