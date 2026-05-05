class PredictionResult {
  final String quality;
  final double confidence;
  final String recommendation;

  PredictionResult({
    required this.quality,
    required this.confidence,
    required this.recommendation,
  });
}