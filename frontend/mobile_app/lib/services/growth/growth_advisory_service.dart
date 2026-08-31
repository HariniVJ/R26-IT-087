import '../../models/irrigation_weather.dart';
import '../../services/irrigation/irrigation_weather_service.dart';
import '../../services/irrigation/location_service.dart';
import '../../services/sensor/soil_bluetooth_service.dart';

/// On-device growth advisory. Stage classification already ran in TFLite;
/// this builds the result payload the result screen expects, without a backend.
class GrowthAdvisoryService {
  static Future<Map<String, dynamic>> getAdvisory({
    required String predictedClass,
    required double confidence,
    required Map<String, double> allProbabilities,
    required String captureDate,
    double lat = 9.7,
    double lon = 80.0,
    String? farmerId,
  }) async {
    final stage = _stageInfo[predictedClass];
    if (stage == null) {
      throw Exception('Unknown growth stage: $predictedClass');
    }

    final capturedAt = DateTime.tryParse(captureDate) ?? DateTime.now();

    IrrigationWeather? weather;
    try {
      final snapshot =
          await IrrigationWeatherService().loadForFarm(FarmLocationService());
      weather = snapshot.weather;
    } catch (_) {}

    if (weather == null) {
      try {
        weather = await IrrigationWeatherService().fetchWeather(
          latitude: lat,
          longitude: lon,
        );
      } catch (_) {}
    }

    final reading = SoilBluetoothService.instance.latestReading.value;
    final connected = SoilBluetoothService.instance.isConnected.value;
    final soilAvailable = connected && reading != null;

    final airTemp = weather?.tempMean;
    final humidity = weather?.humidity;
    final rainy = weather != null &&
        ((weather.rainMm > 0.2) ||
            (weather.rainProbability ?? 0) >= 40 ||
            weather.rainWithinTwoHours);
    final soilTemp = soilAvailable ? reading.temp : null;

    final environment = _environment(
      airTemp: airTemp,
      soilTemp: soilTemp,
      humidity: humidity,
      rainy: rainy,
    );

    final transitionMin = stage['transitionMin'] as int;
    final transitionMax = stage['transitionMax'] as int;
    final harvestMin = stage['harvestMin'] as int;
    final harvestMax = stage['harvestMax'] as int;
    final nextStage = stage['next'] as String?;
    final mature = predictedClass == 'MatureFruit';

    final start = capturedAt.add(Duration(days: transitionMin));
    final end = capturedAt.add(Duration(days: transitionMax));
    String fmt(DateTime d) =>
        '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

    final weatherCondition = weather == null
        ? 'Unavailable'
        : rainy
            ? 'Rainy'
            : environment['level'] == 'Caution'
                ? 'Needs Monitoring'
                : 'Favourable';

    return {
      'status': 'success',
      'growth_stage': {
        'detected': predictedClass,
        'display_name': stage['display'],
        'confidence_percent': double.parse((confidence * 100).toStringAsFixed(1)),
        'all_probabilities': allProbabilities,
        'model_accuracy_percent': 86.27,
      },
      'next_stage': nextStage,
      'transition_prediction': {
        'min_days': transitionMin,
        'max_days': transitionMax,
        'range': mature
            ? 'Ready for maturity assessment'
            : '$transitionMin–$transitionMax days',
        'capture_date': fmt(capturedAt),
        'estimated_start_date': fmt(mature ? capturedAt : start),
        'estimated_end_date': fmt(mature ? capturedAt : end),
        'estimated_date_range': mature
            ? 'Mature stage detected'
            : '${_pretty(start)} – ${_pretty(end)}',
        'message': mature
            ? 'Current stage is ready for maturity assessment.'
            : 'Estimated time to reach $nextStage: $transitionMin–$transitionMax days',
      },
      'harvest_prediction': {
        'estimated_days': mature ? 0 : (harvestMin + harvestMax) ~/ 2,
        'min_days': harvestMin,
        'max_days': harvestMax,
        'range': mature
            ? 'Maturity assessment now'
            : '$harvestMin–$harvestMax days',
        'message': mature
            ? 'Mature fruit stage detected. Check maturity indicators before harvesting.'
            : 'Estimated remaining time to mature stage: $harvestMin–$harvestMax days',
        'weather_adjusted': false,
        'soil_adjusted': false,
        'method': 'On-device stage-based growth timeline estimation',
      },
      'weather': {
        'available': weather != null,
        'temperature_celsius': airTemp,
        'humidity_percent': humidity,
        'precipitation_mm': weather?.rainMm,
        'weather_code': weather?.weatherCode,
        'is_rainy': rainy,
        'condition': weatherCondition,
      },
      'soil': {
        'available': soilAvailable,
        'farmer_id': farmerId,
        'reading_id': null,
        'temperature_celsius': soilTemp,
        'timestamp': soilAvailable ? DateTime.now().toIso8601String() : null,
        'source': soilAvailable ? 'live_bluetooth' : null,
        'message': soilAvailable
            ? 'Latest soil temperature from the connected IoT sensor.'
            : 'No live soil sensor reading. Connect the Bluetooth soil sensor.',
      },
      'environment': environment,
      'recommendations': {
        'care_tip': stage['careTip'],
        'care_action': stage['careAction'],
        'risk_warning': stage['riskWarning'],
      },
    };
  }

