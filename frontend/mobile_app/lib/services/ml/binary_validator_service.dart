import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

import '../../../config/disease_ml_config.dart';
import 'fruit_segmentation_service.dart';
import 'image_utils.dart';
import 'tflite_helper.dart';

class ValidatorResult {
  final bool isPomegranate;
  final String label;

  /// Confidence of [label] (0..1) — same meaning as before.
  final double confidence;

  /// Raw p(pomegranate), 0..1.
  final double pomegranateProbability;

  ValidatorResult({
    required this.isPomegranate,
    required this.label,
    required this.confidence,
    this.pomegranateProbability = 0.0,
  });
}

/// Model 1 — "Is this a pomegranate?"
///
/// IMPORTANT (fix): the new validator was trained on the YOLO fruit crop with
/// gray background and 0..1 input. The old code sent the FULL photo scaled to
/// −1..1 to the OLD model, so results never matched Colab.
class BinaryValidatorService {
  BinaryValidatorService._();
  static final BinaryValidatorService instance = BinaryValidatorService._();

  Interpreter? _interpreter;
  bool get isLoaded => _interpreter != null;

  Future<void> loadModel() async {
    _interpreter ??= await TfliteHelper.load(DiseaseModels.validator, 'validator');
  }

  /// p(pomegranate) for a fruit crop (from FruitSegmentationService).
  Future<double> pomegranateProbability(img.Image crop) async {
    await loadModel();
    final it = _interpreter!;
    final input = DiseaseModels.validatorLegacyMode
        ? ImageUtils.toInputMinus1To1(crop, DiseaseImageConfig.cnnInputSize)
        : ImageUtils.toInput01(crop, DiseaseImageConfig.cnnInputSize);
    final outLen = it.getOutputTensor(0).shape.last;
    final output = List.generate(1, (_) => List.filled(outLen, 0.0));
    it.run(input, output);

    final scores = List<double>.from(output[0]);
    final p = outLen == 1
        ? scores[0] // single sigmoid
        : scores[DiseaseLabels.validatorClasses.indexOf('pomegranate')];
    debugPrint('🔍 Validator p(pomegranate)=${p.toStringAsFixed(3)}');
    return p;
  }

  /// Validates an already-cropped fruit image (used by DiseasePipeline).
  Future<ValidatorResult> validateCrop(img.Image crop) async {
    final p = await pomegranateProbability(crop);
    final isPom = p >= DiseaseThresholds.validatorAccept;
    return ValidatorResult(
      isPomegranate: isPom,
      label: isPom ? 'pomegranate' : 'not_pomegranate',
      confidence: isPom ? p : 1 - p,
      pomegranateProbability: p,
    );
  }

  /// Same signature as before: validates a photo file.
  /// Runs YOLO first; no fruit found ⇒ not a pomegranate.
  Future<ValidatorResult> validate(File imageFile) async {
    final image = ImageUtils.loadForInference(imageFile);
    final fruit = await FruitSegmentationService.instance.analyze(image);
    if (fruit == null) {
      return ValidatorResult(
        isPomegranate: false,
        label: 'not_pomegranate',
        confidence: 1.0,
        pomegranateProbability: 0.0,
      );
    }
    return validateCrop(fruit.crop);
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
  }
}
