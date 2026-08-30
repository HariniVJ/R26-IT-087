import 'dart:io';

import '../disease/disease_service.dart';
import '../../models/Disease_prediction_result_model.dart';

/// Bridges the Grading component to the Disease component: when a
/// fruit is graded as "Low" quality, this runs the SAME image through
/// the already-built disease detection pipeline (pomegranate
/// validation -> 5-class classifier -> severity -> treatment lookup)
/// so the low-quality popup can explain WHY it's low quality and what
/// to do about it.
class GradingDiseaseBridgeService {
  GradingDiseaseBridgeService._();
  static final GradingDiseaseBridgeService instance =
      GradingDiseaseBridgeService._();

  Future<PredictionResultModel?> getDiseaseInfoForLowQuality(
    File imageFile,
  ) async {
    try {
      return await DiseaseService.predictDisease(imageFile);
    } catch (e) {
      // If pomegranate validation or disease detection fails for any
      // reason (e.g. binary validator rejects it), we simply skip the
      // popup — the grading result itself is shown regardless.
      // ignore: avoid_print
      print('Disease bridge lookup failed: $e');
      return null;
    }
  }
}
