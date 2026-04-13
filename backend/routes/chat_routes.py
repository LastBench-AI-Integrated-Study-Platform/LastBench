from fastapi import APIRouter, HTTPException, Depends
from typing import List, Optional
from datetime import datetime
from bson import ObjectId
from db.connection import db
from models.chat_models import GroupCreate, MessageSend
import re

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

@router.get("/search_users")
async def search_users(query: str = ""):
    if not query.strip():
        return {"users": []}
    
    pattern = re.compile(query.strip(), re.IGNORECASE)
    db_users = list(db.users.find(
        {"$or": [{"name": {"$regex": pattern}}, {"email": {"$regex": pattern}}]},
        {"_id": 0, "name": 1, "email": 1}
    ).limit(10))
    
    return {"users": db_users}

@router.post("/groups/join")
async def join_group(payload: dict):
    group_id = payload.get("group_id")
    user_email = payload.get("user_email")
    if not group_id or not user_email:
        raise HTTPException(status_code=400, detail="Missing group_id or user_email")
    
    try:
        obj_id = ObjectId(group_id)
        result = db.groups.update_one({"_id": obj_id}, {"$addToSet": {"members": user_email}})
        if result.matched_count == 0:
            raise HTTPException(status_code=404, detail="Group not found")
        return {"message": "Joined successfully"}
    except Exception as e:
        raise HTTPException(status_code=400, detail="Invalid group ID")

@router.get("/groups/{group_id}/members")
async def get_group_members(group_id: str):
    try:
        obj_id = ObjectId(group_id)
        group = db.groups.find_one({"_id": obj_id})
        if not group:
            raise HTTPException(status_code=404, detail="Group not found")
        
        member_emails = group.get("members", [])
        members = list(db.users.find({"email": {"$in": member_emails}}, {"_id": 0, "name": 1, "email": 1}))
        return {"members": members}
    except Exception as e:
        raise HTTPException(status_code=400, detail="Invalid group ID")

@router.get("/messages/personal_history")
async def get_personal_message_history(user_email: str, partner_email: str):
    messages = list(db.messages.find({
        "group_id": None,
        "$or": [
            {"sender_email": user_email, "recipient_email": partner_email},
            {"sender_email": partner_email, "recipient_email": user_email}
        ]
    }).sort("timestamp", 1))
    
    formatted = []
    for m in messages:
        formatted.append({
            "id": str(m["_id"]),
            "sender_email": m.get("sender_email"),
            "recipient_email": m.get("recipient_email"),
            "content": m.get("content"),
            "timestamp": m.get("timestamp", datetime.now()).isoformat()
        })
    return {"messages": formatted}

@router.get("/messages/group_history")
async def get_group_message_history(group_id: str):
    messages = list(db.messages.find({"group_id": group_id}).sort("timestamp", 1))
    
    formatted = []
    for m in messages:
        sender = db.users.find_one({"email": m.get("sender_email")})
        sender_name = sender["name"] if sender else "Unknown"
        
        formatted.append({
            "id": str(m["_id"]),
            "sender_email": m.get("sender_email"),
            "sender_name": sender_name,
            "content": m.get("content"),
            "timestamp": m.get("timestamp", datetime.now()).isoformat()
        })
    return {"messages": formatted}

@router.put("/messages/{msg_id}")
async def edit_message(msg_id: str, payload: dict):
    user_email = payload.get("user_email")
    content = payload.get("content")
    try:
        obj_id = ObjectId(msg_id)
        msg = db.messages.find_one({"_id": obj_id})
        if not msg:
            raise HTTPException(status_code=404, detail="Message not found")
        if msg.get("sender_email") != user_email:
            raise HTTPException(status_code=403, detail="Unauthorized")
            
        db.messages.update_one({"_id": obj_id}, {"$set": {"content": content}})
        return {"message": "Message updated"}
    except Exception as e:
        raise HTTPException(status_code=400, detail="Invalid message ID")

@router.delete("/messages/{msg_id}")
async def delete_message(msg_id: str, user_email: str):
    try:
        obj_id = ObjectId(msg_id)
        msg = db.messages.find_one({"_id": obj_id})
        if not msg:
            raise HTTPException(status_code=404, detail="Message not found")
        if msg.get("sender_email") != user_email:
            raise HTTPException(status_code=403, detail="Unauthorized")
            
        db.messages.delete_one({"_id": obj_id})
        return {"message": "Message deleted"}
    except Exception as e:
        raise HTTPException(status_code=400, detail="Invalid message ID")
