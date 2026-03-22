import asyncio
import os
from datetime import datetime
from db.connection import db

async def seed_data():
    user_email = "praneetha7597@gmail.com"
    bot_email = "testbot@gmail.com"
    
    # Ensure bot user exists
    if not db.users.find_one({"email": bot_email}):
        db.users.insert_one({"email": bot_email, "name": "Test Bot", "password": "hash"})

    # Check for or create a Test Group
    group = db.groups.find_one({"name": "Test Group"})
    if not group:
        result = db.groups.insert_one({
            "name": "Test Group",
            "description": "Group for testing unread highlights.",
            "members": [user_email, bot_email],
            "created_at": datetime.now()
        })
        group_id = str(result.inserted_id)
    else:
        group_id = str(group["_id"])
        # Ensure user is in group
        if user_email not in group.get("members", []):
            db.groups.update_one({"_id": group["_id"]}, {"$push": {"members": user_email}})

    # Insert an unread message from the bot
    db.messages.insert_one({
        "sender_email": bot_email,
        "content": "Hey Praneetha! Did you see the new WhatsApp-style separators and the unread message outline?",
        "timestamp": datetime.now(),
        "group_id": group_id,
        "recipient_email": None,
        "is_read": False,
        "read_by": [bot_email]  # Only read by the bot since it sent it
    })

    print(f"Test message successfully seeded into Group ID: {group_id}")

if __name__ == "__main__":
    asyncio.run(seed_data())
