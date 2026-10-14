// lib/models/grading_result.dart
import '../services/disease/treatment_data.dart';

/// One saved quality-grading record (Firestore: quality_results).
///
/// Disease fields are filled ONLY when quality == 'low_quality' and
/// defectType == 'disease'. In that case the same photo is sent to the
/// Disease component (YOLO severity → validator → 5-class classifier) and
/// its result is stored here, so the history "eye" icon can show the
/// disease, severity and treatment WITHOUT re-running any model.
class GradingResult {
  final String id;
  final String userId;
  final String quality;
  final double confidence; // 0..1
  final String? defectType;

  /// Severity used for the waste-use recommendation.
  /// For defectType == 'disease' this is the Disease component's YOLO
  /// severity (more accurate); otherwise the grading model's value.
  final double? severityPercent;
  final int? weightGrams;
  final String recommendation;
  final String? explanation;
  final String? wasteUsage;
  final String? safetyNote;

  // ── Disease component result (low_quality + disease only) ──
  /// 'confirmed' | 'uncertain' | 'healthy' | 'not_detected' | 'failed'
  final String? diseaseStatus;
  final String? diseaseName; // e.g. 'Anthracnose' (English key)
  final double? diseaseConfidence; // 0..100
  final double? diseaseSeverityPercent; // 0..100 (YOLO)
  final String? diseaseSeverityLevel; // 'Mild' | 'Moderate' | 'Severe'

  /// Organic recommendation text (language at detection time).
  final String? diseaseTreatment;

  /// Chemical recommendation text (language at detection time).
  final String? diseaseChemicalTreatment;
  final List<String>? diseasePrevention;

  /// Seed for the 3–4 prevention tips, so re-building them in another
  /// language gives the SAME tips.
  final int? diseaseTipsSeed;

  final String? imageUrl;

  /// Local device file path, saved alongside imageUrl (offline fallback).
  final String? imagePath;

  final String? createdAt;

  const GradingResult({
    required this.id,
    required this.userId,
    required this.quality,
    required this.confidence,
    this.defectType,
    this.severityPercent,
    this.weightGrams,
    required this.recommendation,
    this.explanation,
    this.wasteUsage,
    this.safetyNote,
    this.diseaseStatus,
    this.diseaseName,
    this.diseaseConfidence,
    this.diseaseSeverityPercent,
    this.diseaseSeverityLevel,
    this.diseaseTreatment,
    this.diseaseChemicalTreatment,
    this.diseasePrevention,
    this.diseaseTipsSeed,
    this.imageUrl,
    this.imagePath,
    this.createdAt,
  });

