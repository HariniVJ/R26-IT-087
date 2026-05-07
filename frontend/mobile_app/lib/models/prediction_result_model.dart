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

  factory PredictionResultModel.fromApi(
    Map<String, dynamic> json,
    String localImagePath,
  ) {
    final treatmentInfo = json['treatment_info'] ?? {};

    String treatmentText = treatmentInfo['treatment'] ?? '';

    if (treatmentInfo['prevention'] != null) {
      final list = List<String>.from(treatmentInfo['prevention']);
      treatmentText += '\n\nPrevention:\n${list.map((e) => '• $e').join('\n')}';
    }

    return PredictionResultModel(
      diseaseName: json['disease_name'] ?? 'Unknown',
      confidence: (json['confidence'] ?? 0).toDouble(),
      treatment: treatmentText,
      imagePath: localImagePath,
      detectedAt: DateTime.now(),
    );
  }
}
