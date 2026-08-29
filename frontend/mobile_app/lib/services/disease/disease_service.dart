import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path_provider/path_provider.dart';

import '../../l10n/d_app_strings.dart';
import '../../models/Disease_prediction_result_model.dart';
import '../ml/model_inference_service.dart';
import 'treatment_data.dart';

class DiseaseService {
  static final _ml = ModelInferenceService.instance;
  static final _db = FirebaseFirestore.instance;
  static const _collection = 'disease_predictions'; // matches firestore.rules

  /// Full on-device pipeline: validate → classify → severity →
  /// treatment lookup → save every field to Firestore.
  ///
  /// Works offline: Firestore queues the write locally and syncs
  /// automatically when the connection returns — this call does not
  /// wait for the network, so the UI never blocks on a bad connection.
  static Future<PredictionResultModel> predictDisease(
    File imageFile, {
    AppLanguage language = AppLanguage.english,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      throw Exception('You must be signed in to run detection.');
    }

    // ── 1. Validate: is this actually a pomegranate? (binary model) ──
    final validation = await _ml.validatePomegranate(imageFile);
    final isPomegranate = validation.label == 'pomegranate';

    if (!isPomegranate) {
      throw Exception(
        'This does not look like a pomegranate fruit. '
        'Please capture a clear photo of a pomegranate.',
      );
    }

    // ── 2. Classify disease type (5-class model) ─────────────────────
    final classification = await _ml.classifyDisease(imageFile);
    final diseaseName = classification.label;
    final confidence = classification.confidence * 100;
    final isHealthy = diseaseName.toLowerCase() == 'healthy';

    // ── 3. Severity: level + percentage (segmentation model) ─────────
    double severityPct = 0.0;
    String severityLevel = 'N/A';

    if (!isHealthy) {
      final severity = await _ml.analyzeSeverity(imageFile);
      severityPct = severity.percentage;
      severityLevel = severity.level;
    }

    // ── 4. Treatment + prevention + follow-up days (local lookup) ────
    final info = TreatmentData.forDisease(diseaseName, language);

    // ── 5. Save the captured photo to app storage for History screen ─
    final savedImagePath = await _copyImageToAppStorage(imageFile);

    final now = DateTime.now();
    final followUpDueDate = now.add(Duration(days: info.followUpDays));

    // ── 6. Write EVERY field to Firestore ─────────────────────────────
    String? predictionId;
    try {
      final doc = await _db.collection(_collection).add({
        'user_id': uid,

        // Binary validator result
        'is_pomegranate': isPomegranate,
        'validator_confidence': validation.confidence * 100,

        // Disease classification
        'disease_name': diseaseName,
        'confidence': confidence,
        'is_disease': !isHealthy,

        // Severity
        'severity_percentage': severityPct,
        'severity_level': severityLevel,

        // Treatment / prevention / follow-up
        'treatment_info': {
          'treatment': info.treatment,
          'prevention': info.prevention,
          'follow_up_days': info.followUpDays,
        },
        'follow_up_due_date': followUpDueDate,
        'follow_up_done': false,

        // Language the treatment text was generated in
        'language': language.code,

        // Image + meta
        'image_path': savedImagePath,
        'created_at': FieldValue.serverTimestamp(),
        'created_at_local':
            now, // fallback if serverTimestamp is pending offline
      });
      predictionId = doc.id;
    } catch (e) {
      // ignore: avoid_print
      print('Firestore save queued/failed (will retry when online): $e');
    }

    return PredictionResultModel(
      predictionId: predictionId,
      isPomegranate: isPomegranate,
      validatorConfidence: validation.confidence * 100,
      diseaseName: diseaseName,
      confidence: confidence,
      isDisease: !isHealthy,
      severityPercentage: severityPct,
      severityLevel: severityLevel,
      treatment: info.treatment,
      prevention: info.prevention,
      followUpDays: info.followUpDays,
      followUpDueDate: followUpDueDate,
      followUpDone: false,
      imagePath: savedImagePath,
      responseTimeSeconds: 0.0,
      detectedAt: now,
    );
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
}
