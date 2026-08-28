// lib/services/grading/grading_firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../config/firestore_schema.dart';
import '../../models/grading_result.dart';

/// Handles saving/fetching fruit quality grading results in Firestore.
/// Online is the primary mode. Firestore's built-in offline cache
/// (enabled by default on Android/iOS) automatically queues writes and
/// serves cached reads when the network is weak or unavailable — no
/// extra offline-handling code is required here.
class GradingFirestoreService {
  GradingFirestoreService._();
  static final GradingFirestoreService instance = GradingFirestoreService._();

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  String? get _uid =>
      Firebase.apps.isEmpty ? null : FirebaseAuth.instance.currentUser?.uid;

  Future<GradingResult> saveResult(GradingResult result) async {
    final uid = _uid;
    if (uid == null) {
      throw Exception('Please log in before saving a grading result.');
    }

    final docRef = _db.collection(FirestoreSchema.qualityResults).doc();
    final now = DateTime.now().toIso8601String();

    final data = result.toJson()
      ..['user_id'] = uid
      ..['created_at'] = now;

    // If offline, Firestore queues this write locally and syncs it
    // automatically once connectivity returns.
    await docRef.set(data);

    return GradingResult(
      id: docRef.id,
      userId: uid,
      quality: result.quality,
      confidence: result.confidence,
      defectType: result.defectType,
      severityPercent: result.severityPercent,
      weightGrams: result.weightGrams,
      recommendation: result.recommendation,
      imageUrl: result.imageUrl,
      createdAt: now,
    );
  }

  Future<List<GradingResult>> getHistory(String userId) async {
    final snapshot = await _db
        .collection(FirestoreSchema.qualityResults)
        .where('user_id', isEqualTo: userId)
        .get();

    final results = snapshot.docs
        .map((doc) => GradingResult.fromJson({...doc.data(), 'id': doc.id}))
        .toList();

    // Sort client-side (avoids needing a Firestore composite index)
    results.sort((a, b) {
      final aDate = a.dateTime ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = b.dateTime ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });

    return results;
  }

  Future<void> deleteOne(String id) async {
    await _db.collection(FirestoreSchema.qualityResults).doc(id).delete();
  }

  Future<void> deleteAll(String userId) async {
    final snapshot = await _db
        .collection(FirestoreSchema.qualityResults)
        .where('user_id', isEqualTo: userId)
        .get();
    for (final doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }
}
