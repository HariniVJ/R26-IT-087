import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class MlLabels {
  MlLabels._();
  static const validatorClasses = ['pomegranate', 'not_pomegranate'];
  static const diseaseClasses = [
    'Alternaria',
    'Anthracnose',
    'Bacterial_Blight',
    'Cercospora',
    'Healthy',
  ];
  // Order matches yolo_classes in labels.json
  static const yoloClasses = ['affected_region', 'fruit'];
}

class MlConfig {
  MlConfig._();
  static const validatorInputSize = 224;
  static const classifierInputSize = 224;

  static const validatorAssetPath =
      'assets/models/binary_pomegranate_validator.tflite';
  static const classifierAssetPath =
      'assets/models/pomegranate_disease_classifier.tflite';
  static const severityAssetPath =
      'assets/models/pomegranate_severity_seg_v2.tflite';

  static const validatorAcceptThreshold = 0.5;
  static const validatorEnabled = false; // binary validator model is broken

  static const yoloConfThreshold = 0.25;
  static const yoloIouThreshold = 0.45;
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

class _Box {
  final double cx, cy, w, h, score;
  _Box(this.cx, this.cy, this.w, this.h, this.score);

  double get area => w.abs() * h.abs();

  double iou(_Box other) {
    final x1 = math.max(cx - w / 2, other.cx - other.w / 2);
    final y1 = math.max(cy - h / 2, other.cy - other.h / 2);
    final x2 = math.min(cx + w / 2, other.cx + other.w / 2);
    final y2 = math.min(cy + h / 2, other.cy + other.h / 2);

    final interW = math.max(0.0, x2 - x1);
    final interH = math.max(0.0, y2 - y1);
    final interArea = interW * interH;

    final unionArea = area + other.area - interArea;
    return unionArea <= 0 ? 0.0 : interArea / unionArea;
  }
}

class ModelInferenceService {
  ModelInferenceService._();
  static final ModelInferenceService instance = ModelInferenceService._();

  Interpreter? _validator;
  Interpreter? _classifier;
  Interpreter? _severity;

  bool get isLoaded =>
      _classifier != null &&
      _severity != null &&
      (!MlConfig.validatorEnabled || _validator != null);

  Future<void> loadModels() async {
    if (isLoaded) return;

    if (MlConfig.validatorEnabled) {
      _validator = await Interpreter.fromAsset(MlConfig.validatorAssetPath);
      _debugPrintShapes('validator', _validator!);
    }

    _classifier = await Interpreter.fromAsset(MlConfig.classifierAssetPath);
    _severity = await Interpreter.fromAsset(MlConfig.severityAssetPath);

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

  List<List<List<double>>> _preprocessScaled(File file, int size) {
    final bytes = file.readAsBytesSync();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) throw Exception('Could not decode image.');

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

  /// NCHW preprocessing for the YOLO severity model: [1, 3, H, W].
  List<List<List<List<double>>>> _preprocessNCHW(File file, int w, int h) {
    final bytes = file.readAsBytesSync();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) throw Exception('Could not decode image.');

    final resized = img.copyResize(decoded, width: w, height: h);

    final channelData = List.generate(3, (c) {
      return List.generate(h, (y) {
        return List.generate(w, (x) {
          final p = resized.getPixel(x, y);
          final value = c == 0 ? p.r : (c == 1 ? p.g : p.b);
          return value / 255.0;
        });
      });
    });

    return [channelData];
  }

  int _argmax(List<double> scores) {
    int best = 0;
    for (int i = 1; i < scores.length; i++) {
      if (scores[i] > scores[best]) best = i;
    }
    return best;
  }

  double _sigmoid(double x) => 1.0 / (1.0 + math.exp(-x));

  List<_Box> _nms(List<_Box> boxes, double iouThreshold) {
    boxes.sort((a, b) => b.score.compareTo(a.score));
    final kept = <_Box>[];

    for (final box in boxes) {
      bool overlaps = false;
      for (final k in kept) {
        if (box.iou(k) > iouThreshold) {
          overlaps = true;
          break;
        }
      }
      if (!overlaps) kept.add(box);
    }
    return kept;
  }

  Future<MlResult> validatePomegranate(File imageFile) async {
    await loadModels();

    if (!MlConfig.validatorEnabled) {
      return MlResult('pomegranate', 1.0);
    }

    final size = MlConfig.validatorInputSize;
    final input = [_preprocessScaled(imageFile, size)];

    final outputShape = _validator!.getOutputTensor(0).shape;
    final outLen = outputShape.last;

    if (outLen == 1) {
      final output = List.generate(1, (_) => List.filled(1, 0.0));
      _validator!.run(input, output);
      final prob = output[0][0];
      final isPom = prob >= MlConfig.validatorAcceptThreshold;
      return MlResult(
        isPom ? 'pomegranate' : 'not_pomegranate',
        isPom ? prob : 1 - prob,
      );
    }

    final output = List.generate(1, (_) => List.filled(outLen, 0.0));
    _validator!.run(input, output);
    final scores = output[0];
    final idx = _argmax(scores);
    return MlResult(MlLabels.validatorClasses[idx], scores[idx]);
  }

