import 'irrigation_weather.dart';

class IrrigationResult {
  final bool success;
  final String mode;
  final String status;
  final String reason;
  final String? modelPrediction;
  final String? finalPrediction;
  final IrrigationWeather? weatherUsed;
  final double soilMoisture;
  final double? soilTemperature;
  final double? modelConfidence;
  final double? latitude;
  final double? longitude;
  final String weatherSource;
  final DateTime createdAt;

  const IrrigationResult({
    required this.success,
    required this.mode,
    required this.status,
    required this.reason,
    required this.soilMoisture,
    required this.weatherSource,
    required this.createdAt,
    this.soilTemperature,
    this.modelConfidence,
    this.modelPrediction,
    this.finalPrediction,
    this.weatherUsed,
    this.latitude,
    this.longitude,
  });

  Map<String, dynamic> toHistoryMap() {
    return {
      'created_at': createdAt.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'soil_moisture': soilMoisture,
      'temp_mean': weatherUsed?.tempMean,
      'apparent_temp_mean': weatherUsed?.apparentTempMean,
      'solar_radiation': weatherUsed?.solarRadiation,
      'rain_mm': weatherUsed?.rainMm,
      'rain_hours': weatherUsed?.rainHours,
      'forecast_rain_24h': weatherUsed?.forecastRain24h,
      'wind_speed_max': weatherUsed?.windSpeedMax,
      'et0': weatherUsed?.et0,
      'weather_code': weatherUsed?.weatherCode,
      'model_prediction': modelPrediction,
      'final_prediction': finalPrediction,
      'status': status,
      'reason': reason,
      'weather_source': weatherSource,
      'mode': mode,
    };
  }
}
