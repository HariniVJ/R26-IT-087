"""
COMMON FILE - Shared by all 4 team members.
Firebase initialization for the AI Farming System backend.
Place your serviceAccountKey.json in the backend/ root folder.
"""

import firebase_admin
from firebase_admin import credentials, firestore, storage

SERVICE_ACCOUNT_PATH = "serviceAccountKey.json"
STORAGE_BUCKET = "YOUR_PROJECT_ID.appspot.com"  # ← Replace with your actual Firebase project ID


def initialize_firebase():
    """Initialize Firebase app only once (safe to call multiple times)."""
    if not firebase_admin._apps:
        cred = credentials.Certificate(SERVICE_ACCOUNT_PATH)
        firebase_admin.initialize_app(cred, {
            "storageBucket": STORAGE_BUCKET
        })


# Initialize on import
initialize_firebase()

# Shared clients — import these in any service file
db = firestore.client()
bucket = storage.bucket()