from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.models.weather import IrrigationMobileInput, FertilizerMobileInput
from app.services.irrigation_service import predict_irrigation_from_mobile
from app.services.fertilizer_service import predict_fertilizer_from_mobile


app = FastAPI(
    title="Pomegranate Farming Backend",
    description="Backend API for Flutter irrigation and fertilizer recommendation app",
    version="1.0.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/")
def home():
    return {
        "message": "Pomegranate Farming Backend is running"
    }


@app.get("/health")
def health_check():
    return {
        "status": "healthy"
    }


@app.post("/predict-irrigation")
def predict_irrigation(input_data: IrrigationMobileInput):
    result = predict_irrigation_from_mobile(
        soil_moisture=input_data.soil_moisture,
        latitude=input_data.latitude,
        longitude=input_data.longitude
    )
    return result


@app.post("/predict-fertilizer")
def predict_fertilizer(input_data: FertilizerMobileInput):
    result = predict_fertilizer_from_mobile(
        moisture=input_data.moisture,
        temp=input_data.temp,
        ec=input_data.ec,
        ph=input_data.ph,
        nitrogen=input_data.nitrogen,
        phosphorus=input_data.phosphorus,
        potassium=input_data.potassium,
        tree_age=input_data.tree_age
    )
    return result