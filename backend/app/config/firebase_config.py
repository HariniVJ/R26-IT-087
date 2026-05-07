import firebase_admin
from firebase_admin import credentials, firestore
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parents[2]
SERVICE_ACCOUNT_PATH = BASE_DIR / "serviceAccountKey.json"

_db = None

def init_firebase():
    global _db

    if not firebase_admin._apps:
        cred = credentials.Certificate(str(SERVICE_ACCOUNT_PATH))
        firebase_admin.initialize_app(cred)

    _db = firestore.client()
    return _db

def get_db():
    global _db

    if _db is None:
        _db = init_firebase()

    return _db