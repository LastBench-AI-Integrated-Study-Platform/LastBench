from bson import ObjectId
from models.deadline_model import deadline_collection
from models.deadline_schemas import DeadlineCreate, DeadlineStatusUpdate, DeadlineResponse


def _to_response(doc: dict) -> DeadlineResponse:
    return DeadlineResponse(
        id=str(doc["_id"]),
        user_id=doc["user_email"],  # email as identifier
        title=doc["title"],
        date=doc["date"],
        status=doc.get("status", "pending"),
        notified=doc.get("notified", False),
    )


def create_deadline(user_email: str, data: DeadlineCreate) -> DeadlineResponse:
    doc = {
        "user_email": user_email,
        "title":      data.title,
        "date":       data.date,
        "status":     "pending",
        "notified":   False,
    }
    result = deadline_collection.insert_one(doc)
    doc["_id"] = result.inserted_id
    return _to_response(doc)


def get_deadlines_by_user(user_email: str) -> list[DeadlineResponse]:
    docs = deadline_collection.find({"user_email": user_email})
    return [_to_response(doc) for doc in docs]


def update_deadline_status(deadline_id: str, user_email: str, data: DeadlineStatusUpdate):
    if not ObjectId.is_valid(deadline_id):
        return None
    result = deadline_collection.find_one_and_update(
        {"_id": ObjectId(deadline_id), "user_email": user_email},
        {"$set": {"status": data.status}},
        return_document=True,
    )
    return _to_response(result) if result else None


def delete_deadline(deadline_id: str, user_email: str) -> bool:
    if not ObjectId.is_valid(deadline_id):
        return False
    result = deadline_collection.delete_one(
        {"_id": ObjectId(deadline_id), "user_email": user_email}
    )
    return result.deleted_count > 0