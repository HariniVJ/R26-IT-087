import httpx

from app.config.firebase_config import db


# ============================================================
# FIREBASE COLLECTION
# ============================================================

SENSOR_COLLECTION = "sensor_readings"


# ============================================================
# POMEGRANATE GROWTH / HARVEST TIMELINE
# ============================================================

STAGE_INFO = {

    # --------------------------------------------------------
    # STAGE 1 - BUD
    # --------------------------------------------------------
    "Bud": {
        "display_name": "Bud Stage 🌱",
        "next_stage": "Flower",

        "transition_min": 5,
        "transition_max": 15,

        "harvest_min": 125,
        "harvest_max": 165,

        "care_tip": (
            "Maintain adequate soil moisture and normal plant nutrition. "
            "Avoid allowing the root zone to become excessively dry or waterlogged."
        ),

        "care_action": (
            "Check irrigation and drainage regularly. "
            "Observe developing buds for healthy growth and possible pest symptoms."
        ),

        "risk_warning": (
            "Water stress, excessive moisture, or poor plant condition may affect "
            "healthy bud and flower development."
        ),
    },

    # --------------------------------------------------------
    # STAGE 2 - FLOWER
    # --------------------------------------------------------
    "Flower": {
        "display_name": "Flower Stage 🌸",
        "next_stage": "EarlyFruit",

        "transition_min": 21,
        "transition_max": 28,

        # Sri Lankan reference:
        # approximately 4-5 months from flowering to maturity
        "harvest_min": 120,
        "harvest_max": 150,

        "care_tip": (
            "Maintain suitable irrigation and good airflow around the canopy. "
            "Monitor flowers carefully during rainy or humid conditions."
        ),

        "care_action": (
            "Inspect flowers regularly for pest activity and fungal symptoms. "
            "Maintain good drainage, sunlight, and air circulation around the plant."
        ),

        "risk_warning": (
            "Rainy and humid conditions may increase disease risk during flowering. "
            "Monitor flower condition and pest activity closely during wet weather."
        ),
    },

    # --------------------------------------------------------
    # STAGE 3 - EARLY FRUIT
    # --------------------------------------------------------
    "EarlyFruit": {
        "display_name": "Early Fruit Stage 🍑",
        "next_stage": "MidGrowth",

        # Calibrated prototype transition range
        "transition_min": 71,
        "transition_max": 87,

        "harvest_min": 99,
        "harvest_max": 122,

        "care_tip": (
            "Maintain consistent soil moisture while young fruits develop. "
            "Avoid sudden changes between very dry and very wet soil conditions."
        ),

        "care_action": (
            "Inspect young fruits for insect holes, spots, or physical damage. "
            "Where practical, protect healthy young fruits using suitable fruit covers."
        ),

        "risk_warning": (
            "Young fruits may be vulnerable to insects and disease. "
            "Remove seriously damaged fruits and continue regular monitoring."
        ),
    },

    # --------------------------------------------------------
    # STAGE 4 - MID GROWTH
    # --------------------------------------------------------
    "MidGrowth": {
        "display_name": "Mid-Growth Stage 🍊",
        "next_stage": "MatureFruit",

        "transition_min": 28,
        "transition_max": 35,

        "harvest_min": 28,
        "harvest_max": 35,

        "care_tip": (
            "Maintain consistent soil moisture, adequate drainage, and good airflow "
            "while the fruit completes its final development."
        ),

        "care_action": (
            "Inspect fruits regularly for cracking, rot, spots, or insect damage. "
            "Avoid sudden changes in irrigation or soil moisture."
        ),

        "risk_warning": (
            "Changes in moisture and wet weather near maturity may increase "
            "fruit cracking and disease risk."
        ),
    },

    # --------------------------------------------------------
    # STAGE 5 - MATURE FRUIT
    # --------------------------------------------------------
    "MatureFruit": {
        "display_name": "Mature Fruit Stage 🍎",
        "next_stage": None,

        "transition_min": 0,
        "transition_max": 0,

        "harvest_min": 0,
        "harvest_max": 0,

        "care_tip": (
            "Check the fruit carefully for suitable maturity before harvesting."
        ),

        "care_action": (
            "Assess maturity and harvest suitable fruits carefully by cutting "
            "the stalk rather than pulling the fruit."
        ),

        "risk_warning": (
            "Do not harvest immature fruit expecting it to continue ripening "
            "after harvest. Inspect mature fruits for cracking, damage, or rot."
        ),
    },
}


