#Daily random insight model
from pydantic import BaseModel
from datetime import datetime
from typing import Optional

class DailyInsightModel(BaseModel):
    content: str
    createdAt: Optional[datetime] = None
    updatedAt: Optional[datetime] = None

    class Config:
        orm_mode = True
