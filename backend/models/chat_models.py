from pydantic import BaseModel
from typing import List, Optional

class GroupCreate(BaseModel):
    name: str
    description: Optional[str] = ""
    members: List[str] = []

class MessageSend(BaseModel):
    sender_email: str
    content: str
    group_id: Optional[str] = None
    recipient_email: Optional[str] = None

class MessageEdit(BaseModel):
    content: str
