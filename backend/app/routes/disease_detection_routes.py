from fastapi import APIRouter, UploadFile, File, Form, HTTPException
from typing import List

from app.controllers.disease_controller import (
    upload_and_analyze_controller,
    get_treatment_controller,
    get_all_diseases_controller,
    get_history_controller
)

router = APIRouter(
    prefix="/api/disease",
    tags=["Disease Detection"]
)

@router.get("/health")
def health_check():
    return {
        "success": True,
        "message": "Disease Detection Service is running"
    }

@router.post("/upload-and-analyze")
async def upload_and_analyze(
    file: UploadFile = File(...),
    user_id: str = Form(...)
):
    allowed_extensions = [".jpg", ".jpeg", ".png"]

    filename = file.filename.lower()

    if not any(filename.endswith(ext) for ext in allowed_extensions):
        raise HTTPException(
            status_code=400,
            detail="Only image files are allowed"
        )

    return await upload_and_analyze_controller(file, user_id)
@router.get("/treatment/{disease_name}")
def get_treatment(disease_name: str):
    return get_treatment_controller(disease_name)

@router.get("/all-diseases")
def all_diseases():
    return get_all_diseases_controller()

@router.get("/history/{user_id}")
def prediction_history(user_id: str):
    return get_history_controller(user_id)

@router.post("/batch-analyze")
async def batch_analyze(
    files: List[UploadFile] = File(...),
    user_id: str = Form(...)
):
    if len(files) > 10:
        raise HTTPException(status_code=400, detail="Maximum 10 images allowed")

    results = []

    for file in files:
        if not file.content_type.startswith("image/"):
            results.append({
                "filename": file.filename,
                "success": False,
                "message": "Invalid file type"
            })
            continue

        result = await upload_and_analyze_controller(file, user_id)
        results.append(result)

    return {
        "success": True,
        "message": "Batch analysis completed",
        "count": len(results),
        "data": results
    }