import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../config/api_config.dart';
import '../../models/grading_result.dart';

class GradingApiService {
  Future<GradingResult> saveResult({
    required String userId,
    required String quality,
    required double confidence,
    File? imageFile,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.grading}/save-result');

      final request = http.MultipartRequest('POST', uri)
        ..fields['user_id'] = userId
        ..fields['quality'] = quality
        ..fields['confidence'] = confidence.toString();

      if (imageFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath('file', imageFile.path),
        );
      }

      final streamed = await request.send().timeout(
        const Duration(seconds: 40),
      );
      final res = await http.Response.fromStream(streamed);

      _check(res);

      final body = jsonDecode(res.body);
      return GradingResult.fromJson(body['data']);
    } on SocketException {
      throw Exception('Cannot connect backend: ${ApiConfig.baseUrl}');
    } on TimeoutException {
      throw Exception('Backend timeout: ${ApiConfig.baseUrl}');
    }
  }

  Future<List<GradingResult>> getHistory(String userId) async {
    try {
      final res = await http
          .get(Uri.parse('${ApiConfig.grading}/history/$userId'))
          .timeout(const Duration(seconds: 40));

      _check(res);

      final body = jsonDecode(res.body);
      final data = body['data'] as List? ?? [];

      return data.map((e) => GradingResult.fromJson(e)).toList();
    } on SocketException {
      throw Exception('Cannot fetch history. Backend offline.');
    } on TimeoutException {
      throw Exception('History loading timeout.');
    }
  }

  Future<void> deleteOne(String resultId) async {
    final res = await http.delete(
      Uri.parse('${ApiConfig.grading}/result/$resultId'),
    );
    _check(res);
  }

  Future<void> deleteAll(String userId) async {
    final res = await http.delete(
      Uri.parse('${ApiConfig.grading}/history/$userId'),
    );
    _check(res);
  }

  void _check(http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) return;

    String msg = 'Server error ${res.statusCode}';
    try {
      final body = jsonDecode(res.body);
      msg = body['detail']?.toString() ?? msg;
    } catch (_) {}

    throw Exception(msg);
  }
}
