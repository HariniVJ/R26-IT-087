import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../common/api_config.dart';
import '../../models/prediction_result_model.dart';

class DiseaseService {
  /// Upload image and run complete disease analysis.
  ///
  /// Backend:
  /// POST /api/disease/upload-and-analyze
  static Future<PredictionResultModel> predictDisease(File imageFile) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/disease/upload-and-analyze',
    );

    try {
      final request = http.MultipartRequest('POST', uri);

      // Temporary demo user.
      // Later replace with logged-in Firebase UID.
      request.fields['user_id'] = 'user001';

      request.files.add(
        await http.MultipartFile.fromPath('file', imageFile.path),
      );

      final streamedResponse = await request.send();

      final response = await http.Response.fromStream(streamedResponse);

      Map<String, dynamic> data = {};

      try {
        data = jsonDecode(response.body);
      } catch (_) {
        throw Exception('Invalid response received from the server.');
      }

      // -----------------------------
      // Backend HTTP error
      // -----------------------------
      if (response.statusCode != 200) {
        String message = 'Disease analysis failed';

        if (data['detail'] != null) {
          message = data['detail'].toString();
        } else if (data['message'] != null) {
          message = data['message'].toString();
        }

        throw Exception(message);
      }

      // -----------------------------
      // Backend logical rejection
      // Example:
      // blur / dark / non-pomegranate
      // -----------------------------
      if (data['success'] == false) {
        final message =
            data['message']?.toString() ?? 'The image could not be analyzed.';

        throw Exception(message);
      }

      // -----------------------------
      // Optional quality rejection
      // -----------------------------
      final qualityStatus = data['quality_status']?.toString().toLowerCase();

      if (qualityStatus == 'rejected' || qualityStatus == 'poor') {
        final message =
            data['quality_message']?.toString() ??
            data['message']?.toString() ??
            'Image quality is poor. Please capture another image.';

        throw Exception(message);
      }

      // -----------------------------
      // Optional pomegranate validator
      // -----------------------------
      if (data.containsKey('is_pomegranate') &&
          data['is_pomegranate'] == false) {
        final message =
            data['validation_message']?.toString() ??
            data['message']?.toString() ??
            'Please upload a valid pomegranate fruit image.';

        throw Exception(message);
      }

      // -----------------------------
      // Treatment information
      // -----------------------------
      final dynamic rawTreatmentInfo = data['treatment_info'];

      final Map<String, dynamic> treatmentInfo = rawTreatmentInfo is Map
          ? Map<String, dynamic>.from(rawTreatmentInfo)
          : <String, dynamic>{};

      final String treatment = treatmentInfo['treatment']?.toString() ?? '';

      // Prevention
      List<String> prevention = [];

      final preventionData = treatmentInfo['prevention'];

      if (preventionData is List) {
        prevention = preventionData.map((item) => item.toString()).toList();
      } else if (preventionData is String && preventionData.trim().isNotEmpty) {
        prevention = [preventionData];
      }

      // Follow-up
      int followUpDays = 0;

      final followUpValue =
          treatmentInfo['follow_up_days'] ?? data['follow_up_days'];

      if (followUpValue is int) {
        followUpDays = followUpValue;
      } else if (followUpValue is num) {
        followUpDays = followUpValue.toInt();
      } else if (followUpValue != null) {
        followUpDays = int.tryParse(followUpValue.toString()) ?? 0;
      }

      // -----------------------------
      // Severity
      // -----------------------------
      final double severityPercentage = _toDouble(
        data['severity_percentage'] ?? data['severity_percent'] ?? 0,
      );

      final String severityLevel =
          data['severity_level']?.toString() ??
          (data['severity'] is Map
              ? data['severity']['level']?.toString()
              : null) ??
          'N/A';

      // -----------------------------
      // Explainability / segmentation
      // -----------------------------
      final String? segmentationImageUrl =
          data['segmentation_image_url']?.toString() ??
          data['mask_image_url']?.toString();

      final String? gradCamImageUrl =
          data['gradcam_image_url']?.toString() ??
          data['grad_cam_image_url']?.toString();

      return PredictionResultModel(
        predictionId: data['prediction_id']?.toString(),

        diseaseName: data['disease_name']?.toString() ?? 'Unknown',

        confidence: _toDouble(data['confidence']),

        isDisease: data['is_disease'] == true,

        severityPercentage: severityPercentage,

        severityLevel: severityLevel,

        treatment: treatment,

        prevention: prevention,

        followUpDays: followUpDays,

        imagePath: imageFile.path,

        segmentationImageUrl: segmentationImageUrl,

        gradCamImageUrl: gradCamImageUrl,

        responseTimeSeconds: _toDouble(data['response_time_seconds']),

        detectedAt: DateTime.now(),
      );
    } on SocketException {
      throw Exception(
        'Cannot connect to the backend server. '
        'Please check whether the FastAPI server is running.',
      );
    } on http.ClientException {
      throw Exception('Unable to connect to the backend server.');
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }

      throw Exception('Unexpected error: $e');
    }
  }

  /// Get treatment directly by disease name.
  static Future<Map<String, dynamic>> getTreatment(String diseaseName) async {
    final encodedDisease = Uri.encodeComponent(diseaseName);

    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/disease/treatment/$encodedDisease',
    );

    final response = await http.get(uri);

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(
        data['detail'] ?? data['message'] ?? 'Failed to load treatment',
      );
    }

    if (data['success'] != true) {
      throw Exception(data['message'] ?? 'Treatment not found');
    }

    if (data['data'] is Map) {
      return Map<String, dynamic>.from(data['data']);
    }

    return {};
  }

  /// Convert backend numeric values safely.
  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;

    if (value is double) return value;

    if (value is int) {
      return value.toDouble();
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString()) ?? 0.0;
  }
}
