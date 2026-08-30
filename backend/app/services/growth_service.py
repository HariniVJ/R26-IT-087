import httpx

from datetime import datetime, timedelta

from app.config.firebase_config import db


SENSOR_COLLECTION = "sensor_readings"


STAGE_INFO = {
    "Bud": {
        "display_name": "Bud Stage 🌱",
        "next_stage": "Flower",
        "transition_min": 5,
        "transition_max": 15,
        "harvest_min": 101,
        "harvest_max": 158,
        "care_tip": (
            "Maintain steady soil moisture during dry periods, but avoid keeping "
            "the root zone waterlogged. Provide good sunlight and maintain an "
            "open, well-ventilated canopy."
        ),
        "care_action": (
            "Inspect buds and tender shoots regularly for insects, discoloration, "
            "spots, deformation, or drying. Maintain good drainage and remove "
            "seriously affected plant material."
        ),
        "risk_warning": (
            "Rainy or humid weather may increase bud rot and fungal infection risk. "
            "Too little water may weaken buds, while waterlogged soil may damage "
            "roots and reduce healthy bud development."
        ),
    },

    "Flower": {
        "display_name": "Flower Stage 🌸",
        "next_stage": "EarlyFruit",
        "transition_min": 21,
        "transition_max": 28,
        "harvest_min": 96,
        "harvest_max": 143,
        "care_tip": (
            "Maintain moderate and consistent soil moisture during flowering. "
            "Provide good sunlight and airflow and maintain a healthy flower load."
        ),
        "care_action": (
            "Inspect flowers and tender shoots regularly for pests, disease, "
            "discoloration, drying, and abnormal flower drop. Maintain good "
            "drainage and avoid unnecessary overhead watering."
        ),
        "risk_warning": (
            "Heavy rain may damage flowers and increase flower drop. High humidity "
            "may increase fungal infection risk, while waterlogging may affect "
            "flower development and fruit set."
        ),
    },

    "EarlyFruit": {
        "display_name": "Early Fruit Stage 🍑",
        "next_stage": "MidGrowth",
        "transition_min": 15,
        "transition_max": 45,
        "harvest_min": 75,
        "harvest_max": 115,
        "care_tip": (
            "Maintain steady soil moisture while young fruits develop. Avoid "
            "allowing the soil to become very dry followed by excessive watering."
        ),
        "care_action": (
            "Inspect young fruits regularly for insect holes, larvae, black spots, "
            "or other damage. Protect healthy young fruits where practical and "
            "remove badly damaged fruits."
        ),
        "risk_warning": (
            "Pomegranate fruit borers may damage developing fruits. High humidity "
            "and rain may increase fruit rot risk, while irregular watering may "
            "increase fruit-cracking risk."
        ),
    },

    "MidGrowth": {
        "display_name": "Mid-Growth Stage 🍊",
        "next_stage": "MatureFruit",
        "transition_min": 60,
        "transition_max": 70,
        "harvest_min": 60,
        "harvest_max": 70,
        "care_tip": (
            "Maintain consistent soil moisture, adequate drainage, and good airflow "
            "while the fruit continues developing toward maturity."
        ),
        "care_action": (
            "Inspect fruits regularly for cracking, rot, spots, or insect damage. "
            "Maintain consistent irrigation and avoid sudden changes in soil moisture."
        ),
        "risk_warning": (
            "Sudden changes in moisture, heavy rainfall, or irregular irrigation "
            "may increase fruit-cracking and disease risk as the fruit develops."
        ),
    },

    "MatureFruit": {
        "display_name": "Mature Fruit Stage 🍎",
        "next_stage": None,
        "transition_min": 0,
        "transition_max": 0,
        "harvest_min": 0,
        "harvest_max": 0,
        "care_tip": (
            "Check the fruit carefully for suitable maturity before harvesting. "
            "Pomegranate should be harvested after reaching proper maturity."
        ),
        "care_action": (
            "Harvest suitable fruits carefully using pruning shears or a knife. "
            "Cut the stalk rather than pulling the fruit and handle harvested "
            "fruits gently."
        ),
        "risk_warning": (
            "Over-mature fruits may crack or lose market quality. Heavy rain or "
            "sudden changes in water availability may increase cracking risk, "
            "and damaged mature fruits may be more vulnerable to decay."
        ),
    },
}


