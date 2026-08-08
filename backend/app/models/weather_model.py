from pydantic import BaseModel

class IrrigationMobileInput(BaseModel):
    
    soil_moisture: float
    latitude: float
    longitude: float