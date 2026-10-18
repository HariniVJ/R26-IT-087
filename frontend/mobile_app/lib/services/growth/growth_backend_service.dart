import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class GrowthBackendDetection {
  final bool detected;
  final String? stage;
  final double confidence;
  final double detectionScore;
  final Map<String, double> allProbabilities;
  final String? rejectionReason;

  const GrowthBackendDetection({
    required this.detected,
    required this.stage,
    required this.confidence,
    required this.detectionScore,
    required this.allProbabilities,
    this.rejectionReason,
  });
}

class GrowthBackendService {
  GrowthBackendService._();

  static final GrowthBackendService instance =
      GrowthBackendService._();

  String get _baseUrl {
    // Flutter Web -> PC localhost
    if (kIsWeb) {
      return 'http://localhost:8000';
    }

    // Android Emulator -> Windows PC localhost
    return 'http://10.0.2.2:8000';
  }

  Future<GrowthBackendDetection> analyse(
    File imageFile,
  ) async {
    final uri = Uri.parse(
      '$_baseUrl/api/growth/predict',
    );

    final request = http.MultipartRequest(
      'POST',
      uri,
    );

    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        imageFile.path,
      ),
    );

    final streamedResponse = await request.send();

    final responseBody =
        await streamedResponse.stream.bytesToString();

    if (kDebugMode) {
      debugPrint('');
      debugPrint('===== GROWTH V2 BACKEND =====');
      debugPrint(
        'Status: ${streamedResponse.statusCode}',
      );
      debugPrint(responseBody);
      debugPrint('=============================');
    }

    // --------------------------------------------------
    // Rejected image / Unknown / no pomegranate detected
    // --------------------------------------------------
    if (streamedResponse.statusCode == 422) {
      String rejectionReason =
          'This image could not be identified as a supported pomegranate growth stage.';

      double confidence = 0.0;

      final Map<String, double> probabilities = {};

      try {
        final decoded = jsonDecode(responseBody);

        final detail = decoded['detail'];

        if (detail is Map) {
          rejectionReason =
              detail['message']?.toString() ??
              detail['rejection_reason']?.toString() ??
              detail['reason']?.toString() ??
              rejectionReason;

          final dynamic confidenceValue =
              detail['confidence'] ??
              detail['confidence_percent'];

          if (confidenceValue is num) {
            confidence = confidenceValue.toDouble();

            if (confidence > 1) {
              confidence /= 100;
            }
          }

          final dynamic probabilityData =
              detail['all_probabilities'];

          if (probabilityData is Map) {
            probabilityData.forEach((key, value) {
              if (value is num) {
                probabilities[key.toString()] =
                    value.toDouble();
              }
            });
          }
        } else if (detail != null) {
          rejectionReason = detail.toString();
        }
      } catch (_) {
        // Keep default rejection message.
      }

      return GrowthBackendDetection(
        detected: false,
        stage: null,
        confidence: confidence,
        detectionScore: 0.0,
        allProbabilities: probabilities,
        rejectionReason: rejectionReason,
      );
    }

    // --------------------------------------------------
    // Any unexpected backend error
    // --------------------------------------------------
    if (streamedResponse.statusCode != 200) {
      throw Exception(
        'Growth prediction failed. '
        'HTTP ${streamedResponse.statusCode}: '
        '$responseBody',
      );
    }

    // --------------------------------------------------
    // Successful prediction
    // --------------------------------------------------
    final Map<String, dynamic> data =
        jsonDecode(responseBody);

    final Map<String, dynamic> growthStage =
        Map<String, dynamic>.from(
      data['growth_stage'] ?? {},
    );

    final String? stage =
        growthStage['detected']?.toString();

    final double confidencePercent =
        (growthStage['confidence_percent'] as num?)
                ?.toDouble() ??
            0.0;

    final Map<String, double> probabilities = {};

    final dynamic probabilityData =
        growthStage['all_probabilities'];

    if (probabilityData is Map) {
      probabilityData.forEach((key, value) {
        if (value is num) {
          probabilities[key.toString()] =
              value.toDouble();
        }
      });
    }

    // The current /predict response does not expose
    // YOLO detector confidence separately.
    // Keep compatibility with the existing UI for now.
    final dynamic detectorValue =
        data['detection_score'];

    double detectionScore;

    if (detectorValue is num) {
      detectionScore = detectorValue.toDouble();

      if (detectionScore > 1) {
        detectionScore /= 100;
      }
    } else {
      detectionScore = confidencePercent / 100;
    }

    return GrowthBackendDetection(
      detected: stage != null && stage.isNotEmpty,
      stage: stage,
      confidence: confidencePercent / 100,
      detectionScore: detectionScore,
      allProbabilities: probabilities,
      rejectionReason: null,
    );
  }
}