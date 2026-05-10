import os
from pathlib import Path

import firebase_admin
from firebase_admin import credentials, firestore, storage
from dotenv import load_dotenv

load_dotenv()

BASE_DIR = Path(__file__).resolve().parents[2]
SERVICE_ACCOUNT_PATH = BASE_DIR / "serviceAccountKey.json"

STORAGE_BUCKET = os.getenv(
    "STORAGE_BUCKET",
    "r26-it-087.firebasestorage.app"
)

_db = None
_bucket = None


def init_firebase():
    global _db, _bucket

    if not firebase_admin._apps:
        cred = credentials.Certificate(str(SERVICE_ACCOUNT_PATH))
        firebase_admin.initialize_app(cred, {
            "storageBucket": STORAGE_BUCKET
        })

    _db = firestore.client()
    _bucket = storage.bucket()

    return _db


def get_db():
    global _db

    if _db is None:
        _db = init_firebase()

    return _db


def get_bucket():
    global _bucket

    if _bucket is None:
        init_firebase()

    return _bucket


init_firebase()

db = get_db()
bucket = get_bucket()