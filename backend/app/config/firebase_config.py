import os
import firebase_admin
from firebase_admin import credentials, firestore, storage
from dotenv import load_dotenv

load_dotenv()

SERVICE_ACCOUNT_PATH = "serviceAccountKey.json"

STORAGE_BUCKET = os.getenv(
    "STORAGE_BUCKET",
    "r26-it-087.firebasestorage.app"
)

def initialize_firebase():
    if not firebase_admin._apps:
        cred = credentials.Certificate(SERVICE_ACCOUNT_PATH)
        firebase_admin.initialize_app(cred, {
            "storageBucket": STORAGE_BUCKET
        })

initialize_firebase()

db = firestore.client()
bucket = storage.bucket()