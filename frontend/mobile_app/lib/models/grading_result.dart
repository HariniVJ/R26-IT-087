class GradingResult {
  final String id;
  final String userId;
  final String quality;
  final double confidence;
  final String? defectType;
  final double? severityPercent;
  final int? weightGrams;
  final String recommendation;
  final String? explanation;
  final String? wasteUsage;
  final String? safetyNote;

  // 🆕 Populated only for defectType == 'disease', after the Disease
  // component's pipeline identifies which disease it is. Lets the
  // history "eye" icon show the same treatment info the original popup
  // showed, without re-running the disease model every time.
  final String? diseaseName;
  final String? diseaseTreatment;
  final List<String>? diseasePrevention;

  final String? imageUrl;

  // 🆕 Local device file path, saved alongside imageUrl. This lets the
  // UI show the photo instantly (before/without a Storage upload) and
  // acts as a fallback if imageUrl ever ends up null (upload failed,
  // offline, etc). See widgets/grading_image.dart for the fallback logic.
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
    this.diseaseName,
    this.diseaseTreatment,
    this.diseasePrevention,
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
      diseaseName: json['disease_name'] as String?,
      diseaseTreatment: json['disease_treatment'] as String?,
      diseasePrevention: (json['disease_prevention'] as List?)
          ?.map((e) => e.toString())
          .toList(),
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
    'disease_name': diseaseName,
    'disease_treatment': diseaseTreatment,
    'disease_prevention': diseasePrevention,
    'image_url': imageUrl,
    'image_path': imagePath,
    'created_at': createdAt,
  };

  String get confidencePercent => '${(confidence * 100).toStringAsFixed(1)}%';
  double get confidenceArc => confidence.clamp(0.0, 1.0);

  String get severityDisplay => severityPercent != null
      ? '${severityPercent!.toStringAsFixed(1)}%'
      : 'N/A';

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
