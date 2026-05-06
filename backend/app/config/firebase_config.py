import firebase_admin
from firebase_admin import credentials, firestore, storage

SERVICE_ACCOUNT_PATH = "serviceAccountKey.json"
STORAGE_BUCKET = "YOUR_PROJECT_ID.appspot.com"  # change this

cred = credentials.Certificate(SERVICE_ACCOUNT_PATH)

if not firebase_admin._apps:
    firebase_admin.initialize_app(cred, {
        "storageBucket": STORAGE_BUCKET
    })

db = firestore.client()
bucket = storage.bucket()