# ============================================================
# GET LATEST IOT SOIL TEMPERATURE FROM FIREBASE
# ============================================================

def get_latest_soil_temperature(
    farmer_id: str | None,
) -> dict:
    """
    Read the latest IoT soil temperature stored in Firestore.

    Existing teammate flow:
        IoT device
            ->
        sensor_readings Firestore collection
            ->
        soilTemperature

    IMPORTANT:
    This function is READ-ONLY.

    It does not modify:
    - IoT code
    - fertilizer code
    - irrigation code
    - Firebase sensor records

    Soil temperature is used as environmental context only.
    It does NOT add/subtract fixed harvest days.
    """

    # Farmer ID has not yet been connected
    if not farmer_id:

        return {
            "available": False,
            "temperature_celsius": None,
            "timestamp": None,
            "source": None,
            "message": (
                "Farmer soil sensor data is not connected to "
                "this prediction request yet."
            ),
        }

    try:

        docs = (
            db.collection(SENSOR_COLLECTION)
            .where(
                "farmerId",
                "==",
                farmer_id,
            )
            .stream()
        )

        latest_data = None
        latest_timestamp = None
        latest_id = None

        for doc in docs:

            data = doc.to_dict()

            timestamp = data.get("timestamp")

            # First available record
            if latest_data is None:
                latest_data = data
                latest_timestamp = timestamp
                latest_id = doc.id
                continue

            # Choose newest timestamp
            if (
                timestamp is not None
                and (
                    latest_timestamp is None
                    or timestamp > latest_timestamp
                )
            ):
                latest_data = data
                latest_timestamp = timestamp
                latest_id = doc.id

        # No records found for farmer
        if latest_data is None:

            return {
                "available": False,
                "temperature_celsius": None,
                "timestamp": None,
                "source": None,
                "message": (
                    "No IoT soil sensor reading was found "
                    "for this farmer."
                ),
            }

        soil_temperature = latest_data.get(
            "soilTemperature"
        )

        if soil_temperature is None:

            return {
                "available": False,
                "temperature_celsius": None,
                "timestamp": None,
                "source": latest_data.get("source"),
                "message": (
                    "The latest sensor record does not contain "
                    "a soil temperature value."
                ),
            }

        # Convert Firebase timestamp for JSON response
        timestamp_value = latest_timestamp

        if hasattr(
            timestamp_value,
            "isoformat",
        ):
            timestamp_value = (
                timestamp_value.isoformat()
            )

        return {
            "available": True,

            "reading_id": latest_id,

            "temperature_celsius": round(
                float(soil_temperature),
                1,
            ),

            "timestamp": timestamp_value,

            "source": latest_data.get(
                "source",
                "IoT sensor",
            ),

            "message": (
                "Latest IoT soil temperature retrieved "
                "from Firebase."
            ),
        }

    except Exception as e:

        print(
            f"Soil temperature Firebase error: {e}"
        )

        return {
            "available": False,
            "temperature_celsius": None,
            "timestamp": None,
            "source": None,
            "message": (
                "Latest soil sensor reading could not "
                "be retrieved."
            ),
        }


# ============================================================
# CURRENT WEATHER API
# ============================================================

