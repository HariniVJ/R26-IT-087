// lib/services/grading/grading_firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../config/firestore_schema.dart';
import '../../models/grading_result.dart';

/// Saves / fetches fruit quality grading results in Firestore.
/// Firestore's offline cache (on by default on Android/iOS) queues writes
/// and serves cached reads when the network is weak or unavailable.
class GradingFirestoreService {
  GradingFirestoreService._();
  static final GradingFirestoreService instance = GradingFirestoreService._();

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(FirestoreSchema.qualityResults);

  String? get _uid =>
      Firebase.apps.isEmpty ? null : FirebaseAuth.instance.currentUser?.uid;

  Future<GradingResult> saveResult(GradingResult result) async {
    final uid = _uid;
    if (uid == null) {
      throw Exception('Please log in before saving a grading result.');
    }

    final docRef = _col.doc();
    final now = DateTime.now().toIso8601String();

    final data = result.toJson()
      ..['user_id'] = uid
      ..['created_at'] = now;

    // Offline → queued locally and synced automatically later.
    await docRef.set(data);

    // Built from the exact map that was written, so every saved field
    // (including disease fields) is returned and can never drift.
    return GradingResult.fromJson({...data, 'id': docRef.id});
  }

  Future<List<GradingResult>> getHistory(String userId) async {
    final snapshot = await _col.where('user_id', isEqualTo: userId).get();

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
    await _col.doc(id).delete();
  }

  /// Updates any fields of a saved record (used to attach the Disease
  /// component's finding + recalculated recommendation).
  Future<void> updateFields(String id, Map<String, dynamic> fields) async {
    await _col.doc(id).update(fields);
  }

  /// Older call — name / treatment / prevention only.
  Future<void> attachDiseaseInfo({
    required String id,
    required String diseaseName,
    required String treatment,
    required List<String> prevention,
  }) async {
    await _col.doc(id).update({
      'disease_name': diseaseName,
      'disease_treatment': treatment,
      'disease_prevention': prevention,
    });
  }

  Future<void> deleteAll(String userId) async {
    final snapshot = await _col.where('user_id', isEqualTo: userId).get();
    for (final doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }
}
