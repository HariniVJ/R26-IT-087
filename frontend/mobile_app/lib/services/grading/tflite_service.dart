// lib/services/grading/tflite_service.dart
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import '../../models/Q_prediction_result.dart';

class TfliteService {
  Interpreter? _binaryInterpreter;
  Interpreter? _qualityInterpreter;
  Interpreter? _defectInterpreter;
  Interpreter? _segInterpreter;

  static const int imgSize = 224;
  final List<String> binaryClasses = ["not_pomegranate", "pomegranate"];
  final List<String> qualityClasses = [
    "high_quality",
    "low_quality",
    "medium_quality",
  ];
  final List<String> defectClasses = ["crack", "disease", "rot", "sunburn"];
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
    try {
      _segInterpreter = await Interpreter.fromAsset(
        'assets/models/quality/segmentation_model.tflite',
      );
    } catch (e) {
      debugPrintSafe(
        '⚠️ Segmentation model failed to load, will use color-heuristic severity only: $e',
      );
      _segInterpreter = null;
    }
    _loaded = true;
  }

  void debugPrintSafe(String msg) {
    // ignore: avoid_print
    print(msg);
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

  /// Color-based severity fallback — used for disease, or whenever
  /// segmentation fails/is unavailable. Measures % of surface that looks
  /// dark/decayed or discolored, so severity is NEVER left null.
  double _colorHeuristicSeverity(img.Image image) {
    int abnormalPixels = 0;
    int totalPixels = 0;
    for (int y = 0; y < image.height; y += 2) {
      for (int x = 0; x < image.width; x += 2) {
        final p = image.getPixel(x, y);
        final r = p.r, g = p.g, b = p.b;
        final brightness = (r + g + b) / 3;
        final isDark = brightness < 60;
        final isBrown =
            r > 60 && r < 160 && g > 30 && g < 120 && b < 80 && r > g && g >= b;
        if (isDark || isBrown) abnormalPixels++;
        totalPixels++;
      }
    }
    if (totalPixels == 0) return 0.0;
    final pct = (abnormalPixels / totalPixels) * 100;
    return double.parse(pct.clamp(0, 100).toStringAsFixed(2));
  }

  /// Descriptive color profile for High/Medium fruits — informational only.
  Map<String, dynamic> _analyzeColorProfile(img.Image image) {
    int rSum = 0, gSum = 0, count = 0;
    for (int y = 0; y < image.height; y += 4) {
      for (int x = 0; x < image.width; x += 4) {
        final p = image.getPixel(x, y);
        rSum += p.r.toInt();
        gSum += p.g.toInt();
        count++;
      }
    }
    if (count == 0) return {"tone": "Unknown"};
    final avgR = rSum / count;
    final avgG = gSum / count;
    final rednessRatio = avgR / (avgG + 1);
    String tone;
    if (rednessRatio > 1.6) {
      tone = "Deep Reddish";
    } else if (rednessRatio > 1.2) {
      tone = "Reddish";
    } else {
      tone = "Pale / Yellowish";
    }
    return {"tone": tone};
  }

  /// Segmentation-based severity for crack/rot/sunburn. Returns null if
  /// the model isn't loaded or decoding fails — caller must fall back.
  Future<double?> _runSegmentationSeverity(File imageFile) async {
    if (_segInterpreter == null) return null;
    try {
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) return null;

      final input = _preprocess(image, imgSize);
      final inputTensor = input.reshape([1, imgSize, imgSize, 3]);

      final out0Shape = _segInterpreter!.getOutputTensor(0).shape;
      final out1Shape = _segInterpreter!.getOutputTensor(1).shape;

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
      final numClasses = segClasses.length;
      const numMaskCoeffs = 32;
      final protoSize = out1Shape[2];

      final bestScorePerClass = List.filled(numClasses, -1.0);
      final bestAnchorPerClass = List.filled(numClasses, -1);

      for (int a = 0; a < numAnchors; a++) {
        for (int c = 0; c < numClasses; c++) {
          final score = out0[0][4 + c][a];
          if (score > bestScorePerClass[c]) {
            bestScorePerClass[c] = score;
            bestAnchorPerClass[c] = a;
          }
        }
      }

      const double confThreshold = 0.20;
      int? fruitPixels;
      int? defectPixels;
      double bestDefectScore = -1;

      for (int c = 0; c < numClasses; c++) {
        if (bestScorePerClass[c] < confThreshold) continue;
        final anchor = bestAnchorPerClass[c];
        final coeffs = List<double>.generate(
          numMaskCoeffs,
          (m) => out0[0][8 + m][anchor],
        );

        int pixelCount = 0;
        for (int py = 0; py < protoSize; py++) {
          for (int px = 0; px < protoSize; px++) {
            double sum = 0;
            for (int m = 0; m < numMaskCoeffs; m++) {
              sum += coeffs[m] * out1[0][m][py][px];
            }
            final activated = 1 / (1 + math.exp(-sum));
            if (activated > 0.5) pixelCount++;
          }
        }

        if (segClasses[c] == "fruit") {
          fruitPixels = pixelCount;
        } else if (bestScorePerClass[c] > bestDefectScore) {
          bestDefectScore = bestScorePerClass[c];
          defectPixels = pixelCount;
        }
      }

      if (fruitPixels == null || fruitPixels == 0 || defectPixels == null)
        return null;

      final severity = ((defectPixels / fruitPixels) * 100).clamp(0.0, 100.0);
      return double.parse(severity.toStringAsFixed(2));
    } catch (e) {
      debugPrintSafe(
        '⚠️ Segmentation decode failed, will use color fallback: $e',
      );
      return null;
    }
  }

  Future<bool> checkIsPomegranate(File imageFile) async {
    if (!_loaded) await loadModel();
    final bytes = await imageFile.readAsBytes();
    final image = img.decodeImage(bytes);
    if (image == null) return false;
    final input = _preprocess(image, imgSize);
    final result = _classify(_binaryInterpreter!, input, binaryClasses);
    return result["label"] == "pomegranate";
  }

  Future<Uint8List?> getPreprocessedPreview(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final image = img.decodeImage(bytes);
    if (image == null) return null;
    final resized = img.copyResize(image, width: imgSize, height: imgSize);
    return Uint8List.fromList(img.encodePng(resized));
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
    Map<String, dynamic>? colorProfile;

    if (qualityResult["label"] == "low_quality") {
      final defectResult = _classify(_defectInterpreter!, input, defectClasses);
      defectType = defectResult["label"];
      defectConfidence = defectResult["confidence"];

      if (defectType == "disease") {
        // Color heuristic until Disease Detection component is integrated
        severity = _colorHeuristicSeverity(image);
      } else {
        // crack / rot / sunburn — segmentation model first
        severity = await _runSegmentationSeverity(imageFile);
        // Guaranteed fallback — severity is NEVER left null
        severity ??= _colorHeuristicSeverity(image);
      }
    } else {
      colorProfile = _analyzeColorProfile(image);
    }

    return {
      "isPomegranate": true,
      "quality": qualityResult["label"],
      "qualityConfidence": qualityResult["confidence"],
      "allQualityScores": qualityResult["all_scores"],
      "defectType": defectType,
      "defectConfidence": defectConfidence,
      "severity": severity,
      "colorProfile": colorProfile,
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

    final colorProfile =
        pipelineResult["colorProfile"] as Map<String, dynamic>?;

    return PredictionResult(
      quality: pipelineResult["quality"] as String,
      confidence: (pipelineResult["qualityConfidence"] as double) * 100,
      defectType: pipelineResult["defectType"] as String?,
      severityPercent: pipelineResult["severity"] as double?,
      colorTone: colorProfile?["tone"] as String?,
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
    _segInterpreter?.close();
  }
}
