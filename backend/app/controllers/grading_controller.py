import os
import shutil

from fastapi import APIRouter, File, Form, HTTPException, UploadFile

from app.services.firebase_service import (
    get_user_history,
    save_prediction_result,
    upload_image_to_storage,
)
from app.services.grading_recommendation_service import get_recommendation

router = APIRouter()

# Temporary local folder for uploaded images before they go to Firebase Storage
UPLOAD_DIR = "uploads"
os.makedirs(UPLOAD_DIR, exist_ok=True)

# Allowed image MIME types
ALLOWED_TYPES = {"image/jpeg", "image/png", "image/webp", "image/jpg"}


@router.get("/")
def grading_home():
    """Health-check for the grading component."""
    return {"message": "Fruit Quality Grading component is running ✅"}


@router.post("/save-result")
async def save_result(
    user_id: str = Form(..., description="Unique user / farmer ID"),
    quality: str = Form(
        ...,
        description="One of: high_quality | medium_quality | low_quality",
    ),
    confidence: float = Form(
        ..., ge=0.0, le=1.0, description="Model confidence score (0.0 – 1.0)"
    ),
    file: UploadFile | None = File(None, description="Optional fruit image"),
):
    """
    Save a fruit quality grading result.

    - Accepts form data: user_id, quality, confidence
    - Optionally accepts an image file (JPEG / PNG / WEBP)
    - Uploads image to Firebase Storage (if provided)
    - Saves result + recommendation to Firestore
    - Returns saved record
    """
    # ── Validate quality label ─────────────────────────────────────────────────
    valid_labels = {"high_quality", "medium_quality", "low_quality"}
    if quality not in valid_labels:
        raise HTTPException(
            status_code=422,
            detail=f"Invalid quality value '{quality}'. Must be one of: {valid_labels}",
        )

    # ── Handle optional image upload ───────────────────────────────────────────
    image_url = None
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
            # Always clean up the temp file
            if local_path and os.path.exists(local_path):
                os.remove(local_path)

    # ── Get recommendation & save to Firestore ─────────────────────────────────
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


@router.get("/history/{user_id}")
def get_history(user_id: str):
    """
    Retrieve the grading history for a specific user.

    Returns list of past results sorted newest-first.
    """
    try:
        results = get_user_history(user_id)
    except Exception as exc:
        raise HTTPException(status_code=500, detail=f"Failed to fetch history: {str(exc)}")

    return {
        "success": True,
        "count": len(results),
        "data": results,
    }