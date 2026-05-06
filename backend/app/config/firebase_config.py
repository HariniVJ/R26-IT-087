import os
import firebase_admin
from firebase_admin import credentials, firestore, storage

_BASE_DIR = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SERVICE_ACCOUNT_PATH = os.path.join(_BASE_DIR, "serviceAccountKey.json")
STORAGE_BUCKET = "r26-it-087.appspot.com"  


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