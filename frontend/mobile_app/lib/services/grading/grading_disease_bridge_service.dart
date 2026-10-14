// lib/services/grading/grading_disease_bridge_service.dart
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../config/disease_ml_config.dart';
import '../../l10n/d_app_strings.dart';
import '../../models/Disease_prediction_result_model.dart';
import '../disease/treatment_data.dart';
import '../ml/detection_exceptions.dart';
import '../ml/disease_pipeline.dart';

/// What the Disease component found for a "low quality → disease" fruit.
enum DiseaseCheckStatus {
  /// A disease was identified with good confidence.
  confirmed,

  /// A disease was identified, but the model is not sure (low confidence /
  /// small margin). Show it with an "uncertain" note.
  uncertain,

  /// The disease classifier says the fruit is healthy (does not agree with
  /// the grading defect model). No disease treatment is shown.
  healthy,

  /// The disease pipeline did not find a pomegranate / fruit in the photo.
  notDetected,

  /// Something went wrong (model error).
  failed,
}

/// Disease result for one graded fruit — everything the grading screens
/// need: name, confidence, severity, Organic + Chemical treatment,
/// prevention tips and schedule. All text is in the CURRENT app language.
class DiseaseFinding {
  final DiseaseCheckStatus status;
  final String diseaseName; // English key, e.g. 'Bacterial_Blight'
  final double confidence; // 0..100 (same display rule as Disease module)
  final double severityPercent; // 0..100 (Disease YOLO)
  final String severityLevel; // 'Mild' | 'Moderate' | 'Severe' | 'N/A'
  final List<String> warningKeys; // keys for dt()
  final int tipsSeed; // same tips in every language
  final DateTime detectedAt;
  final String imagePath;

  const DiseaseFinding({
    required this.status,
    required this.diseaseName,
    required this.confidence,
    required this.severityPercent,
    required this.severityLevel,
    required this.warningKeys,
    required this.tipsSeed,
    required this.detectedAt,
    required this.imagePath,
  });

  factory DiseaseFinding.empty(DiseaseCheckStatus status, String imagePath) {
    final now = DateTime.now();
    return DiseaseFinding(
      status: status,
      diseaseName: '',
      confidence: 0,
      severityPercent: 0,
      severityLevel: 'N/A',
      warningKeys: const [],
      tipsSeed: TreatmentOptionsData.seedFor(null, now),
      detectedAt: now,
      imagePath: imagePath,
    );
  }

  /// Show the disease + treatment section only for these.
  bool get hasDisease =>
      status == DiseaseCheckStatus.confirmed ||
      status == DiseaseCheckStatus.uncertain;

  bool get isUncertain => status == DiseaseCheckStatus.uncertain;

  /// 'confirmed' | 'uncertain' | 'healthy' | 'not_detected' | 'failed'
  String get statusKey => switch (status) {
    DiseaseCheckStatus.confirmed => 'confirmed',
    DiseaseCheckStatus.uncertain => 'uncertain',
    DiseaseCheckStatus.healthy => 'healthy',
    DiseaseCheckStatus.notDetected => 'not_detected',
    DiseaseCheckStatus.failed => 'failed',
  };

  /// Translated disease name, e.g. "பாக்டீரியா கருகல்".
  String get displayName => LanguageController.instance.disease(diseaseName);

  /// Translated level + %, e.g. "Moderate (28.7%)".
  String get severityDisplay =>
      '${LanguageController.instance.severity(severityLevel)} '
      '(${severityPercent.toStringAsFixed(1)}%)';

  String get confidenceDisplay => '${confidence.toStringAsFixed(1)}%';

  /// Organic or Chemical recommendation + image + 3–4 prevention tips.
  TreatmentContent treatmentFor(TreatmentType type) =>
      TreatmentOptionsData.forDisease(
        diseaseName,
        type,
        severityLevel: severityLevel,
        seed: tipsSeed,
      );

  TreatmentContent get organic => treatmentFor(TreatmentType.organic);
  TreatmentContent get chemical => treatmentFor(TreatmentType.chemical);

