from pydantic import BaseModel, Field
from typing import Optional
from bson import ObjectId


# ── Helper: make ObjectId serializable ───────────────────────────────────────
class PyObjectId(ObjectId):
    @classmethod
    def __get_validators__(cls):
        yield cls.validate

    @classmethod
    def validate(cls, v):
        if not ObjectId.is_valid(v):
            raise ValueError("Invalid ObjectId")
        return ObjectId(v)

    @classmethod
    def __get_pydantic_json_schema__(cls, schema):
        schema.update(type="string")
        return schema


# ── Request: Create a new deadline ───────────────────────────────────────────
class DeadlineCreate(BaseModel):
    title:   str
    date:    str    # "YYYY-MM-DD"


# ── Request: Update status ────────────────────────────────────────────────────
class DeadlineStatusUpdate(BaseModel):
    status:  str    # "pending" | "completed"


# ── Response: what the API sends back ────────────────────────────────────────
class DeadlineResponse(BaseModel):
    id:       str         # MongoDB _id as string
    user_id:  str
    title:    str
    date:     str
    status:   str
    notified: bool

    class Config:
        populate_by_name = True
        arbitrary_types_allowed = True


# ── Helper: convert MongoDB doc → DeadlineResponse ───────────────────────────
def deadline_to_response(doc: dict) -> DeadlineResponse:
    return DeadlineResponse(
        id=str(doc["_id"]),
        user_id=str(doc["user_id"]),
        title=doc["title"],
        date=doc["date"],
        status=doc.get("status", "pending"),
        notified=doc.get("notified", False),
    )