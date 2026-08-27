import '../models/irrigation_result.dart';
import '../models/irrigation_weather.dart';
import 'irrigation_tflite_service.dart';

/// Combines TFLite inference with the existing backend safety rules.
/// The model always runs on the phone. Weather is optional.
class IrrigationPredictionService {
  IrrigationPredictionService({IrrigationTfliteService? modelService})
      : _modelService = modelService ?? IrrigationTfliteService();

  final IrrigationTfliteService _modelService;

  Future<IrrigationResult> predict({
    required double soilMoisture,
    IrrigationWeather? weather,
    double? latitude,
    double? longitude,
  }) async {
    final now = DateTime.now();

    if (soilMoisture <= 0 || soilMoisture > 100) {
      return IrrigationResult(
        success: false,
        mode: 'invalid',
        status: 'Cannot Predict',
        reason: 'Invalid soil moisture reading. Please check the sensor.',
        soilMoisture: soilMoisture,
        weatherSource: 'none',
        createdAt: now,
        latitude: latitude,
        longitude: longitude,
      );
    }

    if (weather == null) {
      return _soilOnlyDecision(
        soilMoisture: soilMoisture,
        latitude: latitude,
        longitude: longitude,
        createdAt: now,
      );
    }

    final errors = _validateInput(soilMoisture, weather);
    if (errors.isNotEmpty) {
      return IrrigationResult(
        success: false,
        mode: weather.isCached ? 'cached_weather' : 'live_weather',
        status: 'Cannot Predict',
        reason: errors.join(' '),
        soilMoisture: soilMoisture,
        weatherUsed: weather,
        weatherSource: weather.isCached ? 'cached' : 'live',
        createdAt: now,
        latitude: latitude,
        longitude: longitude,
      );
    }

    try {
      await _modelService.loadModel();
      final modelOutput =
          await _modelService.predict(weather.toModelFeatures(soilMoisture));

      final finalPrediction = _applySafetyRules(
        modelPrediction: modelOutput.label,
        soilMoisture: soilMoisture,
        forecastRain24h: weather.forecastRain24h,
      );
      final message = _farmerMessage(finalPrediction);

      return IrrigationResult(
        success: true,
        mode: weather.isCached ? 'cached_weather' : 'live_weather',
        status: message.$1,
        reason: message.$2,
        modelPrediction: modelOutput.label,
        finalPrediction: finalPrediction,
        soilMoisture: soilMoisture,
        weatherUsed: weather,
        weatherSource: weather.isCached ? 'cached' : 'live',
        createdAt: now,
        latitude: latitude,
        longitude: longitude,
      );
    } catch (e) {
      return _soilOnlyDecision(
        soilMoisture: soilMoisture,
        latitude: latitude,
        longitude: longitude,
        createdAt: now,
        extraReason: 'On-device model could not run ($e). Using soil moisture only.',
      );
    }
  }

  IrrigationResult _soilOnlyDecision({
    required double soilMoisture,
    required DateTime createdAt,
    double? latitude,
    double? longitude,
    String? extraReason,
  }) {
    late final String prediction;
    late final String status;
    late final String reason;

    if (soilMoisture >= 70) {
      prediction = 'SKIP_SOIL_ALREADY_WET';
      status = 'Not Suitable Now';
      reason = 'Soil is already wet. Fresh weather forecast is unavailable.';
    } else if (soilMoisture < 45) {
      prediction = 'SUITABLE_BASED_ON_SOIL';
      status = 'Suitable Based on Soil';
      reason =
          'Soil moisture is low. Fresh weather forecast is unavailable in offline mode.';
    } else {
      prediction = 'NO_URGENT_IRRIGATION';
      status = 'No Urgent Irrigation Needed';
      reason =
          'Soil moisture is moderate. Fresh weather forecast is unavailable.';
    }

    return IrrigationResult(
      success: true,
      mode: 'soil_only',
      status: status,
      reason: extraReason == null ? reason : '$reason $extraReason',
      finalPrediction: prediction,
      soilMoisture: soilMoisture,
      weatherSource: 'none',
      createdAt: createdAt,
      latitude: latitude,
      longitude: longitude,
    );
  }

  List<String> _validateInput(double soilMoisture, IrrigationWeather weather) {
    final errors = <String>[];
    if (!(soilMoisture >= 5 && soilMoisture <= 95)) {
      errors.add('Invalid soil moisture value. Please check the soil sensor.');
    }
    if (!(weather.tempMean >= 15 && weather.tempMean <= 45)) {
      errors.add('Invalid temperature value from weather data.');
    }
    if (!(weather.apparentTempMean >= 15 && weather.apparentTempMean <= 55)) {
      errors.add('Invalid apparent temperature value from weather data.');
    }
    if (!(weather.solarRadiation >= 0 && weather.solarRadiation <= 40)) {
      errors.add('Invalid solar radiation value.');
    }
    if (weather.rainMm < 0) errors.add('Rainfall cannot be negative.');
    if (!(weather.rainHours >= 0 && weather.rainHours <= 24)) {
      errors.add('Rain hours must be between 0 and 24.');
    }
    if (weather.forecastRain24h < 0) {
      errors.add('Forecast rainfall cannot be negative.');
    }
    if (weather.windSpeedMax < 0) errors.add('Wind speed cannot be negative.');
    if (weather.windGustMax < 0) errors.add('Wind gust cannot be negative.');
    if (weather.et0 < 0) errors.add('ET0 cannot be negative.');
    if (!(weather.weatherCode >= 0 && weather.weatherCode <= 99)) {
      errors.add('Invalid weather code.');
    }
    return errors;
  }

  String _applySafetyRules({
    required String modelPrediction,
    required double soilMoisture,
    required double forecastRain24h,
  }) {
    if (soilMoisture >= 70) return 'SKIP_SOIL_ALREADY_WET';
    if (forecastRain24h >= 2.0) return 'SKIP_RAIN_EXPECTED';
    return modelPrediction;
  }

  (String, String) _farmerMessage(String prediction) {
    switch (prediction) {
      case 'SUITABLE_TO_IRRIGATE':
      case 'SUITABLE_BASED_ON_SOIL':
        return (
          prediction == 'SUITABLE_BASED_ON_SOIL'
              ? 'Suitable Based on Soil'
              : 'Suitable Now',
          prediction == 'SUITABLE_BASED_ON_SOIL'
              ? 'Soil moisture is low. Weather forecast is unavailable in offline mode.'
              : 'Soil moisture is low and no rainfall forecast detected.',
        );
      case 'SKIP_RAIN_EXPECTED':
        return (
          'Not Suitable Now',
          'Rainfall is expected, so irrigation can be skipped.',
        );
      case 'SKIP_SOIL_ALREADY_WET':
        return ('Not Suitable Now', 'Soil is already wet.');
      case 'NO_URGENT_IRRIGATION':
        return ('No Urgent Irrigation Needed', 'Soil moisture is moderate.');
      default:
        return ('Unknown', 'Unable to generate irrigation advice.');
    }
  }
}
