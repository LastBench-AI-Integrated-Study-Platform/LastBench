from fastapi import APIRouter, HTTPException, Form, Request
from fastapi.responses import HTMLResponse
from pydantic import BaseModel
from datetime import datetime
from typing import Optional
from utils.security import hash_password, verify_password
from db.connection import db
from models.user_model import UserSignup, UserLogin

# Models for reset flow
class ResetCreate(BaseModel):
    session_id: str

class ResetDecision(BaseModel):
    action: str  # 'accept' or 'reject'
    email: Optional[str] = None

class ResetPasswordRequest(BaseModel):
    session_id: str
    email: str
    new_password: str

from utils.security import hash_password, verify_password
from db.connection import db

router = APIRouter(prefix="/auth", tags=["Auth"])


@router.post("/signup")
async def signup(user: UserSignup):
    existing = db.users.find_one({"email": user.email})
    if existing:
        raise HTTPException(status_code=400, detail="Email already registered")

    db.users.insert_one({
        "name": user.name,
        "email": user.email,
        "password": hash_password(user.password),
        "exam": user.exam
    })

    return {"message": "Signup successful"}


@router.post("/login")
async def login(user: UserLogin):
    db_user = db.users.find_one({"email": user.email})
    if not db_user:
        raise HTTPException(status_code=401, detail="Invalid credentials")

    if not verify_password(user.password, db_user["password"]):
        raise HTTPException(status_code=401, detail="Invalid credentials")

    return {
        "message": "Login successful",
        "user": {
            "name": db_user["name"],
            "email": db_user["email"],
            "exam": db_user["exam"]
        }
    }


# ---------------------------------------------------------------------------
# Password reset via OTP email flow
# ---------------------------------------------------------------------------
class ResetRequest(BaseModel):
    email: str

class ResetVerify(BaseModel):
    email: str
    otp: str

from utils.email import send_otp_email


import os

def _generate_otp(code_len: int = 6) -> str:
    from random import randint
    minv = 10 ** (code_len - 1)
    maxv = (10 ** code_len) - 1
    return str(randint(minv, maxv))


@router.post("/reset_password/request")
async def request_password_reset(payload: ResetRequest):
    """Generate an OTP and send it to the user's registered email."""
    email = payload.email.lower()
    user = db.users.find_one({"email": email})
    if not user:
        # Do not reveal whether user exists
        return {"message": "If the email is registered, an OTP has been sent"}

    otp = _generate_otp(6)
    expires_at = datetime.now().timestamp() + (10 * 60)  # 10 minutes
    doc = {
        "email": email,
        "otp": otp,
        "created_at": datetime.now().isoformat(),
        "expires_at": expires_at,
        "used": False,
    }
    db.password_otps.insert_one(doc)

    # Send email (best-effort) and log errors
    send_ok = False
    try:
        send_otp_email(email, otp)
        send_ok = True
        print(f"[auth] Sent OTP to {email}")
    except Exception as e:
        # Log the error so developers can see why email failed
        print(f"[auth] Failed to send OTP to {email}: {e}")

    # For local development, return the OTP when DEV_SHOW_OTP=true (do NOT enable in production)
    if os.environ.get("DEV_SHOW_OTP", "false").lower() == "true":
        return {"message": "If the email is registered, an OTP has been sent", "sent": send_ok, "otp": otp}

    return {"message": "If the email is registered, an OTP has been sent", "sent": send_ok}


@router.get("/reset_password/debug")
def debug_get_latest_otp(email: str):
    """Return the most recent OTP for the given email (DEV only).
    Enable by setting DEV_SHOW_OTP=true in environment. This is intentionally unsafe for production."""
    if os.environ.get("DEV_SHOW_OTP", "false").lower() != "true":
        raise HTTPException(status_code=404, detail="Not found")

    doc = db.password_otps.find_one({"email": email}, sort=[("created_at", -1)])
    if not doc:
        return {"found": False}

    return {
        "found": True,
        "otp": doc.get("otp"),
        "created_at": doc.get("created_at"),
        "expires_at": doc.get("expires_at"),
        "used": doc.get("used", False),
    }


@router.post("/reset_password/verify")
async def verify_otp(payload: ResetVerify):
    """Verify the OTP for the given email."""
    email = payload.email.lower()
    otp = payload.otp.strip()

    # Find latest unused OTP for this email
    doc = db.password_otps.find_one({"email": email, "used": False}, sort=[("created_at", -1)])
    if not doc:
        raise HTTPException(status_code=400, detail="Invalid or expired OTP")

    if doc.get("expires_at", 0) < datetime.now().timestamp():
        raise HTTPException(status_code=400, detail="Invalid or expired OTP")

    if doc.get("otp") != otp:
        raise HTTPException(status_code=400, detail="Invalid or expired OTP")

    # Mark this OTP as verified/used to prevent replay
    db.password_otps.update_one({"_id": doc["_id"]}, {"$set": {"used": True, "verified_at": datetime.now().isoformat()}})

    return {"message": "OTP verified"}


class ResetPasswordRequest(BaseModel):
    session_id: Optional[str] = None
    email: Optional[str] = None
    otp: Optional[str] = None
    new_password: str


@router.post("/reset_password")
def reset_password(req: ResetPasswordRequest):
    """Reset the user's password using either legacy session_id flow or OTP + email."""
    # Legacy session-based flow
    if req.session_id:
        sess = db.reset_sessions.find_one({"session_id": req.session_id})
        if not sess:
            raise HTTPException(status_code=404, detail="Session not found")

        if sess.get("status") != "accepted":
            raise HTTPException(status_code=403, detail="Reset session not accepted")

        # If approved_email present, enforce it matches provided email
        approved = sess.get("approved_email")
        if approved and approved.lower() != (req.email or "").lower():
            raise HTTPException(status_code=403, detail="Email mismatch for approved reset")

        user = db.users.find_one({"email": req.email})
        if not user:
            raise HTTPException(status_code=404, detail="User not found")

        db.users.update_one({"email": req.email}, {"$set": {"password": hash_password(req.new_password)}})
        db.reset_sessions.update_one({"session_id": req.session_id}, {"$set": {"status": "used", "used_at": datetime.now().isoformat()}})

        return {"message": "Password reset successful"}

    # OTP-based flow
    if not req.email or not req.otp:
        raise HTTPException(status_code=400, detail="Email and OTP are required")

    email = req.email.lower()
    otp = req.otp.strip()

    doc = db.password_otps.find_one({"email": email, "used": True}, sort=[("created_at", -1)])
    # We expect the OTP to have been marked as used/verified by /verify endpoint
    if not doc or doc.get("otp") != otp:
        raise HTTPException(status_code=400, detail="Invalid or expired OTP")

    # final safety check: ensure not expired
    if doc.get("expires_at", 0) < datetime.now().timestamp():
        raise HTTPException(status_code=400, detail="Invalid or expired OTP")

    user = db.users.find_one({"email": email})
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    # Update password and mark OTP used to prevent reuse
    db.users.update_one({"email": email}, {"$set": {"password": hash_password(req.new_password)}})
    db.password_otps.update_one({"_id": doc["_id"]}, {"$set": {"used": True, "used_at": datetime.now().isoformat()}})

    return {"message": "Password reset successful"}

