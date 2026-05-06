// YOUR FILE — Member 4: Fruit Quality Grading
// lib/models/grading_result.dart

class GradingResult {
  final String id;
  final String userId;
  final String quality;
  final double confidence;
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

  factory GradingResult.fromJson(Map<String, dynamic> json) => GradingResult(
        id:             json['id']             as String? ?? '',
        userId:         json['user_id']        as String? ?? '',
        quality:        json['quality']        as String? ?? '',
        confidence:     (json['confidence'] as num?)?.toDouble() ?? 0.0,
        recommendation: json['recommendation'] as String? ?? '',
        imageUrl:       json['image_url']      as String?,
        createdAt:      json['created_at']     as String?,
      );

  String get confidencePercent => '${(confidence * 100).toStringAsFixed(1)}%';

  /// Returns a friendly date string from ISO timestamp
  String get displayDate {
    if (createdAt == null) return '';
    try {
      final dt = DateTime.parse(createdAt!).toLocal();
      final months = ['Jan','Feb','Mar','Apr','May','Jun',
                      'Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return createdAt!;
    }
  }

  DateTime? get dateTime {
    if (createdAt == null) return null;
    try { return DateTime.parse(createdAt!).toLocal(); } catch (_) { return null; }
  }
}