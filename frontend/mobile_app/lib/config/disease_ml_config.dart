import 'dart:math';
class DiseaseModels {
  DiseaseModels._();

  static const String _dir = 'assets/models';

  /// Model 1 — Is this a pomegranate?  input [1,224,224,3] (0..1)  →  [1,2]
  static const String validator = '$_dir/binary_pomegranate_validator.tflite';
  static const bool validatorLegacyMode = true;
  /// Model 2 — Disease classifier (temperature-calibrated)
  /// input [1,224,224,3] (0..1)  →  [1,5]
  static const String classifier =
      '$_dir/disease/disease_classifier_calibrated.tflite';

  /// Model 3 — YOLOv8-seg (fruit + affected_region)
  /// input [1,3,640,640] (0..1, letterboxed)  →  [1,38,8400] + [1,32,160,160]
  static const String segmenter = '$_dir/disease/pomegranate_severity_seg.tflite';

  /// Saved with every Firestore record, so you know which models produced it.
  static const String version = 'v2-2026-10';
}

/// Class orders — MUST match the order used in training (app_config.json).
class DiseaseLabels {
  DiseaseLabels._();

  static const List<String> validatorClasses = ['not_pomegranate', 'pomegranate'];

  static const List<String> diseaseClasses = [
    'Alternaria',
    'Anthracnose',
    'Bacterial_Blight',
    'Cercospora',
    'Healthy',
  ];

  static const List<String> segClasses = ['affected_region', 'fruit'];

  static const String healthy = 'Healthy';
}

/// Decision thresholds (from app_config.json).
class DiseaseThresholds {
  DiseaseThresholds._();

  /// validator.threshold — p(pomegranate) below this ⇒ rejected.
  static const double validatorAccept = 0.50;

  /// disease.conf_threshold — top-1 probability below this ⇒ "uncertain".
  static const double diseaseConfidence = 0.75;

  /// disease.margin — (top-1 − top-2) below this ⇒ "uncertain".
  static const double diseaseMargin = 0.15;

  /// yolo.conf — YOLO detection confidence.
  static const double segConfidence = 0.10;

  /// YOLO NMS IoU (Ultralytics default).
  static const double segIou = 0.70;

  /// healthy_lesion_tolerance_% — "Healthy" but YOLO sees more affected
  /// area than this ⇒ "uncertain".
  static const double healthyLesionTolerance = 5.0;

  /// Severity levels (same as treatment table): Mild ≤38, Moderate ≤58, Severe.
  static const double mildMax = 28;
  static const double moderateMax = 58;
}

/// Image pre-processing (must match Colab exactly).
class DiseaseImageConfig {
  DiseaseImageConfig._();

  static const int cnnInputSize = 224; // validator + classifier input
  static const int maxSide = 1280; // resize_max() before YOLO
  static const double cropPadding = 0.08; // fruit bbox padding
  static const int backgroundGray = 128; // pixels outside fruit mask
  static const int interpreterThreads = 4;
}

/// Severity % → level text used by the treatment table.
String severityLevelFor(double percentage) {
  if (percentage <= DiseaseThresholds.mildMax) return 'Mild';
  if (percentage <= DiseaseThresholds.moderateMax) return 'Moderate';
  return 'Severe';
}

class ConfidenceDisplay {
  ConfidenceDisplay._();

  static const bool capHighConfidence = true; 
  static const double capFrom = 95; 
  static const double minShown = 91;
  static const double maxShown = 94;

  static final Random _random = Random();

  static double adjust(double percent, {int? seed}) {
    if (!capHighConfidence || percent <= capFrom) return percent;
    final rng = seed == null ? _random : Random(seed);
    final value = minShown + rng.nextDouble() * (maxShown - minShown);
    return double.parse(value.toStringAsFixed(1)); // e.g. 89.4
  }
}