import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/prediction_result_model.dart';

class HistoryService {
  static const String baseUrl = 'http://127.0.0.1:8000';
  static const String userId = 'user001';

  static final List<PredictionResultModel> _localHistory = [];

  static void addHistory(PredictionResultModel result) {
    _localHistory.insert(0, result);
  }

  static List<PredictionResultModel> getHistory() {
    return _localHistory;
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
        diseaseName: item['disease_name'] ?? 'Unknown',
        confidence: (item['confidence'] ?? 0).toDouble(),
        treatment: treatmentText,
        imagePath: '',
        detectedAt:
            DateTime.tryParse(item['created_at'] ?? '') ?? DateTime.now(),
      );
    }).toList();
  }

  static void deleteItem(int index) {
    _localHistory.removeAt(index);
  }

  static void clearAll() {
    _localHistory.clear();
  }
}
