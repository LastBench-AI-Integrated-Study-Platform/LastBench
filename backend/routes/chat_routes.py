import re
from fastapi import APIRouter, HTTPException, Depends, WebSocket, WebSocketDisconnect
from typing import List, Optional
from datetime import datetime
from bson import ObjectId
from db.connection import db
from models.chat_models import GroupCreate, MessageSend, MessageEdit
from websocket_manager import manager

router = APIRouter(prefix="/chat", tags=["Chat"])

@router.websocket("/ws/{user_email}")
async def websocket_endpoint(websocket: WebSocket, user_email: str):
    await manager.connect(user_email, websocket)
    try:
        while True:
            # We don't expect messages *from* the client via WS right now, 
            # they use POST /chat/messages. We just keep connection open.
            data = await websocket.receive_text()
    except WebSocketDisconnect:
        manager.disconnect(user_email, websocket)

@router.get("/users/search")
async def search_users(query: str, user_email: str):
    if not query:
        return {"users": []}
    
    # Case-insensitive regex search on name
    regex = re.compile(f".*{re.escape(query)}.*", re.IGNORECASE)
    
    users = list(db.users.find({
        "name": {"$regex": regex},
        "email": {"$ne": user_email}
    }).limit(20))
    
    formatted_users = []
    for u in users:
        formatted_users.append({
            "name": u.get("name", u["email"]),
            "email": u["email"]
        })
        
    return {"users": formatted_users}

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

@router.post("/groups/{group_id}/join")
async def join_group(group_id: str, user_email: str):
    try:
        group_obj_id = ObjectId(group_id)
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid group ID format")

    group = db.groups.find_one({"_id": group_obj_id})
    if not group:
        raise HTTPException(status_code=404, detail="Group not found")

    if user_email in group.get("members", []):
        return {"message": "User is already a member of this group"}

    db.groups.update_one(
        {"_id": group_obj_id},
        {"$addToSet": {"members": user_email}}
    )
    return {"message": "Successfully joined the group"}
@router.get("/groups/{group_id}/members")
def get_group_members(group_id: str):
    group = db.groups.find_one({"_id": ObjectId(group_id)})

    if not group:
        raise HTTPException(status_code=404, detail="Group not found")

    users = list(db.users.find({"email": {"$in": group["members"]}}))

    members = []
    for u in users:
        members.append({
            "name": u.get("name", u["email"]),
            "email": u["email"]
        })

    return {"members": members}
