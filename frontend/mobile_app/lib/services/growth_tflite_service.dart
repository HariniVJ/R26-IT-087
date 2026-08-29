// lib/services/growth_tflite_service.dart
//
// Member 2: Fruit Growth Stage Detection + Harvest Prediction
//
// Two-stage on-device pipeline:
//   1. YOLOv11 detects whether a pomegranate is present at all.
//      If nothing is found the image is rejected. This is what stops
//      apples, tomatoes and unrelated photos being classified as fruit
//      stages - a softmax CNN alone cannot do this because it must
//      always assign 100% of probability across its known classes.
//   2. If a fruit is found, the region is cropped and passed to the
//      CNN, which classifies the growth stage.
//
// Model tensor shapes (confirmed from export):
//   YOLO  input  [1, 3, 416, 416]   <- channels FIRST (NCHW)
//   YOLO  output [1, 9, 3549]       <- 9 = 4 box + 5 class, 3549 anchors
//   CNN   input  [1, 224, 224, 3]   <- channels last (NHWC)

import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class GrowthDetectionResult {
  final bool detected;
  final String? stage;
  final double confidence;        // CNN confidence in the stage
  final double detectionScore;    // YOLO confidence a fruit is present
  final Map<String, double> allProbabilities;
  final String? rejectionReason;

  const GrowthDetectionResult({
    required this.detected,
    this.stage,
    this.confidence = 0.0,
    this.detectionScore = 0.0,
    this.allProbabilities = const {},
    this.rejectionReason,
  });

  factory GrowthDetectionResult.rejected(String reason, double score) =>
      GrowthDetectionResult(
        detected: false,
        detectionScore: score,
        rejectionReason: reason,
      );
}

class GrowthTfliteService {
  GrowthTfliteService._();
  static final GrowthTfliteService instance = GrowthTfliteService._();

  static const String _yoloAsset = 'assets/models/pomegranate_yolo.tflite';
  static const String _cnnAsset  = 'assets/models/pomegranate_cnn.tflite';
  static const String _yoloLabelsAsset = 'assets/models/growth_yolo_labels.txt';
  static const String _cnnLabelsAsset  = 'assets/models/growth_cnn_labels.txt';

  // Detection threshold. Raise it if unrelated fruit slips through,
  // lower it if real pomegranates are being rejected.
  static const double detectionThreshold = 0.35;

  // Classification threshold, applied after detection passes.
  static const double classificationThreshold = 0.50;

  static const int _yoloSize = 416;
  static const int _cnnSize  = 224;
  static const int _numAnchors = 3549;
  static const int _numYoloClasses = 5;

  Interpreter? _yolo;
  Interpreter? _cnn;
  List<String> _yoloLabels = [];
  List<String> _cnnLabels = [];
  bool _loaded = false;

  bool get isLoaded => _loaded;

  Future<void> loadModels() async {
    if (_loaded) return;

    try {
      _yolo = await Interpreter.fromAsset(_yoloAsset);
      _cnn  = await Interpreter.fromAsset(_cnnAsset);

      _yoloLabels = await _readLabels(_yoloLabelsAsset);
      _cnnLabels  = await _readLabels(_cnnLabelsAsset);

      if (kDebugMode) {
        debugPrint('YOLO in : ${_yolo!.getInputTensor(0).shape}');
        debugPrint('YOLO out: ${_yolo!.getOutputTensor(0).shape}');
        debugPrint('CNN  in : ${_cnn!.getInputTensor(0).shape}');
        debugPrint('CNN  out: ${_cnn!.getOutputTensor(0).shape}');
        debugPrint('CNN labels: $_cnnLabels');
      }

      _loaded = true;
    } catch (e) {
      _loaded = false;
      throw Exception(
        'Failed to load growth models.\n'
        'Check these are in pubspec.yaml assets:\n'
        '  $_yoloAsset\n'
        '  $_cnnAsset\n'
        '  $_yoloLabelsAsset\n'
        '  $_cnnLabelsAsset\n'
        'Error: $e',
      );
    }
  }

  Future<List<String>> _readLabels(String asset) async {
    final raw = await rootBundle.loadString(asset);
    return raw
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
  }

  // ── Main entry point ───────────────────────────────────────────
  Future<GrowthDetectionResult> analyse(File imageFile) async {
    if (!_loaded) await loadModels();

    final bytes = await imageFile.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      return GrowthDetectionResult.rejected('Could not read the image file.', 0);
    }

    // ── Stage 1: does a pomegranate exist in this image? ─────────
    final detection = _runYolo(decoded);

    if (detection == null) {
      return GrowthDetectionResult.rejected(
        'No pomegranate was detected in this image. '
        'Please upload a clear photo of a pomegranate plant or fruit.',
        0,
      );
    }

    // ── Stage 2: crop the fruit and classify its stage ───────────
    final crop = _cropDetection(decoded, detection);
    final classification = _runCnn(crop);

    final topStage = classification.entries
        .reduce((a, b) => a.value >= b.value ? a : b);

