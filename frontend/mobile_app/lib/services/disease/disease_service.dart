import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';

import '../../l10n/d_app_strings.dart';
import '../../models/Disease_prediction_result_model.dart';
import '../ml/model_inference_service.dart';
import '../ml/binary_validator_service.dart';
import 'treatment_data.dart';

class DiseaseService {
  static final _validator = BinaryValidatorService.instance;
  static final _ml = ModelInferenceService.instance;
  static final _db = FirebaseFirestore.instance;
  static final _storage = FirebaseStorage.instance;
  static const _collection = 'disease_predictions';

  static Future<PredictionResultModel> predictDisease(
    File imageFile, {
    AppLanguage language = AppLanguage.english,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      throw Exception('You must be signed in to run detection.');
    }

    // ── 1. Validate: is this actually a pomegranate? ──────────────────
    final validation = await _validator.validate(imageFile);

    if (!validation.isPomegranate) {
      throw Exception(
        'This does not look like a pomegranate fruit '
        '(${(validation.confidence * 100).toStringAsFixed(1)}% confidence). '
        'Please capture a clear photo of a pomegranate.',
      );
    }

    // ── 2. Classify disease type ────────────────────────────────────
    final classification = await _ml.classifyDisease(imageFile);
    final diseaseName = classification.label;
    final confidence = classification.confidence * 100;
    final isHealthy = diseaseName.toLowerCase() == 'healthy';

    // ── 3. Severity ────────────────────────────────────────────────
    double severityPct = 0.0;
    String severityLevel = 'N/A';

    if (!isHealthy) {
      final severity = await _ml.analyzeSeverity(imageFile);
      severityPct = severity.percentage;
      severityLevel = severity.level;
    }

    // ── 4. Treatment ───────────────────────────────────────────────
    final info = TreatmentData.forDisease(diseaseName, language);

    // ── 5. Save image locally (for immediate display) ────────────────
    final savedImagePath = await _copyImageToAppStorage(imageFile);

    // ── 6. Upload image to Firebase Storage (for history/cross-device) ──
    String? imageUrl;
    try {
      imageUrl = await _uploadImageToStorage(imageFile, uid);
    } catch (e) {
      // ignore: avoid_print
      print('Image upload failed (history thumbnail will be unavailable): $e');
    }

    final now = DateTime.now();
    final followUpDueDate = now.add(Duration(days: info.followUpDays));

    // ── 7. Write to Firestore ──────────────────────────────────────
    String? predictionId;
    try {
      final doc = await _db.collection(_collection).add({
        'user_id': uid,
        'is_pomegranate': validation.isPomegranate,
        'validator_confidence': validation.confidence * 100,
        'disease_name': diseaseName,
        'confidence': confidence,
        'is_disease': !isHealthy,
        'severity_percentage': severityPct,
        'severity_level': severityLevel,
        'treatment_info': {
          'treatment': info.treatment,
          'prevention': info.prevention,
          'follow_up_days': info.followUpDays,
        },
        'follow_up_due_date': followUpDueDate,
        'follow_up_done': false,
        'language': language.code,
        'image_path': savedImagePath,
        'image_url': imageUrl, // <-- Firebase Storage download URL
        'created_at': FieldValue.serverTimestamp(),
        'created_at_local': now,
      });
      predictionId = doc.id;
    } catch (e) {
      // ignore: avoid_print
      print('Firestore save queued/failed (will retry when online): $e');
    }

    return PredictionResultModel(
      predictionId: predictionId,
      isPomegranate: validation.isPomegranate,
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
      imageUrl: imageUrl,
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
