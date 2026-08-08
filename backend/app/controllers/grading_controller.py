import os
from fastapi import HTTPException, UploadFile

from app.services.firebase_service import (
    delete_all_user_results,
    delete_single_result,
    get_single_result,
    get_user_history,
    save_prediction_result,
)

from app.services.grading_recommendation_service import get_recommendation

UPLOAD_DIR = "uploads"
os.makedirs(UPLOAD_DIR, exist_ok=True)

VALID_QUALITIES = {
    "high_quality",
    "medium_quality",
    "low_quality",
}


async def handle_save_result(
    user_id: str,
    quality: str,
    confidence: float,
    file: UploadFile | None,
) -> dict:

    if quality not in VALID_QUALITIES:
        raise HTTPException(
            status_code=422,
            detail="Invalid quality label",
        )

    try:
        recommendation = get_recommendation(quality)

        # NO IMAGE STORAGE
        result = save_prediction_result(
            user_id=user_id,
            quality=quality,
            confidence=confidence,
            recommendation=recommendation,
            image_url=None,
        )

        return {
            "success": True,
            "message": "Prediction result saved successfully",
            "data": result,
        }

    except Exception as exc:
        raise HTTPException(
            status_code=500,
            detail=f"Database error: {str(exc)}",
        )


def handle_get_history(user_id: str) -> dict:
    results = get_user_history(user_id)

    return {
        "success": True,
        "count": len(results),
        "data": results,
    }


def handle_get_single(result_id: str) -> dict:
    result = get_single_result(result_id)

    if result is None:
        raise HTTPException(
            status_code=404,
            detail="Result not found",
        )

    return {
        "success": True,
        "data": result,
    }


def handle_delete_single(result_id: str) -> dict:
    deleted = delete_single_result(result_id)

    if not deleted:
        raise HTTPException(
            status_code=404,
            detail="Result not found",
        )

    return {
        "success": True,
        "message": "Result deleted successfully",
    }


def handle_delete_all(user_id: str) -> dict:
    count = delete_all_user_results(user_id)

    return {
        "success": True,
        "message": f"Deleted {count} result(s)",
        "deleted_count": count,
    }