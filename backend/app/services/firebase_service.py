from datetime import datetime, timezone

from firebase_admin import firestore as fs

from app.config.firebase_config import db

COLLECTION = "quality_results"


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
        "image_url": None,
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

    docs = (
        db.collection(COLLECTION)
        .where("user_id", "==", user_id)
        .stream()
    )

    count = 0

    for doc in docs:
        doc.reference.delete()
        count += 1

    return count