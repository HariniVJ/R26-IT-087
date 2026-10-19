from pathlib import Path

from pomcare_growth_v2.pomcare_predictor import PomCarePredictor
from pomcare_growth_v2.pomcare_utils import CLASSES


BUNDLE_DIR = (
    Path(__file__).resolve().parents[2]
    / "pomcare_growth_v2"
)

_predictor = None


def load_model():
    global _predictor

    if _predictor is None:
        print(
            f"Loading PomCare Growth V2 model from: "
            f"{BUNDLE_DIR}"
        )

        _predictor = PomCarePredictor(
            bundle_dir=BUNDLE_DIR,
            device="cpu",
        )

        print("PomCare Growth V2 model loaded successfully!")

    return _predictor


def predict_growth_stage(image_bytes: bytes) -> dict:
    predictor = load_model()

    result = predictor.predict(image_bytes)

    # New model class probabilities
    class_scores = result.get("class_scores") or {}

    all_probabilities = {
        class_name: round(
            float(class_scores.get(class_name, 0.0)),
            4,
        )
        for class_name in CLASSES
    }

    classifier_score = result.get("classifier_score")

    confidence = (
        float(classifier_score)
        if classifier_score is not None
        else 0.0
    )

    # Rejected image:
    # no detection / unknown / uncertain
    if not result.get("accepted", False):
        return {
            "predicted_class": None,
            "confidence": round(confidence, 4),
            "all_probabilities": all_probabilities,
            "rejected": True,
            "rejection_reason": result.get(
                "message",
                "The image could not be confidently "
                "identified as a supported pomegranate stage.",
            ),
        }

    # Accepted pomegranate growth stage
    return {
        "predicted_class": result["stage"],
        "confidence": round(confidence, 4),
        "all_probabilities": all_probabilities,
        "rejected": False,
        "rejection_reason": None,
    }