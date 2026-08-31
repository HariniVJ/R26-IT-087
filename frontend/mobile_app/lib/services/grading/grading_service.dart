// lib/services/grading/grading_service.dart
import 'dart:io';

import '../../models/grading_result.dart';
import '../../models/Disease_prediction_result_model.dart';
import 'grading_firestore_service.dart';
import 'recommendation_service.dart';
import 'image_storage_service.dart';
import 'grading_disease_bridge_service.dart';

class GradingService {
  final GradingFirestoreService _firestore = GradingFirestoreService.instance;
  final RecommendationService _recommendation = RecommendationService.instance;
  final ImageStorageService _imageStorage = ImageStorageService.instance;
  final GradingDiseaseBridgeService _diseaseBridge =
      GradingDiseaseBridgeService.instance;

  Future<void> init() async {}

  Future<GradingResult> saveResult({
    required String userId,
    required String quality,
    required double confidence,
    File? imageFile,
    String? defectType,
    double? severityPercent,
    int? weightGrams,
  }) async {
    final ruleRow = await _recommendation.getRecommendation(
      quality: quality,
      defectType: defectType,
      severityPercent: severityPercent,
      weightGrams: weightGrams,
    );

    final recommendation =
        ruleRow?['recommended_usage'] as String? ??
        'Manual inspection recommended';

    // 🆕 FIX: previously only 'recommended_usage' was read from the rule
    // row, so explanation / waste_usage / safety_note were silently
    // dropped and never reached the UI. Pull them out here too.
    final explanation = ruleRow?['explanation'] as String?;
    final wasteUsage = ruleRow?['waste_usage'] as String?;
    final safetyNote = ruleRow?['safety_note'] as String?;

    String? imageUrl;
    if (imageFile != null) {
      // Image is uploaded to Firebase Storage first, and the returned
      // download URL is what actually gets stored in Firestore below
      // (via GradingResult.imageUrl -> toJson()['image_url']). History
      // screens then just Image.network(result.imageUrl) that URL back —
      // no separate fetch step is needed.
      imageUrl = await _imageStorage.uploadGradingImage(imageFile, userId);
    }

    final draft = GradingResult(
      id: '',
      userId: userId,
      quality: quality,
      confidence: confidence,
      defectType: defectType,
      severityPercent: severityPercent,
      weightGrams: weightGrams,
      recommendation: recommendation,
      explanation: explanation,
      wasteUsage: wasteUsage,
      safetyNote: safetyNote,
      imageUrl: imageUrl,
      createdAt: DateTime.now().toIso8601String(),
    );

    return await _firestore.saveResult(draft);
  }

  /// Called when the fruit is graded "low_quality". The 4-class defect
  /// model already tells us WHICH kind of low-quality issue this is:
  /// "crack" / "rot" / "sunburn" / "disease".
  ///
  /// - For "crack" / "rot" / "sunburn": these are physical defects with
  ///   no disease to identify — no need to run the disease pipeline.
  /// - For "disease": the defect model only knows "this fruit has SOME
  ///   disease", not WHICH one. So this is the one case where we hand
  ///   the same image to the Disease component's full independent
  ///   pipeline (binary validator -> 5-class classifier -> severity ->
  ///   treatment matrix lookup) to find out exactly which disease
  ///   (Alternaria / Anthracnose / Bacterial_Blight / Cercospora) and
  ///   what treatment to recommend.
  ///
  /// Returns a [LowQualityInfo] describing what to show in the popup,
  /// or null if quality isn't "low_quality" at all.
  Future<LowQualityInfo?> checkDiseaseIfLowQuality({
    required String quality,
    required String? defectType,
    required File imageFile,
  }) async {
    if (quality != 'low_quality') return null;

    switch (defectType) {
      case 'disease':
        // Only this category needs the Disease component pipeline.
        final diseaseResult = await _diseaseBridge.getDiseaseInfoForLowQuality(
          imageFile,
        );
        return LowQualityInfo.disease(diseaseResult);

      case 'crack':
      case 'rot':
      case 'sunburn':
        // Physical defect — no disease identification needed.
        return LowQualityInfo.physicalDefect(defectType!);

      default:
        // Unknown/missing defectType — nothing specific to show.
        return null;
    }
  }

  Future<List<GradingResult>> getHistory(String userId) =>
      _firestore.getHistory(userId);
  Future<void> deleteOne(String id) => _firestore.deleteOne(id);
  Future<void> deleteAll(String userId) => _firestore.deleteAll(userId);
}

/// Describes what kind of low-quality popup to show — either a
/// physical defect (crack/rot/sunburn, no disease lookup needed) or a
/// disease result (fetched fresh from the Disease component).
class LowQualityInfo {
  final bool isDiseaseCase;
  final String? physicalDefectType; // "crack" | "rot" | "sunburn"
  final PredictionResultModel? diseaseResult; // populated only if isDiseaseCase

  LowQualityInfo._({
    required this.isDiseaseCase,
    this.physicalDefectType,
    this.diseaseResult,
  });

  factory LowQualityInfo.physicalDefect(String defectType) {
    return LowQualityInfo._(
      isDiseaseCase: false,
      physicalDefectType: defectType,
    );
  }

  factory LowQualityInfo.disease(PredictionResultModel? result) {
    return LowQualityInfo._(isDiseaseCase: true, diseaseResult: result);
  }
}
