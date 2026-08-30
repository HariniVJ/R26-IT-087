// lib/models/prediction_result.dart
import 'package:PomCare/models/grading_result.dart';

class PredictionResult {
  final String quality;
  final double confidence;
  final String? defectType;
  final double? severityPercent;
  final String? colorTone;
  final String recommendation;

  const PredictionResult({
    required this.quality,
    required this.confidence,
    this.defectType,
    this.severityPercent,
    this.colorTone,
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
      confidence: confidenceDecimal,
      defectType: defectType,
      severityPercent: severityPercent,
      weightGrams: weightGrams,
      recommendation: recommendation,
      imageUrl: imageUrl,
      createdAt: DateTime.now().toIso8601String(),
    );
  }
}
