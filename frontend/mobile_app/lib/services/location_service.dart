import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/farm_location.dart';

/// One-shot location for weather lookup. Does not track the farmer.
class FarmLocationService {
  static const _latKey = 'last_farm_latitude';
  static const _lngKey = 'last_farm_longitude';

  Future<FarmLocation> getCurrentLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      final cached = await loadLastLocation();
      if (cached != null) {
        return FarmLocation(
          latitude: cached.latitude,
          longitude: cached.longitude,
          source: 'cached_location_services_off',
        );
      }
      throw LocationException(
        'Location services are turned off. Please enable GPS and try again.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw LocationException(
        'Location permission was denied. Weather cannot be fetched without your farm location.',
      );
    }

    if (permission == LocationPermission.deniedForever) {
      throw LocationException(
        'Location permission is permanently denied. Enable it in phone settings to use live weather.',
      );
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );

      final location = FarmLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        source: 'gps',
      );
      await _saveLastLocation(location);
      return location;
    } catch (_) {
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        return FarmLocation(
          latitude: lastKnown.latitude,
          longitude: lastKnown.longitude,
          source: 'last_known',
        );
      }

      final cached = await loadLastLocation();
      if (cached != null) return cached;

      throw LocationException(
        'Could not get your current location. Please try again outdoors.',
      );
    }
  }

  Future<FarmLocation?> loadLastLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final lat = prefs.getDouble(_latKey);
    final lng = prefs.getDouble(_lngKey);
    if (lat == null || lng == null) return null;

    return FarmLocation(
      latitude: lat,
      longitude: lng,
      source: 'cached',
    );
  }

  Future<void> _saveLastLocation(FarmLocation location) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_latKey, location.latitude);
    await prefs.setDouble(_lngKey, location.longitude);
  }
}

class LocationException implements Exception {
  final String message;
  LocationException(this.message);

  @override
  String toString() => message;
}
