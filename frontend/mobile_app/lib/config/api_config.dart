import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  static String get baseUrl {
    final url = dotenv.env['API_BASE_URL'];
    if (url == null || url.trim().isEmpty) {
      throw Exception('API_BASE_URL missing in .env file');
    }
    return url.trim();
  }

  static String get grading => '$baseUrl/grading';
  static String get growthAdvisory => '$baseUrl/api/growth/advisory';
}
