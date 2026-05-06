from fastapi import FastAPI
from app.routes.grading_routes import router as grading_router

app = FastAPI(
    title="AI-Based Intelligent Farming System",
    description="Pomegranate yield and quality improvement — 4-component integrated backend",
    version="1.0.0"
)


@app.get("/", tags=["Health"])
def root():
    return {"message": "AI Farming System Backend is running ✅"}


# ── Register routers ───────────────────────────────────────────────────────────
app.include_router(grading_router, prefix="/grading", tags=["Fruit Quality Grading"])