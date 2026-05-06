// YOUR FILE — Member 4: Fruit Quality Grading
// lib/models/prediction_result.dart
// Local model returned by TFLiteService — before saving to backend.

class PredictionResult {
  final String quality;       // 'high_quality' | 'medium_quality' | 'low_quality'
  final double confidence;    // 0.0 – 100.0  (percentage, e.g. 94.2)
  final String recommendation;

  const PredictionResult({
    required this.quality,
    required this.confidence,
    required this.recommendation,
  });

  /// Confidence as 0.0–1.0 float (for backend which expects 0–1)
  double get confidenceDecimal => confidence / 100.0;

  /// Confidence as display string e.g. "94.2%"
  String get confidencePercent => '${confidence.toStringAsFixed(1)}%';
}