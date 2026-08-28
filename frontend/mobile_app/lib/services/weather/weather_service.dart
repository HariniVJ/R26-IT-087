import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../l10n/app_strings.dart';
import '../../models/irrigation_weather.dart';
import '../irrigation/location_service.dart';

class WeatherData {
  final String temp;
  final String feelsLike;
  final String conditionKey;
  final String description;
  final String humidity;
  final String wind;
  final String location;
  final String country;
  final String iconCode;
  final String weatherEmoji;
  final String precipitation;
  final String rainProbability;
  final int? rainExpectedInHours;
  final DateTime updatedAt;
  final IrrigationWeather? raw;

  const WeatherData({
    required this.temp,
    required this.feelsLike,
    required this.conditionKey,
    required this.description,
    required this.humidity,
    required this.wind,
    required this.location,
    required this.country,
    required this.iconCode,
    required this.weatherEmoji,
    required this.precipitation,
    required this.rainProbability,
    required this.updatedAt,
    this.rainExpectedInHours,
    this.raw,
  });

  String get condition => t(conditionKey);
  String get humidityText => humidity;
  String get rainProbabilityText => rainProbability;
  String get locationLabel => location;
}

/// Home weather uses the same Open-Meteo + GPS path as irrigation.
class WeatherService {
  static const _endpoint = 'https://api.open-meteo.com/v1/forecast';

  final _location = FarmLocationService();

  Future<WeatherData> fetchWeather() async {
    final location = await _location.getCurrentLocation();

    final weather = await _fetchCurrentWeather(
      location.latitude,
      location.longitude,
    );

    final conditionKey = weather.conditionLabel ?? 'partlyCloudy';
    final place =
        '${location.latitude.toStringAsFixed(3)}, ${location.longitude.toStringAsFixed(3)}';

    return WeatherData(
      temp: '${weather.tempMean.round()}°C',
      feelsLike: '${weather.apparentTempMean.round()}°C',
      conditionKey: conditionKey,
      description: t(conditionKey),
      humidity: '${(weather.humidity ?? 0).round()}%',
      wind: '${weather.windSpeedMax.round()} km/h',
      location: place,
      country: '',
      iconCode: '',
      weatherEmoji: _emoji(weather.weatherCode),
      precipitation: '${weather.rainMm.toStringAsFixed(1)} mm',
      rainProbability: '${(weather.rainProbability ?? 0).round()}%',
      rainExpectedInHours: weather.rainExpectedInHours,
      updatedAt: weather.fetchedAt,
      raw: weather,
    );
  }

  Future<IrrigationWeather> _fetchCurrentWeather(
    double latitude,
    double longitude,
  ) async {
    final uri = Uri.parse(_endpoint).replace(
      queryParameters: {
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'current':
            'temperature_2m,apparent_temperature,precipitation,relative_humidity_2m,weather_code,wind_speed_10m',
        'daily':
            'temperature_2m_max,temperature_2m_min,apparent_temperature_max,apparent_temperature_min,precipitation_sum,precipitation_hours,wind_speed_10m_max,et0_fao_evapotranspiration,weather_code',
        'hourly': 'precipitation,precipitation_probability,weather_code',
        'forecast_days': '2',
        'timezone': 'auto',
      },
    );

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) {
        throw Exception('Weather API returned ${response.statusCode}.');
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final current = json['current'] as Map<String, dynamic>;
      final daily = json['daily'] as Map<String, dynamic>;
      final hourly = json['hourly'] as Map<String, dynamic>?;
      final weatherCode = (current['weather_code'] as num?)?.toDouble() ?? 0;
      final dailyWeatherCode = (daily['weather_code'] as List?)?.first as num?;
      final tempMax = (daily['temperature_2m_max'] as List).first as num;
      final tempMin = (daily['temperature_2m_min'] as List).first as num;
      final apparentMax =
          (daily['apparent_temperature_max'] as List).first as num;
      final apparentMin =
          (daily['apparent_temperature_min'] as List).first as num;
      final rain = _rainHint(hourly);

      return IrrigationWeather(
        tempMean: (tempMax + tempMin) / 2,
        apparentTempMean: (apparentMax + apparentMin) / 2,
        solarRadiation: 0,
        rainMm: (current['precipitation'] as num?)?.toDouble() ?? 0,
        rainHours: ((daily['precipitation_hours'] as List).first as num)
            .toDouble(),
        forecastRain24h: ((daily['precipitation_sum'] as List).first as num)
            .toDouble(),
        windSpeedMax: ((daily['wind_speed_10m_max'] as List).first as num)
            .toDouble(),
        windGustMax: 0,
        et0: ((daily['et0_fao_evapotranspiration'] as List).first as num)
            .toDouble(),
        weatherCode: weatherCode,
        dailyWeatherCode: dailyWeatherCode?.toDouble() ?? weatherCode,
        humidity: (current['relative_humidity_2m'] as num?)?.toDouble(),
        rainProbability: rain.probability,
        rainExpectedInHours: rain.inHours,
        conditionLabel: _conditionKey(weatherCode),
        fetchedAt: DateTime.now(),
      );
    } on SocketException {
      throw Exception(t('weatherUnavailable'));
    } on TimeoutException {
      throw Exception(t('weatherUnavailable'));
    } catch (error) {
      throw Exception(t('weatherUnavailable'));
    }
  }

  ({int? inHours, double? probability}) _rainHint(
    Map<String, dynamic>? hourly,
  ) {
    if (hourly == null) return (inHours: null, probability: null);
    final precipitation = (hourly['precipitation'] as List?) ?? [];
    final probabilities = (hourly['precipitation_probability'] as List?) ?? [];
    for (var index = 0; index < precipitation.length; index++) {
      final amount = (precipitation[index] as num?)?.toDouble() ?? 0;
      if (amount > 0) {
        final probability = index < probabilities.length
            ? (probabilities[index] as num?)?.toDouble()
            : null;
        return (inHours: index, probability: probability);
      }
    }
    return (inHours: null, probability: null);
  }

  String _conditionKey(double code) {
    final value = code.round();
    if (value == 0) return 'clear';
    if (value <= 3) return 'partlyCloudy';
    if (value <= 48) return 'cloudy';
    if (value <= 67 || (value >= 80 && value <= 82)) return 'rain';
    if (value >= 95) return 'storm';
    return 'cloudy';
  }

  String _emoji(double code) {
    final c = code.round();
    if (c == 0) return '☀️';
    if (c <= 3) return '⛅';
    if (c <= 48) return '☁️';
    if (c <= 67) return '🌧️';
    if (c <= 82) return '🌦️';
    return '⛈️';
  }
}
