from fastapi import APIRouter
from pydantic import BaseModel, Field

from app.services.firebase_service import save_sensor_reading

router = APIRouter()


class SensorReadingInput(BaseModel):
    farmer_id: str = Field(..., description="Firebase Auth UID of the farmer")
    farm_id: str | None = None
    tree_id: str | None = None
    moisture: float
    temperature: float
    ph: float
    nitrogen: float
    phosphorus: float
    potassium: float
    ec: float | None = None


@router.post("/sensor-readings")
def post_sensor_reading(payload: SensorReadingInput):
    """ESP32 / backend path: append soil sensor history to Firestore via Admin SDK."""
    saved = save_sensor_reading(
        farmer_id=payload.farmer_id,
        farm_id=payload.farm_id,
        tree_id=payload.tree_id,
        moisture=payload.moisture,
        temperature=payload.temperature,
        ph=payload.ph,
        nitrogen=payload.nitrogen,
        phosphorus=payload.phosphorus,
        potassium=payload.potassium,
        ec=payload.ec,
    )
    return {"success": True, "data": saved}
