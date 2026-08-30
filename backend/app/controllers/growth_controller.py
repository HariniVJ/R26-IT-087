from typing import Dict, Optional

from fastapi import (
    APIRouter,
    UploadFile,
    File,
    HTTPException,
    Query,
)

from pydantic import BaseModel

from app.models.growth_model import predict_growth_stage
from app.services.growth_service import build_growth_result


router = APIRouter(
    prefix="/api/growth",
    tags=["Growth Stage Detection"],
)


class GrowthAdvisoryRequest(BaseModel):
    predicted_class: str
    confidence: float
    all_probabilities: Dict[str, float]
    lat: float = 9.7
    lon: float = 80.0
    farmer_id: Optional[str] = None
    capture_date: Optional[str] = None


@router.post("/predict")
async def predict(
    file: UploadFile = File(
        ...,
        description="Upload a pomegranate fruit/plant image",
    ),
    lat: float = Query(
        default=9.7,
        description="Farm latitude",
    ),
    lon: float = Query(
        default=80.0,
        description="Farm longitude",
    ),
    farmer_id: Optional[str] = Query(
        default=None,
        description="Farmer Firebase user ID",
    ),
    capture_date: Optional[str] = Query(
        default=None,
        description="Image capture date in YYYY-MM-DD format",
    ),
):
    allowed_types = [
        "image/jpeg",
        "image/jpg",
        "image/png",
        "image/webp",
        "application/octet-stream",
        "binary/octet-stream",
    ]

    if (
        file.content_type
        and file.content_type not in allowed_types
    ):
        raise HTTPException(
            status_code=400,
            detail=(
                "Invalid file type. "
                "Please upload a JPEG, PNG, or WEBP image."
            ),
        )

    image_bytes = await file.read()

    if len(image_bytes) > 10 * 1024 * 1024:
        raise HTTPException(
            status_code=400,
            detail=(
                "Image file is too large. "
                "Maximum size is 10 MB."
            ),
        )

    is_jpeg = (
        image_bytes[:3] == b"\xff\xd8\xff"
    )

    is_png = (
        image_bytes[:4] == b"\x89PNG"
    )

    is_webp = (
        image_bytes[8:12] == b"WEBP"
        if len(image_bytes) > 12
        else False
    )

    if not (
        is_jpeg
        or is_png
        or is_webp
    ):
        raise HTTPException(
            status_code=400,
            detail=(
                "File does not appear to be "
                "a valid image."
            ),
        )

    try:
        prediction = predict_growth_stage(
            image_bytes
        )

    except FileNotFoundError as e:
        raise HTTPException(
            status_code=500,
            detail=str(e),
        )

    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=(
                f"Prediction error: {str(e)}"
            ),
        )

    if prediction.get("rejected"):
        raise HTTPException(
            status_code=422,
            detail={
                "error": "not_pomegranate",
                "message": prediction[
                    "rejection_reason"
                ],
                "tip": (
                    "Please upload a clear, "
                    "well-lit photo of a pomegranate "
                    "fruit or plant."
                ),
            },
        )

    try:
        result = await build_growth_result(
            predicted_class=prediction[
                "predicted_class"
            ],
            confidence=prediction[
                "confidence"
            ],
            all_probabilities=prediction[
                "all_probabilities"
            ],
            lat=lat,
            lon=lon,
            farmer_id=farmer_id,
            capture_date=capture_date,
        )

    except ValueError as e:
        raise HTTPException(
            status_code=400,
            detail=str(e),
        )

    return result


@router.post("/advisory")
async def growth_advisory(
    request: GrowthAdvisoryRequest,
):
    try:
        result = await build_growth_result(
            predicted_class=request.predicted_class,
            confidence=request.confidence,
            all_probabilities=request.all_probabilities,
            lat=request.lat,
            lon=request.lon,
            farmer_id=request.farmer_id,
            capture_date=request.capture_date,
        )

    except ValueError as e:
        raise HTTPException(
            status_code=400,
            detail=str(e),
        )

    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=(
                f"Growth advisory error: {str(e)}"
            ),
        )

    return result


@router.get("/health")
async def health_check():
    return {
        "status": "ok",
        "message": (
            "Growth stage detection service "
            "is running"
        ),
    }