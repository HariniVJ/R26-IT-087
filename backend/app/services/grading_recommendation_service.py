def get_recommendation(label: str) -> str:
    if label == "high_quality":
        return "Suitable for export and premium market sale."
    elif label == "medium_quality":
        return "Suitable for juice, jam, or food processing."
    elif label == "low_quality":
        return "Suitable for compost or organic fertilizer production."
    return "No recommendation available."