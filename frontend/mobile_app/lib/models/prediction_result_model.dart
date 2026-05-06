class PredictionResultModel {
  final String diseaseName;
  final double confidence;
  final String treatment;
  final String imagePath;
  final DateTime detectedAt;

  PredictionResultModel({
    required this.diseaseName,
    required this.confidence,
    required this.treatment,
    required this.imagePath,
    required this.detectedAt,
  });
}
