class GradingResult {
  final String id;
  final String userId;
  final String quality;
  final double confidence;
  final String? defectType; 
  final double? severityPercent; 
  final int? weightGrams; 
  final String recommendation;
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
    'image_url': imageUrl,
    'created_at': createdAt,
  };

  String get confidencePercent => '${(confidence * 100).toStringAsFixed(1)}%';
  double get confidenceArc => confidence.clamp(0.0, 1.0);

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

  // grading_result.dart-ல், displayDate getter-க்கு கீழே சேருங்க

  DateTime? get dateTime {
    if (createdAt == null) return null;
    try {
      return DateTime.parse(createdAt!).toLocal();
    } catch (_) {
      return null;
    }
  }
}


