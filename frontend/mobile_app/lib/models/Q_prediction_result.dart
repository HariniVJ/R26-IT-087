import 'package:PomCare/models/grading_result.dart';

class PredictionResult {
  final String quality;
  final double confidence; // 0.0–100.0 percentage
  final String? defectType; // 🆕 null for high/medium quality
  final double? severityPercent; // 🆕 0–100, null if no defect
  final String recommendation;

  const PredictionResult({
    required this.quality,
    required this.confidence,
    this.defectType,
    this.severityPercent,
    required this.recommendation,
  });

  double get confidenceDecimal => confidence / 100.0;
  String get confidencePercent => '${confidence.toStringAsFixed(1)}%';

  String get severityDisplay => severityPercent != null
      ? '${severityPercent!.toStringAsFixed(1)}%'
      : 'N/A';

    GradingResult toGradingResult({
    required String userId,
    int? weightGrams,
    String? imageUrl,
  }) {
    return GradingResult(
      id: '',
      userId: userId,
      quality: quality,
      confidence:
          confidenceDecimal, // ✅ percentage → decimal conversion happens HERE
      defectType: defectType,
      severityPercent: severityPercent,
      weightGrams: weightGrams,
      recommendation: recommendation,
      imageUrl: imageUrl,
      createdAt: DateTime.now().toIso8601String(),
    );
  }
}


