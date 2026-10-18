class PredictionResultModel {
  final String? predictionId;

  // Binary validator (pomegranate vs not)
  final bool isPomegranate;
  final double validatorConfidence;

  // Disease classification
  final String diseaseName;
  final double confidence; // 0..100
  final bool isDisease;

  // Second most likely disease + confidence status (kept for Firestore)
  final String secondDiseaseName;
  final double secondConfidence; // 0..100
  final String status; // 'ok' | 'uncertain'
  final List<String> warnings; // already translated text

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
  final String? imageUrl;

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
    this.secondDiseaseName = '',
    this.secondConfidence = 0.0,
    this.status = 'ok',
    this.warnings = const [],
    this.severityPercentage = 0.0,
    this.severityLevel = 'N/A',
    required this.treatment,
    this.prevention = const [],
    this.followUpDays = 0,
    this.followUpDueDate,
    this.followUpDone = false,
    required this.imagePath,
    this.imageUrl,
    this.responseTimeSeconds = 0.0,
    required this.detectedAt,
  });

  bool get isHealthy => diseaseName.toLowerCase() == 'healthy';

  bool get isUncertain => status == 'uncertain';

  /// Show treatment / prevention / follow-up for every disease result.
  /// Healthy results stop at the result screen.
  bool get needsTreatment => isDisease && !isHealthy;

  /// Schedule a follow-up reminder ONLY when this is true.
  bool get needsFollowUp => needsTreatment && followUpDueDate != null;

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
