// lib/services/grading_service.dart
import 'dart:io';
import '../models/grading_result.dart';
import 'local_db_service.dart';

class GradingService {
  final LocalDbService _db = LocalDbService();

  Future<void> init() async {
    await _db.init();
  }

  /// Saves a completed grading result to local offline history.
  /// Called by the UI screen after TfliteService.predict() returns.
  Future<GradingResult> saveResult({
    required String userId,
    required String quality,
    required double confidence,
    File? imageFile,
    String? defectType,
    double? severityPercent,
    int? weightGrams,
  }) async {
    final ruleRow = await _db.getRecommendation(
      quality: quality,
      defectType: defectType,
      severityPercent: severityPercent,
      weightGrams: weightGrams,
    );

    final recommendation =
        ruleRow?["recommended_usage"] as String? ??
        "Manual inspection recommended";

    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final result = GradingResult(
      id: id,
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

    await _db.saveHistory(result.toJson()..["id"] = id);
    return result;
  }

  Future<List<GradingResult>> getHistory(String userId) async {
    final rows = await _db.getHistory(userId);
    return rows.map((r) => GradingResult.fromJson(r)).toList();
  }

  Future<void> deleteOne(String id) async {
    await _db.deleteOne(id);
  }

  Future<void> deleteAll(String userId) async {
    await _db.deleteAll(userId);
  }
}
