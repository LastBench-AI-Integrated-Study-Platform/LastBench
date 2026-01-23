from fastapi import APIRouter, HTTPException
from models.user_model import UserSignup, UserLogin
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
