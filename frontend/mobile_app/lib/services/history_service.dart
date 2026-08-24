import 'dart:convert';

import 'package:http/http.dart' as http;

import '../common/api_config.dart';
import '../models/prediction_result_model.dart';

class HistoryService {
  // Temporary demo user.
  // Later replace with actual logged-in user ID.
  static const String userId = 'user001';

  /// -------------------------------------------
  /// GET ALL AVAILABLE DISEASES
  /// -------------------------------------------
  static Future<List<String>> getAllDiseases() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/disease/all-diseases');

    try {
      final response = await http.get(uri);

      final data = jsonDecode(response.body);

      if (response.statusCode != 200) {
        throw Exception(
          data['detail'] ?? data['message'] ?? 'Failed to load diseases',
        );
      }

      if (data['success'] != true) {
        throw Exception(data['message'] ?? 'Failed to load diseases');
      }

      final List items = data['data'] is List ? data['data'] : [];

      return items.map<String>((item) {
        if (item is Map && item['disease_name'] != null) {
          return item['disease_name'].toString();
        }

        return item.toString();
      }).toList();
    } catch (e) {
      throw Exception('Failed to load diseases: $e');
    }
  }

  /// -------------------------------------------
  /// GET USER DETECTION HISTORY
  /// -------------------------------------------
  static Future<List<PredictionResultModel>> getFirebaseHistory() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/disease/history/$userId');

    try {
      final response = await http.get(uri);

      final data = jsonDecode(response.body);

      if (response.statusCode != 200) {
        throw Exception(
          data['detail'] ?? data['message'] ?? 'Failed to load history',
        );
      }

      if (data['success'] != true) {
        throw Exception(data['message'] ?? 'Failed to load history');
      }

      final List items = data['data'] is List ? data['data'] : [];

      return items.map<PredictionResultModel>((rawItem) {
        final Map<String, dynamic> item = Map<String, dynamic>.from(
          rawItem as Map,
        );

        // -------------------------
        // Treatment
        // -------------------------
        final dynamic rawTreatmentInfo = item['treatment_info'];

        final Map<String, dynamic> treatmentInfo = rawTreatmentInfo is Map
            ? Map<String, dynamic>.from(rawTreatmentInfo)
            : <String, dynamic>{};

        final String treatment = treatmentInfo['treatment']?.toString() ?? '';

        // -------------------------
        // Prevention
        // -------------------------
        List<String> prevention = [];

        final preventionRaw = treatmentInfo['prevention'];

        if (preventionRaw is List) {
          prevention = preventionRaw.map((e) => e.toString()).toList();
        } else if (preventionRaw is String && preventionRaw.trim().isNotEmpty) {
          prevention = [preventionRaw];
        }

        // -------------------------
        // Follow-up
        // -------------------------
        final dynamic followUpRaw =
            treatmentInfo['follow_up_days'] ?? item['follow_up_days'];

        int followUpDays = 0;

        if (followUpRaw is int) {
          followUpDays = followUpRaw;
        } else if (followUpRaw is num) {
          followUpDays = followUpRaw.toInt();
        } else if (followUpRaw != null) {
          followUpDays = int.tryParse(followUpRaw.toString()) ?? 0;
        }

        // -------------------------
        // Severity
        // -------------------------
        final double severityPercentage = _toDouble(
          item['severity_percentage'] ?? item['severity_percent'] ?? 0,
        );

        final String severityLevel =
            item['severity_level']?.toString() ?? 'N/A';

        // -------------------------
        // Date
        // -------------------------
        final DateTime detectedAt =
            DateTime.tryParse(item['created_at']?.toString() ?? '') ??
            DateTime.now();

        return PredictionResultModel(
          predictionId: item['prediction_id']?.toString(),

          diseaseName: item['disease_name']?.toString() ?? 'Unknown',

          confidence: _toDouble(item['confidence']),

          isDisease: item['is_disease'] == true,

          severityPercentage: severityPercentage,

          severityLevel: severityLevel,

          treatment: treatment,

          prevention: prevention,

          followUpDays: followUpDays,

          // Your backend currently does not
          // return stored image path/URL.
          imagePath:
              item['image_url']?.toString() ??
              item['image_path']?.toString() ??
              '',

          segmentationImageUrl: item['segmentation_image_url']?.toString(),

          gradCamImageUrl: item['gradcam_image_url']?.toString(),

          responseTimeSeconds: _toDouble(item['response_time_seconds']),

          detectedAt: detectedAt,
        );
      }).toList();
    } catch (e) {
      throw Exception('Failed to load history: $e');
    }
  }

  /// -------------------------------------------
  /// DELETE HISTORY
  /// -------------------------------------------
  static Future<void> deleteFirebaseHistory(String predictionId) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/disease/history/$predictionId',
    );

    try {
      final response = await http.delete(uri);

      final data = jsonDecode(response.body);

      if (response.statusCode != 200) {
        throw Exception(data['detail'] ?? data['message'] ?? 'Delete failed');
      }

      if (data['success'] != true) {
        throw Exception(data['message'] ?? 'Delete failed');
      }
    } catch (e) {
      throw Exception('Delete failed: $e');
    }
  }

  /// Safe conversion of dynamic backend values.
  static double _toDouble(dynamic value) {
    if (value == null) {
      return 0.0;
    }

    if (value is double) {
      return value;
    }

    if (value is int) {
      return value.toDouble();
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString()) ?? 0.0;
  }
}
