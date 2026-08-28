import 'irrigation_result.dart';

class IrrigationHistoryRecord {
  final String id;
  final DateTime createdAt;
  final double? latitude;
  final double? longitude;
  final double soilMoisture;
  final double? tempMean;
  final double? apparentTempMean;
  final double? solarRadiation;
  final double? rainMm;
  final double? rainHours;
  final double? forecastRain24h;
  final double? windSpeedMax;
  final double? et0;
  final double? weatherCode;
  final String? modelPrediction;
  final String? finalPrediction;
  final double? modelConfidence;
  final String? pumpStatus;
  final int? rainExpectedInHours;
  final double? rainProbability;
  final String status;
  final String reason;
  final String weatherSource;
  final String mode;

  const IrrigationHistoryRecord({
    required this.id,
    required this.createdAt,
    required this.soilMoisture,
    required this.status,
    required this.reason,
    required this.weatherSource,
    required this.mode,
    this.latitude,
    this.longitude,
    this.tempMean,
    this.apparentTempMean,
    this.solarRadiation,
    this.rainMm,
    this.rainHours,
    this.forecastRain24h,
    this.windSpeedMax,
    this.et0,
    this.weatherCode,
    this.modelPrediction,
    this.finalPrediction,
    this.modelConfidence,
    this.pumpStatus,
    this.rainExpectedInHours,
    this.rainProbability,
  });

  factory IrrigationHistoryRecord.fromMap(Map<String, dynamic> map) {
    return IrrigationHistoryRecord(
      id: map['id']?.toString() ?? '',
      createdAt: _parseTime(map['created_at'] ?? map['createdAt'] ?? map['predictedAt']),
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      soilMoisture: (map['soil_moisture'] as num?)?.toDouble() ??
          (map['soilMoisture'] as num?)?.toDouble() ??
          0,
      tempMean: (map['temp_mean'] as num?)?.toDouble() ??
          (map['temperature'] as num?)?.toDouble(),
      apparentTempMean: (map['apparent_temp_mean'] as num?)?.toDouble() ??
          (map['apparentTemperature'] as num?)?.toDouble(),
      solarRadiation: (map['solar_radiation'] as num?)?.toDouble() ??
          (map['solarRadiation'] as num?)?.toDouble(),
      rainMm: (map['rain_mm'] as num?)?.toDouble() ??
          (map['rainfall'] as num?)?.toDouble(),
      rainHours: (map['rain_hours'] as num?)?.toDouble() ??
          (map['rainHours'] as num?)?.toDouble(),
      forecastRain24h: (map['forecast_rain_24h'] as num?)?.toDouble() ??
          (map['forecastRainfall'] as num?)?.toDouble() ??
          (map['rainfallForecast'] as num?)?.toDouble(),
      windSpeedMax: (map['wind_speed_max'] as num?)?.toDouble() ??
          (map['windSpeedMax'] as num?)?.toDouble(),
      et0: (map['et0'] as num?)?.toDouble(),
      weatherCode: (map['weather_code'] as num?)?.toDouble() ??
          (map['weatherCode'] as num?)?.toDouble(),
      modelPrediction: (map['model_prediction'] ?? map['modelPrediction'])
          ?.toString(),
      finalPrediction: (map['final_prediction'] ??
              map['finalPrediction'] ??
              map['prediction'])
          ?.toString(),
      modelConfidence: (map['modelConfidence'] as num?)?.toDouble() ??
          (map['model_confidence'] as num?)?.toDouble(),
      pumpStatus: (map['pumpStatus'] ?? map['pump_status'])?.toString(),
      rainExpectedInHours: (map['rainExpectedInHours'] as num?)?.toInt() ??
          (map['rain_expected_in_hours'] as num?)?.toInt(),
      rainProbability: (map['rainProbability'] as num?)?.toDouble() ??
          (map['rain_probability'] as num?)?.toDouble(),
      status: map['status']?.toString() ?? 'Unknown',
      reason: map['reason']?.toString() ?? '',
      weatherSource: (map['weather_source'] ?? map['weatherSource'])
              ?.toString() ??
          'none',
      mode: map['mode']?.toString() ?? 'unknown',
    );
  }

  factory IrrigationHistoryRecord.fromFirestore(
    String id,
    Map<String, dynamic> data,
  ) {
    return IrrigationHistoryRecord.fromMap({
      'id': id,
      ...data,
      'created_at': data['createdAt'] ?? data['predictedAt'],
    });
  }

  static DateTime _parseTime(dynamic value) {
    if (value is DateTime) return value;
    if (value == null) return DateTime.now();
    try {
      return (value as dynamic).toDate() as DateTime;
    } catch (_) {
      return DateTime.tryParse(value.toString()) ?? DateTime.now();
    }
  }
}

extension IrrigationResultHistory on IrrigationResult {
  IrrigationHistoryRecord toHistoryRecord({String id = ''}) {
    return IrrigationHistoryRecord(
      id: id,
      createdAt: createdAt,
      latitude: latitude,
      longitude: longitude,
      soilMoisture: soilMoisture,
      tempMean: weatherUsed?.tempMean,
      apparentTempMean: weatherUsed?.apparentTempMean,
      solarRadiation: weatherUsed?.solarRadiation,
      rainMm: weatherUsed?.rainMm,
      rainHours: weatherUsed?.rainHours,
      forecastRain24h: weatherUsed?.forecastRain24h,
      windSpeedMax: weatherUsed?.windSpeedMax,
      et0: weatherUsed?.et0,
      weatherCode: weatherUsed?.weatherCode,
      modelPrediction: modelPrediction,
      finalPrediction: finalPrediction,
      modelConfidence: modelConfidence,
      pumpStatus: 'off',
      rainExpectedInHours: weatherUsed?.rainExpectedInHours,
      rainProbability: weatherUsed?.rainProbability,
      status: status,
      reason: reason,
      weatherSource: weatherSource,
      mode: mode,
    );
  }
}
