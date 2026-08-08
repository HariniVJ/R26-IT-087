import httpx  # for calling weather API  (pip install httpx)
import os

STAGE_INFO = {
    "Bud": {
        "display_name": "Bud Stage 🌱",
        "next_stage": "Flower",
        "days_min": 150,
        "days_max": 180,
        "care_tip": (
            "Ensure adequate irrigation. Apply balanced NPK fertilizer. "
            "Check for aphids and mites which attack young buds."
        ),
        "risk_warning": (
            "Frost or extreme heat can damage buds. "
            "Avoid over-watering to prevent root rot."
        ),
    },
    "Flower": {
        "display_name": "Flower Stage 🌸",
        "next_stage": "EarlyFruit",
        "days_min": 120,
        "days_max": 150,
        "care_tip": (
            "Reduce irrigation slightly during flowering. "
            "Avoid pesticides that harm pollinators. "
            "Hand-pollination can improve fruit set."
        ),
        "risk_warning": (
            "Heavy rain or wind can cause flower drop. "
            "Watch for fungal disease in humid conditions."
        ),
    },
    "EarlyFruit": {
        "display_name": "Early Fruit Stage 🍑",
        "next_stage": "MidGrowth",
        "days_min": 90,
        "days_max": 120,
        "care_tip": (
            "Increase potassium fertilizer to support fruit development. "
            "Thin excess fruitlets to improve size of remaining fruits. "
            "Maintain consistent soil moisture."
        ),
        "risk_warning": (
            "Fruit cracking risk increases with irregular watering. "
            "Watch for pomegranate butterfly larva attacking young fruits."
        ),
    },
    "MidGrowth": {
        "display_name": "Mid Growth Stage 🍊",
        "next_stage": "MatureFruit",
        "days_min": 45,
        "days_max": 90,
        "care_tip": (
            "Continue potassium and calcium fertilization. "
            "Maintain regular irrigation schedule. "
            "Remove damaged or diseased fruits promptly."
        ),
        "risk_warning": (
            "Cercospora fruit spot and bacterial blight may appear. "
            "High humidity increases disease risk — improve air circulation."
        ),
    },
    "MatureFruit": {
        "display_name": "Mature Fruit 🍎 — Ready Soon!",
        "next_stage": None,
        "days_min": 0,
        "days_max": 14,
        "care_tip": (
            "Reduce irrigation 1–2 weeks before harvest to improve sugar content. "
            "Check fruit by tapping — a metallic sound means it is ready. "
            "Harvest with pruning shears, leaving a short stem."
        ),
        "risk_warning": (
            "Delay in harvesting causes over-ripening and fruit drop. "
            "Birds and insects may damage mature fruits — use netting."
        ),
    },
}


# ── Weather adjustment logic ─────────────────────────────────────────────────
def adjust_for_weather(base_days: int, temperature: float, is_rainy: bool) -> int:
    """
    Adjust estimated harvest days based on weather.

    Rules:
      - Hot weather (>30°C) + sunny → reduces time by 5 days (faster ripening)
      - Cool weather (<20°C) → adds 10 days (slower development)
      - Rainy/cloudy conditions → adds 7 days (less sunlight, disease risk)
      - Normal (20–30°C, no rain) → no change

    Args:
        base_days:   Default days estimate
        temperature: Current temperature in Celsius
        is_rainy:    True if rainy or heavily cloudy
    
    Returns:
        Adjusted number of days
    """
    adjustment = 0

    if is_rainy:
        adjustment += 7   # rainy slows ripening

    if temperature > 30:
        adjustment -= 5   # hot weather speeds up ripening
    elif temperature < 20:
        adjustment += 10  # cool weather slows ripening

    adjusted = base_days + adjustment

    # Never go below 0 days
    return max(0, adjusted)


# ── Weather API call ─────────────────────────────────────────────────────────
async def get_weather(lat: float = 9.7, lon: float = 80.0) -> dict:
    """
    Fetch current weather from Open-Meteo API.
    
    Open-Meteo is FREE — no API key needed!
    Default coordinates: Jaffna, Sri Lanka (pomegranate farming area)
    
    Returns:
        dict with 'temperature' (float) and 'is_rainy' (bool)
    """
    url = (
        f"https://api.open-meteo.com/v1/forecast"
        f"?latitude={lat}&longitude={lon}"
        f"&current_weather=true"
        f"&hourly=precipitation"
    )

    try:
        async with httpx.AsyncClient(timeout=5.0) as client:
            response = await client.get(url)
            response.raise_for_status()
            data = response.json()

        temperature = data["current_weather"]["temperature"]
        weather_code = data["current_weather"]["weathercode"]

        # Weather codes 51–99 are precipitation/rain/storm
        is_rainy = weather_code >= 51

        return {
            "temperature": temperature,
            "is_rainy": is_rainy,
            "weather_code": weather_code,
        }

    except Exception as e:
        # If weather API fails, return default Sri Lanka values
        print(f"Weather API error (using defaults): {e}")
        return {
            "temperature": 28.0,
            "is_rainy": False,
            "weather_code": 0,
        }


# ── Main service function ────────────────────────────────────────────────────
async def build_growth_result(
    predicted_class: str,
    confidence: float,
    all_probabilities: dict,
    lat: float = 9.7,
    lon: float = 80.0,
) -> dict:
    """
    Build the complete API response for the farmer.
    
    Args:
        predicted_class:    e.g. "MidGrowth"
        confidence:         e.g. 0.912
        all_probabilities:  dict of all 5 class scores
        lat, lon:           farm location for weather lookup
    
    Returns:
        Full JSON-ready response dict
    """
    # Get stage info
    stage = STAGE_INFO[predicted_class]

    # Get weather data
    weather = await get_weather(lat, lon)

    # Calculate base days (midpoint of range)
    base_days = (stage["days_min"] + stage["days_max"]) // 2

    # Adjust for weather
    adjusted_days = adjust_for_weather(
        base_days,
        weather["temperature"],
        weather["is_rainy"],
    )

    # Build harvest message
    if predicted_class == "MatureFruit":
        harvest_message = "Your pomegranate is ready to harvest soon!"
    elif adjusted_days == 0:
        harvest_message = "Ready to harvest now!"
    else:
        harvest_message = f"Approximately {adjusted_days} days until harvest"

    return {
        "status": "success",
        "growth_stage": {
            "detected": predicted_class,
            "display_name": stage["display_name"],
            "confidence_percent": round(confidence * 100, 1),
            "all_probabilities": all_probabilities,
            "model_accuracy_percent": 86.27,
        },
        "next_stage": stage["next_stage"],
        "harvest_prediction": {
            "estimated_days": adjusted_days,
            "range": f"{stage['days_min']}–{stage['days_max']} days (base estimate)",
            "message": harvest_message,
            "weather_adjusted": True,
        },
        "weather": {
            "temperature_celsius": weather["temperature"],
            "condition": "Rainy" if weather["is_rainy"] else "Clear/Dry",
            "effect_on_harvest": (
                "Rainy weather adds ~7 days" if weather["is_rainy"]
                else ("Hot weather reduces time by ~5 days" if weather["temperature"] > 30
                      else "Cool weather adds ~10 days" if weather["temperature"] < 20
                      else "Normal conditions — no adjustment")
            ),
        },
        "recommendations": {
            "care_tip": stage["care_tip"],
            "risk_warning": stage["risk_warning"],
        },
    }