  static String _pretty(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  static Map<String, String> _environment({
    required double? airTemp,
    required double? soilTemp,
    required double? humidity,
    required bool rainy,
  }) {
    bool inRange(double? t) => t != null && t >= 23 && t <= 30;

    if (rainy) {
      return {
        'level': 'Caution',
        'status': 'Rain or high rain chance',
        'reason': 'Current weather indicates rain. Extra care is needed.',
        'farmer_message':
            'Monitor the crop closely. Avoid extra irrigation if rain is expected.',
        'harvest_impact':
            'The estimated growth-stage date range remains unchanged.',
      };
    }

    if (inRange(airTemp) && inRange(soilTemp)) {
      return {
        'level': 'Favourable',
        'status': 'Normal development conditions',
        'reason':
            'Air and soil temperatures are within the 23–30°C reference range.',
        'farmer_message':
            'Current conditions are suitable. Continue regular crop care.',
        'harvest_impact':
            'Environmental conditions do not change the estimated date range.',
      };
    }

    if (airTemp != null && soilTemp == null) {
      return {
        'level': 'Unknown',
        'status': 'Soil sensor data unavailable',
        'reason':
            'Air temperature is ${airTemp.toStringAsFixed(1)}°C. No live soil reading.',
        'farmer_message':
            'Connect the soil sensor for a complete environmental assessment.',
        'harvest_impact':
            'The estimated growth-stage date range remains unchanged.',
      };
    }

    return {
      'level': 'Unknown',
      'status': 'Limited environment data',
      'reason': 'Weather or soil data is incomplete for a full assessment.',
      'farmer_message':
          'Continue normal plant monitoring and connect the soil sensor if possible.',
      'harvest_impact':
          'The estimated growth-stage date range remains unchanged.',
    };
  }
}

const _stageInfo = {
  'Bud': {
    'display': 'Bud Stage',
    'next': 'Flower',
    'transitionMin': 5,
    'transitionMax': 15,
    'harvestMin': 101,
    'harvestMax': 158,
    'careTip':
        'Maintain steady soil moisture during dry periods, but avoid keeping the root zone waterlogged. Provide good sunlight and an open canopy.',
    'careAction':
        'Inspect buds and tender shoots regularly for insects, discoloration, or drying. Maintain drainage and remove seriously affected material.',
    'riskWarning':
        'Rainy or humid weather may increase bud rot. Too little water weakens buds; waterlogged soil damages roots.',
  },
  'Flower': {
    'display': 'Flower Stage',
    'next': 'EarlyFruit',
    'transitionMin': 21,
    'transitionMax': 28,
    'harvestMin': 96,
    'harvestMax': 143,
    'careTip':
        'Maintain moderate, consistent soil moisture during flowering. Provide sunlight and airflow.',
    'careAction':
        'Inspect flowers for pests, disease, drying, and abnormal drop. Avoid unnecessary overhead watering.',
    'riskWarning':
        'Heavy rain may damage flowers. High humidity increases fungal risk.',
  },
  'EarlyFruit': {
    'display': 'Early Fruit Stage',
    'next': 'MidGrowth',
    'transitionMin': 15,
    'transitionMax': 45,
    'harvestMin': 75,
    'harvestMax': 115,
    'careTip':
        'Keep soil moisture steady while young fruits develop. Avoid dry-then-flood watering.',
    'careAction':
        'Inspect young fruits for insect holes, spots, or damage. Remove badly damaged fruits.',
    'riskWarning':
        'Fruit borers may damage developing fruits. Irregular watering increases cracking risk.',
  },
  'MidGrowth': {
    'display': 'Mid-Growth Stage',
    'next': 'MatureFruit',
    'transitionMin': 60,
    'transitionMax': 70,
    'harvestMin': 60,
    'harvestMax': 70,
    'careTip':
        'Maintain consistent moisture, drainage, and airflow as fruit develops.',
    'careAction':
        'Inspect fruits for cracking, rot, spots, or insect damage. Avoid sudden moisture changes.',
    'riskWarning':
        'Sudden moisture changes or heavy rain may increase cracking and disease risk.',
  },
  'MatureFruit': {
    'display': 'Mature Fruit Stage',
    'next': null,
    'transitionMin': 0,
    'transitionMax': 0,
    'harvestMin': 0,
    'harvestMax': 0,
    'careTip':
        'Check the fruit carefully for suitable maturity before harvesting.',
    'careAction':
        'Harvest with pruning shears. Cut the stalk rather than pulling the fruit.',
    'riskWarning':
        'Over-mature fruits may crack or lose quality. Heavy rain increases cracking risk.',
  },
};
