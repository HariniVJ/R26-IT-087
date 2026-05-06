import os
import shutil
from fastapi import APIRouter, UploadFile, File, Form, HTTPException

from app.services.firebase_service import (
    upload_image_to_storage,
    save_prediction_result,
    get_user_history
)
from app.services.recommendation_service import get_recommendation

router = APIRouter()

UPLOAD_DIR = "uploads"
os.makedirs(UPLOAD_DIR, exist_ok=True)


@router.get("/")
def home():
    return {
        "message": "Pomegranate Quality Backend is running"
    }


@router.post("/save-result")
async def save_result(
    user_id: str = Form(...),
    quality: str = Form(...),
    confidence: float = Form(...),
    file: UploadFile | None = File(None),
):
    try:
        recommendation = get_recommendation(quality)
        image_url = None

        if file is not None:
            if not file.content_type.startswith("image/"):
                raise HTTPException(status_code=400, detail="Only image files are allowed")

            local_path = os.path.join(UPLOAD_DIR, file.filename)

            with open(local_path, "wb") as buffer:
                shutil.copyfileobj(file.file, buffer)

            image_url = upload_image_to_storage(local_path, user_id)

        result = save_prediction_result(
            user_id=user_id,
            quality=quality,
            confidence=confidence,
            recommendation=recommendation,
            image_url=image_url
        )

        return {
            "success": True,
            "message": "Prediction result saved successfully",
            "data": result
        }

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/history/{user_id}")
def history(user_id: str):
    results = get_user_history(user_id)

    return {
        "success": True,
        "count": len(results),
        "data": results
    }