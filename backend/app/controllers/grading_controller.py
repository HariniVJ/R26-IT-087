import os
import shutil

from fastapi import HTTPException, UploadFile

from app.services.firebase_service import (
    delete_all_user_results,
    delete_single_result,
    get_single_result,
    get_user_history,
    save_prediction_result,
    upload_image_to_storage,
)
from app.services.grading_recommendation_service import get_recommendation

# Temp folder for images before Firebase Storage upload
UPLOAD_DIR = "uploads"
os.makedirs(UPLOAD_DIR, exist_ok=True)

ALLOWED_TYPES  = {"image/jpeg", "image/jpg", "image/png", "image/webp"}
VALID_QUALITIES = {"high_quality", "medium_quality", "low_quality"}


# ── CREATE ─────────────────────────────────────────────────────────────────────

async def handle_save_result(
    user_id: str,
    quality: str,
    confidence: float,
    file: UploadFile | None,
) -> dict:
    """
    Validate inputs, upload image (if provided), save result to Firestore.
    Called by POST /grading/save-result
    """
    # Validate quality label
    if quality not in VALID_QUALITIES:
        raise HTTPException(
            status_code=422,
            detail=f"Invalid quality '{quality}'. Must be one of: {VALID_QUALITIES}",
        )

    # Handle optional image
    image_url  = None
    local_path = None

    if file is not None:
        if file.content_type not in ALLOWED_TYPES:
            raise HTTPException(
                status_code=400,
                detail=f"Unsupported file type '{file.content_type}'. Allowed: {ALLOWED_TYPES}",
            )
        local_path = os.path.join(UPLOAD_DIR, f"{user_id}_{file.filename}")
        try:
            with open(local_path, "wb") as buffer:
                shutil.copyfileobj(file.file, buffer)
            image_url = upload_image_to_storage(local_path, user_id)
        finally:
            if local_path and os.path.exists(local_path):
                os.remove(local_path)

    # Get recommendation and save
    try:
        recommendation = get_recommendation(quality)
        result = save_prediction_result(
            user_id=user_id,
            quality=quality,
            confidence=confidence,
            recommendation=recommendation,
            image_url=image_url,
        )
    except Exception as exc:
        raise HTTPException(status_code=500, detail=f"Database error: {str(exc)}")

    return {
        "success": True,
        "message": "Prediction result saved successfully",
        "data": result,
    }


# ── READ ───────────────────────────────────────────────────────────────────────

def handle_get_history(user_id: str) -> dict:
    """
    Fetch all grading history for a user, newest first.
    Called by GET /grading/history/{user_id}
    """
    try:
        results = get_user_history(user_id)
    except Exception as exc:
        raise HTTPException(status_code=500, detail=f"Failed to fetch history: {str(exc)}")

    return {
        "success": True,
        "count":   len(results),
        "data":    results,
    }


def handle_get_single(result_id: str) -> dict:
    """
    Fetch one grading result by its document ID.
    Called by GET /grading/result/{result_id}
    """
    try:
        result = get_single_result(result_id)
    except Exception as exc:
        raise HTTPException(status_code=500, detail=f"Failed to fetch result: {str(exc)}")

    if result is None:
        raise HTTPException(status_code=404, detail=f"Result '{result_id}' not found")

    return {
        "success": True,
        "data":    result,
    }


# ── DELETE ─────────────────────────────────────────────────────────────────────

def handle_delete_single(result_id: str) -> dict:
    """
    Delete one grading result by document ID.
    Called by DELETE /grading/result/{result_id}
    """
    try:
        deleted = delete_single_result(result_id)
    except Exception as exc:
        raise HTTPException(status_code=500, detail=f"Failed to delete: {str(exc)}")

    if not deleted:
        raise HTTPException(status_code=404, detail=f"Result '{result_id}' not found")

    return {
        "success": True,
        "message": f"Result '{result_id}' deleted successfully",
    }


def handle_delete_all(user_id: str) -> dict:
    """
    Delete all grading results for a user.
    Called by DELETE /grading/history/{user_id}
    """
    try:
        count = delete_all_user_results(user_id)
    except Exception as exc:
        raise HTTPException(status_code=500, detail=f"Failed to delete history: {str(exc)}")

    return {
        "success": True,
        "message": f"Deleted {count} result(s) for user '{user_id}'",
        "deleted_count": count,
    }