import 'dart:io';

import '../../../config/disease_ml_config.dart';
import 'binary_validator_service.dart';
import 'detection_exceptions.dart';
import 'fruit_segmentation_service.dart';
import 'image_utils.dart';
import 'model_inference_service.dart';

/// Warning keys (translated with AppStrings in d_app_strings.dart).
class DiseaseWarnings {
  DiseaseWarnings._();
  static const uncertain = 'warn_uncertain';
  static const healthyButLesions = 'warn_healthy_but_lesions';
  static const noLesionSegmented = 'warn_no_lesion_segmented';
  static const multipleFruits = 'warn_multiple_fruits';
}

class PipelineResult {
  final double pomegranateProbability; // 0..1
  final String disease;
  final double confidence; // 0..1
  final String secondDisease;
  final double secondConfidence; // 0..1
  final bool isHealthy;
  final bool isUncertain;
  final double severityPercent;
  final String severityLevel; // 'N/A' for Healthy
  final List<String> warningKeys;
  final int fruitCount;

  const PipelineResult({
    required this.pomegranateProbability,
    required this.disease,
    required this.confidence,
    required this.secondDisease,
    required this.secondConfidence,
    required this.isHealthy,
    required this.isUncertain,
    required this.severityPercent,
    required this.severityLevel,
    required this.warningKeys,
    required this.fruitCount,
  });
}

/// The full on-device pipeline — identical order to Colab analyze_full():
///
///   photo → YOLO (fruit? severity, crop) → validator (pomegranate?) →
///   disease classifier → uncertain / healthy rules
///
/// Works 100% offline (no network used here).
class DiseasePipeline {
  DiseasePipeline._();
  static final DiseasePipeline instance = DiseasePipeline._();

  final _seg = FruitSegmentationService.instance;
  final _validator = BinaryValidatorService.instance;
  final _classifier = ModelInferenceService.instance;

  /// Optional: call once (e.g. when the detection screen opens) so the first
  /// prediction is fast.
  Future<void> warmUp() async {
    await Future.wait([_seg.load(), _validator.loadModel(), _classifier.loadModels()]);
  }

  Future<PipelineResult> run(File imageFile) async {
    // 0. Decode + EXIF rotation + resize_max(1280)
    final image = ImageUtils.loadForInference(imageFile);

    // 1. YOLO — find the fruit, measure severity, make the gray crop
    final fruit = await _seg.analyze(image);
    if (fruit == null) {
      throw NotPomegranateException(1.0, reason: NotPomegranateReason.noFruitDetected);
    }

    // 2. Validator — is the cropped fruit a pomegranate?
        // 2. Validator — old model sees the full photo, new model sees the crop
    final v = await _validator.validateCrop(
      DiseaseModels.validatorLegacyMode ? image : fruit.crop,
    );
    if (!v.isPomegranate) throw NotPomegranateException(v.confidence);

    // 3. Disease classifier (calibrated) on the same crop
    final cls = await _classifier.classifyCrop(fruit.crop);

    // 4. Rules (same as Colab)
    final warnings = <String>[];
    var uncertain = cls.confidence < DiseaseThresholds.diseaseConfidence ||
        (cls.confidence - cls.secondConfidence) < DiseaseThresholds.diseaseMargin;
    if (uncertain) warnings.add(DiseaseWarnings.uncertain);

    final healthy = cls.label == DiseaseLabels.healthy;
    double severity;
    String level;
    if (healthy) {
      severity = 0.0;
      level = 'N/A';
      if (fruit.severityPercent > DiseaseThresholds.healthyLesionTolerance) {
        uncertain = true;
        warnings.add(DiseaseWarnings.healthyButLesions);
      }
    } else {
      severity = fruit.severityPercent;
      level = severityLevelFor(severity);
      if (severity == 0) warnings.add(DiseaseWarnings.noLesionSegmented);
    }
    if (fruit.fruitCount > 1) warnings.add(DiseaseWarnings.multipleFruits);

    return PipelineResult(
      pomegranateProbability: v.pomegranateProbability,
      disease: cls.label,
      confidence: cls.confidence,
      secondDisease: cls.secondLabel,
      secondConfidence: cls.secondConfidence,
      isHealthy: healthy,
      isUncertain: uncertain,
      severityPercent: severity,
      severityLevel: level,
      warningKeys: warnings,
      fruitCount: fruit.fruitCount,
    );
  }
}
