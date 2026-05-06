// YOUR FILE — Member 4: Fruit Quality Grading
// lib/services/grading_api_service.dart

import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/grading_result.dart';

class GradingApiService {
  // Android emulator  → http://10.0.2.2:8000
  // Physical device   → http://YOUR_LAN_IP:8000
  // iOS simulator     → http://127.0.0.1:8000
  static const _base = 'http://192.168.8.141:8000';

  Future<GradingResult> saveResult({
    required String userId,
    required String quality,
    required double confidence,
    File? imageFile,
  }) async {
    final uri     = Uri.parse('$_base/grading/save-result');
    final request = http.MultipartRequest('POST', uri)
      ..fields['user_id']    = userId
      ..fields['quality']    = quality
      ..fields['confidence'] = confidence.toString();

    if (imageFile != null) {
      request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));
    }

    final streamed = await request.send().timeout(const Duration(seconds: 30));
    final res      = await http.Response.fromStream(streamed);
    _check(res);
    final body = jsonDecode(res.body);
    return GradingResult.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<List<GradingResult>> getHistory(String userId) async {
    final res = await http.get(Uri.parse('$_base/grading/history/$userId'))
        .timeout(const Duration(seconds: 15));
    _check(res);
    final body = jsonDecode(res.body);
    return (body['data'] as List)
        .map((e) => GradingResult.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> deleteOne(String resultId) async {
    final res = await http.delete(Uri.parse('$_base/grading/result/$resultId'))
        .timeout(const Duration(seconds: 15));
    _check(res);
  }

  Future<void> deleteAll(String userId) async {
    final res = await http.delete(Uri.parse('$_base/grading/history/$userId'))
        .timeout(const Duration(seconds: 15));
    _check(res);
  }

  void _check(http.Response res) {
    if (res.statusCode != 200) {
      final body = jsonDecode(res.body);
      throw Exception(body['detail'] ?? 'Server error ${res.statusCode}');
    }
  }
}