import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../config/api_config.dart';

class GrowthAdvisoryService {
  static Future<Map<String, dynamic>> getAdvisory({
    required String predictedClass,
    required double confidence,
    required Map<String, double> allProbabilities,
    required String captureDate,
    double lat = 9.7,
    double lon = 80.0,
    String? farmerId,
  }) async {
    final response = await http.post(
      Uri.parse(
        ApiConfig.growthAdvisory,
      ),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'predicted_class': predictedClass,
        'confidence': confidence,
        'all_probabilities': allProbabilities,
        'lat': lat,
        'lon': lon,
        'farmer_id': farmerId,
        'capture_date': captureDate,
      }),
    );

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(
        jsonDecode(response.body),
      );
    }

    throw Exception(
      'Growth advisory request failed: '
      '${response.statusCode} ${response.body}',
    );
  }
}