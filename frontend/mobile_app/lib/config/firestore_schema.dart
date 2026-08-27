/// Firestore collection names used by the Flutter app.
///
/// These are documents, not SQL tables. A collection is created automatically
/// when the first document is written.
class FirestoreSchema {
  static const users = 'users';
  static const irrigation = 'irrigation';
  static const weather = 'weather';
  static const fertilizer = 'fertilizer';

  /// Existing backend collections. Kept so Admin SDK history is not orphaned.
  /// Flutter does not write these yet.
  static const qualityResults = 'quality_results';
  static const diseasePredictions = 'disease_predictions';
}
