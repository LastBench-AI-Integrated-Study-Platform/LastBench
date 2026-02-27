"""
Doubt section services - handles database operations for doubts, comments, and replies
"""

from db.connection import db
from models.doubt_model import (
    DoubtModel, CommentModel, ReplyModel,
    DoubtCreate, CommentCreate, ReplyCreate,
    DoubtUpdate, CommentUpdate
)
from datetime import datetime
from bson import ObjectId
from typing import List, Optional


# ============================================================================
# DOUBT SERVICES
# ============================================================================

def create_doubt(doubt: DoubtCreate, user_id: Optional[str] = None) -> dict:
    """Create a new doubt"""
    try:
        doubt_data = {
            "user_id": ObjectId(user_id) if user_id else None,
            "title": doubt.title,
            "content": doubt.content,
            "subject": doubt.subject or "General",
            "author": doubt.author,
            "authorAvatar": doubt.authorAvatar,
            "imageUrls": doubt.imageUrls or [],
            "tags": doubt.tags or [],
            "comments": [],
            "createdAt": datetime.utcnow(),
            "updatedAt": datetime.utcnow()
        }

        result = db.doubts.insert_one(doubt_data)
        doubt_data["_id"] = str(result.inserted_id)
        
        return {
            "success": True,
            "message": "Doubt created successfully",
            "doubt_id": str(result.inserted_id),
            "data": doubt_data
        }
    except Exception as e:
        return {
            "success": False,
            "message": f"Error creating doubt: {str(e)}"
        }


def get_all_doubts(skip: int = 0, limit: int = 20, subject: Optional[str] = None) -> dict:
    """Get all doubts with pagination and optional subject filter"""
    try:
        query = {}
        if subject:
            query["subject"] = subject

        total_doubts = db.doubts.count_documents(query)
        
        doubts = list(db.doubts.find(query)
                      .sort("createdAt", -1)
                      .skip(skip)
                      .limit(limit))
        
        # Convert ObjectIds to strings
        for doubt in doubts:
            doubt["_id"] = str(doubt["_id"])
            doubt["user_id"] = str(doubt.get("user_id", "")) if doubt.get("user_id") else None
            if doubt.get("comments"):
                for comment in doubt["comments"]:
                    comment["_id"] = str(comment.get("_id", ""))

        return {
            "success": True,
            "total": total_doubts,
            "skip": skip,
            "limit": limit,
            "data": doubts
        }
    except Exception as e:
        return {
            "success": False,
            "message": f"Error fetching doubts: {str(e)}"
        }


def get_doubt_by_id(doubt_id: str) -> dict:
    """Get a specific doubt by ID"""
    try:
        doubt = db.doubts.find_one({"_id": ObjectId(doubt_id)})
        
        if not doubt:
            return {
                "success": False,
                "message": "Doubt not found"
            }

        # Convert ObjectIds to strings
        doubt["_id"] = str(doubt["_id"])
        doubt["user_id"] = str(doubt.get("user_id", "")) if doubt.get("user_id") else None
        
        if doubt.get("comments"):
            for comment in doubt["comments"]:
                comment["_id"] = str(comment.get("_id", ""))

        return {
            "success": True,
            "data": doubt
        }
    except Exception as e:
        return {
            "success": False,
            "message": f"Error fetching doubt: {str(e)}"
        }


def update_doubt(doubt_id: str, doubt_update: DoubtUpdate) -> dict:
    """Update a doubt"""
    try:
        update_data = {}
        if doubt_update.title:
            update_data["title"] = doubt_update.title
        if doubt_update.content:
            update_data["content"] = doubt_update.content
        if doubt_update.subject:
            update_data["subject"] = doubt_update.subject
        if doubt_update.imageUrls is not None:
            update_data["imageUrls"] = doubt_update.imageUrls
        if doubt_update.tags is not None:
            update_data["tags"] = doubt_update.tags

        update_data["updatedAt"] = datetime.utcnow()

        result = db.doubts.update_one(
            {"_id": ObjectId(doubt_id)},
            {"$set": update_data}
        )

        if result.matched_count == 0:
            return {
                "success": False,
                "message": "Doubt not found"
            }

        return {
            "success": True,
            "message": "Doubt updated successfully"
        }
    except Exception as e:
        return {
            "success": False,
            "message": f"Error updating doubt: {str(e)}"
        }


def delete_doubt(doubt_id: str) -> dict:
    """Delete a doubt"""
    try:
        result = db.doubts.delete_one({"_id": ObjectId(doubt_id)})

        if result.deleted_count == 0:
            return {
                "success": False,
                "message": "Doubt not found"
            }

        return {
            "success": True,
            "message": "Doubt deleted successfully"
        }
    except Exception as e:
        return {
            "success": False,
            "message": f"Error deleting doubt: {str(e)}"
        }


# ============================================================================
# COMMENT SERVICES
# ============================================================================

