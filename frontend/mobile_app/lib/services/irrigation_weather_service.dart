import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/farm_location.dart';
import '../models/irrigation_weather.dart';
import 'location_service.dart';

/// Open-Meteo weather for the irrigation TFLite model.
/// Network code stays here so screens never call the weather API directly.
class IrrigationWeatherService {
  static const _cacheKey = 'irrigation_weather_cache';
  static const _endpoint = 'https://api.open-meteo.com/v1/forecast';

  String? lastError;

  Future<FarmWeatherSnapshot> loadForFarm(FarmLocationService locationService) async {
    lastError = null;
    FarmLocation? location;
    try {
      location = await locationService.getCurrentLocation();
    } catch (e) {
      lastError = e.toString();
      return FarmWeatherSnapshot(
        location: await locationService.loadLastLocation(),
        weather: await loadCachedWeather(),
        locationError: e.toString(),
      );
    }

    final weather = await fetchWeather(
      latitude: location.latitude,
      longitude: location.longitude,
    );
    return FarmWeatherSnapshot(
      location: location,
      weather: weather,
      locationError: null,
    );
  }

  Future<IrrigationWeather?> fetchWeather({
    required double latitude,
    required double longitude,
  }) async {
    try {
      lastError = null;
      final uri = Uri.parse(_endpoint).replace(
        queryParameters: {
          'latitude': latitude.toString(),
          'longitude': longitude.toString(),
          'current': [
            'temperature_2m',
            'apparent_temperature',
            'precipitation',
            'weather_code',
            'wind_speed_10m',
            'wind_gusts_10m',
          ].join(','),
          'daily': [
            'temperature_2m_max',
            'temperature_2m_min',
            'apparent_temperature_max',
            'apparent_temperature_min',
            'shortwave_radiation_sum',
            'precipitation_sum',
            'precipitation_hours',
            'wind_speed_10m_max',
            'wind_gusts_10m_max',
            'et0_fao_evapotranspiration',
            'weather_code',
          ].join(','),
          'forecast_days': '1',
          'timezone': 'auto',
        },
      );

      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) {
        lastError =
            'Weather API returned ${response.statusCode}. Using saved weather if available.';
        return loadCachedWeather();
      }

      final weather = _parse(jsonDecode(response.body) as Map<String, dynamic>);
      await _saveCache(weather);
      return weather;
    } on SocketException {
      lastError = 'No internet connection. Using saved weather if available.';
      return loadCachedWeather();
    } on TimeoutException {
      lastError = 'Weather request timed out. Using saved weather if available.';
      return loadCachedWeather();
    } catch (_) {
      lastError = 'Could not load live weather. Using saved weather if available.';
      return loadCachedWeather();
    }
  }

  Future<IrrigationWeather?> loadCachedWeather() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cacheKey);
    if (raw == null || raw.isEmpty) return null;

    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return IrrigationWeather.fromJson(json).copyWith(isCached: true);
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveCache(IrrigationWeather weather) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheKey, jsonEncode(weather.toJson()));
  }

  IrrigationWeather _parse(Map<String, dynamic> weather) {
    final current = weather['current'] as Map<String, dynamic>;
    final daily = weather['daily'] as Map<String, dynamic>;

    final tempMean =
        ((daily['temperature_2m_max'][0] as num) +
            (daily['temperature_2m_min'][0] as num)) /
        2;
    final apparentTempMean =
        ((daily['apparent_temperature_max'][0] as num) +
            (daily['apparent_temperature_min'][0] as num)) /
        2;

    return IrrigationWeather(
      tempMean: double.parse(tempMean.toStringAsFixed(2)),
      apparentTempMean: double.parse(apparentTempMean.toStringAsFixed(2)),
      solarRadiation: (daily['shortwave_radiation_sum'][0] as num).toDouble(),
      rainMm: (current['precipitation'] as num?)?.toDouble() ?? 0,
      rainHours: (daily['precipitation_hours'][0] as num).toDouble(),
      forecastRain24h: (daily['precipitation_sum'][0] as num).toDouble(),
      windSpeedMax: (daily['wind_speed_10m_max'][0] as num).toDouble(),
      windGustMax: (daily['wind_gusts_10m_max'][0] as num).toDouble(),
      et0: (daily['et0_fao_evapotranspiration'][0] as num).toDouble(),
      weatherCode: (current['weather_code'] as num?)?.toDouble() ?? 0,
      dailyWeatherCode: (daily['weather_code'][0] as num).toDouble(),
      fetchedAt: DateTime.now(),
      isCached: false,
    );
  }
}

class FarmWeatherSnapshot {
  final FarmLocation? location;
  final IrrigationWeather? weather;
  final String? locationError;

  const FarmWeatherSnapshot({
    required this.location,
    required this.weather,
    this.locationError,
  });
}
