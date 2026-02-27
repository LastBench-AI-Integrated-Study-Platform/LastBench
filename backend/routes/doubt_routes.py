"""
Doubt section routes - API endpoints for Q&A functionality
"""

from fastapi import APIRouter, HTTPException, File, UploadFile
from typing import Optional, List
import os
from pathlib import Path

from models.doubt_model import (
    DoubtCreate, CommentCreate, ReplyCreate,
    DoubtUpdate, CommentUpdate
)
from services.doubt_services import (
    create_doubt, get_all_doubts, get_doubt_by_id,
    update_doubt, delete_doubt,
    add_comment, update_comment, delete_comment,
    add_reply, delete_reply,
    get_doubt_statistics
)

router = APIRouter(prefix="/doubts", tags=["Doubts"])

# ============================================================================
# CONFIGURATION
# ============================================================================

UPLOAD_DIR = Path("uploads/doubt_images")
UPLOAD_DIR.mkdir(parents=True, exist_ok=True)

ALLOWED_EXTENSIONS = {"jpg", "jpeg", "png", "gif", "webp"}
MAX_FILE_SIZE = 5 * 1024 * 1024  # 5MB


# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

def validate_image_upload(file: UploadFile) -> bool:
    """Validate uploaded image file"""
    if not file.filename:
        return False
    
    ext = Path(file.filename).suffix.lower().lstrip(".")
    return ext in ALLOWED_EXTENSIONS


async def save_image(file: UploadFile) -> Optional[str]:
    """Save uploaded image and return file path"""
    try:
        if not validate_image_upload(file):
            return None

        # Generate unique filename
        import uuid
        unique_filename = f"{uuid.uuid4()}_{file.filename}"
        filepath = UPLOAD_DIR / unique_filename

        # Read and save file
        contents = await file.read()
        if len(contents) > MAX_FILE_SIZE:
            return None

        with open(filepath, "wb") as f:
            f.write(contents)

        return f"uploads/doubt_images/{unique_filename}"
    except Exception as e:
        print(f"Error saving image: {str(e)}")
        return None


# ============================================================================
# DOUBT ENDPOINTS
# ============================================================================

@router.post("/create")
async def create_new_doubt(
    doubt: DoubtCreate,
    user_id: Optional[str] = None
):
    """Create a new doubt"""
    result = create_doubt(doubt, user_id)
    
    if not result["success"]:
        raise HTTPException(status_code=400, detail=result["message"])
    
    return result


@router.get("/all")
async def get_all_doubts_endpoint(
    skip: int = 0,
    limit: int = 20,
    subject: Optional[str] = None
):
    """Get all doubts with pagination"""
    result = get_all_doubts(skip, limit, subject)
    
    if not result["success"]:
        raise HTTPException(status_code=400, detail=result["message"])
    
    return result


@router.get("/{doubt_id}")
async def get_doubt_endpoint(doubt_id: str):
    """Get a specific doubt by ID"""
    result = get_doubt_by_id(doubt_id)
    
    if not result["success"]:
        raise HTTPException(status_code=404, detail=result["message"])
    
    return result


@router.put("/{doubt_id}")
async def update_doubt_endpoint(doubt_id: str, doubt_update: DoubtUpdate):
    """Update a doubt"""
    result = update_doubt(doubt_id, doubt_update)
    
    if not result["success"]:
        raise HTTPException(status_code=400, detail=result["message"])
    
    return result


@router.delete("/{doubt_id}")
async def delete_doubt_endpoint(doubt_id: str):
    """Delete a doubt"""
    result = delete_doubt(doubt_id)
    
    if not result["success"]:
        raise HTTPException(status_code=400, detail=result["message"])
    
    return result


# ============================================================================
# COMMENT ENDPOINTS
# ============================================================================

@router.post("/{doubt_id}/comments")
async def add_comment_endpoint(doubt_id: str, comment: CommentCreate):
    """Add a comment/answer to a doubt"""
    result = add_comment(doubt_id, comment)
    
    if not result["success"]:
        raise HTTPException(status_code=400, detail=result["message"])
    
    return result


@router.put("/{doubt_id}/comments/{comment_id}")
async def update_comment_endpoint(
    doubt_id: str,
    comment_id: str,
    comment_update: CommentUpdate
):
    """Update a comment"""
    result = update_comment(doubt_id, comment_id, comment_update)
    
    if not result["success"]:
        raise HTTPException(status_code=400, detail=result["message"])
    
    return result


@router.delete("/{doubt_id}/comments/{comment_id}")
async def delete_comment_endpoint(doubt_id: str, comment_id: str):
    """Delete a comment"""
    result = delete_comment(doubt_id, comment_id)
    
    if not result["success"]:
        raise HTTPException(status_code=400, detail=result["message"])
    
    return result


# ============================================================================
# REPLY ENDPOINTS
# ============================================================================

@router.post("/{doubt_id}/comments/{comment_id}/replies")
async def add_reply_endpoint(
    doubt_id: str,
    comment_id: str,
    reply: ReplyCreate
):
    """Add a reply to a comment"""
    result = add_reply(doubt_id, comment_id, reply)
    
    if not result["success"]:
        raise HTTPException(status_code=400, detail=result["message"])
    
    return result


@router.delete("/{doubt_id}/comments/{comment_id}/replies/{reply_id}")
async def delete_reply_endpoint(
    doubt_id: str,
    comment_id: str,
    reply_id: str
):
    """Delete a reply from a comment"""
    result = delete_reply(doubt_id, comment_id, reply_id)
    
    if not result["success"]:
        raise HTTPException(status_code=400, detail=result["message"])
    
    return result


# ============================================================================
# FILE UPLOAD ENDPOINTS
# ============================================================================

@router.post("/upload-image")
async def upload_doubt_image(file: UploadFile = File(...)):
    """Upload an image for doubt/comment"""
    if not validate_image_upload(file):
        raise HTTPException(
            status_code=400,
            detail="Invalid file type. Allowed: jpg, jpeg, png, gif, webp"
        )

    filepath = await save_image(file)
    
    if not filepath:
        raise HTTPException(
            status_code=400,
            detail="Failed to save image. File may be too large."
        )

    return {
        "success": True,
        "message": "Image uploaded successfully",
        "filepath": filepath
    }


@router.post("/upload-images")
async def upload_multiple_doubt_images(files: List[UploadFile] = File(...)):
    """Upload multiple images for doubt/comment"""
    filepaths = []
    errors = []

    for file in files:
        if not validate_image_upload(file):
            errors.append(f"{file.filename}: Invalid file type")
            continue

        filepath = await save_image(file)
        
        if not filepath:
            errors.append(f"{file.filename}: Failed to save")
        else:
            filepaths.append(filepath)

    if not filepaths and errors:
        raise HTTPException(
            status_code=400,
            detail=f"No files uploaded. Errors: {errors}"
        )

    return {
        "success": True,
        "message": "Images uploaded successfully",
        "filepaths": filepaths,
        "errors": errors if errors else None
    }


# ============================================================================
# STATISTICS ENDPOINTS
# ============================================================================

@router.get("/stats/overview")
async def get_doubt_stats():
    """Get doubt section statistics"""
    result = get_doubt_statistics()
    
    if not result["success"]:
        raise HTTPException(status_code=400, detail=result["message"])
    
    return result