async def get_weather(
    lat: float = 9.7,
    lon: float = 80.0,
) -> dict:
    """
    Retrieve CURRENT weather from Open-Meteo.

    IMPORTANT:
    This is not an ML weather prediction model.

    Open-Meteo provides current:
    - air temperature
    - relative humidity
    - precipitation
    - weather condition code

    Your system interprets these values for
    agricultural advisory.

    Weather does NOT automatically alter harvest days.
    """

    url = (
        "https://api.open-meteo.com/v1/forecast"
        f"?latitude={lat}"
        f"&longitude={lon}"
        "&current="
        "temperature_2m,"
        "relative_humidity_2m,"
        "precipitation,"
        "weather_code"
    )

    try:

        async with httpx.AsyncClient(
            timeout=5.0
        ) as client:

            response = await client.get(url)

            response.raise_for_status()

            data = response.json()

        current = data.get(
            "current",
            {},
        )

        temperature = current.get(
            "temperature_2m"
        )

        humidity = current.get(
            "relative_humidity_2m"
        )

        precipitation = current.get(
            "precipitation",
            0,
        )

        weather_code = current.get(
            "weather_code",
            0,
        )

        # Open-Meteo rain / precipitation codes
        is_rainy = (
            (
                precipitation is not None
                and precipitation > 0
            )
            or
            (
                weather_code is not None
                and weather_code >= 51
            )
        )

        return {
            "available": True,

            "temperature": temperature,

            "humidity": humidity,

            "precipitation": precipitation,

            "weather_code": weather_code,

            "is_rainy": is_rainy,
        }

    except Exception as e:

        print(
            f"Weather API error: {e}"
        )

        # Never use fake/default weather values
        return {
            "available": False,
            "temperature": None,
            "humidity": None,
            "precipitation": None,
            "weather_code": None,
            "is_rainy": False,
        }


# ============================================================
# TEMPERATURE COMPARISON
# ============================================================

def build_temperature_comparison(
    weather: dict,
    soil: dict,
) -> dict:
    """
    Compare CURRENT air temperature with the latest
    IoT soil-temperature measurement.

    IMPORTANT:
    The difference is displayed for context only.

    We do NOT say:
        +5°C = add days
        -5°C = subtract days

    because there is no locally validated formula
    supporting those fixed adjustments.
    """

    air_temp = weather.get(
        "temperature"
    )

    soil_temp = soil.get(
        "temperature_celsius"
    )

    if (
        not weather.get("available")
        or
        not soil.get("available")
        or
        air_temp is None
        or
        soil_temp is None
    ):

        return {
            "available": False,
            "air_temperature_celsius": air_temp,
            "soil_temperature_celsius": soil_temp,
            "difference_celsius": None,
            "message": (
                "Air and soil temperature comparison "
                "is not available."
            ),
        }

    difference = round(
        float(air_temp)
        - float(soil_temp),
        1,
    )

    return {
        "available": True,

        "air_temperature_celsius": round(
            float(air_temp),
            1,
        ),

        "soil_temperature_celsius": round(
            float(soil_temp),
            1,
        ),

        "difference_celsius": difference,

        "message": (
            f"Current air temperature is "
            f"{float(air_temp):.1f}°C and the latest "
            f"IoT soil temperature is "
            f"{float(soil_temp):.1f}°C."
        ),
    }


# ============================================================
# ENVIRONMENTAL INTELLIGENCE
# ============================================================

