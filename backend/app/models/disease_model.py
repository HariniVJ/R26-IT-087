from pydantic import BaseModel
from typing import List, Optional

class TreatmentInfo(BaseModel):
    disease_name: str
    status: str
    severity: str
    description: str
    treatment: str
    prevention: List[str]

class PredictionResponse(BaseModel):
    success: bool
    message: str
    user_id: Optional[str]
    disease_name: str
    confidence: float
    is_disease: bool
    treatment_info: TreatmentInfo
    image_url: Optional[str] = None
    prediction_id: Optional[str] = None
    response_time_seconds: float