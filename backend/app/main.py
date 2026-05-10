from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.controllers.growth_controller import router as growth_router

app = FastAPI(
    title="Pomegranate Growth Stage Detection API",
    description=(
        "AI-Based system for pomegranate growth stage detection "
        "and harvest time prediction. Project R26-IT-087 | Thishoharini V"
    ),
    version="1.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(growth_router)

@app.get("/")
def root():
    return {
        "message": "Pomegranate Growth Stage Detection API is running!",
        "docs": "Visit /docs for Swagger UI",
        "endpoints": {
            "detect_growth_stage_and_harvest_time": "POST /api/growth/predict"
        }
    }