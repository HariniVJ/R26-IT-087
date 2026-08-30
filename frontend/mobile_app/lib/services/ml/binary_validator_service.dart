import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class ValidatorResult {
  final bool isPomegranate;
  final String label;
  final double confidence;

  ValidatorResult({
    required this.isPomegranate,
    required this.label,
    required this.confidence,
  });
}

class BinaryValidatorService {
  BinaryValidatorService._();
  static final BinaryValidatorService instance = BinaryValidatorService._();

  static const String _modelPath =
      'assets/models/binary_pomegranate_validator.tflite';
  static const int _inputSize = 224;
  static const double _acceptThreshold = 0.5;

  // Trained with class order: ['not_pomegranate', 'pomegranate']
  static const List<String> _classes = ['not_pomegranate', 'pomegranate'];

  Interpreter? _interpreter;

  bool get isLoaded => _interpreter != null;

  Future<void> loadModel() async {
    if (isLoaded) return;
    _interpreter = await Interpreter.fromAsset(_modelPath);

    // ignore: avoid_print
    print(
      '[binary_validator] input=${_interpreter!.getInputTensor(0).shape} '
      'output=${_interpreter!.getOutputTensor(0).shape}',
    );
  }

  List<List<List<double>>> _preprocess(File file) {
    final bytes = file.readAsBytesSync();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw Exception('Could not decode image.');
    }

    final resized = img.copyResize(
      decoded,
      width: _inputSize,
      height: _inputSize,
      interpolation: img.Interpolation.average,
    );

    // MobileNetV2 preprocess_input: scales pixels to -1..1
    return List.generate(_inputSize, (y) {
      return List.generate(_inputSize, (x) {
        final p = resized.getPixel(x, y);
        return [(p.r / 127.5) - 1.0, (p.g / 127.5) - 1.0, (p.b / 127.5) - 1.0];
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

  /// Validates whether [imageFile] contains a pomegranate.
  /// Handles both possible output shapes automatically:
  ///  - [1, 1] -> single sigmoid value
  ///  - [1, 2] -> two-class softmax
  Future<ValidatorResult> validate(File imageFile) async {
    await loadModel();

    final input = [_preprocess(imageFile)];
    final outputShape = _interpreter!.getOutputTensor(0).shape;
    final outLen = outputShape.last;

    if (outLen == 1) {
      final output = List.generate(1, (_) => List.filled(1, 0.0));
      _interpreter!.run(input, output);

      final prob = output[0][0];
      final isPom = prob >= _acceptThreshold;

      return ValidatorResult(
        isPomegranate: isPom,
        label: isPom ? 'pomegranate' : 'not_pomegranate',
        confidence: isPom ? prob : 1 - prob,
      );
    }

    final output = List.generate(1, (_) => List.filled(outLen, 0.0));
    _interpreter!.run(input, output);

    final scores = output[0];
    final idx = _argmax(scores);
    final label = _classes[idx];

    return ValidatorResult(
      isPomegranate: label == 'pomegranate',
      label: label,
      confidence: scores[idx],
    );
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
  }
}
