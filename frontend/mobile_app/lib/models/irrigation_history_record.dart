class IrrigationHistoryRecord {
  final int id;
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
  });

  factory IrrigationHistoryRecord.fromMap(Map<String, dynamic> map) {
    return IrrigationHistoryRecord(
      id: map['id'] as int,
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ??
          DateTime.now(),
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      soilMoisture: (map['soil_moisture'] as num?)?.toDouble() ?? 0,
      tempMean: (map['temp_mean'] as num?)?.toDouble(),
      apparentTempMean: (map['apparent_temp_mean'] as num?)?.toDouble(),
      solarRadiation: (map['solar_radiation'] as num?)?.toDouble(),
      rainMm: (map['rain_mm'] as num?)?.toDouble(),
      rainHours: (map['rain_hours'] as num?)?.toDouble(),
      forecastRain24h: (map['forecast_rain_24h'] as num?)?.toDouble(),
      windSpeedMax: (map['wind_speed_max'] as num?)?.toDouble(),
      et0: (map['et0'] as num?)?.toDouble(),
      weatherCode: (map['weather_code'] as num?)?.toDouble(),
      modelPrediction: map['model_prediction']?.toString(),
      finalPrediction: map['final_prediction']?.toString(),
      status: map['status']?.toString() ?? 'Unknown',
      reason: map['reason']?.toString() ?? '',
      weatherSource: map['weather_source']?.toString() ?? 'none',
      mode: map['mode']?.toString() ?? 'unknown',
    );
  }
}
