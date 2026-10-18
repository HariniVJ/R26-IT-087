import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

import '../../../config/disease_ml_config.dart';
import 'fruit_segmentation_service.dart';
import 'image_utils.dart';
import 'tflite_helper.dart';

/// Kept for backward compatibility — values now come from disease_ml_config.dart.
class MlLabels {
  MlLabels._();
  static const diseaseClasses = DiseaseLabels.diseaseClasses;
  static const segClasses = DiseaseLabels.segClasses;
}

/// Kept for backward compatibility — edit disease_ml_config.dart instead.
class MlConfig {
  MlConfig._();
  static const classifierInputSize = DiseaseImageConfig.cnnInputSize;
  static const classifierAssetPath = DiseaseModels.classifier;
  static const segmentationAssetPath = DiseaseModels.segmenter;
  static const segConfThreshold = DiseaseThresholds.segConfidence;
  static const segIouThreshold = DiseaseThresholds.segIou;
}

class MlResult {
  final String label;
  final double confidence; // 0..1

  /// Second most likely disease (for the "uncertain" rule and the UI).
  final String secondLabel;
  final double secondConfidence; // 0..1
  final List<double> scores;

  MlResult(
    this.label,
    this.confidence, {
    this.secondLabel = '',
    this.secondConfidence = 0.0,
    this.scores = const [],
  });
}

class SeverityResult {
  final double percentage;
  final String level;
  SeverityResult(this.percentage, this.level);
}

/// Model 2 (disease classifier) + severity access.
class ModelInferenceService {
  ModelInferenceService._();
  static final ModelInferenceService instance = ModelInferenceService._();

  Interpreter? _classifier;
  bool get isLoaded => _classifier != null;

  Future<void> loadModels() async {
    _classifier ??= await TfliteHelper.load(DiseaseModels.classifier, 'classifier');
  }

  /// Classifies the gray-background fruit crop (same input as Colab).
  /// The model already contains temperature scaling + softmax.
  Future<MlResult> classifyCrop(img.Image crop) async {
    await loadModels();
    final labels = DiseaseLabels.diseaseClasses;
    final modelClasses = _classifier!.getOutputTensor(0).shape.last;
    if (modelClasses != labels.length) {
      throw Exception('Disease model outputs $modelClasses classes but '
          'DiseaseLabels.diseaseClasses has ${labels.length} labels.');
    }

    final input = ImageUtils.toInput01(crop, DiseaseImageConfig.cnnInputSize);
    final output = List.generate(1, (_) => List.filled(labels.length, 0.0));
    _classifier!.run(input, output);

    final scores = List<double>.from(output[0]);
    final order = List<int>.generate(scores.length, (i) => i)
      ..sort((a, b) => scores[b].compareTo(scores[a]));

    debugPrint('🔍 Disease scores: ${[
      for (var i = 0; i < labels.length; i++) '${labels[i]}=${scores[i].toStringAsFixed(3)}'
    ].join(', ')}');

    return MlResult(
      labels[order[0]],
      scores[order[0]],
      secondLabel: labels[order[1]],
      secondConfidence: scores[order[1]],
      scores: scores,
    );
  }

  /// Same signature as before. Now crops the fruit first (YOLO), exactly like
  /// Colab. Falls back to the whole photo only if no fruit is found.
  Future<MlResult> classifyDisease(File imageFile) async {
    final image = ImageUtils.loadForInference(imageFile);
    final fruit = await FruitSegmentationService.instance.analyze(image);
    return classifyCrop(fruit?.crop ?? image);
  }

  /// Same signature as before.
  Future<SeverityResult> analyzeSeverity(File imageFile) async {
    try {
      final image = ImageUtils.loadForInference(imageFile);
      final fruit = await FruitSegmentationService.instance.analyze(image);
      if (fruit == null) return SeverityResult(0.0, 'N/A');
      return SeverityResult(fruit.severityPercent, severityLevelFor(fruit.severityPercent));
    } catch (e) {
      debugPrint('⚠️ Severity segmentation failed — defaulting to 0%/N/A: $e');
      return SeverityResult(0.0, 'N/A');
    }
  }

  void dispose() {
    _classifier?.close();
    _classifier = null;
    FruitSegmentationService.instance.dispose();
  }
}
