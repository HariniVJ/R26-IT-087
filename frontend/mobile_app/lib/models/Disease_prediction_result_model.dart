class PredictionResultModel {
  final String? predictionId;

  // Binary validator (pomegranate vs not)
  final bool isPomegranate;
  final double validatorConfidence;

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

  // Follow-up tracking
  final DateTime? followUpDueDate;
  final bool followUpDone;

  // Image
  final String imagePath;

  // Other information
  final double responseTimeSeconds;
  final DateTime detectedAt;

  PredictionResultModel({
    this.predictionId,
    this.isPomegranate = true,
    this.validatorConfidence = 0.0,
    required this.diseaseName,
    required this.confidence,
    this.isDisease = true,
    this.severityPercentage = 0.0,
    this.severityLevel = 'N/A',
    required this.treatment,
    this.prevention = const [],
    this.followUpDays = 0,
    this.followUpDueDate,
    this.followUpDone = false,
    required this.imagePath,
    this.responseTimeSeconds = 0.0,
    required this.detectedAt,
  });

  bool get isHealthy => diseaseName.toLowerCase() == 'healthy';

  bool get isHighConfidence => confidence >= 80;

  bool get isMediumConfidence => confidence >= 60 && confidence < 80;

  bool get isLowConfidence => confidence < 60;

  /// True when a follow-up is due (date has passed) and not yet completed.
  bool get isFollowUpPending {
    if (followUpDone || followUpDueDate == null) return false;
    return DateTime.now().isAfter(followUpDueDate!);
  }

  /// Days remaining until follow-up is due (negative = overdue).
  int? get daysUntilFollowUp {
    if (followUpDueDate == null) return null;
    return followUpDueDate!.difference(DateTime.now()).inDays;
  }
}
