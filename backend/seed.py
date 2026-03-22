import os
import sys
from datetime import datetime, timedelta

# ensure backend is in path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from db.connection import db

print("Starting seed script for specific email...")

me = "praneetha7597@gmail.com"

# Insert the user if it doesn't exist
if not db.users.find_one({"email": me}):
    db.users.insert_one({"email": me, "name": "Praneetha"})
    print(f"Created user {me}")

# Get a couple of other users
other_users = list(db.users.find({"email": {"$ne": me}}).limit(2))

# Fallback fake emails if no other users
other1 = other_users[0].get("email") if len(other_users) > 0 else "fake1@example.com"
other2 = other_users[1].get("email") if len(other_users) > 1 else "fake2@example.com"

print(f"Using emails for seeded data: {me}, {other1}, {other2}")

# duplicate groups
groups = [
    {
        "name": "Praneetha's Study Group",
        "description": "Preparing for finals",
        "members": [me, other1, other2],
        "created_at": datetime.now() - timedelta(days=2)
    },
    {
        "name": "Praneetha's Study Group", # intentional duplicate
        "description": "Duplicate group",
        "members": [me, other1],
        "created_at": datetime.now() - timedelta(days=1)
    },
    {
        "name": "Praneetha's Project Team",
        "description": "Science project",
        "members": [me, other2],
        "created_at": datetime.now() - timedelta(hours=5)
    },
    {
        "name": "Praneetha's Project Team", # intentional duplicate
        "description": "Science project backup",
        "members": [me, other1, other2],
        "created_at": datetime.now() - timedelta(hours=2)
    }
]

db.groups.insert_many(groups)
print(f"Inserted {len(groups)} groups for {me}.")

# duplicate messages (chats)
# Use the newly created group for group messages
sample_group = db.groups.find_one({"name": "Praneetha's Study Group"})
group_id = str(sample_group["_id"]) if sample_group else None

messages = [
    {
        "sender_email": me,
        "content": "Hey there! How is everyone doing?",
        "timestamp": datetime.now() - timedelta(minutes=60),
        "group_id": None,
        "recipient_email": other1
    },
    {
        "sender_email": other1,
        "content": "I'm good, you?",
        "timestamp": datetime.now() - timedelta(minutes=55),
        "group_id": None,
        "recipient_email": me
    },
    {
        "sender_email": me,
        "content": "Hey there! How is everyone doing? (duplicate message test)",
        "timestamp": datetime.now() - timedelta(minutes=50),
        "group_id": None,
        "recipient_email": other1
    },
    # Another personal chat sequence
    {
        "sender_email": other2,
        "content": "Did you finish the assignment, Praneetha?",
        "timestamp": datetime.now() - timedelta(minutes=30),
        "group_id": None,
        "recipient_email": me
    },
    {
        "sender_email": me,
        "content": "Almost done!",
        "timestamp": datetime.now() - timedelta(minutes=25),
        "group_id": None,
        "recipient_email": other2
    },
    {
        "sender_email": other2,
        "content": "Did you finish the assignment, Praneetha? (Duplicate)",
        "timestamp": datetime.now() - timedelta(minutes=20),
        "group_id": None,
        "recipient_email": me
    },
    # And duplicate messages to groups
    {
        "sender_email": me,
        "content": "Welcome to my group guys!",
        "timestamp": datetime.now() - timedelta(minutes=10),
        "group_id": group_id,
        "recipient_email": None
    },
    {
        "sender_email": me,
        "content": "Welcome to my group guys!", # exact duplicate
        "timestamp": datetime.now() - timedelta(minutes=9),
        "group_id": group_id,
        "recipient_email": None
    },
    {
        "sender_email": other1,
        "content": "Glad to be here with you",
        "timestamp": datetime.now() - timedelta(minutes=5),
        "group_id": group_id,
        "recipient_email": None
    },
    {
        "sender_email": other1,
        "content": "Glad to be here with you", # exact duplicate
        "timestamp": datetime.now() - timedelta(minutes=4),
        "group_id": group_id,
        "recipient_email": None
    }
]

db.messages.insert_many(messages)
print(f"Inserted {len(messages)} messages for {me}.")
print("Done inserting duplicate dummy data for specific email.")
