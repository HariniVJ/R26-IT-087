// YOUR FILE — Member 4: Fruit Quality Grading
// lib/services/grading/tflite_service.dart
//
// Connects pomegranate_quality_model.tflite to Flutter.
// Model trained with MobileNetV2 CNN (has Rescaling(1./255) layer built in).
// Input:  [1, 224, 224, 3] — raw pixel values 0-255 (NOT normalized in Dart)
// Output: [1, 3] — softmax probabilities for 3 classes
//
// labels.txt order (from training sorted() call):
//   0 -> high_quality
//   1 -> low_quality
//   2 -> medium_quality

import 'dart:io';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import '../../models/prediction_result.dart';

class TfliteService {
  Interpreter? _interpreter;
  List<String> _labels = [];
  bool _isLoaded = false;

  bool get isLoaded => _isLoaded;

  // Load model + labels
  Future<void> loadModel() async {
    if (_isLoaded) return;

    try {
      _interpreter = await Interpreter.fromAsset(
        'assets/models/pomegranat_quality_model.tflite',
      );

      final raw = await rootBundle.loadString('assets/models/labels.txt');
      _labels = raw
          .split('\n')
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .toList();

      _isLoaded = true;
    } catch (e) {
      _isLoaded = false;
      throw Exception(
        'Failed to load TFLite model.\n'
        'Make sure these files exist and are declared in pubspec.yaml:\n'
        '  assets/models/pomegranat_quality_model.tflite\n'
        '  assets/models/labels.txt\n'
        'Error: $e',
      );
    }
  }

  // Predict quality from image file
  Future<PredictionResult> predict(File imageFile) async {
    if (!_isLoaded) await loadModel();

    // Decode image
    final bytes = await imageFile.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) throw Exception('Could not decode image file.');

    // Resize to 224x224
    final resized = img.copyResize(
      decoded,
      width: 224,
      height: 224,
      interpolation: img.Interpolation.linear,
    );

    // Build input tensor [1, 224, 224, 3]
    // Pass raw 0-255 values — model has Rescaling(1./255) built in
    final input = _buildInputTensor(resized);
    final output = List.generate(1, (_) => List.filled(_labels.length, 0.0));

    // Run inference
    _interpreter!.run(input, output);

    // Model output is already softmax probabilities
    final probs = List<double>.from(output[0] as List);

    // Find highest probability class
    int maxIdx = 0;
    double maxVal = probs[0];
    for (int i = 1; i < probs.length; i++) {
      if (probs[i] > maxVal) {
        maxVal = probs[i];
        maxIdx = i;
      }
    }

    final label = maxIdx < _labels.length ? _labels[maxIdx] : 'unknown';
    final confidence = double.parse((maxVal * 100).toStringAsFixed(2));

    return PredictionResult(
      quality: label,
      confidence: confidence,
      recommendation: _getRecommendation(label),
    );
  }

  // Get all 3 class scores for breakdown bars in result screen
  Future<Map<String, double>> getAllScores(File imageFile) async {
    if (!_isLoaded) await loadModel();

    final bytes = await imageFile.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return {};

    final resized = img.copyResize(decoded, width: 224, height: 224);
    final input = _buildInputTensor(resized);
    final output = List.generate(1, (_) => List.filled(_labels.length, 0.0));

    _interpreter!.run(input, output);

    final probs = List<double>.from(output[0] as List);
    final scores = <String, double>{};

    for (int i = 0; i < _labels.length && i < probs.length; i++) {
      scores[_labels[i]] = double.parse(probs[i].toStringAsFixed(4));
    }

    return scores;
  }

  // Build input tensor [1, 224, 224, 3] with raw 0-255 float values
  List _buildInputTensor(img.Image image) {
    return List.generate(
      1,
      (_) => List.generate(
        224,
        (y) => List.generate(224, (x) {
          final pixel = image.getPixel(x, y);
          return [pixel.r.toDouble(), pixel.g.toDouble(), pixel.b.toDouble()];
        }),
      ),
    );
  }

  // Recommendation text per quality label
  String _getRecommendation(String label) {
    switch (label) {
      case 'high_quality':
        return 'Suitable for export and premium market sale.';
      case 'medium_quality':
        return 'Suitable for juice, jam, or food processing.';
      case 'low_quality':
        return 'Suitable for compost or organic fertilizer production.';
      default:
        return 'No recommendation available.';
    }
  }

  // Cleanup
  void dispose() {
    _interpreter?.close();
    _isLoaded = false;
  }
}
