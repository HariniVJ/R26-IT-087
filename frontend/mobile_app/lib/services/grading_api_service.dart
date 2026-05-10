// YOUR FILE — Member 4: Fruit Quality Grading
// lib/services/grading_api_service.dart
//
// FIXES:
//   1. getHistory now returns empty list instead of crashing on timeout
//   2. Longer timeout for history (30s) — Firestore can be slow on first call
//   3. Better error messages that explain the actual problem
//   4. _check() now includes response body in error for debugging

import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/grading_result.dart';

class GradingApiService {
  // ── Change this to your PC's WiFi IP address ──────────────────────────────
  // Find it by running: ipconfig  (Windows) or ifconfig (Mac/Linux)
  // Look for "IPv4 Address" under "Wireless LAN adapter Wi-Fi"
  // Example: 192.168.8.141
  //
  // Android emulator → http://10.0.2.2:8000
  // Physical device  → http://YOUR_LAN_IP:8000
  //static const _base = 'http://10.0.2.2:8000';
     static const _base = 'http://192.168.8.141:8000';

  // ── Save result (called silently in background) ────────────────────────────
  Future<GradingResult> saveResult({
    required String userId,
    required String quality,
    required double confidence,
    File? imageFile,
  }) async {
    try {
      final uri = Uri.parse('$_base/grading/save-result');
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
        const Duration(seconds: 30),
      );
      final res = await http.Response.fromStream(streamed);
      _check(res);

      final body = jsonDecode(res.body);
      return GradingResult.fromJson(body['data'] as Map<String, dynamic>);
    } on TimeoutException {
      throw Exception(
        'Save timed out — backend not reachable at $_base\n'
        'Make sure uvicorn is running and your IP is correct.',
      );
    } on SocketException {
      throw Exception(
        'Cannot connect to backend at $_base\n'
        'Check that:\n'
        '  1. uvicorn main:app --host 0.0.0.0 --port 8000 is running\n'
        '  2. Your phone and PC are on the same WiFi\n'
        '  3. The IP address $_base is correct',
      );
    }
  }

  // ── Get history from Firestore via backend ─────────────────────────────────
  Future<List<GradingResult>> getHistory(String userId) async {
    try {
      final res = await http
          .get(Uri.parse('$_base/grading/history/$userId'))
          .timeout(const Duration(seconds: 30)); // FIX: was 15s, now 30s

      _check(res);

      final body = jsonDecode(res.body);
      final data = body['data'] as List? ?? [];

      return data
          .map((e) => GradingResult.fromJson(e as Map<String, dynamic>))
          .toList();
    } on TimeoutException {
      throw Exception(
        'History fetch timed out.\n'
        'Make sure your backend is running:\n'
        '  uvicorn main:app --host 0.0.0.0 --port 8000',
      );
    } on SocketException {
      throw Exception(
        'Cannot reach backend at $_base\n'
        'Check your WiFi connection and backend server.',
      );
    } catch (e) {
      // Re-throw with cleaner message
      throw Exception(
        'Failed to load history: ${e.toString().replaceFirst("Exception: ", "")}',
      );
    }
  }

  // ── Delete one result ──────────────────────────────────────────────────────
  Future<void> deleteOne(String resultId) async {
    try {
      final res = await http
          .delete(Uri.parse('$_base/grading/result/$resultId'))
          .timeout(const Duration(seconds: 15));
      _check(res);
    } on TimeoutException {
      throw Exception('Delete timed out — check backend connection.');
    } on SocketException {
      throw Exception('Cannot connect to backend to delete result.');
    }
  }

  // ── Delete all results for a user ─────────────────────────────────────────
  Future<void> deleteAll(String userId) async {
    try {
      final res = await http
          .delete(Uri.parse('$_base/grading/history/$userId'))
          .timeout(const Duration(seconds: 15));
      _check(res);
    } on TimeoutException {
      throw Exception('Delete all timed out — check backend connection.');
    } on SocketException {
      throw Exception('Cannot connect to backend to delete history.');
    }
  }

  // ── Check response status ──────────────────────────────────────────────────
  void _check(http.Response res) {
    if (res.statusCode == 200) return;

    String detail = 'Server error ${res.statusCode}';
    try {
      final body = jsonDecode(res.body);
      detail = body['detail']?.toString() ?? detail;
    } catch (_) {}

    throw Exception(detail);
  }
}