@router.get("/groups")
async def get_groups(user_email: str):
    # Fetch only groups where the user is a member
    groups = list(db.groups.find({"members": {"$in": [user_email]}}))
    
    formatted_groups = []
    for g in groups:
        # Calculate initials
        name_parts = g.get("name", "Unknown").split()
        initials = "".join([part[0].upper() for part in name_parts[:2]]) if name_parts else "U"
        
        active_count = len(g.get("members", []))
        
        # Count unread messages in this group for this user
        # We assume messages have a `read_by` list. If it doesn't exist, we consider it unread if user didn't send it.
        # This is a basic implementation of group unread counts.
        unread_count = db.messages.count_documents({
            "group_id": str(g["_id"]),
            "sender_email": {"$ne": user_email},
            "read_by": {"$ne": user_email}
        })
        
        formatted_groups.append({
            "id": str(g["_id"]),
            "name": g.get("name", "Unknown"),
            "initials": initials,
            "active": active_count,
            "unread_count": unread_count,
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
        "recipient_email": msg.recipient_email,
        "is_read": False,
        "read_by": [msg.sender_email] if msg.group_id else []
    }
    result = db.messages.insert_one(new_msg)
    
    # Broadcast realtime event
    formatted_msg = {
        "id": str(result.inserted_id),
        "sender_email": msg.sender_email,
        "content": msg.content,
        "timestamp": new_msg["timestamp"].isoformat(),
        "is_read": False,
        "group_id": msg.group_id,
        "recipient_email": msg.recipient_email
    }
    
    notify_emails = []
    if msg.group_id:
        group = db.groups.find_one({"_id": ObjectId(msg.group_id)})
        if group:
            notify_emails = group.get("members", [])
    else:
        notify_emails = [msg.sender_email, msg.recipient_email] if msg.recipient_email else [msg.sender_email]
        
    await manager.notify_users(notify_emails, "new_message", formatted_msg)
    
    return {"message": "Message sent", "message_id": str(result.inserted_id)}

@router.get("/personal")
async def get_personal_chats(user_email: str):
    # Fetch ALL users except the current user
    users = list(db.users.find({"email": {"$ne": user_email}}))
    
    conversations = []
    for u in users:
        partner_email = u["email"]
        partner_name = u.get("name", partner_email)
        
        # Get latest message between user_email and partner_email
        latest_msg = db.messages.find_one({
            "$or": [
                {"sender_email": user_email, "recipient_email": partner_email, "group_id": None},
                {"sender_email": partner_email, "recipient_email": user_email, "group_id": None}
            ]
        }, sort=[("timestamp", -1)])
        
        if latest_msg:
            # Count unread messages from partner to user
            unread_count = db.messages.count_documents({
                "sender_email": partner_email,
                "recipient_email": user_email,
                "group_id": None,
                "is_read": False
            })
            
            time_obj = latest_msg.get("timestamp", datetime.now())
            time_str = time_obj.strftime("%I:%M %p")
            msg_content = latest_msg.get("content", "")
            
            conversations.append({
                "name": partner_name,
                "email": partner_email,
                "message": msg_content,
                "time": time_str,
                "timestamp": time_obj,
                "unread_count": unread_count
            })
            
    # Sort conversations by latest message timestamp descending
    conversations.sort(key=lambda x: x["timestamp"], reverse=True)
    
    # Convert timestamp to isoformat for frontend
    for c in conversations:
        if "timestamp" in c:
            c["timestamp"] = c["timestamp"].isoformat()
            
    return {"chats": conversations}

@router.get("/personal/messages")
async def get_personal_messages(user_email: str, partner_email: str):
    # Mark incoming unread messages from partner_email as read
    db.messages.update_many(
        {
            "sender_email": partner_email,
            "recipient_email": user_email,
            "group_id": None,
            "is_read": False
        },
        {"$set": {"is_read": True}}
    )
    
    # Fetch all messages between these two users
    messages = list(db.messages.find({
        "$or": [
            {"sender_email": user_email, "recipient_email": partner_email, "group_id": None},
            {"sender_email": partner_email, "recipient_email": user_email, "group_id": None}
        ]
    }).sort("timestamp", 1))
    
    formatted_messages = []
    for m in messages:
        formatted_messages.append({
            "id": str(m["_id"]),
            "sender_email": m.get("sender_email"),
            "content": m.get("content"),
            "timestamp": m.get("timestamp", datetime.now()).isoformat(),
            "is_read": m.get("is_read", True),
            "is_edited": m.get("is_edited", False)
        })
        
    return {"messages": formatted_messages}

@router.get("/groups/{group_id}/messages")
async def get_group_messages(group_id: str, user_email: str):
    # Verify user is in group
    group = db.groups.find_one({"_id": ObjectId(group_id), "members": {"$in": [user_email]}})
    if not group:
        raise HTTPException(status_code=403, detail="Not a member of this group or group not found")
        
    # Mark messages as read by pushing user_email to read_by array
    db.messages.update_many(
        {
            "group_id": group_id,
            "read_by": {"$ne": user_email}
        },
        {"$addToSet": {"read_by": user_email}}
    )
        
    # Fetch messages
    messages = list(db.messages.find({"group_id": group_id}).sort("timestamp", 1))
    
    # We want to return sender names. Let's get all unique sender emails.
    sender_emails = list(set([m.get("sender_email") for m in messages if m.get("sender_email")]))
    
    # Fetch users match those emails
    users = list(db.users.find({"email": {"$in": sender_emails}}))
    email_to_name = {u["email"]: u.get("name", u["email"]) for u in users}
    
    formatted_messages = []
    for m in messages:
        sender_email = m.get("sender_email")
        sender_name = email_to_name.get(sender_email, sender_email)
        
        formatted_messages.append({
            "id": str(m["_id"]),
            "sender_email": sender_email,
            "sender_name": sender_name,
            "content": m.get("content"),
            "timestamp": m.get("timestamp", datetime.now()).isoformat(),
            "is_edited": m.get("is_edited", False)
        })
        
    return {"messages": formatted_messages}

@router.put("/messages/{message_id}")
async def edit_message(message_id: str, email: str, edit_data: MessageEdit):
    message = db.messages.find_one({"_id": ObjectId(message_id)})
    if not message:
        raise HTTPException(status_code=404, detail="Message not found")
        
    if message.get("sender_email") != email:
        raise HTTPException(status_code=403, detail="Not authorized to edit this message")
        
    db.messages.update_one(
        {"_id": ObjectId(message_id)},
        {"$set": {"content": edit_data.content, "is_edited": True}}
    )

    # Broadcast realtime event
    notify_emails = []
    group_id = message.get("group_id")
    if group_id:
        group = db.groups.find_one({"_id": ObjectId(group_id)})
        if group:
            notify_emails = group.get("members", [])
    else:
        notify_emails = [message.get("sender_email"), message.get("recipient_email")]

    await manager.notify_users(
        notify_emails, 
        "message_edited", 
        {"id": message_id, "content": edit_data.content, "group_id": group_id, "recipient_email": message.get("recipient_email")}
    )

    return {"message": "Message edited successfully"}

@router.delete("/messages/{message_id}")
async def delete_message(message_id: str, email: str):
    message = db.messages.find_one({"_id": ObjectId(message_id)})
    if not message:
        raise HTTPException(status_code=404, detail="Message not found")
        
    if message.get("sender_email") != email:
        raise HTTPException(status_code=403, detail="Not authorized to delete this message")
        
    db.messages.delete_one({"_id": ObjectId(message_id)})
    
    # Broadcast realtime event
    notify_emails = []
    group_id = message.get("group_id")
    if group_id:
        group = db.groups.find_one({"_id": ObjectId(group_id)})
        if group:
            notify_emails = group.get("members", [])
    else:
        notify_emails = [message.get("sender_email"), message.get("recipient_email")]

    await manager.notify_users(
        notify_emails, 
        "message_deleted", 
        {"id": message_id, "group_id": group_id, "recipient_email": message.get("recipient_email")}
    )

    return {"message": "Message deleted successfully"}