  Future<MlResult> classifyDisease(File imageFile) async {
    await loadModels();

    final size = MlConfig.classifierInputSize;
    final input = [_preprocessScaled(imageFile, size)];

    final numClasses = MlLabels.diseaseClasses.length;
    final output = List.generate(1, (_) => List.filled(numClasses, 0.0));

    _classifier!.run(input, output);

    final scores = output[0];
    final idx = _argmax(scores);
    return MlResult(MlLabels.diseaseClasses[idx], scores[idx]);
  }

  /// SIMPLE severity estimate: (sum of affected-region box areas) /
  /// (largest fruit box area) * 100. Uses only the detection head
  /// [1,38,8400] — ignores mask coefficients/protos entirely, so no
  /// pixel-level decoding, no coordinate-scale guessing. Box coords
  /// from YOLOv8 TFLite export are pixel-space (0-inputSize), used
  /// directly — areas are ratios so the exact scale cancels out.
  Future<SeverityResult> analyzeSeverity(File imageFile) async {
    await loadModels();

    final inputShape = _severity!.getInputTensor(0).shape; // [1,3,H,W]
    final inputW = inputShape[3];
    final inputH = inputShape[2];

    final input = _preprocessNCHW(imageFile, inputW, inputH);

    final detShape = _severity!.getOutputTensor(0).shape; // [1,38,8400]
    final numAttrs = detShape[1];
    final numAnchors = detShape[2];

    final detOutput = List.generate(
      1,
      (_) => List.generate(numAttrs, (_) => List.filled(numAnchors, 0.0)),
    );

    // We only need output[0] here — pass a dummy for output[1] (protos)
    // since this model has 2 outputs but we're not using the mask data.
    final protoShape = _severity!.getOutputTensor(1).shape;
    final protoOutput = List.generate(
      1,
      (_) => List.generate(
        protoShape[1],
        (_) => List.generate(
          protoShape[2],
          (_) => List.filled(protoShape[3], 0.0),
        ),
      ),
    );

    _severity!.runForMultipleInputs([input], {0: detOutput, 1: protoOutput});

    const affectedClassIdx = 0;
    const fruitClassIdx = 1;
    const scoreOffset = 4; // after cx, cy, w, h

    final affectedBoxes = <_Box>[];
    final fruitBoxes = <_Box>[];

    for (int a = 0; a < numAnchors; a++) {
      final cx = detOutput[0][0][a];
      final cy = detOutput[0][1][a];
      final bw = detOutput[0][2][a];
      final bh = detOutput[0][3][a];

      final affectedRaw = detOutput[0][scoreOffset + affectedClassIdx][a];
      final fruitRaw = detOutput[0][scoreOffset + fruitClassIdx][a];

      // Scores are typically raw logits in YOLOv8 TFLite export.
      final affectedScore = _sigmoid(affectedRaw);
      final fruitScore = _sigmoid(fruitRaw);

      if (affectedScore >= MlConfig.yoloConfThreshold) {
        affectedBoxes.add(_Box(cx, cy, bw, bh, affectedScore));
      }
      if (fruitScore >= MlConfig.yoloConfThreshold) {
        fruitBoxes.add(_Box(cx, cy, bw, bh, fruitScore));
      }
    }

    final keptFruit = _nms(fruitBoxes, MlConfig.yoloIouThreshold);
    final keptAffected = _nms(affectedBoxes, MlConfig.yoloIouThreshold);

    // ignore: avoid_print
    print(
      '🔍 Severity: fruitBoxes=${keptFruit.length} '
      'affectedBoxes=${keptAffected.length}',
    );

    if (keptFruit.isEmpty) {
      return SeverityResult(0.0, 'N/A');
    }

    // Reference area = the single largest/most confident fruit box.
    keptFruit.sort((a, b) => b.score.compareTo(a.score));
    final fruitArea = keptFruit.first.area;

    if (fruitArea <= 0) {
      return SeverityResult(0.0, 'N/A');
    }

    // Sum affected-region box areas (capped so overlapping boxes can't
    // push the total past the fruit's own area).
    double affectedArea = 0.0;
    for (final b in keptAffected) {
      affectedArea += b.area;
    }
    affectedArea = math.min(affectedArea, fruitArea);

    double percentage = (affectedArea / fruitArea) * 100.0;
    percentage = percentage.clamp(0.0, 100.0);

    String level;
    if (percentage <= 38) {
      level = 'Mild';
    } else if (percentage <= 58) {
      level = 'Moderate';
    } else {
      level = 'Severe';
    }

    // ignore: avoid_print
    print(
      '🔍 Severity: fruitArea=$fruitArea affectedArea=$affectedArea '
      '→ ${percentage.toStringAsFixed(1)}% ($level)',
    );

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
