import 'dart:io';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import '../models/prediction_result.dart';

class TfliteService {
  late Interpreter _interpreter;
  late List<String> _labels;

  Future<void> loadModel() async {
    _interpreter = await Interpreter.fromAsset(
      'assets/models/pomegranate_quality_model.tflite',
    );

    final labelsData = await rootBundle.loadString('assets/labels.txt');
    _labels = labelsData
        .split('\n')
        .where((label) => label.trim().isNotEmpty)
        .map((label) => label.trim())
        .toList();
  }

  Future<PredictionResult> predict(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final originalImage = img.decodeImage(bytes);

    if (originalImage == null) {
      throw Exception('Invalid image');
    }

    final resizedImage = img.copyResize(
      originalImage,
      width: 224,
      height: 224,
    );

    final input = List.generate(
      1,
      (_) => List.generate(
        224,
        (y) => List.generate(
          224,
          (x) {
            final pixel = resizedImage.getPixel(x, y);

            return [
              pixel.r.toDouble(),
              pixel.g.toDouble(),
              pixel.b.toDouble(),
            ];
          },
        ),
      ),
    );

    final output = List.generate(1, (_) => List.filled(3, 0.0));

    _interpreter.run(input, output);

    final probabilities = output[0];

    int maxIndex = 0;
    double maxValue = probabilities[0];

    for (int i = 1; i < probabilities.length; i++) {
      if (probabilities[i] > maxValue) {
        maxValue = probabilities[i];
        maxIndex = i;
      }
    }

    final label = _labels[maxIndex];
    final confidence = maxValue * 100;

    return PredictionResult(
      quality: label,
      confidence: confidence,
      recommendation: getRecommendation(label),
    );
  }

  String getRecommendation(String label) {
    if (label == 'high_quality') {
      return 'Suitable for export and premium market sale.';
    } else if (label == 'medium_quality') {
      return 'Suitable for juice, jam, or food processing.';
    } else {
      return 'Suitable for compost or organic fertilizer production.';
    }
  }

  void close() {
    _interpreter.close();
  }
}