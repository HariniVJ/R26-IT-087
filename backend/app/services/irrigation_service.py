import os
import joblib
import pandas as pd

from app.services.weather_service import get_weather_data


MODEL_PATH = os.path.join("models", "irrigation_model.pkl")

saved_model = joblib.load(MODEL_PATH)

model = saved_model["model"]
feature_cols = saved_model["feature_cols"]


def validate_input(data: dict):
    errors = []

    if not (5 <= data["soil_moisture"] <= 95):
        errors.append("Invalid soil moisture value. Please check the soil sensor.")

    if not (15 <= data["temp_mean"] <= 45):
        errors.append("Invalid temperature value from weather API.")

    if not (15 <= data["apparent_temp_mean"] <= 55):
        errors.append("Invalid apparent temperature value from weather API.")

    if not (0 <= data["solar_radiation"] <= 40):
        errors.append("Invalid solar radiation value.")

    if data["rain_mm"] < 0:
        errors.append("Rainfall cannot be negative.")

    if not (0 <= data["rain_hours"] <= 24):
        errors.append("Rain hours must be between 0 and 24.")

    if data["forecast_rain_24h"] < 0:
        errors.append("Forecast rainfall cannot be negative.")

    if data["wind_speed_max"] < 0:
        errors.append("Wind speed cannot be negative.")

    if data["wind_gust_max"] < 0:
        errors.append("Wind gust cannot be negative.")

    if data["et0"] < 0:
        errors.append("ET0 cannot be negative.")

    if not (0 <= data["weather_code"] <= 99):
        errors.append("Invalid weather code.")

    return errors


def apply_safety_rules(model_prediction: str, soil_moisture: float, forecast_rain_24h: float):
    if soil_moisture >= 70:
        return "SKIP_SOIL_ALREADY_WET"

    if forecast_rain_24h >= 2.0:
        return "SKIP_RAIN_EXPECTED"

    return model_prediction


def farmer_message(prediction: str):
    if prediction == "SUITABLE_TO_IRRIGATE":
        return {
            "status": "Suitable Now",
            "reason": "Soil moisture is low and no rainfall forecast detected."
        }

    if prediction == "SKIP_RAIN_EXPECTED":
        return {
            "status": "Not Suitable Now",
            "reason": "Rainfall is expected, so irrigation can be skipped."
        }

    if prediction == "SKIP_SOIL_ALREADY_WET":
        return {
            "status": "Not Suitable Now",
            "reason": "Soil is already wet."
        }

    if prediction == "NO_URGENT_IRRIGATION":
        return {
            "status": "No Urgent Irrigation Needed",
            "reason": "Soil moisture is moderate."
        }

    return {
        "status": "Unknown",
        "reason": "Unable to generate irrigation advice."
    }


def predict_irrigation_from_mobile(soil_moisture: float, latitude: float, longitude: float):
    try:
        weather_data = get_weather_data(latitude, longitude)
        print("\n================ BACKEND IRRIGATION PANEL ================")
        print(f"Soil Moisture        : {soil_moisture} %")
        print(f"Latitude             : {latitude}")
        print(f"Longitude            : {longitude}")

        print("\n---------------- WEATHER DATA USED ----------------")
        print(f"Temperature          : {weather_data.get('temp_mean')} °C")
        print(f"Apparent Temp        : {weather_data.get('apparent_temp_mean')} °C")
        print(f"Rain Now             : {weather_data.get('rain_mm')} mm")
        print(f"Rain Hours           : {weather_data.get('rain_hours')} h")
        print(f"Forecast Rain 24h    : {weather_data.get('forecast_rain_24h')} mm")
        print(f"Wind Speed           : {weather_data.get('wind_speed_max')} km/h")
        print(f"ET0                  : {weather_data.get('et0')} mm")
        print(f"Weather Code         : {weather_data.get('weather_code')}")
        print(f"Daily Weather Code   : {weather_data.get('daily_weather_code')}")
        print("---------------------------------------------------")
    except Exception as error:
        return {
            "success": False,
            "prediction": "WEATHER_API_ERROR",
            "status": "Cannot Predict",
            "reason": f"Weather API failed: {str(error)}"
        }

    model_input = {
        "soil_moisture": soil_moisture,
        **weather_data
    }

    errors = validate_input(model_input)

    if errors:
        return {
            "success": False,
            "prediction": "INVALID_INPUT",
            "status": "Cannot Predict",
            "reason": errors,
            "weather_used": weather_data
        }

    input_df = pd.DataFrame([model_input])[feature_cols]

    model_prediction = model.predict(input_df)[0]
    print("\n---------------- MODEL OUTPUT ----------------")
    print(f"Model Prediction     : {model_prediction}")

    final_prediction = apply_safety_rules(
        model_prediction=model_prediction,
        soil_moisture=soil_moisture,
        forecast_rain_24h=model_input["forecast_rain_24h"]
    )

    message = farmer_message(final_prediction)
    print("\n---------------- FINAL OUTPUT ----------------")
    print(f"Final Prediction     : {final_prediction}")
    print(f"Status               : {message['status']}")
    print(f"Reason               : {message['reason']}")
    print("===========================================================\n")

    return {
        "success": True,
        "model_prediction": model_prediction,
        "final_prediction": final_prediction,
        "status": message["status"],
        "reason": message["reason"],
        "weather_used": weather_data
    }