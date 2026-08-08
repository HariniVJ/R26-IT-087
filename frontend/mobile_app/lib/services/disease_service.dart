import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/prediction_result_model.dart';

class DiseaseService {
  // Windows testing
  static const String baseUrl = 'http://172.20.10.7:8000';

  // Mobile testing use PC IPv4
  // Example:
  // static const String baseUrl = 'http://192.168.1.12:8000';

  static Future<PredictionResultModel> predictDisease(File imageFile) async {
    final uri = Uri.parse('$baseUrl/api/disease/upload-and-analyze');

    final request = http.MultipartRequest('POST', uri);

    request.fields['user_id'] = 'user001';

    request.files.add(
      await http.MultipartFile.fromPath('file', imageFile.path),
    );

    final streamedResponse = await request.send();

    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      print(data);

      final treatmentInfo = data['treatment_info'] ?? {};

      String treatment = treatmentInfo['treatment'] ?? '';

      if (treatmentInfo['prevention'] != null) {
        final preventionList = List<String>.from(treatmentInfo['prevention']);

        treatment +=
            '\n\nPrevention:\n${preventionList.map((e) => '• $e').join('\n')}';
      }

      return PredictionResultModel(
        diseaseName: data['disease_name'] ?? 'Unknown',

        confidence: (data['confidence'] ?? 0).toDouble(),

        treatment: treatment,

        imagePath: imageFile.path,

        detectedAt: DateTime.now(),
      );
    } else {
      throw Exception('Backend error: ${response.body}');
    }
  }
}
