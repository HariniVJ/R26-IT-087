import os
import uuid
from datetime import datetime, timezone
from firebase_admin import firestore

from app.firebase_config import db, bucket

def upload_image_to_storage(local_path: str, user_id: str) -> str:
    file_extension = os.path.splitext(local_path)[1]
    file_name = f"quality_uploads/{user_id}/{uuid.uuid4()}{file_extension}"

    blob = bucket.blob(file_name)
    blob.upload_from_filename(local_path)
    blob.make_public()

    return blob.public_url


def save_prediction_result(
    user_id: str,
    quality: str,
    confidence: float,
    recommendation: str,
    image_url: str | None = None,
):
    data = {
        "user_id": user_id,
        "quality": quality,
        "confidence": confidence,
        "recommendation": recommendation,
        "image_url": image_url,
        "created_at": datetime.now(timezone.utc),
        "component": "fruit_quality_grading"
    }

    doc_ref = db.collection("quality_results").document()
    doc_ref.set(data)

    return {
        "id": doc_ref.id,
        **data
    }


def get_user_history(user_id: str):
    docs = (
        db.collection("quality_results")
        .where("user_id", "==", user_id)
        .order_by("created_at", direction=firestore.Query.DESCENDING)
        .stream()
    )

    results = []
    for doc in docs:
        item = doc.to_dict()
        item["id"] = doc.id
        results.append(item)

    return results