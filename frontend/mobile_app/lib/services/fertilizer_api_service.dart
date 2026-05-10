import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class FertilizerApiService {
  static String get baseUrl {
    final url = dotenv.env['API_BASE_URL'];

    if (url == null || url.isEmpty) {
      throw Exception('API_BASE_URL is missing in .env file');
    }

    return url;
  }

  static Future<Map<String, dynamic>> predictFertilizer({
    required double moisture,
    required double temp,
    required double ec,
    required double ph,
    required double nitrogen,
    required double phosphorus,
    required double potassium,
    required double treeAge,
  }) async {
    final url = Uri.parse('$baseUrl/predict-fertilizer');

    final response = await http
        .post(
          url,
          headers: {
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'moisture': moisture,
            'temp': temp,
            'ec': ec,
            'ph': ph,
            'nitrogen': nitrogen,
            'phosphorus': phosphorus,
            'potassium': potassium,
            'tree_age': treeAge,
          }),
        )
        .timeout(const Duration(seconds: 8));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      data['mode'] = 'online';
      return data;
    }

    throw Exception('Backend error: ${response.statusCode}: ${response.body}');
  }
}