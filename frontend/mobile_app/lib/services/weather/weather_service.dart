import '../../l10n/app_strings.dart';
import '../../models/farm_location.dart';
import '../../models/irrigation_weather.dart';
import '../irrigation/irrigation_weather_service.dart';
import '../irrigation/location_service.dart';
import 'place_name_service.dart';

class WeatherData {
  final String temp;
  final String feelsLike;
  final String condition;
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
    required this.condition,
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

  String get humidityText => humidity;
  String get rainProbabilityText => rainProbability;
  String get locationLabel => location;
}

/// Home weather uses the same Open-Meteo + GPS path as irrigation.
class WeatherService {
  final _location = FarmLocationService();
  final _meteo = IrrigationWeatherService();
  final _places = PlaceNameService();

  Future<WeatherData> fetchWeather() async {
    FarmLocation location;
    try {
      location = await _location.getCurrentLocation();
    } catch (_) {
      final last = await _location.loadLastLocation();
      if (last == null) rethrow;
      location = last;
    }

    final weather = await _meteo.fetchWeather(
      latitude: location.latitude,
      longitude: location.longitude,
    );
    if (weather == null) {
      throw Exception(t('weatherUnavailable'));
    }

    final conditionKey = weather.conditionLabel ?? 'partlyCloudy';
    final place = await _places.resolve(location.latitude, location.longitude);

    return WeatherData(
      temp: '${weather.tempMean.round()}°C',
      feelsLike: '${weather.apparentTempMean.round()}°C',
      condition: t(conditionKey),
      description: t(conditionKey),
      humidity: '${(weather.humidity ?? 0).round()}%',
      wind: '${weather.windSpeedMax.round()} km/h',
      location: place,
      country: '',
      iconCode: '',
      weatherEmoji: weatherConditionEmoji(weather.weatherCode),
      precipitation: '${weather.rainMm.toStringAsFixed(1)} mm',
      rainProbability: '${(weather.rainProbability ?? 0).round()}%',
      rainExpectedInHours: weather.rainExpectedInHours,
      updatedAt: weather.fetchedAt,
      raw: weather,
    );
  }

}
