# backend/app/main.py
# Merged: Soil/Weather component + Growth Stage Detection component

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

# ── Soil/Weather component (teammate) ────────────────────────────
from app.models.weather import IrrigationMobileInput, FertilizerMobileInput
from app.services.irrigation_service import predict_irrigation_from_mobile
from app.services.fertilizer_service import predict_fertilizer_from_mobile

# ── Growth Stage Detection component (Thishoharini) ──────────────
from app.controllers.growth_controller import router as growth_router

app = FastAPI(
    title="Pomegranate Intelligent Farming API",
    description="AI-Based Intelligent Farming System for Improving Pomegranate Yield and Quality. Project R26-IT-087",
    version="1.0.0",
)

# ── CORS ──────────────────────────────────────────────────────────
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ── Growth router ─────────────────────────────────────────────────
app.include_router(growth_router)

# ── Root ──────────────────────────────────────────────────────────
@app.get("/")
def root():
    return {
        "message": "Pomegranate Farming API is running!",
        "docs": "Visit /docs for Swagger UI",
    }

@app.get("/health")
def health_check():
    return {"status": "healthy"}

# ── Soil/Weather endpoints (teammate) ─────────────────────────────
@app.post("/predict-irrigation")
def predict_irrigation(input_data: IrrigationMobileInput):
    return predict_irrigation_from_mobile(
        soil_moisture=input_data.soil_moisture,
        latitude=input_data.latitude,
        longitude=input_data.longitude
    )

@app.post("/predict-fertilizer")
def predict_fertilizer(input_data: FertilizerMobileInput):
    return predict_fertilizer_from_mobile(
        moisture=input_data.moisture,
        temp=input_data.temp,
        ec=input_data.ec,
        ph=input_data.ph,
        nitrogen=input_data.nitrogen,
        phosphorus=input_data.phosphorus,
        potassium=input_data.potassium,
        tree_age=input_data.tree_age
    )