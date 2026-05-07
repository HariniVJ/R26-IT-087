from datetime import datetime
from app.config.firebase_config import db

COLLECTION_NAME = "disease_predictions"

def save_prediction_to_firebase(data: dict):
    if db is None:
        return None

    data["created_at"] = datetime.utcnow().isoformat()
    doc_ref = db.collection(COLLECTION_NAME).document()
    doc_ref.set(data)

    return doc_ref.id

def get_user_prediction_history(user_id: str):
    if db is None:
        return []

    docs = (
        db.collection(COLLECTION_NAME)
        .where("user_id", "==", user_id)
        .order_by("created_at", direction="DESCENDING")
        .stream()
    )

    history = []
    for doc in docs:
        item = doc.to_dict()
        item["prediction_id"] = doc.id
        history.append(item)

    return history