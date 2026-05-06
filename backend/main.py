from fastapi import FastAPI
from app.controllers.grading_controller import router as grading_router

app = FastAPI(
    title="AI Farming System Backend",
    version="1.0.0"
)

app.include_router(
    grading_router,
    prefix="/grading",
    tags=["Fruit Quality Grading"]
)

@app.get("/")
def home():
    return {
        "message": "AI Farming System Backend is running"
    }