def build_environment_status(
    predicted_class: str,
    weather: dict,
    soil: dict,
) -> dict:
    """
    Combine:

        Current growth stage
        +
        Current weather
        +
        Latest IoT soil temperature

    Output:
        Favourable / Caution / Unknown
        Reason
        Farmer message
        Harvest impact

    IMPORTANT:
    Environmental information does NOT add or
    subtract arbitrary harvest days.
    """

    weather_available = weather.get(
        "available",
        False,
    )

    soil_available = soil.get(
        "available",
        False,
    )

    temperature = weather.get(
        "temperature"
    )

    humidity = weather.get(
        "humidity"
    )

    is_rainy = weather.get(
        "is_rainy",
        False,
    )

    soil_temperature = soil.get(
        "temperature_celsius"
    )

    # ========================================================
    # NO WEATHER + NO SOIL
    # ========================================================

    if (
        not weather_available
        and
        not soil_available
    ):

        return {
            "level": "Unknown",

            "status": (
                "Environmental data unavailable"
            ),

            "reason": (
                "Current weather information and the "
                "latest IoT soil temperature are not available."
            ),

            "farmer_message": (
                "The normal stage-based estimate is being used. "
                "Continue monitoring the plant and scan it again later."
            ),

            "harvest_impact": (
                "No environmental day adjustment has been applied."
            ),
        }

    # ========================================================
    # RAINFALL CONDITION
    # ========================================================

    if weather_available and is_rainy:

        rain_reasons = {

            "Bud": (
                "Rainy conditions may cause excess moisture "
                "around the root zone. Good drainage is important "
                "while buds are developing."
            ),

            "Flower": (
                "Rainy conditions may increase disease risk "
                "during flowering. Inspect flowers regularly "
                "and maintain good airflow."
            ),

            "EarlyFruit": (
                "Wet conditions may increase disease pressure "
                "on young fruit. Check drainage and inspect "
                "developing fruits regularly."
            ),

            "MidGrowth": (
                "Rain and sudden changes in moisture near "
                "maturity may increase fruit-cracking and "
                "disease risk."
            ),

            "MatureFruit": (
                "Wet conditions may increase fruit cracking "
                "or fruit-rot risk. Inspect mature fruit "
                "carefully before harvesting."
            ),
        }

        reason = rain_reasons.get(
            predicted_class,
            (
                "Rainy conditions may affect "
                "normal plant development."
            ),
        )

        if soil_available:

            reason += (
                f" The latest IoT soil temperature "
                f"is {soil_temperature:.1f}°C."
            )

        return {
            "level": "Caution",

            "status": (
                "Rainfall risk detected"
            ),

            "reason": reason,

            "farmer_message": (
                "Maintain good drainage and continue "
                "monitoring the plant. Check irrigation "
                "and soil condition before adding more water."
            ),

            "harvest_impact": (
                "The normal stage-based time range is retained. "
                "Continue monitoring because development may vary "
                "under wet conditions."
            ),
        }

    # ========================================================
    # AIR TEMPERATURE OUTSIDE REFERENCE RANGE
    # ========================================================

    if (
        weather_available
        and
        temperature is not None
        and
        (
            temperature < 23
            or
            temperature > 30
        )
    ):

        if temperature > 30:

            reason = (
                f"Current air temperature is "
                f"{temperature:.1f}°C, which is above "
                "the usual ecological reference range "
                "used for pomegranate cultivation."
            )

            farmer_message = (
                "Monitor plant condition and irrigation "
                "carefully because warmer conditions may "
                "increase water stress."
            )

        else:

            reason = (
                f"Current air temperature is "
                f"{temperature:.1f}°C, which is below "
                "the usual ecological reference range "
                "used for pomegranate cultivation."
            )

            farmer_message = (
                "Plant development may be slower under "
                "cooler conditions. Continue monitoring "
                "the current growth stage."
            )

        if soil_available:

            reason += (
                f" The latest IoT soil temperature "
                f"is {soil_temperature:.1f}°C."
            )

        return {
            "level": "Caution",

            "status": (
                "Temperature needs monitoring"
            ),

            "reason": reason,

            "farmer_message": farmer_message,

            "harvest_impact": (
                "The normal stage-based estimate is retained. "
                "No fixed number of days is added or removed."
            ),
        }

    # ========================================================
    # WEATHER UNAVAILABLE, SOIL AVAILABLE
    # ========================================================

    if (
        not weather_available
        and
        soil_available
    ):

        return {
            "level": "Unknown",

            "status": (
                "Weather unavailable"
            ),

            "reason": (
                f"Current weather information could not "
                f"be retrieved. The latest IoT soil "
                f"temperature is {soil_temperature:.1f}°C."
            ),

            "farmer_message": (
                "Continue monitoring the plant. "
                "The soil sensor reading is available, "
                "but weather information is required for "
                "a complete environmental assessment."
            ),

            "harvest_impact": (
                "The normal stage-based estimate is used."
            ),
        }

    # ========================================================
    # WEATHER AVAILABLE, SOIL NOT CONNECTED
    # ========================================================

    if (
        weather_available
        and
        not soil_available
    ):

        return {
            "level": "Favourable",

            "status": (
                "Weather conditions acceptable"
            ),

            "reason": (
                f"Current air temperature is "
                f"{temperature:.1f}°C with no rainfall "
                f"warning. Latest IoT soil temperature "
                f"is not available for this request."
            ),

            "farmer_message": (
                "Continue normal irrigation, plant care, "
                "and regular monitoring."
            ),

            "harvest_impact": (
                "Normal stage-based estimate applied."
            ),
        }

    # ========================================================
    # BOTH WEATHER + SOIL AVAILABLE
    # ========================================================

    humidity_text = ""

    if humidity is not None:

        humidity_text = (
            f" Current relative humidity is "
            f"{humidity:.0f}%."
        )

    return {
        "level": "Favourable",

        "status": (
            "Normal development expected"
        ),

        "reason": (
            f"Current air temperature is "
            f"{temperature:.1f}°C and the latest "
            f"IoT soil temperature is "
            f"{soil_temperature:.1f}°C."
            f"{humidity_text} "
            "No major rainfall or air-temperature "
            "warning is currently detected."
        ),

        "farmer_message": (
            "Continue normal irrigation, plant care, "
            "and regular monitoring."
        ),

        "harvest_impact": (
            "Normal stage-based estimate applied."
        ),
    }


