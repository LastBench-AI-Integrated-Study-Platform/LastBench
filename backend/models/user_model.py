from pydantic import BaseModel, EmailStr

class UserSignup(BaseModel):
    name: str
    email: EmailStr
    password: str
    exam: str

class UserLogin(BaseModel):
    email: EmailStr
    password: str
