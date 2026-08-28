
class IrrigationWeather {
  final double tempMean;
  final double apparentTempMean;
  final double solarRadiation;
  final double rainMm;
  final double rainHours;
  final double forecastRain24h;
  final double windSpeedMax;
  final double windGustMax;
  final double et0;
  final double weatherCode;
  final double dailyWeatherCode;
  final double? humidity;
  final double? rainProbability;
  final int? rainExpectedInHours;
  final String? conditionLabel;
  final DateTime fetchedAt;
  final bool isCached;

  const IrrigationWeather({
    required this.tempMean,
    required this.apparentTempMean,
    required this.solarRadiation,
    required this.rainMm,
    required this.rainHours,
    required this.forecastRain24h,
    required this.windSpeedMax,
    required this.windGustMax,
    required this.et0,
    required this.weatherCode,
    required this.dailyWeatherCode,
    required this.fetchedAt,
    this.humidity,
    this.rainProbability,
    this.rainExpectedInHours,
    this.conditionLabel,
    this.isCached = false,
  });

  bool get rainWithinTwoHours =>
      rainExpectedInHours != null &&
      rainExpectedInHours! >= 0 &&
      rainExpectedInHours! <= 2;

  IrrigationWeather copyWith({bool? isCached}) {
    return IrrigationWeather(
      tempMean: tempMean,
      apparentTempMean: apparentTempMean,
      solarRadiation: solarRadiation,
      rainMm: rainMm,
      rainHours: rainHours,
      forecastRain24h: forecastRain24h,
      windSpeedMax: windSpeedMax,
      windGustMax: windGustMax,
      et0: et0,
      weatherCode: weatherCode,
      dailyWeatherCode: dailyWeatherCode,
      humidity: humidity,
      rainProbability: rainProbability,
      rainExpectedInHours: rainExpectedInHours,
      conditionLabel: conditionLabel,
      fetchedAt: fetchedAt,
      isCached: isCached ?? this.isCached,
    );
  }

  /// Feature order matches `soil_moisture` + weather dict insertion order
  /// from `backend/app/services/irrigation_service.py`.
  List<double> toModelFeatures(double soilMoisture) {
    return [
      soilMoisture,
      tempMean,
      apparentTempMean,
      solarRadiation,
      rainMm,
      rainHours,
      forecastRain24h,
      windSpeedMax,
      windGustMax,
      et0,
      weatherCode,
      dailyWeatherCode,
    ];
  }

  Map<String, dynamic> toJson() {
    return {
      'temp_mean': tempMean,
      'apparent_temp_mean': apparentTempMean,
      'solar_radiation': solarRadiation,
      'rain_mm': rainMm,
      'rain_hours': rainHours,
      'forecast_rain_24h': forecastRain24h,
      'wind_speed_max': windSpeedMax,
      'wind_gust_max': windGustMax,
      'et0': et0,
      'weather_code': weatherCode,
      'daily_weather_code': dailyWeatherCode,
      'humidity': humidity,
      'rain_probability': rainProbability,
      'rain_expected_in_hours': rainExpectedInHours,
      'condition_label': conditionLabel,
      'fetched_at': fetchedAt.toIso8601String(),
      'is_cached': isCached,
    };
  }

  factory IrrigationWeather.fromJson(Map<String, dynamic> json) {
    return IrrigationWeather(
      tempMean: (json['temp_mean'] as num).toDouble(),
      apparentTempMean: (json['apparent_temp_mean'] as num).toDouble(),
      solarRadiation: (json['solar_radiation'] as num).toDouble(),
      rainMm: (json['rain_mm'] as num).toDouble(),
      rainHours: (json['rain_hours'] as num).toDouble(),
      forecastRain24h: (json['forecast_rain_24h'] as num).toDouble(),
      windSpeedMax: (json['wind_speed_max'] as num).toDouble(),
      windGustMax: (json['wind_gust_max'] as num).toDouble(),
      et0: (json['et0'] as num).toDouble(),
      weatherCode: (json['weather_code'] as num).toDouble(),
      dailyWeatherCode: (json['daily_weather_code'] as num).toDouble(),
      humidity: (json['humidity'] as num?)?.toDouble(),
      rainProbability: (json['rain_probability'] as num?)?.toDouble(),
      rainExpectedInHours: (json['rain_expected_in_hours'] as num?)?.toInt(),
      conditionLabel: json['condition_label']?.toString(),
      fetchedAt: DateTime.tryParse(json['fetched_at']?.toString() ?? '') ??
          DateTime.now(),
      isCached: json['is_cached'] == true,
    );
  }
}