  factory GradingResult.fromJson(Map<String, dynamic> json) {
    final rawConf = (json['confidence'] as num?)?.toDouble() ?? 0.0;
    return GradingResult(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      quality: json['quality'] as String? ?? '',
      confidence: rawConf,
      defectType: json['defect_type'] as String?,
      severityPercent: (json['severity_percent'] as num?)?.toDouble(),
      weightGrams: (json['weight_grams'] as num?)?.toInt(),
      recommendation: json['recommendation'] as String? ?? '',
      explanation: json['explanation'] as String?,
      wasteUsage: json['waste_usage'] as String?,
      safetyNote: json['safety_note'] as String?,
      diseaseStatus: json['disease_status'] as String?,
      diseaseName: json['disease_name'] as String?,
      diseaseConfidence: (json['disease_confidence'] as num?)?.toDouble(),
      diseaseSeverityPercent: (json['disease_severity_percent'] as num?)
          ?.toDouble(),
      diseaseSeverityLevel: json['disease_severity_level'] as String?,
      diseaseTreatment: json['disease_treatment'] as String?,
      diseaseChemicalTreatment: json['disease_chemical_treatment'] as String?,
      diseasePrevention: (json['disease_prevention'] as List?)
          ?.map((e) => e.toString())
          .toList(),
      diseaseTipsSeed: (json['disease_tips_seed'] as num?)?.toInt(),
      imageUrl: json['image_url'] as String?,
      imagePath: json['image_path'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'quality': quality,
    'confidence': confidence,
    'defect_type': defectType,
    'severity_percent': severityPercent,
    'weight_grams': weightGrams,
    'recommendation': recommendation,
    'explanation': explanation,
    'waste_usage': wasteUsage,
    'safety_note': safetyNote,
    'disease_status': diseaseStatus,
    'disease_name': diseaseName,
    'disease_confidence': diseaseConfidence,
    'disease_severity_percent': diseaseSeverityPercent,
    'disease_severity_level': diseaseSeverityLevel,
    'disease_treatment': diseaseTreatment,
    'disease_chemical_treatment': diseaseChemicalTreatment,
    'disease_prevention': diseasePrevention,
    'disease_tips_seed': diseaseTipsSeed,
    'image_url': imageUrl,
    'image_path': imagePath,
    'created_at': createdAt,
  };

  GradingResult copyWith({
    String? id,
    double? severityPercent,
    String? recommendation,
    String? explanation,
    String? wasteUsage,
    String? safetyNote,
    String? diseaseStatus,
    String? diseaseName,
    double? diseaseConfidence,
    double? diseaseSeverityPercent,
    String? diseaseSeverityLevel,
    String? diseaseTreatment,
    String? diseaseChemicalTreatment,
    List<String>? diseasePrevention,
    int? diseaseTipsSeed,
    String? imageUrl,
  }) {
    return GradingResult(
      id: id ?? this.id,
      userId: userId,
      quality: quality,
      confidence: confidence,
      defectType: defectType,
      severityPercent: severityPercent ?? this.severityPercent,
      weightGrams: weightGrams,
      recommendation: recommendation ?? this.recommendation,
      explanation: explanation ?? this.explanation,
      wasteUsage: wasteUsage ?? this.wasteUsage,
      safetyNote: safetyNote ?? this.safetyNote,
      diseaseStatus: diseaseStatus ?? this.diseaseStatus,
      diseaseName: diseaseName ?? this.diseaseName,
      diseaseConfidence: diseaseConfidence ?? this.diseaseConfidence,
      diseaseSeverityPercent:
          diseaseSeverityPercent ?? this.diseaseSeverityPercent,
      diseaseSeverityLevel: diseaseSeverityLevel ?? this.diseaseSeverityLevel,
      diseaseTreatment: diseaseTreatment ?? this.diseaseTreatment,
      diseaseChemicalTreatment:
          diseaseChemicalTreatment ?? this.diseaseChemicalTreatment,
      diseasePrevention: diseasePrevention ?? this.diseasePrevention,
      diseaseTipsSeed: diseaseTipsSeed ?? this.diseaseTipsSeed,
      imageUrl: imageUrl ?? this.imageUrl,
      imagePath: imagePath,
      createdAt: createdAt,
    );
  }

  // ── Display helpers ──
  String get confidencePercent => '${(confidence * 100).toStringAsFixed(1)}%';
  double get confidenceArc => confidence.clamp(0.0, 1.0);

  String get severityDisplay => severityPercent != null
      ? '${severityPercent!.toStringAsFixed(1)}%'
      : 'N/A';

  /// True when the Disease component identified a disease (confirmed or
  /// uncertain) — show disease + treatment section.
  /// (Older records saved before disease_status existed also count.)
  bool get hasDiseaseInfo =>
      (diseaseStatus == null ||
          diseaseStatus == 'confirmed' ||
          diseaseStatus == 'uncertain') &&
      diseaseName != null &&
      diseaseName!.isNotEmpty &&
      diseaseName != 'Healthy';

  bool get isDiseaseUncertain => diseaseStatus == 'uncertain';

  String get diseaseDisplayName => (diseaseName ?? '').replaceAll('_', ' ');

  String get diseaseConfidenceDisplay => diseaseConfidence != null
      ? '${diseaseConfidence!.toStringAsFixed(1)}%'
      : 'N/A';

  String get diseaseSeverityDisplay => diseaseSeverityPercent != null
      ? '${diseaseSeverityLevel ?? ''} '
                '(${diseaseSeverityPercent!.toStringAsFixed(1)}%)'
            .trim()
      : 'N/A';

  /// Organic / Chemical treatment rebuilt in the CURRENT app language
  /// (same tips as when it was saved). Null if no disease info.
  TreatmentContent? diseaseTreatmentFor(TreatmentType type) {
    if (!hasDiseaseInfo) return null;
    return TreatmentOptionsData.forDisease(
      diseaseName!,
      type,
      severityLevel: diseaseSeverityLevel,
      seed: diseaseTipsSeed ?? 0,
    );
  }

  /// Interval + applications for the disease treatment.
  TreatmentSchedule? diseaseScheduleFor(TreatmentType type) {
    if (!hasDiseaseInfo) return null;
    return TreatmentData.scheduleFor(
      diseaseName!,
      diseaseSeverityLevel,
      type: type,
    );
  }

  String get displayDate {
    if (createdAt == null) return '';
    try {
      final dt = DateTime.parse(createdAt!).toLocal();
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return createdAt ?? '';
    }
  }

  DateTime? get dateTime {
    if (createdAt == null) return null;
    try {
      return DateTime.parse(createdAt!).toLocal();
    } catch (_) {
      return null;
    }
  }
}
