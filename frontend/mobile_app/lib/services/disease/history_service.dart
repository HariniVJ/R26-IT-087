import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../models/prediction_result_model.dart';

class HistoryService {
  static const String baseUrl = 'http://172.20.10.7:8000';
  static const String userId = 'user001';

  static Future<List<String>> getAllDiseases() async {
    final uri = Uri.parse('$baseUrl/api/disease/all-diseases');
    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Failed to load diseases');
    }

    final data = jsonDecode(response.body);
    final List items = data['data'] ?? [];

    return items.map((item) => item['disease_name'].toString()).toList();
  }

  static Future<List<PredictionResultModel>> getFirebaseHistory() async {
    final uri = Uri.parse('$baseUrl/api/disease/history/$userId');
    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Failed to load history: ${response.body}');
    }

    final data = jsonDecode(response.body);
    final List items = data['data'] ?? [];

    return items.map((item) {
      final treatmentInfo = item['treatment_info'] ?? {};
      String treatmentText = treatmentInfo['treatment'] ?? '';

      if (treatmentInfo['prevention'] != null) {
        final preventionList = List<String>.from(treatmentInfo['prevention']);
        treatmentText +=
            '\n\nPrevention:\n${preventionList.map((e) => '• $e').join('\n')}';
      }

      return PredictionResultModel(
        predictionId: item['prediction_id'],
        diseaseName: item['disease_name'] ?? 'Unknown',
        confidence: (item['confidence'] ?? 0).toDouble(),
        treatment: treatmentText,
        imagePath: '',
        detectedAt:
            DateTime.tryParse(item['created_at'] ?? '') ?? DateTime.now(),
      );
    }).toList();
  }

  static Future<void> deleteFirebaseHistory(String predictionId) async {
    final uri = Uri.parse('$baseUrl/api/disease/history/$predictionId');
    final response = await http.delete(uri);

    if (response.statusCode != 200) {
      throw Exception('Delete failed: ${response.body}');
    }

    final data = jsonDecode(response.body);
    if (data['success'] != true) {
      throw Exception(data['message'] ?? 'Delete failed');
    }
  }

  static void addHistory(PredictionResultModel result) {}
}
