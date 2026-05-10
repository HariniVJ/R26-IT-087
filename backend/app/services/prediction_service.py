import time
from pathlib import Path
import numpy as np
import tensorflow as tf

from app.utils.image_preprocessing import preprocess_image
from app.services.treatment_service import get_treatment_by_disease

BASE_DIR = Path(__file__).resolve().parents[1]
MODEL_PATH = BASE_DIR / "ml_models" / "pomegranate_disease_model.tflite"

CLASS_NAMES = [
    "Alternaria",
    "Anthracnose",
    "Bacterial_Blight",
    "Cercospora",
    "Healthy"
]

interpreter = tf.lite.Interpreter(model_path=str(MODEL_PATH))
interpreter.allocate_tensors()

input_details = interpreter.get_input_details()
output_details = interpreter.get_output_details()

def analyze_disease(image_bytes: bytes):
    start_time = time.time()

    img_array = preprocess_image(image_bytes)

    interpreter.set_tensor(input_details[0]["index"], img_array)
    interpreter.invoke()

    predictions = interpreter.get_tensor(output_details[0]["index"])[0]

    predicted_index = int(np.argmax(predictions))
    confidence = float(np.max(predictions) * 100)

    disease_name = CLASS_NAMES[predicted_index]
    treatment_info = get_treatment_by_disease(disease_name)

    response_time = round(time.time() - start_time, 3)

    return {
        "disease_name": disease_name,
        "confidence": round(confidence, 2),
        "is_disease": disease_name != "Healthy",
        "treatment_info": treatment_info,
        "response_time_seconds": response_time
    }