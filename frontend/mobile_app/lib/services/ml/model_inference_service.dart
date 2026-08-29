import 'dart:io';

import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class MlLabels {
  MlLabels._();
  static const validatorClasses = ['non_pomegranate', 'pomegranate'];
  static const diseaseClasses = [
    'Alternaria',
    'Anthracnose',
    'Bacterial_Blight',
    'Cercospora',
    'Healthy',
  ];
}

class MlConfig {
  MlConfig._();
  // ⚠️ Verify against your models (Netron: https://netron.app) and
  // adjust if the debug print at startup shows different shapes.
  static const validatorInputSize = 224;
  static const classifierInputSize = 224;
  static const severityInputSize = 224;

  static const validatorAssetPath =
      'assets/models/binary_pomegranate_validator.tflite';
  static const classifierAssetPath =
      'assets/models/pomegranate_disease_classifier.tflite';
  static const severityAssetPath =
      'assets/models/pomegranate_severity_seg_v2.tflite';

  static const validatorAcceptThreshold = 0.5;
}

class MlResult {
  final String label;
  final double confidence;
  MlResult(this.label, this.confidence);
}

class SeverityResult {
  final double percentage;
  final String level;
  SeverityResult(this.percentage, this.level);
}

class ModelInferenceService {
  ModelInferenceService._();
  static final ModelInferenceService instance = ModelInferenceService._();

  Interpreter? _validator;
  Interpreter? _classifier;
  Interpreter? _severity;

  bool get isLoaded =>
      _validator != null && _classifier != null && _severity != null;

  Future<void> loadModels() async {
    if (isLoaded) return;

    _validator = await Interpreter.fromAsset(MlConfig.validatorAssetPath);
    _classifier = await Interpreter.fromAsset(MlConfig.classifierAssetPath);
    _severity = await Interpreter.fromAsset(MlConfig.severityAssetPath);

    _debugPrintShapes('validator', _validator!);
    _debugPrintShapes('classifier', _classifier!);
    _debugPrintShapes('severity', _severity!);
  }

  void _debugPrintShapes(String name, Interpreter interp) {
    // ignore: avoid_print
    print(
      '[$name] input=${interp.getInputTensor(0).shape} '
      'output=${interp.getOutputTensor(0).shape}',
    );
  }

  List<List<List<double>>> _preprocess(File file, int size) {
    final bytes = file.readAsBytesSync();
    final decoded = img.decodeImage(bytes);

    if (decoded == null) {
      throw Exception('Could not decode image.');
    }

    final resized = img.copyResize(
      decoded,
      width: size,
      height: size,
      interpolation: img.Interpolation.average,
    );

    return List.generate(size, (y) {
      return List.generate(size, (x) {
        final p = resized.getPixel(x, y);
        return [p.r / 255.0, p.g / 255.0, p.b / 255.0];
      });
    });
  }

  int _argmax(List<double> scores) {
    int best = 0;
    for (int i = 1; i < scores.length; i++) {
      if (scores[i] > scores[best]) best = i;
    }
    return best;
  }

  Future<MlResult> validatePomegranate(File imageFile) async {
    await loadModels();

    final size = MlConfig.validatorInputSize;
    final input = [_preprocess(imageFile, size)];

    final outLen = _validator!.getOutputTensor(0).shape.last;
    final output = List.generate(1, (_) => List.filled(outLen, 0.0));

    _validator!.run(input, output);

    if (outLen == 1) {
      final prob = output[0][0];
      final isPom = prob >= MlConfig.validatorAcceptThreshold;
      return MlResult(
        isPom ? 'pomegranate' : 'non_pomegranate',
        isPom ? prob : 1 - prob,
      );
    }

    final scores = output[0];
    final idx = _argmax(scores);
    return MlResult(MlLabels.validatorClasses[idx], scores[idx]);
  }

  Future<MlResult> classifyDisease(File imageFile) async {
    await loadModels();

    final size = MlConfig.classifierInputSize;
    final input = [_preprocess(imageFile, size)];

    final numClasses = MlLabels.diseaseClasses.length;
    final output = List.generate(1, (_) => List.filled(numClasses, 0.0));

    _classifier!.run(input, output);

    final scores = output[0];
    final idx = _argmax(scores);
    return MlResult(MlLabels.diseaseClasses[idx], scores[idx]);
  }

  Future<SeverityResult> analyzeSeverity(File imageFile) async {
    await loadModels();

    final size = MlConfig.severityInputSize;
    final input = [_preprocess(imageFile, size)];

    final outShape = _severity!.getOutputTensor(0).shape;
    final h = outShape.length >= 3 ? outShape[1] : size;
    final w = outShape.length >= 3 ? outShape[2] : size;

    final output = List.generate(
      1,
      (_) => List.generate(h, (_) => List.generate(w, (_) => [0.0])),
    );

    _severity!.run(input, output);

    int affected = 0;
    final total = h * w;

    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        if (output[0][y][x][0] >= 0.5) affected++;
      }
    }

    final percentage = total == 0 ? 0.0 : (affected / total) * 100.0;

    String level;
    if (percentage <= 38) {
      level = 'Mild';
    } else if (percentage <= 58) {
      level = 'Moderate';
    } else {
      level = 'Severe';
    }

    return SeverityResult(percentage, level);
  }

  void dispose() {
    _validator?.close();
    _classifier?.close();
    _severity?.close();
    _validator = null;
    _classifier = null;
    _severity = null;
  }
}
