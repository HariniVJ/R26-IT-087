import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/Disease_prediction_result_model.dart';

class HistoryService {
  static final _db = FirebaseFirestore.instance;
  static const _collection = 'disease_predictions';

  /// Fetches full detection history for the logged-in farmer.
  /// Works offline: Firestore serves from local cache automatically
  /// when there's no network, then quietly refreshes once reconnected.
  static Future<List<PredictionResultModel>> getFirebaseHistory() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      throw Exception('You must be signed in to view history.');
    }

    final snapshot = await _db
        .collection(_collection)
        .where('user_id', isEqualTo: uid)
        .orderBy('created_at', descending: true)
        .get();

    return snapshot.docs.map((doc) => _fromDoc(doc.id, doc.data())).toList();
  }

 static PredictionResultModel _fromDoc(String id, Map<String, dynamic> item) {
    final treatmentInfo = item['treatment_info'] is Map
        ? Map<String, dynamic>.from(item['treatment_info'])
        : <String, dynamic>{};

    final prevention = treatmentInfo['prevention'] is List
        ? List<String>.from(treatmentInfo['prevention'])
        : <String>[];

    final createdAt = item['created_at'] is Timestamp
        ? (item['created_at'] as Timestamp).toDate()
        : (item['created_at_local'] is Timestamp
              ? (item['created_at_local'] as Timestamp).toDate()
              : DateTime.now());

    final followUpDueDate = item['follow_up_due_date'] is Timestamp
        ? (item['follow_up_due_date'] as Timestamp).toDate()
        : null;

    return PredictionResultModel(
      predictionId: id,
      isPomegranate: item['is_pomegranate'] as bool? ?? true,
      validatorConfidence:
          (item['validator_confidence'] as num?)?.toDouble() ?? 0.0,
      diseaseName: item['disease_name']?.toString() ?? 'Unknown',
      confidence: (item['confidence'] as num?)?.toDouble() ?? 0.0,
      isDisease: item['is_disease'] == true,
      severityPercentage:
          (item['severity_percentage'] as num?)?.toDouble() ?? 0.0,
      severityLevel: item['severity_level']?.toString() ?? 'N/A',
      treatment: treatmentInfo['treatment']?.toString() ?? '',
      prevention: prevention,
      followUpDays: (treatmentInfo['follow_up_days'] as num?)?.toInt() ?? 0,
      followUpDueDate: followUpDueDate,
      followUpDone: item['follow_up_done'] as bool? ?? false,
      imagePath: item['image_path']?.toString() ?? '',
      responseTimeSeconds: 0.0,
      detectedAt: createdAt,
    );
  }
  static Future<void> deleteFirebaseHistory(String predictionId) async {
    await _db.collection(_collection).doc(predictionId).delete();
  }

  // ── Follow-up tracking ──────────────────────────────────────────────

  /// Marks a detection's follow-up check as completed
  /// (e.g. farmer confirms they re-checked the fruit after treatment).
  static Future<void> markFollowUpDone(String predictionId) async {
    await _db.collection(_collection).doc(predictionId).update({
      'follow_up_done': true,
      'follow_up_completed_at': FieldValue.serverTimestamp(),
    });
  }

  /// Returns detections whose follow-up date has arrived and hasn't
  /// been marked done yet — use this to show reminder badges/notifications.
  static Future<List<PredictionResultModel>> getPendingFollowUps() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return [];

    final snapshot = await _db
        .collection(_collection)
        .where('user_id', isEqualTo: uid)
        .where('follow_up_done', isEqualTo: false)
        .get();

    final now = DateTime.now();

    final due = snapshot.docs.where((doc) {
      final dueDate = doc.data()['follow_up_due_date'];
      if (dueDate is! Timestamp) return false;
      return dueDate.toDate().isBefore(now);
    });

    return due.map((doc) => _fromDoc(doc.id, doc.data())).toList();
  }

  /// Forces any locally-queued offline writes to sync to the server.
  /// Call this on app resume or when connectivity returns.
  static Future<void> syncPending() async {
    try {
      await _db.enableNetwork();
      await _db.waitForPendingWrites();
    } catch (e) {
      // ignore: avoid_print
      print('Sync pending writes failed (will retry later): $e');
    }
  }
}
