import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class IrrigationApiService {
  static String get baseUrl {
    final url = dotenv.env['API_BASE_URL'];

    if (url == null || url.isEmpty) {
      throw Exception('API_BASE_URL is missing in .env file');
    }

    return url;
  }

  static Future<Map<String, dynamic>> predictIrrigation({
    required double soilMoisture,
    required double latitude,
    required double longitude,
  }) async {
    final url = Uri.parse('$baseUrl/predict-irrigation');

    final response = await http
        .post(
          url,
          headers: {
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'soil_moisture': soilMoisture,
            'latitude': latitude,
            'longitude': longitude,
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