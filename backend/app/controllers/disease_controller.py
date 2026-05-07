from app.services.prediction_service import analyze_disease
from app.services.treatment_service import (
    get_treatment_by_disease,
    get_all_diseases,
)
from app.services.firebase_service import (
    save_prediction_to_firebase,
    get_user_prediction_history,
    delete_prediction_by_id,
)


async def upload_and_analyze_controller(file, user_id: str):
    image_bytes = await file.read()

    result = analyze_disease(image_bytes)

    firebase_data = {
        "user_id": user_id,
        "filename": file.filename,
        "disease_name": result["disease_name"],
        "confidence": result["confidence"],
        "is_disease": result["is_disease"],
        "treatment_info": result["treatment_info"],
        "response_time_seconds": result["response_time_seconds"],
    }

    prediction_id = save_prediction_to_firebase(firebase_data)

    return {
        "success": True,
        "message": "Disease analysis completed successfully",
        "user_id": user_id,
        "prediction_id": prediction_id,
        **result,
    }


def get_treatment_controller(disease_name: str):
    treatment = get_treatment_by_disease(disease_name)

    if treatment is None:
        return {
            "success": False,
            "message": "Disease not found",
        }

    return {
        "success": True,
        "data": treatment,
    }


def get_all_diseases_controller():
    diseases = get_all_diseases()

    return {
        "success": True,
        "count": len(diseases),
        "data": diseases,
    }


def get_history_controller(user_id: str):
    history = get_user_prediction_history(user_id)

    return {
        "success": True,
        "user_id": user_id,
        "count": len(history),
        "data": history,
    }


def delete_history_controller(prediction_id: str):
    deleted = delete_prediction_by_id(prediction_id)

    if not deleted:
        return {
            "success": False,
            "message": "Prediction record not found",
        }

    return {
        "success": True,
        "message": "Prediction history deleted successfully",
    }