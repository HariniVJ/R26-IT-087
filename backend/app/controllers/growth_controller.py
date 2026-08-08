from fastapi import APIRouter, UploadFile, File, HTTPException, Query
from app.models.growth_model import predict_growth_stage
from app.services.growth_service import build_growth_result

router = APIRouter(prefix="/api/growth", tags=["Growth Stage Detection"])


@router.post("/predict")
async def predict(
    file: UploadFile = File(..., description="Upload a pomegranate fruit/plant image"),
    lat: float = Query(default=9.7,  description="Farm latitude"),
    lon: float = Query(default=80.0, description="Farm longitude"),
):
    # ── Accept all image types ───────────────────────────────────
    allowed_types = [
        "image/jpeg", "image/jpg", "image/png", "image/webp",
        "application/octet-stream", "binary/octet-stream",
    ]
    if file.content_type and file.content_type not in allowed_types:
        raise HTTPException(status_code=400,
            detail=f"Invalid file type. Please upload a JPEG or PNG image.")

    # ── Validate file size ───────────────────────────────────────
    image_bytes = await file.read()
    if len(image_bytes) > 10 * 1024 * 1024:
        raise HTTPException(status_code=400,
            detail="Image file is too large. Maximum size is 10 MB.")

    # ── Validate it is actually an image ─────────────────────────
    is_jpeg = image_bytes[:3] == b'\xff\xd8\xff'
    is_png  = image_bytes[:4] == b'\x89PNG'
    is_webp = image_bytes[8:12] == b'WEBP' if len(image_bytes) > 12 else False
    if not (is_jpeg or is_png or is_webp):
        raise HTTPException(status_code=400,
            detail="File does not appear to be a valid image.")

    # ── Run CNN prediction ───────────────────────────────────────
    try:
        prediction = predict_growth_stage(image_bytes)
    except FileNotFoundError as e:
        raise HTTPException(status_code=500, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Prediction error: {str(e)}")

    # ── Reject if not a pomegranate ──────────────────────────────
    if prediction.get("rejected"):
        raise HTTPException(
            status_code=422,
            detail={
                "error": "not_pomegranate",
                "message": prediction["rejection_reason"],
                "tip": "Please upload a clear, well-lit photo of a pomegranate fruit or plant."
            }
        )

    # ── Build full response ──────────────────────────────────────
    result = await build_growth_result(
        predicted_class=prediction["predicted_class"],
        confidence=prediction["confidence"],
        all_probabilities=prediction["all_probabilities"],
        lat=lat,
        lon=lon,
    )
    return result


@router.get("/health")
async def health_check():
    return {
        "status": "ok",
        "message": "Growth stage detection service is running",
    }