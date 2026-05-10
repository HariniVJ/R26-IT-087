import os
import uuid
from datetime import datetime, timezone

from firebase_admin import firestore as fs

from app.config.firebase_config import db, bucket

COLLECTION = "quality_results"


def upload_image_to_storage(local_path: str, user_id: str) -> str:
    if not os.path.exists(local_path):
        raise FileNotFoundError(f"Image not found: {local_path}")

    ext = os.path.splitext(local_path)[1].lower() or ".jpg"
    storage_path = f"quality_uploads/{user_id}/{uuid.uuid4().hex}{ext}"

    blob = bucket.blob(storage_path)
    blob.upload_from_filename(local_path)
    blob.make_public()

    return blob.public_url


def save_prediction_result(
    user_id: str,
    quality: str,
    confidence: float,
    recommendation: str,
    image_url: str | None = None,
) -> dict:
    data = {
        "user_id": user_id,
        "quality": quality,
        "confidence": round(float(confidence), 4),
        "recommendation": recommendation,
        "image_url": image_url,
        "created_at": datetime.now(timezone.utc),
        "component": "fruit_quality_grading",
    }

    doc_ref = db.collection(COLLECTION).document()
    doc_ref.set(data)

    saved = {"id": doc_ref.id, **data}
    return _serialize(saved)


def _serialize(item: dict) -> dict:
    if hasattr(item.get("created_at"), "isoformat"):
        item["created_at"] = item["created_at"].isoformat()
    return item


def get_user_history(user_id: str) -> list[dict]:
    docs = (
        db.collection(COLLECTION)
        .where("user_id", "==", user_id)
        .order_by("created_at", direction=fs.Query.DESCENDING)
        .stream()
    )

    results = []
    for doc in docs:
        item = doc.to_dict()
        item["id"] = doc.id
        results.append(_serialize(item))

    return results


def get_single_result(result_id: str) -> dict | None:
    doc = db.collection(COLLECTION).document(result_id).get()
    if not doc.exists:
        return None

    item = doc.to_dict()
    item["id"] = doc.id
    return _serialize(item)


def delete_single_result(result_id: str) -> bool:
    doc_ref = db.collection(COLLECTION).document(result_id)

    if not doc_ref.get().exists:
        return False

    doc_ref.delete()
    return True


def delete_all_user_results(user_id: str) -> int:
    docs = db.collection(COLLECTION).where("user_id", "==", user_id).stream()

    count = 0
    for doc in docs:
        doc.reference.delete()
        count += 1

    return count