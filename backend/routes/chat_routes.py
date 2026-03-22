from fastapi import APIRouter, HTTPException, Depends
from typing import List, Optional
from datetime import datetime
from bson import ObjectId
from db.connection import db
from models.chat_models import GroupCreate, MessageSend

router = APIRouter(prefix="/chat", tags=["Chat"])

@router.post("/groups")
async def create_group(group: GroupCreate):
    new_group = {
        "name": group.name,
        "description": group.description,
        "members": group.members,
        "created_at": datetime.now()
    }
    result = db.groups.insert_one(new_group)
    return {"message": "Group created successfully", "group_id": str(result.inserted_id)}

@router.get("/groups")
async def get_groups(user_email: str):
    # Fetch groups where the user is a member
    groups = list(db.groups.find({"members": user_email}))
    
    formatted_groups = []
    for g in groups:
        # Calculate initials
        name_parts = g.get("name", "Unknown").split()
        initials = "".join([part[0].upper() for part in name_parts[:2]]) if name_parts else "U"
        
        # Calculate active members (mock implementation, you might want real logic here)
        active_count = len(g.get("members", []))
        
        formatted_groups.append({
            "id": str(g["_id"]),
            "name": g.get("name", "Unknown"),
            "initials": initials,
            "active": active_count,
            "description": g.get("description", "")
        })
    return {"groups": formatted_groups}

@router.post("/messages")
async def send_message(msg: MessageSend):
    new_msg = {
        "sender_email": msg.sender_email,
        "content": msg.content,
        "timestamp": datetime.now(),
        "group_id": msg.group_id,
        "recipient_email": msg.recipient_email
    }
    result = db.messages.insert_one(new_msg)
    return {"message": "Message sent", "message_id": str(result.inserted_id)}

@router.get("/personal")
async def get_personal_chats(user_email: str):
    # This is a simplified fetch of recent personal messages
    # Ideally, you'd aggregate the latest message per unique conversation partner
    messages = list(db.messages.find({
        "$or": [
            {"sender_email": user_email, "group_id": None},
            {"recipient_email": user_email, "group_id": None}
        ]
    }).sort("timestamp", -1))
    
    # Process into distinct conversations (latest message per partner)
    conversations = {}
    for m in messages:
        # Determine the other person in the conversation
        partner = m["recipient_email"] if m["sender_email"] == user_email else m["sender_email"]
        if partner not in conversations:
            
            # get name of partner
            partner_user = db.users.find_one({"email": partner})
            partner_name = partner_user["name"] if partner_user else partner
            
            # format time
            time_str = m.get("timestamp", datetime.now()).strftime("%I:%M %p")
            
            conversations[partner] = {
                "name": partner_name,
                "email": partner,
                "message": m.get("content", ""),
                "time": time_str
            }
            
    return {"chats": list(conversations.values())}
