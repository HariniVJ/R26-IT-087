"""
YOUR FILE - Member 4: Fruit Quality Grading
Firebase Storage upload and Firestore read/write for grading results.
Uses the shared firebase_config.py for db and bucket clients.
"""

import os
import uuid
from datetime import datetime, timezone

from firebase_admin import firestore as fs

from app.config.firebase_config import db, bucket

# Firestore collection name for this component
COLLECTION = "quality_results"


def upload_image_to_storage(local_path: str, user_id: str) -> str:
    """
    Upload a local image file to Firebase Storage.

    Args:
        local_path: Absolute or relative path to the local image file.
        user_id:    ID of the user uploading the image.

    Returns:
        Public URL string of the uploaded image.

    Raises:
        FileNotFoundError: If local_path does not exist.
    """
    if not os.path.exists(local_path):
        raise FileNotFoundError(f"Image file not found: {local_path}")

    ext = os.path.splitext(local_path)[1]  # e.g. ".jpg"
    storage_path = f"quality_uploads/{user_id}/{uuid.uuid4()}{ext}"

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
    """
    Save a grading prediction result to Firestore.

    Returns:
        Dict with the saved document data plus its Firestore document ID.
    """
    data = {
        "user_id":        user_id,
        "quality":        quality,
        "confidence":     round(confidence, 4),
        "recommendation": recommendation,
        "image_url":      image_url,
        "created_at":     datetime.now(timezone.utc),
        "component":      "fruit_quality_grading",
    }

    doc_ref = db.collection(COLLECTION).document()
    doc_ref.set(data)

    return {"id": doc_ref.id, **data}


def get_user_history(user_id: str) -> list[dict]:
    """
    Retrieve all grading results for a specific user, newest first.

    Args:
        user_id: The user whose history to retrieve.

    Returns:
        List of result dicts, each including the Firestore document ID.
    """
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
        # Convert Firestore timestamp to ISO string for JSON serialisation
        if hasattr(item.get("created_at"), "isoformat"):
            item["created_at"] = item["created_at"].isoformat()
        results.append(item)

    return results