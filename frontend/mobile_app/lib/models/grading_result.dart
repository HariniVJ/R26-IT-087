// YOUR FILE — Member 4: Fruit Quality Grading
// lib/models/grading_result.dart
//
// FIX: confidencePercent was multiplying by 100 again
// Firestore stores confidence as 0.0–1.0 decimal
// Display: multiply by 100 once only

class GradingResult {
  final String id;
  final String userId;
  final String quality;
  final double confidence; // stored as 0.0–1.0 in Firestore
  final String recommendation;
  final String? imageUrl;
  final String? createdAt;

  const GradingResult({
    required this.id,
    required this.userId,
    required this.quality,
    required this.confidence,
    required this.recommendation,
    this.imageUrl,
    this.createdAt,
  });

  factory GradingResult.fromJson(Map<String, dynamic> json) {
    // confidence comes from Firestore as 0.0–1.0
    final rawConf = (json['confidence'] as num?)?.toDouble() ?? 0.0;

    return GradingResult(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      quality: json['quality'] as String? ?? '',
      confidence: rawConf,
      recommendation: json['recommendation'] as String? ?? '',
      imageUrl: json['image_url'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }

  // FIX: confidence is already 0.0–1.0, multiply by 100 once for display
  String get confidencePercent => '${(confidence * 100).toStringAsFixed(1)}%';

  // For arc painter — value must be 0.0–1.0
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

  DateTime? get dateTime {
    if (createdAt == null) return null;
    try {
      return DateTime.parse(createdAt!).toLocal();
    } catch (_) {
      return null;
    }
  }
}
