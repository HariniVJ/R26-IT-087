// lib/services/grading/grading_service.dart
import 'dart:io';

import '../../models/Disease_prediction_result_model.dart';
import '../../models/grading_result.dart';
import '../disease/treatment_data.dart';
import 'grading_disease_bridge_service.dart';
import 'grading_firestore_service.dart';
import 'image_storage_service.dart';
import 'recommendation_service.dart';
import 'package:path_provider/path_provider.dart';

export 'grading_disease_bridge_service.dart'
    show DiseaseFinding, DiseaseCheckStatus;

class GradingService {
  final GradingFirestoreService _firestore = GradingFirestoreService.instance;
  final RecommendationService _recommendation = RecommendationService.instance;
  final ImageStorageService _imageStorage = ImageStorageService.instance;
  final GradingDiseaseBridgeService _diseaseBridge =
      GradingDiseaseBridgeService.instance;

  Future<void> init() async {}

  /// True only for "low quality + disease" — the one case that needs the
  /// Disease component.
  static bool needsDiseaseCheck(String quality, String? defectType) =>
      quality == 'low_quality' && defectType == 'disease';

  // ════════════════════════════════════════════════════════════════════
  //  RECOMMENDED FLOW (one call): grade → disease check → save
  // ════════════════════════════════════════════════════════════════════

  /// Runs the Disease component FIRST when needed (low_quality + disease),
  /// uses its YOLO severity for the waste-use recommendation, and saves
  /// grading + disease info in ONE Firestore write.
  ///
  /// Returns the saved result and the disease finding (null when the
  /// disease check was not needed).
  Future<(GradingResult, DiseaseFinding?)> gradeAndSave({
    required String userId,
    required String quality,
    required double confidence,
    required File imageFile,
    String? defectType,
    double? severityPercent,
    int? weightGrams,
  }) async {
    DiseaseFinding? finding;
    if (needsDiseaseCheck(quality, defectType)) {
      finding = await _diseaseBridge.analyze(imageFile);
    }

    final saved = await saveResult(
      userId: userId,
      quality: quality,
      confidence: confidence,
      imageFile: imageFile,
      defectType: defectType,
      severityPercent: severityPercent,
      weightGrams: weightGrams,
      disease: finding,
    );
    return (saved, finding);
  }

  // ════════════════════════════════════════════════════════════════════
  //  SAVE
  // ════════════════════════════════════════════════════════════════════

  /// Saves a grading result. If [disease] is given and a disease was
  /// identified, its severity replaces the colour-heuristic severity and
  /// the disease name / severity / treatment are saved with the record.
  Future<GradingResult> saveResult({
    required String userId,
    required String quality,
    required double confidence,
    File? imageFile,
    String? defectType,
    double? severityPercent,
    int? weightGrams,
    DiseaseFinding? disease,
  }) async {
    // Disease component severity is more accurate than the colour
    // heuristic → use it for the disease waste-use rule.
    final useDisease =
        disease != null &&
        disease.hasDisease &&
        needsDiseaseCheck(quality, defectType);
    final severity = useDisease ? disease!.severityPercent : severityPercent;

    final ruleRow = await _recommendation.getRecommendation(
      quality: quality,
      defectType: defectType,
      severityPercent: severity,
      weightGrams: weightGrams,
    );

    // Local path first (offline fallback), then best-effort upload.
        final imagePath = imageFile == null
        ? null
        : await _keepLocalCopy(imageFile);
    String? imageUrl;
    if (imageFile != null) {
      imageUrl = await _imageStorage.uploadGradingImage(imageFile, userId);
    }

    var draft = GradingResult(
      id: '',
      userId: userId,
      quality: quality,
      confidence: confidence,
      defectType: defectType,
      severityPercent: severity,
      weightGrams: weightGrams,
      recommendation:
          ruleRow?['recommended_usage'] as String? ??
          'Manual inspection recommended',
      explanation: ruleRow?['explanation'] as String?,
      wasteUsage: ruleRow?['waste_usage'] as String?,
      safetyNote: ruleRow?['safety_note'] as String?,
      imageUrl: imageUrl,
      imagePath: imagePath,
      createdAt: DateTime.now().toIso8601String(),
    );

    if (disease != null && needsDiseaseCheck(quality, defectType)) {
      draft = _withDisease(draft, disease);
    }

    return _firestore.saveResult(draft);
  }

  /// Copies the disease finding onto a grading result.
  GradingResult _withDisease(GradingResult r, DiseaseFinding d) {
    if (!d.hasDisease) {
      // Healthy / not detected / failed → record the status only.
      return r.copyWith(diseaseStatus: d.statusKey);
    }
    return r.copyWith(
      diseaseStatus: d.statusKey,
      diseaseName: d.diseaseName,
      diseaseConfidence: d.confidence,
      diseaseSeverityPercent: d.severityPercent,
      diseaseSeverityLevel: d.severityLevel,
      diseaseTreatment: d.organic.recommendation,
      diseaseChemicalTreatment: d.chemical.recommendation,
      diseasePrevention: d.prevention,
      diseaseTipsSeed: d.tipsSeed,
    );
  }

  // ════════════════════════════════════════════════════════════════════
  //  OLDER TWO-STEP FLOW (save first, disease later) — still supported
  // ════════════════════════════════════════════════════════════════════

