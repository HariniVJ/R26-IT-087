from fastapi import APIRouter, File, Form, UploadFile

from app.controllers.grading_controller import (
    handle_delete_all,
    handle_delete_single,
    handle_get_history,
    handle_get_single,
    handle_save_result,
)

# This router is imported by main.py
router = APIRouter()


# ── Health check ───────────────────────────────────────────────────────────────

@router.get("/")
def grading_home():
    """Health check for the grading component."""
    return {"message": "Fruit Quality Grading component is running ✅"}


# ── CREATE ─────────────────────────────────────────────────────────────────────

@router.post("/save-result", summary="Save a grading result")
async def save_result(
    user_id: str = Form(..., description="Unique user / farmer ID"),
    quality: str = Form(..., description="One of: high_quality | medium_quality | low_quality"),
    confidence: float = Form(..., ge=0.0, le=1.0, description="Model confidence score (0.0 – 1.0)"),
    file: UploadFile | None = File(None, description="Optional fruit image (JPEG/PNG/WEBP)"),
):
    """
    Save a fruit quality grading result.
    - Uploads image to Firebase Storage (if provided)
    - Saves result + recommendation to Firestore
    - Returns saved record
    """
    return await handle_save_result(user_id, quality, confidence, file)


# ── READ ───────────────────────────────────────────────────────────────────────

@router.get("/history/{user_id}", summary="Get grading history for a user")
def get_history(user_id: str):
    """
    Retrieve all grading results for a user, sorted newest first.
    Use the quality filter on the Flutter side to filter by label.
    """
    return handle_get_history(user_id)


@router.get("/result/{result_id}", summary="Get one grading result by ID")
def get_single(result_id: str):
    """Retrieve one specific grading result by its Firestore document ID."""
    return handle_get_single(result_id)


# ── DELETE ─────────────────────────────────────────────────────────────────────

@router.delete("/result/{result_id}", summary="Delete one grading result")
def delete_single(result_id: str):
    """Delete one specific grading result by its Firestore document ID."""
    return handle_delete_single(result_id)


@router.delete("/history/{user_id}", summary="Delete all results for a user")
def delete_all(user_id: str):
    """Delete every grading result belonging to a specific user."""
    return handle_delete_all(user_id)