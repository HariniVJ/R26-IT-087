import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

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
  });
}

class WeatherService {
  static const String _base =
      'https://api.openweathermap.org/data/2.5/weather';

  String get _apiKey {
    final key = dotenv.env['OPENWEATHER_API_KEY'];

    if (key == null || key.isEmpty) {
      throw Exception('OPENWEATHER_API_KEY is missing in .env file');
    }

    return key;
  }

  String get _city {
    return dotenv.env['WEATHER_CITY'] ?? 'Colombo';
  }

  String get _country {
    return dotenv.env['WEATHER_COUNTRY'] ?? 'LK';
  }

  Future<WeatherData> fetchWeather() async {
    final url = Uri.parse(
      '$_base?q=$_city,$_country&appid=$_apiKey&units=metric',
    );

    try {
      final res = await http.get(url).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        return _parse(jsonDecode(res.body) as Map<String, dynamic>);
      }

      throw Exception('Status ${res.statusCode}: ${res.body}');
    } catch (e) {
      throw Exception('Weather fetch failed: $e');
    }
  }

  WeatherData _parse(Map<String, dynamic> json) {
    final main = json['main'] as Map<String, dynamic>;
    final wind = json['wind'] as Map<String, dynamic>;
    final weather = (json['weather'] as List).first as Map<String, dynamic>;
    final sys = json['sys'] as Map<String, dynamic>;

    final tempC = (main['temp'] as num).round();
    final feelsC = (main['feels_like'] as num).round();
    final humidity = (main['humidity'] as num).toInt();
    final windSpeed = ((wind['speed'] as num) * 3.6).round();
    final icon = weather['icon'] as String;

    return WeatherData(
      temp: '$tempC°C',
      feelsLike: '$feelsC°C',
      condition: _capitalize(weather['main'] as String),
      description: _capitalize(weather['description'] as String),
      humidity: '$humidity%',
      wind: '$windSpeed km/h',
      location: json['name'] as String,
      country: sys['country'] as String,
      iconCode: icon,
      weatherEmoji: _emoji(icon),
    );
  }

  String _emoji(String code) {
    final id = code.replaceAll(RegExp(r'[dn]'), '');

    return const {
          '01': '☀️',
          '02': '⛅',
          '03': '🌥️',
          '04': '☁️',
          '09': '🌧️',
          '10': '🌦️',
          '11': '⛈️',
          '13': '❄️',
          '50': '🌫️',
        }[id] ??
        '🌤️';
  }

  String _capitalize(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }
}