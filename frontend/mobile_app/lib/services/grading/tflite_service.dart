// lib/services/grading/tflite_service.dart
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import '../../models/prediction_result.dart';

class TfliteService {
  Interpreter? _binaryInterpreter;
  Interpreter? _qualityInterpreter;
  Interpreter? _defectInterpreter;
  Interpreter? _segInterpreter; // 🆕

  static const int imgSize = 224;
  final List<String> binaryClasses = ["not_pomegranate", "pomegranate"];
  final List<String> qualityClasses = [
    "high_quality",
    "low_quality",
    "medium_quality",
  ];
  final List<String> defectClasses = ["crack", "disease", "rot", "sunburn"];
  // 🆕 Order MUST match your data.yaml names order exactly
  final List<String> segClasses = ["fruit", "crack", "rot", "sunburn"];

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
    _segInterpreter = await Interpreter.fromAsset(
      'assets/models/quality/segmentation_model.tflite',
    ); // 🆕
    _loaded = true;
  }

  Float32List _preprocess(img.Image image, int size) {
    final resized = img.copyResize(image, width: size, height: size);
    final input = Float32List(1 * size * size * 3);
    int idx = 0;
    for (int y = 0; y < size; y++) {
      for (int x = 0; x < size; x++) {
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

  // 🆕 Segmentation decode: finds the best-scoring anchor per class, combines
  // its mask coefficients with the prototypes to get that class's pixel mask.
  Future<Map<String, dynamic>> _runSegmentation(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) return {"defectType": null, "severity": null};

      final input = _preprocess(image, imgSize);
      final inputTensor = input.reshape([1, imgSize, imgSize, 3]);

      final out0Shape = _segInterpreter!
          .getOutputTensor(0)
          .shape; // [1, 40, 1029]
      final out1Shape = _segInterpreter!
          .getOutputTensor(1)
          .shape; // [1, 32, 56, 56]

      final out0 = List.generate(
        out0Shape[0],
        (_) =>
            List.generate(out0Shape[1], (_) => List.filled(out0Shape[2], 0.0)),
      );
      final out1 = List.generate(
        out1Shape[0],
        (_) => List.generate(
          out1Shape[1],
          (_) => List.generate(
            out1Shape[2],
            (_) => List.filled(out1Shape[3], 0.0),
          ),
        ),
      );

      _segInterpreter!.runForMultipleInputs([inputTensor], {0: out0, 1: out1});

      final numAnchors = out0Shape[2];
      final numClasses = segClasses.length; // 4
      const numMaskCoeffs = 32;
      final protoSize = out1Shape[2]; // 56

      // For each class, find the anchor with the highest class score
      final bestScorePerClass = List.filled(numClasses, -1.0);
      final bestAnchorPerClass = List.filled(numClasses, -1);

      for (int a = 0; a < numAnchors; a++) {
        for (int c = 0; c < numClasses; c++) {
          final score = out0[0][4 + c][a]; // channels 4..7 = class scores
          if (score > bestScorePerClass[c]) {
            bestScorePerClass[c] = score;
            bestAnchorPerClass[c] = a;
          }
        }
      }

      // Threshold — adjust if scores look too low/high after testing
      const double confThreshold = 0.25;

      int? fruitPixels;
      String? defectType;
      int? defectPixels;
      double bestDefectScore = -1;

      for (int c = 0; c < numClasses; c++) {
        if (bestScorePerClass[c] < confThreshold) continue;
        final anchor = bestAnchorPerClass[c];

        // Extract this anchor's 32 mask coefficients
        final coeffs = List<double>.generate(
          numMaskCoeffs,
          (m) => out0[0][8 + m][anchor],
        );

        // Combine coefficients with prototypes -> pixel mask, count "on" pixels
        int pixelCount = 0;
        for (int py = 0; py < protoSize; py++) {
          for (int px = 0; px < protoSize; px++) {
            double sum = 0;
            for (int m = 0; m < numMaskCoeffs; m++) {
              sum += coeffs[m] * out1[0][m][py][px];
            }
            final activated = 1 / (1 + math.exp(-sum)); // sigmoid
            if (activated > 0.5) pixelCount++;
          }
        }

        if (segClasses[c] == "fruit") {
          fruitPixels = pixelCount;
        } else if (bestScorePerClass[c] > bestDefectScore) {
          bestDefectScore = bestScorePerClass[c];
          defectType = segClasses[c];
          defectPixels = pixelCount;
        }
      }

      if (fruitPixels == null ||
          fruitPixels == 0 ||
          defectType == null ||
          defectPixels == null) {
        return {"defectType": null, "severity": null};
      }

      final severity = ((defectPixels / fruitPixels) * 100).clamp(0.0, 100.0);
      return {
        "defectType": defectType,
        "severity": double.parse(severity.toStringAsFixed(2)),
      };
    } catch (e) {
      // If segmentation decoding fails for any reason, fail gracefully —
      // the app still works with quality+defect-type, just without severity.
      return {"defectType": null, "severity": null};
    }
  }

  Future<Map<String, dynamic>> runFullPipeline(File imageFile) async {
    if (!_loaded) await loadModel();

    final bytes = await imageFile.readAsBytes();
    final image = img.decodeImage(bytes);
    if (image == null) throw Exception("Could not decode image");

    final input = _preprocess(image, imgSize);

    final binResult = _classify(_binaryInterpreter!, input, binaryClasses);
    if (binResult["label"] == "not_pomegranate") {
      return {
        "isPomegranate": false,
        "binaryConfidence": binResult["confidence"],
      };
    }

    final qualityResult = _classify(
      _qualityInterpreter!,
      input,
      qualityClasses,
    );

    String? defectType;
    double? defectConfidence;
    double? severity;

    if (qualityResult["label"] == "low_quality") {
      final defectResult = _classify(_defectInterpreter!, input, defectClasses);
      defectType = defectResult["label"];
      defectConfidence = defectResult["confidence"];

      // 🆕 Run segmentation for severity, using the classifier's defect type
      // as the primary label (more reliable than segmentation's own class pick)
      final segResult = await _runSegmentation(imageFile);
      severity = segResult["severity"] as double?;
    }

    return {
      "isPomegranate": true,
      "quality": qualityResult["label"],
      "qualityConfidence": qualityResult["confidence"],
      "allQualityScores": qualityResult["all_scores"],
      "defectType": defectType,
      "defectConfidence": defectConfidence,
      "severity": severity, // 🆕
    };
  }

  Map<String, dynamic>? _lastPipelineResult;

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
      severityPercent:
          pipelineResult["severity"]
              as double?, // 🔧 was hardcoded null, now real
      recommendation: "",
    );
  }

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
    _segInterpreter?.close(); // 🆕
  }
}
