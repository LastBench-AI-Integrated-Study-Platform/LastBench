from fastapi import APIRouter, HTTPException, Header, status
from models.deadline_schemas import DeadlineCreate, DeadlineStatusUpdate, DeadlineResponse
from services import deadline_service

router = APIRouter(prefix="/deadlines", tags=["Deadlines"])


def get_user_email(x_user_email: str = Header(...)) -> str:
    """Read user email from request header sent by Flutter."""
    if not x_user_email:
        raise HTTPException(status_code=401, detail="Not authenticated")
    return x_user_email


# ── POST /deadlines ───────────────────────────────────────────────────────────
@router.post("/", response_model=DeadlineResponse, status_code=status.HTTP_201_CREATED)
def create_deadline(data: DeadlineCreate, x_user_email: str = Header(...)):
    return deadline_service.create_deadline(x_user_email, data)


# ── GET /deadlines ────────────────────────────────────────────────────────────
@router.get("/", response_model=list[DeadlineResponse])
def list_deadlines(x_user_email: str = Header(...)):
    return deadline_service.get_deadlines_by_user(x_user_email)


# ── PATCH /deadlines/{id}/status ─────────────────────────────────────────────
@router.patch("/{deadline_id}/status", response_model=DeadlineResponse)
def update_status(deadline_id: str, data: DeadlineStatusUpdate, x_user_email: str = Header(...)):
    if data.status not in ("pending", "completed"):
        raise HTTPException(status_code=400, detail="Status must be 'pending' or 'completed'")
    result = deadline_service.update_deadline_status(deadline_id, x_user_email, data)
    if not result:
        raise HTTPException(status_code=404, detail="Deadline not found")
    return result


# ── DELETE /deadlines/{id} ────────────────────────────────────────────────────
@router.delete("/{deadline_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_deadline(deadline_id: str, x_user_email: str = Header(...)):
    deleted = deadline_service.delete_deadline(deadline_id, x_user_email)
    if not deleted:
        raise HTTPException(status_code=404, detail="Deadline not found")