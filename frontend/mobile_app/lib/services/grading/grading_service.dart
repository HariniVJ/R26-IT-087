// lib/services/grading/grading_service.dart
import 'dart:io';
import '../../models/grading_result.dart';
import 'grading_firestore_service.dart';
import 'recommendation_service.dart';

class GradingService {
  final GradingFirestoreService _firestore = GradingFirestoreService.instance;
  final RecommendationService _recommendation = RecommendationService.instance;

  Future<void> init() async {
    
  }

  Future<GradingResult> saveResult({
    required String userId,
    required String quality,
    required double confidence,
    File? imageFile,
    String? defectType,
    double? severityPercent,
    int? weightGrams,
  }) async {
    final ruleRow = await _recommendation.getRecommendation(
      quality: quality,
      defectType: defectType,
      severityPercent: severityPercent,
      weightGrams: weightGrams,
    );

    final recommendation =
        ruleRow?['recommended_usage'] as String? ??
        'Manual inspection recommended';

    final draft = GradingResult(
      id: '',
      userId: userId,
      quality: quality,
      confidence: confidence,
      defectType: defectType,
      severityPercent: severityPercent,
      weightGrams: weightGrams,
      recommendation: recommendation,
      imageUrl: null,
      createdAt: DateTime.now().toIso8601String(),
    );

    return await _firestore.saveResult(draft);
  }

  Future<List<GradingResult>> getHistory(String userId) =>
      _firestore.getHistory(userId);

  Future<void> deleteOne(String id) => _firestore.deleteOne(id);

  Future<void> deleteAll(String userId) => _firestore.deleteAll(userId);
}
