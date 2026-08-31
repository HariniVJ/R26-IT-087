import 'dart:io';

import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class MlLabels {
  MlLabels._();
  static const diseaseClasses = [
    'Alternaria',
    'Anthracnose',
    'Bacterial_Blight',
    'Cercospora',
    'Healthy',
  ];
}

class MlConfig {
  MlConfig._();
  static const classifierInputSize = 224;

  static const classifierAssetPath =
      'assets/models/pomegranate_disease_classifier.tflite';

  // NOTE: Segmentation model (pomegranate_severity_seg_v2.tflite) has
  // been removed from this service. Severity is currently estimated
  // using a color heuristic below — TEMPORARY, until a validated
  // segmentation model is reintroduced.
}

class MlResult {
  final String label;
  final double confidence;
  MlResult(this.label, this.confidence);
}

class SeverityResult {
  final double percentage;
  final String level;
  SeverityResult(this.percentage, this.level);
}

// ═══════════════════════════════════════════════════════════════════
// TEMPORARY color-heuristic severity estimation.
// No TFLite segmentation model involved — analyzes pixel color/
// brightness to roughly estimate how much of the fruit surface looks
// dark/decayed/discolored. Replace with a proper segmentation-based
// calculation once a validated model is available.
// ═══════════════════════════════════════════════════════════════════

double _colorHeuristicSeverity(img.Image image) {
  int abnormalPixels = 0;
  int totalPixels = 0;

  for (int y = 0; y < image.height; y += 2) {
    for (int x = 0; x < image.width; x += 2) {
      final p = image.getPixel(x, y);
      final r = p.r, g = p.g, b = p.b;
      final brightness = (r + g + b) / 3;

      // Dark / decayed-looking pixels.
      final isDark = brightness < 60;

      // Brownish / rot-colored pixels.
      final isBrown =
          r > 60 && r < 160 && g > 30 && g < 120 && b < 80 && r > g && g >= b;

      if (isDark || isBrown) abnormalPixels++;
      totalPixels++;
    }
  }

  if (totalPixels == 0) return 0.0;
  final pct = (abnormalPixels / totalPixels) * 100;
  return double.parse(pct.clamp(0, 100).toStringAsFixed(2));
}

String _levelFromPercentage(double percentage) {
  if (percentage <= 38) return 'Mild';
  if (percentage <= 58) return 'Moderate';
  return 'Severe';
}

// ═══════════════════════════════════════════════════════════════════
// Main service class
// ═══════════════════════════════════════════════════════════════════

class ModelInferenceService {
  ModelInferenceService._();
  static final ModelInferenceService instance = ModelInferenceService._();

  Interpreter? _classifier;

  bool get isLoaded => _classifier != null;

  Future<void> loadModels() async {
    if (isLoaded) return;

    try {
      _classifier = await Interpreter.fromAsset(MlConfig.classifierAssetPath);
      _debugPrintShapes('classifier', _classifier!);
    } catch (e) {
      throw Exception(
        'Failed to load disease classifier model. Check that '
        '${MlConfig.classifierAssetPath} exists and is a valid TFLite '
        'file.\nOriginal error: $e',
      );
    }
    // Segmentation model loading removed — severity no longer depends
    // on a second TFLite model.
  }

  void _debugPrintShapes(String name, Interpreter interp) {
    // ignore: avoid_print
    print(
      '[$name] input=${interp.getInputTensor(0).shape} '
      'output0=${interp.getOutputTensor(0).shape}',
    );
  }

  List<List<List<double>>> _preprocessScaled(File file, int size) {
    final bytes = file.readAsBytesSync();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) throw Exception('Could not decode image.');

    final resized = img.copyResize(
      decoded,
      width: size,
      height: size,
      interpolation: img.Interpolation.average,
    );

    return List.generate(size, (y) {
      return List.generate(size, (x) {
        final p = resized.getPixel(x, y);
        return [p.r / 255.0, p.g / 255.0, p.b / 255.0];
      });
    });
  }

  int _argmax(List<double> scores) {
    int best = 0;
    for (int i = 1; i < scores.length; i++) {
      if (scores[i] > scores[best]) best = i;
    }
    return best;
  }

  Future<MlResult> classifyDisease(File imageFile) async {
    await loadModels();

    final size = MlConfig.classifierInputSize;
    final input = [_preprocessScaled(imageFile, size)];

    final numClasses = MlLabels.diseaseClasses.length;
    final output = List.generate(1, (_) => List.filled(numClasses, 0.0));

    _classifier!.run(input, output);

    final scores = output[0];
    final idx = _argmax(scores);
    return MlResult(MlLabels.diseaseClasses[idx], scores[idx]);
  }

  /// TEMPORARY severity calculation — color heuristic only, no
  /// segmentation model involved. Kept synchronous-ish (just wrapped in
  /// Future for API compatibility with the rest of the app) so
  /// disease_service.dart and callers don't need any changes.
  Future<SeverityResult> analyzeSeverity(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final decoded = img.decodeImage(bytes);

    if (decoded == null) {
      // ignore: avoid_print
      print('⚠️ Could not decode image for severity — defaulting to 0%/N/A');
      return SeverityResult(0.0, 'N/A');
    }

    final pct = _colorHeuristicSeverity(decoded);
    final level = _levelFromPercentage(pct);

    // ignore: avoid_print
    print('🔍 Severity (color heuristic): ${pct.toStringAsFixed(1)}% ($level)');

    return SeverityResult(pct, level);
  }

  void dispose() {
    _classifier?.close();
    _classifier = null;
  }
}