    // The CNN may carry an explicit Unknown class from earlier training.
    if (topStage.key == 'Unknown') {
      return GrowthDetectionResult.rejected(
        'This does not appear to be a pomegranate fruit.',
        detection.score,
      );
    }

    if (topStage.value < classificationThreshold) {
      return GrowthDetectionResult.rejected(
        'The growth stage could not be determined confidently. '
        'Try a clearer, closer photo of the fruit.',
        detection.score,
      );
    }

    return GrowthDetectionResult(
      detected: true,
      stage: topStage.key,
      confidence: topStage.value,
      detectionScore: detection.score,
      allProbabilities: classification,
    );
  }

  // ── YOLO inference ─────────────────────────────────────────────
  _Detection? _runYolo(img.Image source) {
    final resized = img.copyResize(
      source,
      width: _yoloSize,
      height: _yoloSize,
      interpolation: img.Interpolation.linear,
    );

    // Build NCHW input: [1][3][416][416]
    final input = List.generate(
      1,
      (_) => List.generate(
        3,
        (c) => List.generate(
          _yoloSize,
          (y) => List.generate(_yoloSize, (x) {
            final p = resized.getPixel(x, y);
            final v = c == 0 ? p.r : (c == 1 ? p.g : p.b);
            return v / 255.0;
          }),
        ),
      ),
    );

    // Output [1][9][3549]
    final output = List.generate(
      1,
      (_) => List.generate(9, (_) => List.filled(_numAnchors, 0.0)),
    );

    _yolo!.run(input, output);

    // Find the anchor with the highest class score
    double bestScore = 0.0;
    int bestAnchor = -1;
    int bestClass = -1;

    final rows = output[0];
    for (int a = 0; a < _numAnchors; a++) {
      for (int c = 0; c < _numYoloClasses; c++) {
        final score = rows[4 + c][a];
        if (score > bestScore) {
          bestScore = score;
          bestAnchor = a;
          bestClass = c;
        }
      }
    }

    if (bestScore < detectionThreshold || bestAnchor < 0) {
      return null;
    }

    // Box is cx, cy, w, h. Ultralytics TFLite exports normalised 0-1,
    // but fall back to pixel-space if values look large.
    double cx = rows[0][bestAnchor];
    double cy = rows[1][bestAnchor];
    double w  = rows[2][bestAnchor];
    double h  = rows[3][bestAnchor];

    if (cx > 1.5 || cy > 1.5 || w > 1.5 || h > 1.5) {
      cx /= _yoloSize;
      cy /= _yoloSize;
      w  /= _yoloSize;
      h  /= _yoloSize;
    }

    return _Detection(
      cx: cx,
      cy: cy,
      w: w,
      h: h,
      score: bestScore,
      classIndex: bestClass,
    );
  }

  // ── Crop the detected region, with a little context padding ────
  img.Image _cropDetection(img.Image source, _Detection d) {
    const pad = 0.12;

    final cw = source.width.toDouble();
    final ch = source.height.toDouble();

    var x1 = (d.cx - d.w / 2 - d.w * pad) * cw;
    var y1 = (d.cy - d.h / 2 - d.h * pad) * ch;
    var x2 = (d.cx + d.w / 2 + d.w * pad) * cw;
    var y2 = (d.cy + d.h / 2 + d.h * pad) * ch;

    x1 = x1.clamp(0, cw - 1);
    y1 = y1.clamp(0, ch - 1);
    x2 = x2.clamp(1, cw);
    y2 = y2.clamp(1, ch);

    final cropW = math.max(8, (x2 - x1).round());
    final cropH = math.max(8, (y2 - y1).round());

    return img.copyCrop(
      source,
      x: x1.round(),
      y: y1.round(),
      width: cropW,
      height: cropH,
    );
  }

  // ── CNN inference ──────────────────────────────────────────────
  Map<String, double> _runCnn(img.Image crop) {
    final resized = img.copyResize(
      crop,
      width: _cnnSize,
      height: _cnnSize,
      interpolation: img.Interpolation.linear,
    );

    // NHWC input: [1][224][224][3], normalised to 0-1 to match training
    final input = List.generate(
      1,
      (_) => List.generate(
        _cnnSize,
        (y) => List.generate(_cnnSize, (x) {
          final p = resized.getPixel(x, y);
          return [p.r / 255.0, p.g / 255.0, p.b / 255.0];
        }),
      ),
    );

    final numClasses = _cnnLabels.length;
    final output = List.generate(1, (_) => List.filled(numClasses, 0.0));

    _cnn!.run(input, output);

    final probs = <String, double>{};
    for (int i = 0; i < numClasses; i++) {
      probs[_cnnLabels[i]] = output[0][i].toDouble();
    }
    return probs;
  }

  void dispose() {
    _yolo?.close();
    _cnn?.close();
    _loaded = false;
  }
}

class _Detection {
  final double cx, cy, w, h, score;
  final int classIndex;
  const _Detection({
    required this.cx,
    required this.cy,
    required this.w,
    required this.h,
    required this.score,
    required this.classIndex,
  });
}
