class GradingResult {
  final String id;
  final String userId;
  final String quality;
  final double confidence;
  final String? defectType;
  final double? severityPercent;
  final int? weightGrams;
  final String recommendation;

  // 🆕 FIX: these 3 fields were missing from the model, so the
  // recommendation_service's explanation / waste_usage / safety_note
  // were never saved or displayed anywhere (history_detail_screen.dart
  // was already reading result.explanation / result.wasteUsage /
  // result.safetyNote, but the model never had them -> always null).
  final String? explanation;
  final String? wasteUsage;
  final String? safetyNote;

  final String? imageUrl;
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
    this.imageUrl,
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
      imageUrl: json['image_url'] as String?,
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
    'image_url': imageUrl,
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
