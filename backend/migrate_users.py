# backend/migrate_users.py
# Run this ONCE to add username to all existing users who don't have it.
#
# Usage:
#   cd backend
#   python migrate_users.py

from db.connection import db

def migrate():
    users = db.users.find({})
    updated = 0
    skipped = 0

    for user in users:
        if user.get("username"):
            skipped += 1
            continue  # already has username

        # Derive username from email
        email    = user.get("email", "")
        username = email.split("@")[0].lower() if email else f"user_{str(user['_id'])[:6]}"

        db.users.update_one(
            {"_id": user["_id"]},
            {"$set": {
                "username":  username,
                "is_online": False,
                "socket_id": "",
            }}
        )
        print(f"  ✅ Updated: {email} → username: {username}")
        updated += 1

    print(f"\nDone! Updated: {updated}, Skipped (already had username): {skipped}")

if __name__ == "__main__":
    migrate()