from datetime import datetime
from app.config.firebase_config import get_db

COLLECTION_NAME = "disease_predictions"

def save_prediction_to_firebase(data: dict):
    db = get_db()

    data["created_at"] = datetime.utcnow().isoformat()
    data["component"] = "disease_detection"

    doc_ref = db.collection(COLLECTION_NAME).document()
    doc_ref.set(data)

    return doc_ref.id


def get_user_prediction_history(user_id: str):
    db = get_db()

    docs = (
        db.collection(COLLECTION_NAME)
        .where("user_id", "==", user_id)
        .stream()
    )

    history = []

    for doc in docs:
        item = doc.to_dict()
        item["prediction_id"] = doc.id
        history.append(item)

    history.sort(
        key=lambda x: x.get("created_at", ""),
        reverse=True
    )

    return history