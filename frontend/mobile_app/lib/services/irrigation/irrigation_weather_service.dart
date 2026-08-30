import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/farm_location.dart';
import '../../models/irrigation_weather.dart';
import '../weather/place_name_service.dart';
import 'location_service.dart';

/// Open-Meteo weather for the irrigation TFLite model.
/// Network code stays here so screens never call the weather API directly.
class IrrigationWeatherService {
  static const _cacheKey = 'irrigation_weather_cache';
  static const _endpoint = 'https://api.open-meteo.com/v1/forecast';

  String? lastError;
  final _places = PlaceNameService();

  Future<FarmWeatherSnapshot> loadForFarm(FarmLocationService locationService) async {
    lastError = null;
    FarmLocation? location;
    try {
      location = await locationService.getCurrentLocation();
    } catch (e) {
      lastError = e.toString();
      location = await locationService.loadLastLocation();
      if (location == null) {
        return FarmWeatherSnapshot(
          location: null,
          weather: null,
          locationError: e.toString(),
        );
      }
      final weather = await fetchWeather(
        latitude: location.latitude,
        longitude: location.longitude,
      );
      return FarmWeatherSnapshot(
        location: await _withPlaceName(location),
        weather: weather,
        locationError: e.toString(),
      );
    }

    final weather = await fetchWeather(
      latitude: location.latitude,
      longitude: location.longitude,
    );
    return FarmWeatherSnapshot(
      location: await _withPlaceName(location),
      weather: weather,
      locationError: null,
    );
  }

  Future<FarmLocation> _withPlaceName(FarmLocation location) async {
    final name = await _places.resolve(location.latitude, location.longitude);
    return location.copyWith(placeName: name);
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
            'relative_humidity_2m',
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
          'hourly': [
            'precipitation',
            'precipitation_probability',
            'weather_code',
          ].join(','),
          'forecast_days': '2',
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

    final rainHint = _parseHourlyRain(weather['hourly'] as Map<String, dynamic>?);

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
      humidity: (current['relative_humidity_2m'] as num?)?.toDouble(),
      rainProbability: rainHint.probability,
      rainExpectedInHours: rainHint.inHours,
      conditionLabel: weatherConditionLabel(
        (current['weather_code'] as num?)?.toDouble() ?? 0,
      ),
      fetchedAt: DateTime.now(),
      isCached: false,
    );
  }

  ({int? inHours, double? probability}) _parseHourlyRain(
    Map<String, dynamic>? hourly,
  ) {
    if (hourly == null) return (inHours: null, probability: null);
    final times = (hourly['time'] as List?) ?? [];
    final precip = (hourly['precipitation'] as List?) ?? [];
    final probs = (hourly['precipitation_probability'] as List?) ?? [];
    if (times.isEmpty) return (inHours: null, probability: null);

    final now = DateTime.now();
    var currentIdx = 0;
    for (var i = 0; i < times.length; i++) {
      final parsed = DateTime.tryParse(times[i].toString());
      if (parsed != null && !parsed.isAfter(now)) currentIdx = i;
    }

    double? currentProb;
    if (currentIdx < probs.length && probs[currentIdx] != null) {
      currentProb = (probs[currentIdx] as num).toDouble();
    }

    for (var i = currentIdx + 1; i < times.length && i <= currentIdx + 6; i++) {
      final mm = i < precip.length && precip[i] != null
          ? (precip[i] as num).toDouble()
          : 0.0;
      final p = i < probs.length && probs[i] != null
          ? (probs[i] as num).toDouble()
          : 0.0;
      if (mm >= 0.2 || p >= 40) {
        return (inHours: i - currentIdx, probability: p > 0 ? p : currentProb);
      }
    }
    return (inHours: null, probability: currentProb);
  }
}

String weatherConditionLabel(double code) {
  final c = code.round();
  if (c == 0) return 'sunny';
  if (c <= 2) return 'partlyCloudy';
  if (c <= 48) return 'cloudy';
  if (c <= 67) return 'rain';
  if (c <= 82) return 'rainShowers';
  if (c <= 94) return 'rainShowers';
  return 'thunderstorm';
}

String weatherConditionEmoji(double code) {
  switch (weatherConditionLabel(code)) {
    case 'sunny':
      return '☀️';
    case 'partlyCloudy':
      return '🌤️';
    case 'cloudy':
      return '☁️';
    case 'rain':
      return '🌧️';
    case 'rainShowers':
      return '🌦️';
    case 'thunderstorm':
      return '⛈️';
    default:
      return '☁️';
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
