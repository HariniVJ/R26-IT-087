import requests


def get_weather_data(latitude: float, longitude: float):
    url = "https://api.open-meteo.com/v1/forecast"

    params = {
        "latitude": latitude,
        "longitude": longitude,
        "current": [
            "temperature_2m",
            "apparent_temperature",
            "precipitation",
            "weather_code",
            "wind_speed_10m",
            "wind_gusts_10m"
        ],
        "daily": [
            "temperature_2m_max",
            "temperature_2m_min",
            "apparent_temperature_max",
            "apparent_temperature_min",
            "shortwave_radiation_sum",
            "precipitation_sum",
            "precipitation_hours",
            "wind_speed_10m_max",
            "wind_gusts_10m_max",
            "et0_fao_evapotranspiration",
            "weather_code"
        ],
        "forecast_days": 1,
        "timezone": "auto"
    }

    response = requests.get(url, params=params, timeout=10)
    response.raise_for_status()

    weather = response.json()

    current = weather["current"]
    daily = weather["daily"]

    print("\n========== OPEN-METEO API RAW CHECK ==========")
    print("Current weather code:", current.get("weather_code"))
    print("Daily weather code:", daily["weather_code"][0])
    print("Current precipitation:", current.get("precipitation", 0))
    print("Daily precipitation sum:", daily["precipitation_sum"][0])
    print("Daily precipitation hours:", daily["precipitation_hours"][0])
    print("=============================================\n")

    temp_mean = (
        daily["temperature_2m_max"][0] + daily["temperature_2m_min"][0]
    ) / 2

    apparent_temp_mean = (
        daily["apparent_temperature_max"][0] + daily["apparent_temperature_min"][0]
    ) / 2

    return {
        "temp_mean": round(temp_mean, 2),
        "apparent_temp_mean": round(apparent_temp_mean, 2),
        "solar_radiation": daily["shortwave_radiation_sum"][0],
        "rain_mm": current.get("precipitation", 0),
        "rain_hours": daily["precipitation_hours"][0],
        "forecast_rain_24h": daily["precipitation_sum"][0],
        "wind_speed_max": daily["wind_speed_10m_max"][0],
        "wind_gust_max": daily["wind_gusts_10m_max"][0],
        "et0": daily["et0_fao_evapotranspiration"][0],
        "weather_code": current.get("weather_code", 0),
        "daily_weather_code": daily["weather_code"][0]
    }

