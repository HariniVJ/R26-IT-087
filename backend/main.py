from fastapi import FastAPI
from app.routes import router

app = FastAPI(
    title="Pomegranate Quality Grading Backend",
    description="Backend API for storing quality grading results and images in Firebase",
    version="1.0.0"
)

app.include_router(router)