  /// Called when the fruit is graded "low_quality". The 4-class defect
  /// model already tells us WHICH kind of issue it is:
  ///   crack / rot / sunburn → physical defect, no disease lookup.
  ///   disease               → run the Disease component pipeline to find
  ///                           WHICH disease, severity and treatment.
  /// Returns null if quality isn't "low_quality".
  Future<LowQualityInfo?> checkDiseaseIfLowQuality({
    required String quality,
    required String? defectType,
    required File imageFile,
  }) async {
    if (quality != 'low_quality') return null;

    switch (defectType) {
      case 'disease':
        final finding = await _diseaseBridge.analyze(imageFile);
        return LowQualityInfo.disease(finding);

      case 'crack':
      case 'rot':
      case 'sunburn':
        return LowQualityInfo.physicalDefect(defectType!);

      default:
        return null;
    }
  }

  /// Attaches a disease finding to an already-saved grading record AND
  /// recalculates the waste-use recommendation with the disease severity.
  /// Returns the updated result (use it to refresh the screen).
  Future<GradingResult> attachDiseaseFinding({
    required GradingResult saved,
    required DiseaseFinding finding,
  }) async {
    var updated = _withDisease(saved, finding);

    if (finding.hasDisease) {
      final ruleRow = await _recommendation.getRecommendation(
        quality: saved.quality,
        defectType: saved.defectType,
        severityPercent: finding.severityPercent,
        weightGrams: saved.weightGrams,
      );
      updated = updated.copyWith(
        severityPercent: finding.severityPercent,
        recommendation: ruleRow?['recommended_usage'] as String?,
        explanation: ruleRow?['explanation'] as String?,
        wasteUsage: ruleRow?['waste_usage'] as String?,
        safetyNote: ruleRow?['safety_note'] as String?,
      );
    }

    if (saved.id.isNotEmpty) {
      await _firestore.updateFields(saved.id, {
        'severity_percent': updated.severityPercent,
        'recommendation': updated.recommendation,
        'explanation': updated.explanation,
        'waste_usage': updated.wasteUsage,
        'safety_note': updated.safetyNote,
        'disease_status': updated.diseaseStatus,
        'disease_name': updated.diseaseName,
        'disease_confidence': updated.diseaseConfidence,
        'disease_severity_percent': updated.diseaseSeverityPercent,
        'disease_severity_level': updated.diseaseSeverityLevel,
        'disease_treatment': updated.diseaseTreatment,
        'disease_chemical_treatment': updated.diseaseChemicalTreatment,
        'disease_prevention': updated.diseasePrevention,
        'disease_tips_seed': updated.diseaseTipsSeed,
      });
    }
    return updated;
  }

  /// Older call (name + treatment + prevention only). Kept so existing
  /// screens compile — prefer [attachDiseaseFinding].
  Future<void> attachDiseaseInfo({
    required String resultId,
    required String diseaseName,
    required String treatment,
    required List<String> prevention,
  }) => _firestore.attachDiseaseInfo(
    id: resultId,
    diseaseName: diseaseName,
    treatment: treatment,
    prevention: prevention,
  );
    // ════════════════════════════════════════════════════════════════════
  //  IMAGE — keep on phone + change photo (TEMP edit from history)
  // ════════════════════════════════════════════════════════════════════

  /// Copies the picked image from the image_picker cache into the app's
  /// documents folder, so it survives "Clear cache". Returns the new path.
  Future<String> _keepLocalCopy(File file) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final folder = Directory('${dir.path}/grading_images');
      if (!await folder.exists()) await folder.create(recursive: true);
      final name = 'grading_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final copy = await file.copy('${folder.path}/$name');
      return copy.path;
    } catch (_) {
      return file.path; // fallback: original path
    }
  }

  /// Replaces the photo of an already-saved record: keeps a local copy,
  /// tries to upload to Firebase Storage and updates image_path / image_url.
  /// Returns true when the upload worked (image_url saved).
  Future<bool> replaceImage({
    required GradingResult result,
    required File imageFile,
  }) async {
    if (result.id.isEmpty) return false;

    final localPath = await _keepLocalCopy(imageFile);

    String? url;
    try {
      url = await _imageStorage.uploadGradingImage(
        File(localPath),
        result.userId,
      );
    } catch (_) {
      url = null; // offline / Storage not ready → phone copy still saved
    }

    await _firestore.updateFields(result.id, {
      'image_path': localPath,
      if (url != null) 'image_url': url,
    });
    return url != null;
  }

  // ════════════════════════════════════════════════════════════════════
  //  HISTORY
  // ════════════════════════════════════════════════════════════════════
  Future<List<GradingResult>> getHistory(String userId) =>
      _firestore.getHistory(userId);
  Future<void> deleteOne(String id) => _firestore.deleteOne(id);
  Future<void> deleteAll(String userId) => _firestore.deleteAll(userId);
}

/// What to show in the low-quality popup — either a physical defect
/// (crack / rot / sunburn) or the Disease component's finding.
class LowQualityInfo {
  final bool isDiseaseCase;
  final String? physicalDefectType; // "crack" | "rot" | "sunburn"

  /// Full disease finding (status, name, severity, treatments, tips).
  final DiseaseFinding? finding;

  LowQualityInfo._({
    required this.isDiseaseCase,
    this.physicalDefectType,
    this.finding,
  });

  factory LowQualityInfo.physicalDefect(String defectType) =>
      LowQualityInfo._(isDiseaseCase: false, physicalDefectType: defectType);

  factory LowQualityInfo.disease(DiseaseFinding finding) =>
      LowQualityInfo._(isDiseaseCase: true, finding: finding);

  /// Same data as a Disease-module result (not saved) — for screens that
  /// already use PredictionResultModel. Null when no disease identified.
  PredictionResultModel? get diseaseResult => finding?.toDiseaseResult();

  /// Disease identified (confirmed or uncertain)?
  bool get hasDisease => finding?.hasDisease ?? false;

  /// Organic / Chemical treatment in the current language.
  TreatmentContent? treatmentFor(TreatmentType type) =>
      hasDisease ? finding!.treatmentFor(type) : null;
}
