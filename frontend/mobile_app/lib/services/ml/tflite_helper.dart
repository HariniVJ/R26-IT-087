import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

import '../../../config/disease_ml_config.dart';

/// Shared TFLite helpers — every model is loaded through [load], so loading
/// behaviour (threads, error message, logging) is the same everywhere.
class TfliteHelper {
  TfliteHelper._();

  static Future<Interpreter> load(String assetPath, String name) async {
    try {
      final options = InterpreterOptions()
        ..threads = DiseaseImageConfig.interpreterThreads;
      final interpreter = await Interpreter.fromAsset(assetPath, options: options);
      logShapes(name, interpreter);
      return interpreter;
    } catch (e) {
      throw Exception(
        'Failed to load the $name model.\n'
        'Check that "$assetPath" exists and is listed in pubspec.yaml assets.\n'
        'Original error: $e',
      );
    }
  }

  static void logShapes(String name, Interpreter interpreter) {
    final ins = interpreter.getInputTensors().map((t) => t.shape).join(', ');
    final outs = interpreter.getOutputTensors().map((t) => t.shape).join(', ');
    debugPrint('[$name] inputs=$ins outputs=$outs');
  }

  /// Reads a float32 output tensor (copied, so alignment is always safe).
  static Float32List readFloats(Tensor tensor) =>
      Uint8List.fromList(tensor.data).buffer.asFloat32List();

  /// Index of the largest value.
  static int argmax(List<double> scores) {
    var best = 0;
    for (var i = 1; i < scores.length; i++) {
      if (scores[i] > scores[best]) best = i;
    }
    return best;
  }
}