def add_comment(doubt_id: str, comment: CommentCreate) -> dict:
    """Add a comment/answer to a doubt"""
    try:
        comment_data = {
            "_id": str(ObjectId()),
            "author": comment.author,
            "authorAvatar": comment.authorAvatar,
            "content": comment.content,
            "imageUrls": comment.imageUrls or [],
            "createdAt": datetime.utcnow(),
            "replies": []
        }

        result = db.doubts.update_one(
            {"_id": ObjectId(doubt_id)},
            {"$push": {"comments": comment_data}}
        )

        if result.matched_count == 0:
            return {
                "success": False,
                "message": "Doubt not found"
            }

        return {
            "success": True,
            "message": "Comment added successfully",
            "comment_id": comment_data["_id"],
            "data": comment_data
        }
    except Exception as e:
        return {
            "success": False,
            "message": f"Error adding comment: {str(e)}"
        }


def update_comment(doubt_id: str, comment_id: str, comment_update: CommentUpdate) -> dict:
    """Update a comment"""
    try:
        update_data = {}
        if comment_update.content:
            update_data["comments.$.content"] = comment_update.content
        if comment_update.imageUrls is not None:
            update_data["comments.$.imageUrls"] = comment_update.imageUrls

        if not update_data:
            return {
                "success": False,
                "message": "No fields to update"
            }

        result = db.doubts.update_one(
            {
                "_id": ObjectId(doubt_id),
                "comments._id": comment_id
            },
            {"$set": update_data}
        )

        if result.matched_count == 0:
            return {
                "success": False,
                "message": "Doubt or comment not found"
            }

        return {
            "success": True,
            "message": "Comment updated successfully"
        }
    except Exception as e:
        return {
            "success": False,
            "message": f"Error updating comment: {str(e)}"
        }


def delete_comment(doubt_id: str, comment_id: str) -> dict:
    """Delete a comment"""
    try:
        result = db.doubts.update_one(
            {"_id": ObjectId(doubt_id)},
            {"$pull": {"comments": {"_id": comment_id}}}
        )

        if result.matched_count == 0:
            return {
                "success": False,
                "message": "Doubt not found"
            }

        return {
            "success": True,
            "message": "Comment deleted successfully"
        }
    except Exception as e:
        return {
            "success": False,
            "message": f"Error deleting comment: {str(e)}"
        }


# ============================================================================
# REPLY SERVICES
# ============================================================================

def add_reply(doubt_id: str, comment_id: str, reply: ReplyCreate) -> dict:
    """Add a reply to a comment"""
    try:
        reply_data = {
            "_id": str(ObjectId()),
            "author": reply.author,
            "authorAvatar": reply.authorAvatar,
            "content": reply.content,
            "createdAt": datetime.utcnow()
        }

        result = db.doubts.update_one(
            {
                "_id": ObjectId(doubt_id),
                "comments._id": comment_id
            },
            {"$push": {"comments.$.replies": reply_data}}
        )

        if result.matched_count == 0:
            return {
                "success": False,
                "message": "Doubt or comment not found"
            }

        return {
            "success": True,
            "message": "Reply added successfully",
            "reply_id": reply_data["_id"],
            "data": reply_data
        }
    except Exception as e:
        return {
            "success": False,
            "message": f"Error adding reply: {str(e)}"
        }


def delete_reply(doubt_id: str, comment_id: str, reply_id: str) -> dict:
    """Delete a reply from a comment"""
    try:
        result = db.doubts.update_one(
            {
                "_id": ObjectId(doubt_id),
                "comments._id": comment_id
            },
            {"$pull": {"comments.$.replies": {"_id": reply_id}}}
        )

        if result.matched_count == 0:
            return {
                "success": False,
                "message": "Doubt or comment not found"
            }

        return {
            "success": True,
            "message": "Reply deleted successfully"
        }
    except Exception as e:
        return {
            "success": False,
            "message": f"Error deleting reply: {str(e)}"
        }


# ============================================================================
# STATISTICS SERVICES
# ============================================================================

def get_doubt_statistics() -> dict:
    """Get statistics about doubts"""
    try:
        total_doubts = db.doubts.count_documents({})
        total_comments = 0
        total_replies = 0

        doubts = list(db.doubts.find({}, {"comments": 1}))
        
        for doubt in doubts:
            for comment in doubt.get("comments", []):
                total_comments += 1
                total_replies += len(comment.get("replies", []))

        # Get subject distribution
        subject_distribution = list(db.doubts.aggregate([
            {"$group": {"_id": "$subject", "count": {"$sum": 1}}}
        ]))

        return {
            "success": True,
            "data": {
                "total_doubts": total_doubts,
                "total_comments": total_comments,
                "total_replies": total_replies,
                "subject_distribution": subject_distribution
            }
        }
    except Exception as e:
        return {
            "success": False,
            "message": f"Error fetching statistics: {str(e)}"
        }
