// lib/services/weather_service.dart
// OpenWeatherMap free API — key from your R26-IT-087 account

import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherData {
  final String temp, feelsLike, condition, description;
  final String humidity, wind, location, country, iconCode, weatherEmoji;

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
  // ── Your API key from OpenWeatherMap (R26-IT-087 key) ─────────────────────
  static const _apiKey = 'a0e4608dd7e2386c2a7dd5e581f5e564';
  static const _city = 'Colombo';
  static const _country = 'LK';
  static const _base = 'https://api.openweathermap.org/data/2.5/weather';

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

  WeatherData _parse(Map<String, dynamic> j) {
    final main = j['main'] as Map<String, dynamic>;
    final wind = j['wind'] as Map<String, dynamic>;
    final weather = (j['weather'] as List).first as Map<String, dynamic>;
    final sys = j['sys'] as Map<String, dynamic>;

    final tempC = (main['temp'] as num).round();
    final feelsC = (main['feels_like'] as num).round();
    final hum = (main['humidity'] as num).toInt();
    final spd = ((wind['speed'] as num) * 3.6).round();
    final icon = weather['icon'] as String;

    return WeatherData(
      temp: '$tempC°C',
      feelsLike: '$feelsC°C',
      condition: _cap(weather['main'] as String),
      description: _cap(weather['description'] as String),
      humidity: '$hum%',
      wind: '$spd km/h',
      location: j['name'] as String,
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

  String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
