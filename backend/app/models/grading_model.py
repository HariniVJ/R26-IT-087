from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime


class GradingRequest(BaseModel):
    """Used when sending grading data without a file (JSON body)."""
    user_id: str = Field(..., example="user_abc123")
    quality: str = Field(..., example="high_quality")
    confidence: float = Field(..., ge=0.0, le=1.0, example=0.95)


class GradingResponse(BaseModel):
    """Standard response returned after saving a grading result."""
    id: str
    user_id: str
    quality: str
    confidence: float
    recommendation: str
    image_url: Optional[str] = None
    created_at: datetime
    component: str = "fruit_quality_grading"


class HistoryResponse(BaseModel):
    """Response wrapper for history list endpoint."""
    success: bool
    count: int
    data: list