  /// Prevention tips (same for Organic and Chemical).
  List<String> get prevention => organic.prevention;

  TreatmentSchedule scheduleFor(TreatmentType type) =>
      TreatmentData.scheduleFor(diseaseName, severityLevel, type: type);

  /// Same result as a Disease-module model, so existing disease widgets
  /// (MarkedDiseaseImage, SeverityChip, ClassificationResultView…) can be
  /// reused. NOT saved to the disease history.
  PredictionResultModel? toDiseaseResult() {
    if (!hasDisease) return null;
    final schedule = scheduleFor(TreatmentType.organic);
    final lang = LanguageController.instance.language;
    return PredictionResultModel(
      predictionId: null, // not a disease-history record
      isPomegranate: true,
      diseaseName: diseaseName,
      confidence: confidence,
      isDisease: true,
      status: isUncertain ? 'uncertain' : 'ok',
      warnings: warningKeys.map((k) => AppStrings.translate(k, lang)).toList(),
      severityPercentage: severityPercent,
      severityLevel: severityLevel,
      treatment: organic.recommendation,
      prevention: prevention,
      followUpDays: schedule.everyDays,
      followUpDueDate: detectedAt.add(Duration(days: schedule.everyDays)),
      imagePath: imagePath,
      detectedAt: detectedAt,
    );
  }
}

/// Bridges the Grading component to the Disease component.
///
/// When a fruit is graded "low_quality" with defect "disease", the SAME
/// photo is run through the Disease component's on-device pipeline
/// (YOLO fruit + severity → pomegranate validator → 5-class classifier)
/// to find WHICH disease, how severe, and what treatment to give.
///
/// IMPORTANT: this calls DiseasePipeline directly — NOT
/// DiseaseService.predictDisease — so grading checks are NOT saved into
/// the disease history and no image is uploaded twice.
class GradingDiseaseBridgeService {
  GradingDiseaseBridgeService._();
  static final GradingDiseaseBridgeService instance =
      GradingDiseaseBridgeService._();

  /// Runs the Disease pipeline on [imageFile]. Never throws.
  Future<DiseaseFinding> analyze(File imageFile) async {
    try {
      final out = await DiseasePipeline.instance.run(imageFile);
      final now = DateTime.now();

      final DiseaseCheckStatus status;
      if (out.isHealthy) {
        status = DiseaseCheckStatus.healthy;
      } else if (out.isUncertain) {
        status = DiseaseCheckStatus.uncertain;
      } else {
        status = DiseaseCheckStatus.confirmed;
      }

      // Same confidence display rule as the Disease module.
      final confidence = ConfidenceDisplay.adjust(out.confidence * 100);

      debugPrint(
        '🔗 Grading→Disease: ${out.disease} '
        '(${confidence.toStringAsFixed(1)}%) '
        'severity=${out.severityPercent}% ${out.severityLevel} '
        'status=$status',
      );

      return DiseaseFinding(
        status: status,
        diseaseName: out.disease,
        confidence: confidence,
        severityPercent: out.severityPercent,
        severityLevel: out.severityLevel,
        warningKeys: out.warningKeys,
        tipsSeed: TreatmentOptionsData.seedFor(null, now),
        detectedAt: now,
        imagePath: imageFile.path,
      );
    } on NotPomegranateException catch (e) {
      debugPrint('🔗 Grading→Disease: rejected (${e.reason})');
      return DiseaseFinding.empty(
        DiseaseCheckStatus.notDetected,
        imageFile.path,
      );
    } catch (e) {
      debugPrint('🔗 Grading→Disease failed: $e');
      return DiseaseFinding.empty(DiseaseCheckStatus.failed, imageFile.path);
    }
  }

  /// Kept for older screens: returns a Disease-module result (not saved),
  /// or null when no disease was identified.
  Future<PredictionResultModel?> getDiseaseInfoForLowQuality(
    File imageFile,
  ) async {
    final finding = await analyze(imageFile);
    return finding.toDiseaseResult();
  }
}
