class PredictionResultModel {
  final String? predictionId;

  // Disease classification
  final String diseaseName;
  final double confidence;
  final bool isDisease;

  // Severity
  final double severityPercentage;
  final String severityLevel;

  // Treatment
  final String treatment;
  final List<String> prevention;
  final int followUpDays;

  // Image
  final String imagePath;

  // Explainability / segmentation
  final String? segmentationImageUrl;
  final String? gradCamImageUrl;

  // Other information
  final double responseTimeSeconds;
  final DateTime detectedAt;

  PredictionResultModel({
    this.predictionId,
    required this.diseaseName,
    required this.confidence,
    this.isDisease = true,
    this.severityPercentage = 0.0,
    this.severityLevel = 'N/A',
    required this.treatment,
    this.prevention = const [],
    this.followUpDays = 0,
    required this.imagePath,
    this.segmentationImageUrl,
    this.gradCamImageUrl,
    this.responseTimeSeconds = 0.0,
    required this.detectedAt,
  });

  bool get isHealthy => diseaseName.toLowerCase() == 'healthy';

  bool get isHighConfidence => confidence >= 80;

  bool get isMediumConfidence => confidence >= 60 && confidence < 80;

  bool get isLowConfidence => confidence < 60;
}
