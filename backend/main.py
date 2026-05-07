from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.config.firebase_config import init_firebase
from app.routes.disease_detection_routes import router as disease_router

app = FastAPI(
    title="AI-Based Pomegranate Farming Backend",
    description="Disease Detection and Treatment Recommendation API",
    version="1.0.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

init_firebase()

app.include_router(disease_router)

@app.get("/")
def root():
    return {
        "success": True,
        "message": "AI-Based Pomegranate Farming Backend Running"
    }