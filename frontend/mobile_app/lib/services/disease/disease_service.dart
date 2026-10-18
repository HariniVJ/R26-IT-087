import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../../config/disease_ml_config.dart';
import '../../l10n/d_app_strings.dart';
import '../../models/Disease_prediction_result_model.dart';
import '../ml/disease_pipeline.dart';
import 'treatment_data.dart';

// Screens that `catch (NotPomegranateException e)` keep working unchanged.
export '../ml/detection_exceptions.dart';

class DiseaseService {
  static final _db = FirebaseFirestore.instance;
  static final _storage = FirebaseStorage.instance;
  static const _collection = 'disease_predictions';

  /// Max time to wait for Firestore. Offline, the write stays queued in the
  /// local cache and syncs automatically when the phone is online again.
  static const _writeTimeout = Duration(seconds: 3);

  /// Optional: call when the detection screen opens (faster first result).
  static Future<void> warmUpModels() => DiseasePipeline.instance.warmUp();

  static Future<PredictionResultModel> predictDisease(
    File imageFile, {
    AppLanguage language = AppLanguage.english,
  }) async {
    final stopwatch = Stopwatch()..start();

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      throw Exception('You must be signed in to run detection.');
    }

    // ── 1–4. On-device AI (offline): YOLO → validator → disease → rules ──
    // Throws NotPomegranateException for rejected photos.
    final out = await DiseasePipeline.instance.run(imageFile);

    final diseaseName = out.disease;
    //final confidence = out.confidence * 100;
    final rawConfidence = out.confidence * 100;
    final confidence = ConfidenceDisplay.adjust(rawConfidence);
    final isHealthy = out.isHealthy;

    // ── 5. Treatment + follow-up for every disease result ──
    //   Healthy → no treatment, no prevention list, no follow-up
    final info = TreatmentData.forDisease(
      diseaseName,
      language,
      severityLevel: out.severityLevel,
    );
    final needsTreatment = !isHealthy;
    final String treatment = needsTreatment
        ? info.treatment
        : AppStrings.translate('healthy_no_action', language);
    final prevention = needsTreatment ? info.prevention : <String>[];
    final followUpDays = needsTreatment ? info.followUpDays : 0;
    final warnings = out.warningKeys
        .map((k) => AppStrings.translate(k, language))
        .toList();

    // ── 6. Save image locally (works offline, used for display/history) ──
    final savedImagePath = await _copyImageToAppStorage(imageFile);

    final now = DateTime.now();
    final DateTime? followUpDueDate = needsTreatment
        ? now.add(Duration(days: followUpDays))
        : null;

    // ── 7. Firestore — ID is created on the phone, so this never blocks
    //       offline. The write is queued and synced later automatically. ──
    final docRef = _db.collection(_collection).doc();
    await _safeWrite(
      docRef.set({
        'user_id': uid,
        'is_pomegranate': true,
        'validator_confidence': out.pomegranateProbability * 100,
        'disease_name': diseaseName,
        'confidence': confidence, 
        'raw_confidence': rawConfidence, 
        'second_disease_name': out.secondDisease,
        'second_confidence': out.secondConfidence * 100,
        'status': out.isUncertain ? 'uncertain' : 'ok',
        'warnings': out.warningKeys,
        'is_disease': !isHealthy,
        'severity_percentage': out.severityPercent,
        'severity_level': out.severityLevel,
        'treatment_info': {
          'treatment': treatment,
          'prevention': prevention,
          'follow_up_days': followUpDays,
        },
        'needs_treatment': needsTreatment,
        'follow_up_due_date': followUpDueDate,
        'follow_up_done': false,
        'language': language.code,
        'image_path': savedImagePath,
        'image_url': null, // filled in by the background upload below
        'model_version': DiseaseModels.version,
        'created_at': FieldValue.serverTimestamp(),
        'created_at_local': now,
      }),
    );

    // ── 8. Upload image in the background (does not block the result) ──
    unawaited(_uploadInBackground(docRef, File(savedImagePath), uid));

    stopwatch.stop();

    return PredictionResultModel(
      predictionId: docRef.id,
      isPomegranate: true,
      validatorConfidence: out.pomegranateProbability * 100,
      diseaseName: diseaseName,
      confidence: confidence,
      isDisease: !isHealthy,
      secondDiseaseName: out.secondDisease,
      secondConfidence: out.secondConfidence * 100,
      status: out.isUncertain ? 'uncertain' : 'ok',
      warnings: warnings,
      severityPercentage: out.severityPercent,
      severityLevel: out.severityLevel,
      treatment: treatment,
      prevention: prevention,
      followUpDays: followUpDays,
      followUpDueDate: followUpDueDate,
      followUpDone: false,
      imagePath: savedImagePath,
      imageUrl: null,
      responseTimeSeconds: stopwatch.elapsedMilliseconds / 1000.0,
      detectedAt: now,
    );
  }

  /// Waits a short time for Firestore; offline it simply continues
  /// (the write is already in the local cache and will sync later).
  static Future<void> _safeWrite(Future<void> write) async {
    try {
      await write.timeout(_writeTimeout);
    } on TimeoutException {
      debugPrint('Firestore offline — write queued, will sync when online.');
    } catch (e) {
      debugPrint('Firestore write failed: $e');
    }
  }

  static Future<void> _uploadInBackground(
    DocumentReference<Map<String, dynamic>> docRef,
    File file,
    String uid,
  ) async {
    try {
      final url = await _uploadImageToStorage(file, uid);
      await _safeWrite(docRef.update({'image_url': url}));
    } catch (e) {
      debugPrint(
        'Image upload failed (history thumbnail will use local file): $e',
      );
    }
  }

  static Future<String> _copyImageToAppStorage(File source) async {
    final dir = await getApplicationDocumentsDirectory();
    final folder = Directory('${dir.path}/detections');
    if (!await folder.exists()) {
      await folder.create(recursive: true);
    }
    final fileName = 'detection_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final saved = await source.copy('${folder.path}/$fileName');
    return saved.path;
  }

  static Future<String> _uploadImageToStorage(File file, String uid) async {
    final fileName = 'detection_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = _storage.ref().child('disease_predictions/$uid/$fileName');
    final uploadTask = await ref.putFile(
      file,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    return await uploadTask.ref.getDownloadURL();
  }
}
