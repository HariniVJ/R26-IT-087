# Maps quality labels to human-readable recommendations
RECOMMENDATIONS: dict[str, str] = {
    "high_quality":   "✅ Suitable for export and premium market sale.",
    "medium_quality": "🧃 Suitable for juice, jam, or food processing.",
    "low_quality":    "🌱 Suitable for compost or organic fertilizer production.",
}


def get_recommendation(label: str) -> str:
    """
    Return a usage recommendation based on quality label.

    Args:
        label: One of 'high_quality', 'medium_quality', 'low_quality'

    Returns:
        Recommendation string
    """
    return RECOMMENDATIONS.get(label.lower(), "⚠️ No recommendation available.")