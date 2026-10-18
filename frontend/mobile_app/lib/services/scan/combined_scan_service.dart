// lib/services/scan/combined_scan_service.dart
//
// Saves the quick-scan result (Growth + Quality + Disease) so it appears
// in History → "All". Works offline: the image is copied to the phone,
// the Firestore write is queued, and the image upload happens in the
// background when possible.
import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class CombinedScanService {
  CombinedScanService._();
  static final instance = CombinedScanService._();

  static const collection = 'combined_scans';
  static const _writeTimeout = Duration(seconds: 3);

  final _db = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

  /// Saves one combined scan. [data] holds the result fields
  /// (growth_*, quality_*, disease_*). Returns the document id.
  Future<String?> save({
    required File image,
    required Map<String, dynamic> data,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;

    final localPath = await _keepLocalCopy(image);
    final docRef = _db.collection(collection).doc();
    final now = DateTime.now();

    try {
      await docRef
          .set({
            ...data,
            'user_id': uid,
            'image_path': localPath,
            'image_url': null,
            'created_at': FieldValue.serverTimestamp(),
            'created_at_local': now,
          })
          .timeout(_writeTimeout);
    } on TimeoutException {
      debugPrint('Offline — combined scan queued, will sync later.');
    } catch (e) {
      debugPrint('Combined scan save failed: $e');
      return null;
    }

    unawaited(_uploadInBackground(docRef, File(localPath), uid));
    return docRef.id;
  }

  /// All combined scans of the current user, newest first.
  /// (Sorted on the phone, so no Firestore composite index is needed.)
  Future<List<Map<String, dynamic>>> getHistory() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return [];

    final query = _db.collection(collection).where('user_id', isEqualTo: uid);
    QuerySnapshot<Map<String, dynamic>> snap;
    try {
      snap = await query.get().timeout(const Duration(seconds: 4));
    } catch (_) {
      snap = await query.get(const GetOptions(source: Source.cache));
    }

    final rows = snap.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
    rows.sort((a, b) => dateOf(b).compareTo(dateOf(a)));
    return rows;
  }

  static DateTime dateOf(Map<String, dynamic> row) {
    for (final key in ['created_at', 'created_at_local']) {
      final v = row[key];
      if (v is Timestamp) return v.toDate();
      if (v is DateTime) return v;
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  Future<String> _keepLocalCopy(File source) async {
    final dir = await getApplicationDocumentsDirectory();
    final folder = Directory('${dir.path}/combined_scans');
    if (!await folder.exists()) await folder.create(recursive: true);
    final name = 'scan_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final saved = await source.copy('${folder.path}/$name');
    return saved.path;
  }

  Future<void> _uploadInBackground(
    DocumentReference<Map<String, dynamic>> docRef,
    File file,
    String uid,
  ) async {
    try {
      final ref = _storage.ref('combined_scans/$uid/${docRef.id}.jpg');
      await ref.putFile(file, SettableMetadata(contentType: 'image/jpeg'));
      final url = await ref.getDownloadURL();
      await docRef.update({'image_url': url}).timeout(_writeTimeout);
    } catch (e) {
      debugPrint('Combined scan image upload failed (local file kept): $e');
    }
  }
}
