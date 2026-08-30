import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class MlLabels {
  MlLabels._();
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
  static const classifierInputSize = 224;

  static const classifierAssetPath =
      'assets/models/pomegranate_disease_classifier.tflite';
  static const severityAssetPath =
      'assets/models/pomegranate_severity_seg_v2.tflite';

  // Class scores in this export are already activated (observed 0-1
  // range with no extra sigmoid needed) — see confThreshold usage below.
  static const yoloConfThreshold = 0.5;
  static const yoloIouThreshold = 0.45;
  static const maskThreshold = 0.5;
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

// ═══════════════════════════════════════════════════════════════════
// Top-level helpers — must be top-level (not class methods) so they
// can run inside a background isolate via compute(), keeping the UI
// responsive during the pixel-mask math.
// ═══════════════════════════════════════════════════════════════════

class _Detection {
  final double cx, cy, w, h, score;
  final List<double> maskCoeffs; // 32 raw mask coefficients
  _Detection(this.cx, this.cy, this.w, this.h, this.score, this.maskCoeffs);

  double get area => w.abs() * h.abs();

  double iou(_Detection other) {
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

double _sigmoid(double x) => 1.0 / (1.0 + math.exp(-x));

List<_Detection> _nms(List<_Detection> boxes, double iouThreshold) {
  boxes.sort((a, b) => b.score.compareTo(a.score));
  final kept = <_Detection>[];

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

/// Decodes a single detection's pixel mask at PROTO resolution
/// (e.g. 160x160) using the standard YOLOv8-seg formula:
/// mask = sigmoid( maskCoeffs · protos ), cropped to the box.
/// Box coords here are normalized (0-1); they're converted to proto
/// pixel coordinates internally.
List<List<bool>> _decodeMask(
  _Detection det,
  List<List<List<double>>> protos, // [32, protoH, protoW]
  int protoH,
  int protoW,
) {
  final numCoeffs = protos.length;

  final boxX1 = ((det.cx - det.w / 2) * protoW).floor().clamp(0, protoW - 1);
  final boxY1 = ((det.cy - det.h / 2) * protoH).floor().clamp(0, protoH - 1);
  final boxX2 = ((det.cx + det.w / 2) * protoW).ceil().clamp(0, protoW - 1);
  final boxY2 = ((det.cy + det.h / 2) * protoH).ceil().clamp(0, protoH - 1);

  final mask = List.generate(protoH, (_) => List.filled(protoW, false));

  for (int y = boxY1; y <= boxY2; y++) {
    for (int x = boxX1; x <= boxX2; x++) {
      double sum = 0.0;
      for (int c = 0; c < numCoeffs; c++) {
        sum += det.maskCoeffs[c] * protos[c][y][x];
      }
      mask[y][x] = _sigmoid(sum) >= MlConfig.maskThreshold;
    }
  }

  return mask;
}

int _countTruePixels(List<List<bool>> mask) {
  int count = 0;
  for (final row in mask) {
    for (final v in row) {
      if (v) count++;
    }
  }
  return count;
}

/// Runs in a background isolate via compute(). Mirrors exactly what the
/// Colab `calculate_severity_from_segmentation()` function did:
/// fruit_mask = largest fruit detection's pixel mask
/// affected_union = union of all affected-region pixel masks
/// severity% = (affected_union & fruit_mask pixels) / (fruit_mask pixels) * 100
SeverityResult _processSeverityOutput(Map<String, dynamic> args) {
  final detOutput = args['detOutput'] as List<List<List<double>>>;
  final protoOutput = args['protoOutput'] as List<List<List<List<double>>>>;
  final numAnchors = args['numAnchors'] as int;
  final protoH = args['protoH'] as int;
  final protoW = args['protoW'] as int;
  final numMaskCoeffs = args['numMaskCoeffs'] as int;

  const affectedClassIdx = 0;
  const fruitClassIdx = 1;
  const scoreOffset = 4; // after cx, cy, w, h
  final maskOffset = scoreOffset + MlLabels.yoloClasses.length; // 6

  final affectedDets = <_Detection>[];
  final fruitDets = <_Detection>[];

  for (int a = 0; a < numAnchors; a++) {
    final cx = detOutput[0][0][a];
    final cy = detOutput[0][1][a];
    final bw = detOutput[0][2][a];
    final bh = detOutput[0][3][a];

    // Class scores are already activated in this export — no sigmoid.
    final affectedScore = detOutput[0][scoreOffset + affectedClassIdx][a];
    final fruitScore = detOutput[0][scoreOffset + fruitClassIdx][a];

    if (affectedScore >= MlConfig.yoloConfThreshold) {
      final coeffs = List.generate(
        numMaskCoeffs,
        (m) => detOutput[0][maskOffset + m][a],
      );
      affectedDets.add(_Detection(cx, cy, bw, bh, affectedScore, coeffs));
    }
    if (fruitScore >= MlConfig.yoloConfThreshold) {
      final coeffs = List.generate(
        numMaskCoeffs,
        (m) => detOutput[0][maskOffset + m][a],
      );
      fruitDets.add(_Detection(cx, cy, bw, bh, fruitScore, coeffs));
    }
  }

  final keptFruit = _nms(fruitDets, MlConfig.yoloIouThreshold);
  final keptAffected = _nms(affectedDets, MlConfig.yoloIouThreshold);

  if (keptFruit.isEmpty) {
    return SeverityResult(0.0, 'N/A');
  }

  // Reference fruit mask = the highest-confidence fruit detection.
  keptFruit.sort((a, b) => b.score.compareTo(a.score));
  final fruitMask = _decodeMask(
    keptFruit.first,
    protoOutput[0],
    protoH,
    protoW,
  );

  final fruitPixelCount = _countTruePixels(fruitMask);
  if (fruitPixelCount == 0) {
    return SeverityResult(0.0, 'N/A');
  }

  // Union of all affected-region masks.
  final affectedMasks = keptAffected
      .map((det) => _decodeMask(det, protoOutput[0], protoH, protoW))
      .toList();

  int affectedPixelCount = 0;
  for (int y = 0; y < protoH; y++) {
    for (int x = 0; x < protoW; x++) {
      if (!fruitMask[y][x]) continue; // only count within fruit boundary

      for (final mask in affectedMasks) {
        if (mask[y][x]) {
          affectedPixelCount++;
          break; // count each fruit pixel once
        }
      }
    }
  }

  double percentage = (affectedPixelCount / fruitPixelCount) * 100.0;
  percentage = percentage.clamp(0.0, 100.0);

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

// ═══════════════════════════════════════════════════════════════════
// Main service class
// ═══════════════════════════════════════════════════════════════════

class ModelInferenceService {
  ModelInferenceService._();
  static final ModelInferenceService instance = ModelInferenceService._();

  Interpreter? _classifier;
  Interpreter? _severity;

  // Which output-tensor index holds the detection head vs the mask
  // protos — auto-detected from tensor shape.
  int _detOutputIndex = 0;
  int _protoOutputIndex = 1;

  bool get isLoaded => _classifier != null && _severity != null;

  Future<void> loadModels() async {
    if (isLoaded) return;

    try {
      _classifier = await Interpreter.fromAsset(MlConfig.classifierAssetPath);
      _debugPrintShapes('classifier', _classifier!);
    } catch (e) {
      throw Exception(
        'Failed to load disease classifier model. Check that '
        '${MlConfig.classifierAssetPath} exists and is a valid TFLite '
        'file.\nOriginal error: $e',
      );
    }

    try {
      _severity = await Interpreter.fromAsset(MlConfig.severityAssetPath);
      _debugPrintShapes('severity', _severity!);
      _detectSeverityOutputOrder();
    } catch (e) {
      throw Exception(
        'Failed to load severity segmentation model.\nOriginal error: $e',
      );
    }
  }

  void _detectSeverityOutputOrder() {
    final shape0 = _severity!.getOutputTensor(0).shape;
    final shape1 = _severity!.getOutputTensor(1).shape;

    if (shape0.length == 3 && shape1.length == 4) {
      _detOutputIndex = 0;
      _protoOutputIndex = 1;
    } else if (shape0.length == 4 && shape1.length == 3) {
      _detOutputIndex = 1;
      _protoOutputIndex = 0;
    } else {
      // ignore: avoid_print
      print(
        '⚠️ Unexpected severity model output shapes: $shape0, $shape1. '
        'Defaulting to output[0]=detection, output[1]=protos.',
      );
      _detOutputIndex = 0;
      _protoOutputIndex = 1;
    }

    // ignore: avoid_print
    print(
      '[severity] detected detOutputIndex=$_detOutputIndex '
      'protoOutputIndex=$_protoOutputIndex',
    );
  }

  void _debugPrintShapes(String name, Interpreter interp) {
    // ignore: avoid_print
    print(
      '[$name] input=${interp.getInputTensor(0).shape} '
      'output0=${interp.getOutputTensor(0).shape} '
      'output1=${interp.getOutputTensors().length > 1 ? interp.getOutputTensor(1).shape : "n/a"}',
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

  /// Full pixel-mask severity calculation — matches the Colab
  /// `calculate_severity_from_segmentation()` method exactly:
  /// decode real instance masks (not just bounding boxes), then compute
  /// affected-pixel-overlap ÷ fruit-pixel-count. Runs in a background
  /// isolate so the per-pixel math never freezes the UI.
  Future<SeverityResult> analyzeSeverity(File imageFile) async {
    await loadModels();

    final inputShape = _severity!.getInputTensor(0).shape; // [1,3,H,W]
    final inputW = inputShape[3];
    final inputH = inputShape[2];

    final input = _preprocessNCHW(imageFile, inputW, inputH);

    final detShape = _severity!.getOutputTensor(_detOutputIndex).shape;
    final numAttrs = detShape[1];
    final numAnchors = detShape[2];

    final protoShape = _severity!.getOutputTensor(_protoOutputIndex).shape;
    final numMaskCoeffs = protoShape[1];
    final protoH = protoShape[2];
    final protoW = protoShape[3];

    final detOutput = List.generate(
      1,
      (_) => List.generate(numAttrs, (_) => List.filled(numAnchors, 0.0)),
    );
    final protoOutput = List.generate(
      1,
      (_) => List.generate(
        numMaskCoeffs,
        (_) => List.generate(protoH, (_) => List.filled(protoW, 0.0)),
      ),
    );

    _severity!.runForMultipleInputs(
      [input],
      {_detOutputIndex: detOutput, _protoOutputIndex: protoOutput},
    );

    final result = await compute(_processSeverityOutput, {
      'detOutput': detOutput,
      'protoOutput': protoOutput,
      'numAnchors': numAnchors,
      'protoH': protoH,
      'protoW': protoW,
      'numMaskCoeffs': numMaskCoeffs,
    });

    // ignore: avoid_print
    print(
      '🔍 Severity (pixel-mask): ${result.percentage.toStringAsFixed(1)}% '
      '(${result.level})',
    );

    return result;
  }

  void dispose() {
    _classifier?.close();
    _severity?.close();
    _classifier = null;
    _severity = null;
  }
}
