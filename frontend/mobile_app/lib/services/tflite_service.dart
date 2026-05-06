// YOUR FILE — Member 4: Fruit Quality Grading
// lib/services/tflite_service.dart
//
// Fixes applied to your original code:
//   1. Pixel values normalized to 0.0–1.0  (your code passed 0–255 raw)
//   2. labels.txt path fixed               (your code used wrong path)
//   3. Softmax applied before argmax       (model outputs raw logits)
//   4. All_scores map added                (for score breakdown bars in UI)
//   5. isLoaded guard added                (prevents crash if model fails)
//   6. close() renamed to dispose()        (consistent with Flutter pattern)

import 'dart:io';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import '../models/prediction_result.dart';

class TfliteService {
  // ── Private state ──────────────────────────────────────────────────────────
  Interpreter? _interpreter;
  List<String> _labels = [];
  bool _isLoaded = false;

  bool get isLoaded => _isLoaded;

  // ── Load model + labels ────────────────────────────────────────────────────
  Future<void> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset(
        'assets/models/pomegranate_quality_model.tflite',
      );

      // FIX: correct path is assets/models/labels.txt not assets/labels.txt
      final labelsData = await rootBundle.loadString('assets/models/labels.txt');
      _labels = labelsData
          .split('\n')
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .toList();

      _isLoaded = true;
    } catch (e) {
      _isLoaded = false;
      throw Exception(
        'Failed to load model.\n'
        'Check that these files exist in your project:\n'
        '  • assets/models/pomegranate_quality_model.tflite\n'
        '  • assets/models/labels.txt\n'
        'And are declared in pubspec.yaml under flutter > assets.\n'
        'Original error: $e',
      );
    }
  }

  // ── Predict ────────────────────────────────────────────────────────────────
  Future<PredictionResult> predict(File imageFile) async {
    // Guard: load model if not already loaded
    if (!_isLoaded || _interpreter == null) {
      await loadModel();
    }

    // ── Step 1: Decode image ─────────────────────────────────────────────────
    final bytes         = await imageFile.readAsBytes();
    final originalImage = img.decodeImage(bytes);
    if (originalImage == null) throw Exception('Could not decode image.');

    // ── Step 2: Resize to 224×224 ────────────────────────────────────────────
    final resizedImage = img.copyResize(
      originalImage,
      width: 224,
      height: 224,
      interpolation: img.Interpolation.linear,
    );

    // ── Step 3: Build input tensor [1, 224, 224, 3] ──────────────────────────
    // FIX: divide by 255.0 to normalize to [0.0, 1.0]
    // Your original code passed raw pixel values (0–255) which causes
    // incorrect predictions because the model was trained on normalized data.
    final input = List.generate(
      1,
      (_) => List.generate(
        224,
        (y) => List.generate(
          224,
          (x) {
            final pixel = resizedImage.getPixel(x, y);
            return [
              pixel.r / 255.0,   // ← FIX: was pixel.r.toDouble()
              pixel.g / 255.0,   // ← FIX: was pixel.g.toDouble()
              pixel.b / 255.0,   // ← FIX: was pixel.b.toDouble()
            ];
          },
        ),
      ),
    );

    // ── Step 4: Output tensor [1, 3] ─────────────────────────────────────────
    final output = List.generate(1, (_) => List.filled(3, 0.0));

    // ── Step 5: Run inference ─────────────────────────────────────────────────
    _interpreter!.run(input, output);

    // ── Step 6: Parse scores ──────────────────────────────────────────────────
    final rawScores = List<double>.from(output[0]);

    // FIX: Apply softmax to convert raw logits → probabilities (0.0–1.0)
    // Your original code used raw logits directly for confidence percentage
    // which gives values > 100% or negative values for some models.
    final probabilities = _softmax(rawScores);

    // ── Step 7: Find best class ───────────────────────────────────────────────
    int maxIndex  = 0;
    double maxVal = probabilities[0];
    for (int i = 1; i < probabilities.length; i++) {
      if (probabilities[i] > maxVal) {
        maxVal   = probabilities[i];
        maxIndex = i;
      }
    }

    final label      = maxIndex < _labels.length ? _labels[maxIndex] : 'unknown';
    final confidence = maxVal * 100;   // convert to percentage for display

    return PredictionResult(
      quality:        label,
      confidence:     double.parse(confidence.toStringAsFixed(2)),
      recommendation: _getRecommendation(label),
    );
  }

  // ── All scores (for score breakdown bars in result screen) ────────────────
  /// Returns a map of label → probability (0.0–1.0) for all 3 classes.
  Future<Map<String, double>> getAllScores(File imageFile) async {
    if (!_isLoaded || _interpreter == null) await loadModel();

    final bytes         = await imageFile.readAsBytes();
    final originalImage = img.decodeImage(bytes);
    if (originalImage == null) return {};

    final resized = img.copyResize(originalImage, width: 224, height: 224);

    final input = List.generate(1, (_) =>
      List.generate(224, (y) =>
        List.generate(224, (x) {
          final p = resized.getPixel(x, y);
          return [p.r / 255.0, p.g / 255.0, p.b / 255.0];
        }),
      ),
    );

    final output = List.generate(1, (_) => List.filled(3, 0.0));
    _interpreter!.run(input, output);

    final probs = _softmax(List<double>.from(output[0]));
    final result = <String, double>{};
    for (int i = 0; i < _labels.length && i < probs.length; i++) {
      result[_labels[i]] = double.parse(probs[i].toStringAsFixed(4));
    }
    return result;
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  /// Softmax: converts raw logits → probabilities that sum to 1.0
  List<double> _softmax(List<double> logits) {
    if (logits.isEmpty) return [];
    final maxVal = logits.reduce((a, b) => a > b ? a : b);
    final exps   = logits.map((v) => _safeExp(v - maxVal)).toList();
    final sum    = exps.fold(0.0, (a, b) => a + b);
    if (sum == 0) return List.filled(logits.length, 1.0 / logits.length);
    return exps.map((e) => e / sum).toList();
  }

  double _safeExp(double x) {
    if (x < -88) return 0.0;
    if (x >  88) return double.maxFinite;
    return x == 0 ? 1.0 : _expApprox(x);
  }

  double _expApprox(double x) {
    double result = 1.0, term = 1.0;
    for (int i = 1; i <= 15; i++) {
      term   *= x / i;
      result += term;
      if (term.abs() < 1e-12) break;
    }
    return result < 0 ? 0 : result;
  }

  String _getRecommendation(String label) {
    switch (label) {
      case 'high_quality':
        return '✅ Suitable for export and premium market sale.';
      case 'medium_quality':
        return '🧃 Suitable for juice, jam, or food processing.';
      case 'low_quality':
        return '🌱 Suitable for compost or organic fertilizer production.';
      default:
        return '⚠️ No recommendation available.';
    }
  }

  // ── Cleanup ────────────────────────────────────────────────────────────────
  void dispose() {
    _interpreter?.close();
    _isLoaded = false;
  }
}