from pydantic import BaseModel
class FertilizerMobileInput(BaseModel):
    moisture: float
    temp: float
    ec: float
    ph: float
    nitrogen: float
    phosphorus: float
    potassium: float
    tree_age: float
