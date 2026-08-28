
class FirestoreSchema {
  static const users = 'users';
  static const farms = 'farms';
  static const trees = 'trees';
  static const sensorReadings = 'sensor_readings';
  static const weather = 'weather';
  static const irrigationPredictions = 'irrigation_predictions';
  static const irrigationLogs = 'irrigation_logs';
  static const fertilizerPredictions = 'fertilizer_predictions';
  static const fertilizerLogs = 'fertilizer_logs';
  static const notifications = 'notifications';

  /// Other team modules. Kept so existing Admin SDK history is not orphaned.
  static const qualityResults = 'quality_results';
  static const diseasePredictions = 'disease_predictions';

  /// Older Flutter writes. History screens still read these as fallback.
  static const irrigationLegacy = 'irrigation';
  static const fertilizerLegacy = 'fertilizer';

  static const roleFarmer = 'farmer';

  static const notifyRainExpected = 'RAIN_ALERT';
  static const notifySoilTooLow = 'SOIL_MOISTURE_LOW';
  static const notifySoilWet = 'SOIL_ALREADY_WET';
  static const notifyIrrigationRecommended = 'IRRIGATION_RECOMMENDED';
  static const notifySkippedRain = 'IRRIGATION_SKIPPED_RAIN';
  static const notifyFertilizerRequired = 'FERTILIZER_REQUIRED';
  static const notifyNpkDeficiency = 'NPK_DEFICIENCY';
  static const notifyNLow = 'NITROGEN_LOW';
  static const notifyPLow = 'PHOSPHORUS_LOW';
  static const notifyKLow = 'POTASSIUM_LOW';
  static const notifyNewFertilizer = 'NEW_FERTILIZER';
}
