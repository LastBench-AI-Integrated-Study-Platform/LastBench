from pydantic import BaseModel, EmailStr
from typing import List, Optional
from datetime import datetime

class GroupCreate(BaseModel):
    name: str
    description: Optional[str] = None
    members: List[str] = [] # List of user emails

class MessageSend(BaseModel):
    sender_email: str
    content: str
    group_id: Optional[str] = None
    recipient_email: Optional[str] = None # For personal chats
