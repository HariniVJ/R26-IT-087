import os
import numpy as np
from PIL import Image
import io
import tensorflow as tf

CLASSES = ["Bud", "Flower", "EarlyFruit", "MidGrowth", "MatureFruit"]

MODEL_PATH = os.path.join(os.path.dirname(__file__), "pomegranate_cnn_model.h5")
MIN_CONFIDENCE_THRESHOLD = 0.75

_model = None


def load_model():
    global _model
    if _model is None:
        if not os.path.exists(MODEL_PATH):
            raise FileNotFoundError(
                f"Model file not found at: {MODEL_PATH}\n"
                f"Please copy your trained 'pomegranate_cnn_model.h5' "
                f"into the backend/app/models/ folder."
            )
        print(f"Loading CNN model from: {MODEL_PATH}")
        _model = tf.keras.models.load_model(MODEL_PATH)
        print("Model loaded successfully!")
    return _model


def preprocess_image(image_bytes: bytes) -> np.ndarray:
    img = Image.open(io.BytesIO(image_bytes))
    img = img.convert("RGB")
    img = img.resize((224, 224))
    img_array = np.array(img, dtype=np.float32) / 255.0
    img_array = np.expand_dims(img_array, axis=0)
    return img_array


def predict_growth_stage(image_bytes: bytes) -> dict:
    model = load_model()
    img_array = preprocess_image(image_bytes)
    predictions = model.predict(img_array, verbose=0)

    confidence = float(np.max(predictions[0]))
    class_index = int(np.argmax(predictions[0]))
    predicted_class = CLASSES[class_index]

    all_probabilities = {
        CLASSES[i]: round(float(predictions[0][i]), 4)
        for i in range(len(CLASSES))
    }

    if confidence < MIN_CONFIDENCE_THRESHOLD:
        return {
            "predicted_class": None,
            "confidence": round(confidence, 4),
            "all_probabilities": all_probabilities,
            "rejected": True,
            "rejection_reason": (
                "The uploaded image does not appear to contain a pomegranate fruit. "
                "Please upload a clear photo of a pomegranate plant or fruit."
            )
        }

    return {
        "predicted_class": predicted_class,
        "confidence": round(confidence, 4),
        "all_probabilities": all_probabilities,
        "rejected": False,
        "rejection_reason": None,
    }