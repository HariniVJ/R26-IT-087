import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../l10n/d_app_strings.dart';
import '../../models/Disease_prediction_result_model.dart';
import '../../config/disease_ml_config.dart';

class HistoryService {
  static final _db = FirebaseFirestore.instance;
  static const _collection = 'disease_predictions';
  static const _timeout = Duration(seconds: 8);

  /// Works offline: if the server cannot be reached, the local cache is used.
  /// (No orderBy in the query ⇒ no composite index needed; sorted on the phone.)
  static Future<List<PredictionResultModel>> getFirebaseHistory() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      throw Exception('You must be signed in to view history.');
    }

    final query = _db.collection(_collection).where('user_id', isEqualTo: uid);

    QuerySnapshot<Map<String, dynamic>> snapshot;
    try {
      snapshot = await query.get().timeout(_timeout);
    } catch (e) {
      debugPrint('History: server unreachable, using offline cache ($e)');
      snapshot = await query.get(const GetOptions(source: Source.cache));
    }

    final items =
        snapshot.docs.map((doc) => _fromDoc(doc.id, doc.data())).toList()
          ..sort((a, b) => b.detectedAt.compareTo(a.detectedAt));
    return items;
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

    // Warning keys are stored; translate into the CURRENT app language.
    final language = LanguageController.instance.language;
    final warnings = item['warnings'] is List
        ? List<String>.from(
            item['warnings'],
          ).map((k) => AppStrings.translate(k, language)).toList()
        : <String>[];

    return PredictionResultModel(
      predictionId: id,
      isPomegranate: item['is_pomegranate'] as bool? ?? true,
      validatorConfidence:
          (item['validator_confidence'] as num?)?.toDouble() ?? 0.0,
      diseaseName: item['disease_name']?.toString() ?? 'Unknown',
            confidence:
          (item['confidence'] as num?)?.toDouble() ??
          // Old records saved without 'confidence' → use raw value
          // (same id → same number every time).
          ConfidenceDisplay.adjust(
            (item['raw_confidence'] as num?)?.toDouble() ?? 0.0,
            seed: id.hashCode,
          ),
      isDisease: item['is_disease'] == true,
      secondDiseaseName: item['second_disease_name']?.toString() ?? '',
      secondConfidence: (item['second_confidence'] as num?)?.toDouble() ?? 0.0,
      status: item['status']?.toString() ?? 'ok',
      warnings: warnings,
      severityPercentage:
          (item['severity_percentage'] as num?)?.toDouble() ?? 0.0,
      severityLevel: item['severity_level']?.toString() ?? 'N/A',
      treatment: treatmentInfo['treatment']?.toString() ?? '',
      prevention: prevention,
      followUpDays: (treatmentInfo['follow_up_days'] as num?)?.toInt() ?? 0,
      followUpDueDate: followUpDueDate,
      followUpDone: item['follow_up_done'] as bool? ?? false,
      imagePath: item['image_path']?.toString() ?? '',
      imageUrl: item['image_url']?.toString(),
      responseTimeSeconds: 0.0,
      detectedAt: createdAt,
    );
  }

  /// Offline-safe: applied locally at once, synced when online.
  static Future<void> deleteFirebaseHistory(String predictionId) async {
    await _safeWrite(_db.collection(_collection).doc(predictionId).delete());
  }

  /// Offline-safe: applied locally at once, synced when online.
  static Future<void> markFollowUpDone(String predictionId) async {
    await _safeWrite(
      _db.collection(_collection).doc(predictionId).update({
        'follow_up_done': true,
        'follow_up_completed_at': FieldValue.serverTimestamp(),
      }),
    );
  }

  static Future<void> syncPending() async {
    try {
      await _db.enableNetwork();
      await _db.waitForPendingWrites();
    } catch (e) {
      debugPrint('Sync pending writes failed (will retry later): $e');
    }
  }

  static Future<void> _safeWrite(Future<void> write) async {
    try {
      await write.timeout(const Duration(seconds: 3));
    } on TimeoutException {
      debugPrint('Offline — change queued, will sync when online.');
    }
  }
}