# ============================================================
# MAIN GROWTH RESULT SERVICE
# ============================================================

async def build_growth_result(
    predicted_class: str,
    confidence: float,
    all_probabilities: dict,
    lat: float = 9.7,
    lon: float = 80.0,

    # OPTIONAL so existing controller does not break
    farmer_id: str | None = None,
) -> dict:
    """
    Build complete growth-stage and harvest advisory.

    CNN:
        Detects the current growth stage.

    Timeline:
        Provides next-stage and remaining harvest range.

    Weather:
        Current Open-Meteo environmental information.

    Soil:
        Latest IoT soil temperature from Firebase.

    IMPORTANT:
        Weather and soil information provide advisory
        context only.

        They do NOT currently add/subtract fixed days.
    """

    # ========================================================
    # VALIDATE CNN CLASS
    # ========================================================

    if predicted_class not in STAGE_INFO:

        raise ValueError(
            f"Unknown growth stage: {predicted_class}"
        )

    stage = STAGE_INFO[
        predicted_class
    ]

    # ========================================================
    # CURRENT WEATHER
    # ========================================================

    weather = await get_weather(
        lat,
        lon,
    )

    # ========================================================
    # LATEST IOT SOIL TEMPERATURE
    # ========================================================

    soil = get_latest_soil_temperature(
        farmer_id
    )

    # ========================================================
    # AIR VS SOIL TEMPERATURE COMPARISON
    # ========================================================

    temperature_comparison = (
        build_temperature_comparison(
            weather,
            soil,
        )
    )

    # ========================================================
    # ENVIRONMENTAL ADVISORY
    # ========================================================

    environment = (
        build_environment_status(
            predicted_class,
            weather,
            soil,
        )
    )

    # ========================================================
    # STAGE TIMELINE
    # ========================================================

    transition_min = stage[
        "transition_min"
    ]

    transition_max = stage[
        "transition_max"
    ]

    harvest_min = stage[
        "harvest_min"
    ]

    harvest_max = stage[
        "harvest_max"
    ]

    # ========================================================
    # MATURE FRUIT
    # ========================================================

    if predicted_class == "MatureFruit":

        transition_range = (
            "Ready for maturity assessment"
        )

        harvest_range = (
            "Maturity assessment now"
        )

        estimated_days = 0

        harvest_message = (
            "Mature fruit stage detected. "
            "Check maturity indicators before harvesting."
        )

    # ========================================================
    # ALL OTHER STAGES
    # ========================================================

    else:

        transition_range = (
            f"{transition_min}–"
            f"{transition_max} days"
        )

        harvest_range = (
            f"{harvest_min}–"
            f"{harvest_max} days"
        )

        # Midpoint retained only for compatibility
        # with your current Flutter result screen.
        estimated_days = (
            harvest_min
            +
            harvest_max
        ) // 2

        harvest_message = (
            f"Estimated harvest window: "
            f"{harvest_range}"
        )

    # ========================================================
    # WEATHER DISPLAY
    # ========================================================

    if not weather.get(
        "available"
    ):

        weather_condition = (
            "Unavailable"
        )

        weather_effect = (
            "Weather unavailable — base "
            "estimate used"
        )

    elif weather.get(
        "is_rainy"
    ):

        weather_condition = (
            "Rainy"
        )

        weather_effect = (
            "Rainfall risk detected — "
            "monitor crop condition"
        )

    elif environment[
        "level"
    ] == "Caution":

        weather_condition = (
            "Needs Monitoring"
        )

        weather_effect = (
            "Environmental caution — "
            "base estimate retained"
        )

    else:

        weather_condition = (
            "Favourable"
        )

        weather_effect = (
            "Normal conditions — "
            "base estimate applied"
        )

    # ========================================================
    # FINAL API RESPONSE
    # ========================================================

    return {

        "status": "success",

        # ----------------------------------------------------
        # CNN RESULT
        # ----------------------------------------------------

        "growth_stage": {

            "detected": predicted_class,

            "display_name": stage[
                "display_name"
            ],

            "confidence_percent": round(
                confidence * 100,
                1,
            ),

            "all_probabilities": (
                all_probabilities
            ),

            "model_accuracy_percent": (
                86.27
            ),
        },

        # ----------------------------------------------------
        # NEXT STAGE
        # ----------------------------------------------------

        "next_stage": stage[
            "next_stage"
        ],

        "transition_prediction": {

            "min_days": (
                transition_min
            ),

            "max_days": (
                transition_max
            ),

            "range": (
                transition_range
            ),

            "message": (
                "Current stage is ready for "
                "maturity assessment."
                if predicted_class
                == "MatureFruit"
                else
                "Expected next-stage transition: "
                f"{transition_range}"
            ),
        },

        # ----------------------------------------------------
        # HARVEST ESTIMATION
        # ----------------------------------------------------

        "harvest_prediction": {

            "estimated_days": (
                estimated_days
            ),

            "min_days": (
                harvest_min
            ),

            "max_days": (
                harvest_max
            ),

            "range": (
                harvest_range
            ),

            "message": (
                harvest_message
            ),

            # Weather and soil DO NOT currently
            # alter the numerical range.
            "weather_adjusted": False,

            "soil_adjusted": False,

            "method": (
                "Evidence-informed stage-based "
                "harvest estimation"
            ),
        },

        # ----------------------------------------------------
        # CURRENT WEATHER
        # ----------------------------------------------------

        "weather": {

            "available": weather.get(
                "available",
                False,
            ),

            "temperature_celsius": (
                weather.get(
                    "temperature"
                )
            ),

            "humidity_percent": (
                weather.get(
                    "humidity"
                )
            ),

            "precipitation_mm": (
                weather.get(
                    "precipitation"
                )
            ),

            "condition": (
                weather_condition
            ),

            "effect_on_harvest": (
                weather_effect
            ),
        },

        # ----------------------------------------------------
        # IOT SOIL TEMPERATURE
        # ----------------------------------------------------

        "soil": {

            "available": soil.get(
                "available",
                False,
            ),

            "temperature_celsius": (
                soil.get(
                    "temperature_celsius"
                )
            ),

            "timestamp": soil.get(
                "timestamp"
            ),

            "source": soil.get(
                "source"
            ),

            "message": soil.get(
                "message"
            ),
        },

        # ----------------------------------------------------
        # AIR + SOIL COMPARISON
        # ----------------------------------------------------

        "temperature_comparison": (
            temperature_comparison
        ),

        # ----------------------------------------------------
        # ENVIRONMENTAL INTELLIGENCE
        # ----------------------------------------------------

        "environment": {

            "level": environment[
                "level"
            ],

            "status": environment[
                "status"
            ],

            "reason": environment[
                "reason"
            ],

            "farmer_message": environment[
                "farmer_message"
            ],

            "harvest_impact": environment[
                "harvest_impact"
            ],
        },

        # ----------------------------------------------------
        # FARMER GUIDANCE
        # ----------------------------------------------------

        "recommendations": {

            "care_tip": stage[
                "care_tip"
            ],

            "care_action": stage[
                "care_action"
            ],

            "risk_warning": stage[
                "risk_warning"
            ],
        },
    }