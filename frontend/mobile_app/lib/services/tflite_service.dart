// lib/services/tflite_service.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import '../models/prediction_result.dart';

class TfliteService {
  Interpreter? _binaryInterpreter;
  Interpreter? _qualityInterpreter;
  Interpreter? _defectInterpreter;

  static const int imgSize = 224;
  final List<String> binaryClasses = ["not_pomegranate", "pomegranate"];
  final List<String> qualityClasses = [
    "high_quality",
    "low_quality",
    "medium_quality",
  ];
  final List<String> defectClasses = ["crack", "disease", "rot", "sunburn"];

  bool _loaded = false;
  bool get isLoaded => _loaded;

  Future<void> loadModel() async {
    if (_loaded) return;
    _binaryInterpreter = await Interpreter.fromAsset(
      'assets/models/quality/binary_validation.tflite',
    );
    _qualityInterpreter = await Interpreter.fromAsset(
      'assets/models/quality/quality_model.tflite',
    );
    _defectInterpreter = await Interpreter.fromAsset(
      'assets/models/quality/defect_type_model.tflite',
    );
    _loaded = true;
  }

  Float32List _preprocess(img.Image image) {
    final resized = img.copyResize(image, width: imgSize, height: imgSize);
    final input = Float32List(1 * imgSize * imgSize * 3);
    int idx = 0;
    for (int y = 0; y < imgSize; y++) {
      for (int x = 0; x < imgSize; x++) {
        final p = resized.getPixel(x, y);
        input[idx++] = p.r / 255.0;
        input[idx++] = p.g / 255.0;
        input[idx++] = p.b / 255.0;
      }
    }
    return input;
  }

  Map<String, dynamic> _classify(
    Interpreter interpreter,
    Float32List input,
    List<String> classNames,
  ) {
    final inputTensor = input.reshape([1, imgSize, imgSize, 3]);
    final outputShape = interpreter.getOutputTensor(0).shape;
    final output = List.filled(
      outputShape[1],
      0.0,
    ).reshape([1, outputShape[1]]);

    interpreter.run(inputTensor, output);

    final probs = List<double>.from(output[0]);
    int maxIndex = 0;
    double maxProb = probs[0];
    for (int i = 1; i < probs.length; i++) {
      if (probs[i] > maxProb) {
        maxProb = probs[i];
        maxIndex = i;
      }
    }

    final scores = <String, double>{};
    for (int i = 0; i < classNames.length; i++) {
      scores[classNames[i]] = probs[i];
    }

    return {
      "label": classNames[maxIndex],
      "confidence": maxProb,
      "all_scores": scores,
    };
  }

  /// Full pipeline: Binary -> Quality -> Defect-Type (if low quality)
  Future<Map<String, dynamic>> runFullPipeline(File imageFile) async {
    if (!_loaded) await loadModel();

    final bytes = await imageFile.readAsBytes();
    final image = img.decodeImage(bytes);
    if (image == null) throw Exception("Could not decode image");

    final input = _preprocess(image);

    // Stage 1: Binary validation
    final binResult = _classify(_binaryInterpreter!, input, binaryClasses);
    if (binResult["label"] == "not_pomegranate") {
      return {
        "isPomegranate": false,
        "binaryConfidence": binResult["confidence"],
      };
    }

    // Stage 2: Quality classification
    final qualityResult = _classify(
      _qualityInterpreter!,
      input,
      qualityClasses,
    );

    String? defectType;
    double? defectConfidence;

    // Stage 3: Defect-type router (only for low_quality)
    if (qualityResult["label"] == "low_quality") {
      final defectResult = _classify(_defectInterpreter!, input, defectClasses);
      defectType = defectResult["label"];
      defectConfidence = defectResult["confidence"];
    }

    return {
      "isPomegranate": true,
      "quality": qualityResult["label"],
      "qualityConfidence": qualityResult["confidence"],
      "allQualityScores": qualityResult["all_scores"],
      "defectType": defectType,
      "defectConfidence": defectConfidence,
    };
  }

  // tflite_service.dart-ல், dispose() method-க்கு முன் சேருங்க

  Map<String, dynamic>? _lastPipelineResult;

  /// Returns a PredictionResult — matches what the UI screen expects
  Future<PredictionResult> predict(File imageFile) async {
    final pipelineResult = await runFullPipeline(imageFile);
    _lastPipelineResult = pipelineResult;

    if (pipelineResult["isPomegranate"] == false) {
      throw Exception(
        "Not recognized as a pomegranate. Please retake the photo.",
      );
    }

    return PredictionResult(
      quality: pipelineResult["quality"] as String,
      confidence: (pipelineResult["qualityConfidence"] as double) * 100,
      defectType: pipelineResult["defectType"] as String?,
      severityPercent: null, // segmentation model integration pending
      recommendation: "", // filled in later via DB lookup
    );
  }

  /// Returns quality class scores as a Map — matches what the UI screen expects
  Future<Map<String, double>> getAllScores(File imageFile) async {
    if (_lastPipelineResult == null) {
      await predict(imageFile);
    }
    final raw =
        _lastPipelineResult?["allQualityScores"] as Map<String, double>?;
    return raw ?? {};
  }

  void dispose() {
    _binaryInterpreter?.close();
    _qualityInterpreter?.close();
    _defectInterpreter?.close();
  }
}
