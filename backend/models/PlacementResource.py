# for Bot interviewer option
from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime

class PlacementResourceModel(BaseModel):
    user_id: Optional[str] = Field(
        None,
        description="MongoDB ObjectId reference to User"
    )
    title: Optional[str] = None
    company_name: Optional[str] = None
    resource_type: Optional[str] = None
    file_url: Optional[str] = None
    createdAt: Optional[datetime] = None
    updatedAt: Optional[datetime] = None

    class Config:
        orm_mode = True
