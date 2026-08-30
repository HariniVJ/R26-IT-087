import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Turns GPS coordinates into a city/town name for weather and irrigation.
class PlaceNameService {
  static const _nameKey = 'last_place_name';
  static const _latKey = 'last_place_lat';
  static const _lngKey = 'last_place_lng';

  Future<String> resolve(double latitude, double longitude) async {
    final cached = await _cachedNear(latitude, longitude);
    if (cached != null) return cached;

    final name = await _fromBigDataCloud(latitude, longitude) ??
        await _fromNominatim(latitude, longitude);
    if (name != null && name.isNotEmpty) {
      await _save(latitude, longitude, name);
      return name;
    }
    return 'Current location';
  }

  Future<String?> _cachedNear(double lat, double lng) async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(_nameKey);
    final savedLat = prefs.getDouble(_latKey);
    final savedLng = prefs.getDouble(_lngKey);
    if (name == null || savedLat == null || savedLng == null) return null;
    if ((lat - savedLat).abs() < 0.01 && (lng - savedLng).abs() < 0.01) {
      return name;
    }
    return null;
  }

  Future<void> _save(double lat, double lng, String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nameKey, name);
    await prefs.setDouble(_latKey, lat);
    await prefs.setDouble(_lngKey, lng);
  }

  Future<String?> _fromBigDataCloud(double lat, double lng) async {
    try {
      final uri = Uri.parse(
        'https://api.bigdatacloud.net/data/reverse-geocode-client',
      ).replace(
        queryParameters: {
          'latitude': lat.toString(),
          'longitude': lng.toString(),
          'localityLanguage': 'en',
        },
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 6));
      if (response.statusCode != 200) return null;
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return _label(
        city: json['city']?.toString(),
        locality: json['locality']?.toString(),
        countryCode: json['countryCode']?.toString(),
      );
    } catch (_) {
      return null;
    }
  }

  Future<String?> _fromNominatim(double lat, double lng) async {
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse',
      ).replace(
        queryParameters: {
          'lat': lat.toString(),
          'lon': lng.toString(),
          'format': 'json',
          'addressdetails': '1',
          'accept-language': 'en',
        },
      );
      final response = await http.get(
        uri,
        headers: const {'User-Agent': 'PomCare/1.0 (research irrigation weather)'},
      ).timeout(const Duration(seconds: 6));
      if (response.statusCode != 200) return null;
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final address = json['address'] as Map<String, dynamic>? ?? {};
      return _label(
        city: address['city']?.toString() ??
            address['town']?.toString() ??
            address['village']?.toString() ??
            address['municipality']?.toString(),
        locality: address['suburb']?.toString() ?? address['county']?.toString(),
        countryCode: address['country_code']?.toString(),
      );
    } catch (_) {
      return null;
    }
  }

  String? _label({String? city, String? locality, String? countryCode}) {
    final place = (city != null && city.trim().isNotEmpty)
        ? city.trim()
        : locality?.trim();
    if (place == null || place.isEmpty) return null;
    final code = countryCode?.trim().toUpperCase();
    if (code == null || code.isEmpty) return place;
    return '$place, $code';
  }
}