def get_latest_soil_temperature(
    farmer_id: str | None,
) -> dict:
    if not farmer_id:
        return {
            "available": False,
            "temperature_celsius": None,
            "timestamp": None,
            "source": None,
            "farmer_id": None,
            "reading_id": None,
            "message": (
                "No logged-in farmer ID was provided "
                "for soil sensor lookup."
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

            timestamp = data.get(
                "timestamp"
            )

            if latest_data is None:
                latest_data = data
                latest_timestamp = timestamp
                latest_id = doc.id
                continue

            if timestamp is not None:
                if (
                    latest_timestamp is None
                    or timestamp > latest_timestamp
                ):
                    latest_data = data
                    latest_timestamp = timestamp
                    latest_id = doc.id

        if latest_data is None:
            return {
                "available": False,
                "temperature_celsius": None,
                "timestamp": None,
                "source": None,
                "farmer_id": farmer_id,
                "reading_id": None,
                "message": (
                    "No soil sensor reading was found "
                    "for the logged-in farmer."
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
                "source": latest_data.get(
                    "source"
                ),
                "farmer_id": farmer_id,
                "reading_id": latest_id,
                "message": (
                    "The latest sensor record does not "
                    "contain soilTemperature."
                ),
            }

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
            "temperature_celsius": round(
                float(
                    soil_temperature
                ),
                1,
            ),
            "timestamp": timestamp_value,
            "source": latest_data.get(
                "source",
                "esp32_ble",
            ),
            "farmer_id": latest_data.get(
                "farmerId",
                farmer_id,
            ),
            "reading_id": latest_id,
            "message": (
                "Latest farmer soil temperature "
                "retrieved from sensor_readings."
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
            "farmer_id": farmer_id,
            "reading_id": None,
            "message": (
                "The latest soil sensor reading "
                "could not be retrieved."
            ),
        }


async def get_weather(
    lat: float = 9.7,
    lon: float = 80.0,
) -> dict:
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
            response = await client.get(
                url
            )

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

        return {
            "available": False,
            "temperature": None,
            "humidity": None,
            "precipitation": None,
            "weather_code": None,
            "is_rainy": False,
        }


def build_temperature_comparison(
    weather: dict,
    soil: dict,
) -> dict:
    air_temp = weather.get(
        "temperature"
    )

    soil_temp = soil.get(
        "temperature_celsius"
    )

    if (
        not weather.get(
            "available"
        )
        or not soil.get(
            "available"
        )
        or air_temp is None
        or soil_temp is None
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


def build_environment_status(
    predicted_class: str,
    weather: dict,
    soil: dict,
) -> dict:
    weather_available = weather.get(
        "available",
        False,
    )

    soil_available = soil.get(
        "available",
        False,
    )

    air_temperature = weather.get(
        "temperature"
    )

    humidity = weather.get(
        "humidity"
    )

    precipitation = weather.get(
        "precipitation"
    )

    is_rainy = weather.get(
        "is_rainy",
        False,
    )

    soil_temperature = soil.get(
        "temperature_celsius"
    )

    air_in_reference_range = (
        weather_available
        and air_temperature is not None
        and 23 <= float(
            air_temperature
        ) <= 30
    )

    soil_in_reference_range = (
        soil_available
        and soil_temperature is not None
        and 23 <= float(
            soil_temperature
        ) <= 30
    )

    if (
        not weather_available
        and not soil_available
    ):
        return {
            "level": "Unknown",
            "status": (
                "Environmental data unavailable"
            ),
            "reason": (
                "Current weather data and the latest "
                "IoT soil temperature are unavailable."
            ),
            "farmer_message": (
                "Continue normal stage-based monitoring "
                "and check environmental conditions again later."
            ),
            "harvest_impact": (
                "The estimated growth-stage date range "
                "remains unchanged."
            ),
        }

    if is_rainy:
        rain_reasons = {
            "Bud": (
                "Rainy conditions may increase moisture "
                "around the root zone while buds are developing."
            ),
            "Flower": (
                "Rainy conditions may increase flower damage, "
                "flower drop, and disease pressure during flowering."
            ),
            "EarlyFruit": (
                "Wet conditions may increase disease pressure "
                "on young developing fruits."
            ),
            "MidGrowth": (
                "Rain and sudden changes in moisture may increase "
                "fruit-cracking and disease risk during fruit development."
            ),
            "MatureFruit": (
                "Wet conditions may increase cracking or fruit-rot "
                "risk in mature fruits."
            ),
        }

        reason = rain_reasons.get(
            predicted_class,
            (
                "Rainy conditions may affect "
                "normal plant development."
            ),
        )

        if air_temperature is not None:
            reason += (
                f" Current air temperature is "
                f"{float(air_temperature):.1f}°C."
            )

        if soil_available:
            reason += (
                f" Latest IoT soil temperature is "
                f"{float(soil_temperature):.1f}°C."
            )

        return {
            "level": "Caution",
            "status": (
                "Rainfall conditions need monitoring"
            ),
            "reason": reason,
            "farmer_message": (
                "Maintain proper drainage, monitor soil moisture, "
                "and avoid unnecessary additional irrigation "
                "during wet conditions."
            ),
            "harvest_impact": (
                "Environmental conditions are used only "
                "for development status. The estimated "
                "date range remains unchanged."
            ),
        }

    if (
        weather_available
        and air_temperature is not None
        and not air_in_reference_range
    ):
        if float(
            air_temperature
        ) > 30:
            reason = (
                f"Current air temperature is "
                f"{float(air_temperature):.1f}°C, "
                "which is above the general 23–30°C "
                "reference range used by this system."
            )

            farmer_message = (
                "Monitor the plant and irrigation carefully "
                "because prolonged warmer conditions may "
                "increase plant water stress."
            )

        else:
            reason = (
                f"Current air temperature is "
                f"{float(air_temperature):.1f}°C, "
                "which is below the general 23–30°C "
                "reference range used by this system."
            )

            farmer_message = (
                "Continue monitoring the plant because prolonged "
                "cooler conditions may influence normal development."
            )

        if soil_available:
            reason += (
                f" Latest IoT soil temperature is "
                f"{float(soil_temperature):.1f}°C."
            )

        return {
            "level": "Caution",
            "status": (
                "Air temperature needs monitoring"
            ),
            "reason": reason,
            "farmer_message": farmer_message,
            "harvest_impact": (
                "Temperature does not add or subtract "
                "days from the estimated growth-stage range."
            ),
        }

    if (
        soil_available
        and soil_temperature is not None
        and not soil_in_reference_range
    ):
        if float(
            soil_temperature
        ) > 30:
            reason = (
                f"The latest IoT soil temperature is "
                f"{float(soil_temperature):.1f}°C, "
                "which is above the general 23–30°C "
                "reference range used by this system."
            )

            farmer_message = (
                "Monitor soil condition and irrigation carefully "
                "and continue observing the plant for signs of stress."
            )

        else:
            reason = (
                f"The latest IoT soil temperature is "
                f"{float(soil_temperature):.1f}°C, "
                "which is below the general 23–30°C "
                "reference range used by this system."
            )

            farmer_message = (
                "Continue monitoring the soil and plant condition. "
                "Persistent cooler soil conditions may require "
                "additional attention."
            )

        if air_temperature is not None:
            reason += (
                f" Current air temperature is "
                f"{float(air_temperature):.1f}°C."
            )

        return {
            "level": "Caution",
            "status": (
                "Soil temperature needs monitoring"
            ),
            "reason": reason,
            "farmer_message": farmer_message,
            "harvest_impact": (
                "Soil temperature is used only for "
                "development-condition assessment. "
                "The estimated date range remains unchanged."
            ),
        }

    if (
        weather_available
        and soil_available
        and air_in_reference_range
        and soil_in_reference_range
    ):
        humidity_text = ""

        if humidity is not None:
            humidity_text = (
                f" Relative humidity is "
                f"{float(humidity):.0f}%."
            )

        return {
            "level": "Favourable",
            "status": (
                "Normal development conditions"
            ),
            "reason": (
                f"Current air temperature is "
                f"{float(air_temperature):.1f}°C and the latest "
                f"IoT soil temperature is "
                f"{float(soil_temperature):.1f}°C. "
                f"Both are within the general 23–30°C "
                f"reference range used by this system."
                f"{humidity_text}"
            ),
            "farmer_message": (
                "Current temperature conditions are suitable "
                "for normal monitoring. Continue regular crop "
                "care and irrigation management."
            ),
            "harvest_impact": (
                "Environmental conditions do not change "
                "the estimated growth-stage date range."
            ),
        }

    if (
        weather_available
        and not soil_available
    ):
        return {
            "level": "Unknown",
            "status": (
                "Soil sensor data unavailable"
            ),
            "reason": (
                f"Current air temperature is "
                f"{float(air_temperature):.1f}°C. "
                "No latest IoT soil-temperature reading "
                "was available for the logged-in farmer."
            ),
            "farmer_message": (
                "Continue normal plant monitoring. "
                "Connect or update the soil sensor reading "
                "for a complete environmental assessment."
            ),
            "harvest_impact": (
                "The estimated growth-stage date range "
                "remains unchanged."
            ),
        }

    if (
        not weather_available
        and soil_available
    ):
        return {
            "level": "Unknown",
            "status": (
                "Weather data unavailable"
            ),
            "reason": (
                f"The latest IoT soil temperature is "
                f"{float(soil_temperature):.1f}°C, "
                "but current weather information could "
                "not be retrieved."
            ),
            "farmer_message": (
                "Continue monitoring the plant and soil. "
                "Weather data is required for a complete "
                "environmental assessment."
            ),
            "harvest_impact": (
                "The estimated growth-stage date range "
                "remains unchanged."
            ),
        }

    return {
        "level": "Favourable",
        "status": (
            "Weather conditions acceptable"
        ),
        "reason": (
            "No major environmental warning "
            "is currently detected."
        ),
        "farmer_message": (
            "Continue normal irrigation, plant care, "
            "and regular monitoring."
        ),
        "harvest_impact": (
            "The estimated growth-stage date range "
            "remains unchanged."
        ),
    }


async def build_growth_result(
    predicted_class: str,
    confidence: float,
    all_probabilities: dict,
    lat: float = 9.7,
    lon: float = 80.0,
    farmer_id: str | None = None,
    capture_date: str | None = None,
) -> dict:
    if predicted_class not in STAGE_INFO:
        raise ValueError(
            f"Unknown growth stage: {predicted_class}"
        )

    stage = STAGE_INFO[
        predicted_class
    ]

    if capture_date:
        try:
            captured_at = datetime.strptime(
                capture_date,
                "%Y-%m-%d",
            )

        except ValueError:
            raise ValueError(
                "capture_date must use YYYY-MM-DD format"
            )

    else:
        captured_at = datetime.now()

    weather = await get_weather(
        lat,
        lon,
    )

    soil = get_latest_soil_temperature(
        farmer_id
    )

    temperature_comparison = (
        build_temperature_comparison(
            weather,
            soil,
        )
    )

    environment = (
        build_environment_status(
            predicted_class,
            weather,
            soil,
        )
    )

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

    if predicted_class == "MatureFruit":
        estimated_start_date = captured_at
        estimated_end_date = captured_at

        estimated_date_range = (
            "Mature stage detected"
        )

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

    else:
        estimated_start_date = (
            captured_at
            + timedelta(
                days=transition_min
            )
        )

        estimated_end_date = (
            captured_at
            + timedelta(
                days=transition_max
            )
        )

        estimated_date_range = (
            f"{estimated_start_date.strftime('%d %b %Y')} "
            f"– "
            f"{estimated_end_date.strftime('%d %b %Y')}"
        )

        transition_range = (
            f"{transition_min}–"
            f"{transition_max} days"
        )

        harvest_range = (
            f"{harvest_min}–"
            f"{harvest_max} days"
        )

        estimated_days = (
            harvest_min
            + harvest_max
        ) // 2

        harvest_message = (
            f"Estimated remaining time to mature stage: "
            f"{harvest_range}"
        )

    if not weather.get(
        "available"
    ):
        weather_condition = (
            "Unavailable"
        )

    elif weather.get(
        "is_rainy"
    ):
        weather_condition = (
            "Rainy"
        )

    elif environment[
        "level"
    ] == "Caution":
        weather_condition = (
            "Needs Monitoring"
        )

    else:
        weather_condition = (
            "Favourable"
        )

    return {
        "status": "success",

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

        "next_stage": stage[
            "next_stage"
        ],

        "transition_prediction": {
            "min_days": transition_min,

            "max_days": transition_max,

            "range": transition_range,

            "capture_date": (
                captured_at.strftime(
                    "%Y-%m-%d"
                )
            ),

            "estimated_start_date": (
                estimated_start_date.strftime(
                    "%Y-%m-%d"
                )
            ),

            "estimated_end_date": (
                estimated_end_date.strftime(
                    "%Y-%m-%d"
                )
            ),

            "estimated_date_range": (
                estimated_date_range
            ),

            "message": (
                "Current stage is ready for maturity assessment."
                if predicted_class == "MatureFruit"
                else
                f"Estimated time to reach "
                f"{stage['next_stage']}: "
                f"{transition_range}"
            ),
        },

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

            "weather_adjusted": False,

            "soil_adjusted": False,

            "method": (
                "Farmer-observed stage-based "
                "growth timeline estimation"
            ),
        },

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

            "weather_code": (
                weather.get(
                    "weather_code"
                )
            ),

            "is_rainy": (
                weather.get(
                    "is_rainy",
                    False,
                )
            ),

            "condition": (
                weather_condition
            ),
        },

        "soil": {
            "available": soil.get(
                "available",
                False,
            ),

            "farmer_id": soil.get(
                "farmer_id"
            ),

            "reading_id": soil.get(
                "reading_id"
            ),

            "temperature_celsius": soil.get(
                "temperature_celsius"
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

        "temperature_comparison": (
            temperature_comparison
        ),

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