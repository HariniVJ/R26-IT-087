class PredictionResultModel {
  final String? predictionId;
  final String diseaseName;
  final double confidence;
  final String treatment;
  final String imagePath;
  final DateTime detectedAt;

  PredictionResultModel({
    this.predictionId,
    required this.diseaseName,
    required this.confidence,
    required this.treatment,
    required this.imagePath,
    required this.detectedAt,
  });
}
