#each study group
from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime

class GroupDocumentModel(BaseModel):
    group_id: Optional[str] = Field(
        None,
        description="MongoDB ObjectId reference to Group"
    )
    user_id: Optional[str] = Field(
        None,
        description="MongoDB ObjectId reference to User"
    )
    title: Optional[str] = None
    file_url: Optional[str] = None
    doc_type: Optional[str] = None
    uploaded_at: Optional[datetime] = None

    class Config:
        orm_mode = True
