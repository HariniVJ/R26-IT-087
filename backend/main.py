from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.models.weather_model import IrrigationMobileInput
from app.models.soil_model import FertilizerMobileInput

from app.services.irrigation_service import predict_irrigation_from_mobile
from app.services.fertilizer_service import predict_fertilizer_from_mobile

from app.routes.grading_routes import router as grading_router


app = FastAPI(
    title="AI-Based Intelligent Farming System",
    description="Pomegranate yield and quality improvement backend",
    version="1.0.0",
)


app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


app.include_router(
    grading_router,
    prefix="/grading",
    tags=["Fruit Quality Grading"],
)


@app.get("/", tags=["Health"])
def root():
    return {
        "message": "AI Farming System Backend is running"
    }


@app.get("/health", tags=["Health"])
def health_check():
    return {
        "status": "healthy"
    }


@app.post("/predict-irrigation", tags=["Irrigation"])
def predict_irrigation(input_data: IrrigationMobileInput):
    result = predict_irrigation_from_mobile(
        soil_moisture=input_data.soil_moisture,
        latitude=input_data.latitude,
        longitude=input_data.longitude,
    )

    return result


@app.post("/predict-fertilizer", tags=["Fertilizer"])
def predict_fertilizer(input_data: FertilizerMobileInput):
    result = predict_fertilizer_from_mobile(
        moisture=input_data.moisture,
        temp=input_data.temp,
        ec=input_data.ec,
        ph=input_data.ph,
        nitrogen=input_data.nitrogen,
        phosphorus=input_data.phosphorus,
        potassium=input_data.potassium,
        tree_age=input_data.tree_age,
    )

    return result