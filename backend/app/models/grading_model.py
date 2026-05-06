from pydantic import BaseModel
from typing import Optional

class PredictionCreate(BaseModel):
    user_id: str
    quality: str
    confidence: float
    recommendation: str
    image_url: Optional[str] = None