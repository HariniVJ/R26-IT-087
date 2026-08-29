import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class FertilizerTfliteService {
  static const modelAsset = 'assets/models/fertilizert.tflite';
  static const labelsAsset = 'assets/models/fertilizer_labels.txt';

  Interpreter? _interpreter;
  List<String> _labels = [];
  bool _isLoaded = false;

  bool get isLoaded => _isLoaded;

  Future<void> loadModel() async {
    if (_isLoaded) return;

    _interpreter = await Interpreter.fromAsset(modelAsset);

    final raw = await rootBundle.loadString(labelsAsset);
    _labels = raw
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    if (_labels.isEmpty) {
      _labels = ['LOW', 'MEDIUM', 'HIGH'];
    }

    _isLoaded = true;
  }

  Future<FertilizerModelOutput> predict(List<double> features) async {
    if (!_isLoaded) await loadModel();

    if (features.length != 7) {
      throw ArgumentError('Fertilizer model expects 7 features.');
    }

    final input = [features];
    final classCount = _labels.isEmpty ? 3 : _labels.length;
    final output = List.generate(1, (_) => List.filled(classCount, 0.0));

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

    return FertilizerModelOutput(
      label: maxIdx < _labels.length ? _labels[maxIdx] : 'MEDIUM',
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

class FertilizerModelOutput {
  final String label;
  final double confidence;
  final List<double> scores;

  const FertilizerModelOutput({
    required this.label,
    required this.confidence,
    required this.scores,
  });
}
