import os
import numpy as np
from PIL import Image
import io
import tensorflow as tf

CLASSES = ["Bud", "Flower", "EarlyFruit", "MidGrowth", "MatureFruit", "Unknown"]

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

        # Sanity check: confirm model output size matches CLASSES list
        output_size = _model.output_shape[-1]
        if output_size != len(CLASSES):
            print(
                f"WARNING: Model outputs {output_size} classes but "
                f"CLASSES list has {len(CLASSES)} entries. "
                f"Check that CLASSES order matches your training notebook."
            )
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

    # ── Reject if model explicitly predicts "Unknown" ──────────────
    # This is the 6th class trained on non-pomegranate images
    # (red/green apples, tomatoes, oranges, random objects) to
    # directly solve the false-positive problem from PP1.
    is_unknown_class = (predicted_class == "Unknown")

    # ── Reject if confidence is too low, regardless of class ───────
    # Even if it predicts a real stage, low confidence means the
    # model itself is not sure — safer to reject than guess wrong.
    is_low_confidence = (confidence < MIN_CONFIDENCE_THRESHOLD)

    if is_unknown_class or is_low_confidence:
        if is_unknown_class:
            reason = (
                "This image was identified as a non-pomegranate object "
                "(the AI model was specifically trained to detect this). "
                "Please upload a clear photo of a pomegranate plant or fruit."
            )
        else:
            reason = (
                "The uploaded image does not appear to contain a pomegranate fruit "
                "with enough confidence. Please upload a clear photo of a "
                "pomegranate plant or fruit."
            )

        return {
            "predicted_class": None,
            "confidence": round(confidence, 4),
            "all_probabilities": all_probabilities,
            "rejected": True,
            "rejection_reason": reason,
        }

    return {
        "predicted_class": predicted_class,
        "confidence": round(confidence, 4),
        "all_probabilities": all_probabilities,
        "rejected": False,
        "rejection_reason": None,
    }