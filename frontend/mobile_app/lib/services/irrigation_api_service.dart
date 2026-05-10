import 'dart:convert';
import 'package:http/http.dart' as http;

class IrrigationApiService {
  // Local laptop backend for development:
  static const String baseUrl = 'http://192.168.1.100:8000';

  // Later cloud backend example:
  // static const String baseUrl = 'https://your-backend-name.onrender.com';

  static Future<Map<String, dynamic>> predictIrrigation({
    required double soilMoisture,
    required double latitude,
    required double longitude,
  }) async {
    final url = Uri.parse('$baseUrl/predict-irrigation');

    final response = await http
        .post(
          url,
          headers: {'Content-Type': 'application/json'},
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

    throw Exception('Backend error: ${response.statusCode}');
  }
}
