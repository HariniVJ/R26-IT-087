import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

/// On-device irrigation model.
///
/// Input:  [1, 12] float32 features
/// Output: [1, 4]  class scores
///
/// The 12-feature order comes from the existing Python irrigation service:
/// soil_moisture, temp_mean, apparent_temp_mean, solar_radiation, rain_mm,
/// rain_hours, forecast_rain_24h, wind_speed_max, wind_gust_max, et0,
/// weather_code, daily_weather_code
///
/// Label order is the alphabetical backend class names. Confirm this against
/// the original training encoder if predictions look swapped.
class IrrigationTfliteService {
  static const modelAsset = 'assets/models/pomegranate_irrigation_model.tflite';
  static const labelsAsset = 'assets/models/irrigation_labels.txt';

  Interpreter? _interpreter;
  List<String> _labels = [];
  bool _isLoaded = false;

  bool get isLoaded => _isLoaded;
  List<String> get labels => List.unmodifiable(_labels);

  Future<void> loadModel() async {
    if (_isLoaded) return;

    _interpreter = await Interpreter.fromAsset(modelAsset);

    final raw = await rootBundle.loadString(labelsAsset);
    _labels = raw
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    _isLoaded = true;
  }

  Future<IrrigationModelOutput> predict(List<double> features) async {
    if (!_isLoaded) await loadModel();

    if (features.length != 12) {
      throw ArgumentError('Irrigation model expects 12 features.');
    }

    final input = [features];
    final output = List.generate(1, (_) => List.filled(_labels.length, 0.0));

    _interpreter!.run(input, output);

    final scores = List<double>.from(output[0]);
    var maxIdx = 0;
    var maxVal = scores[0];
    for (var i = 1; i < scores.length; i++) {
      if (scores[i] > maxVal) {
        maxVal = scores[i];
        maxIdx = i;
      }
    }

    return IrrigationModelOutput(
      label: maxIdx < _labels.length ? _labels[maxIdx] : 'UNKNOWN',
      confidence: maxVal,
      scores: scores,
    );
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _isLoaded = false;
  }
}

class IrrigationModelOutput {
  final String label;
  final double confidence;
  final List<double> scores;

  const IrrigationModelOutput({
    required this.label,
    required this.confidence,
    required this.scores,
  });
}
