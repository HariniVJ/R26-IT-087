import 'dart:convert';
import 'package:http/http.dart' as http;

class FertilizerApiService {
  // Same backend IP as irrigation
  static const String baseUrl = 'http://192.168.1.100:8000';

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
          headers: {'Content-Type': 'application/json'},
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

    throw Exception('Backend error: ${response.statusCode}');
  }
}