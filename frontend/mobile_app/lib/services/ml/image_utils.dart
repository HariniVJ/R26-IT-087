import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;

import '../../../config/disease_ml_config.dart';

/// Image helpers shared by all disease models (same steps as the Colab code).
class ImageUtils {
  ImageUtils._();

  /// Decode a photo, apply camera EXIF rotation (cv2.imread does this in
  /// Colab), and convert to plain 8-bit RGB.
  static img.Image decodeFile(File file) {
    final decoded = img.decodeImage(file.readAsBytesSync());
    if (decoded == null) throw Exception('Could not decode image.');
    return img
        .bakeOrientation(decoded)
        .convert(format: img.Format.uint8, numChannels: 3);
  }

  /// Colab resize_max(): shrink so the longest side ≤ [maxSide].
  static img.Image resizeMax(img.Image src, [int maxSide = DiseaseImageConfig.maxSide]) {
    final longest = math.max(src.width, src.height);
    if (longest <= maxSide) return src;
    final s = maxSide / longest;
    return img.copyResize(
      src,
      width: (src.width * s).round(),
      height: (src.height * s).round(),
      interpolation: img.Interpolation.average,
    );
  }

  /// decode + EXIF + resize_max — the first step of every prediction.
  static img.Image loadForInference(File file) => resizeMax(decodeFile(file));

  /// Colab to_cnn_input(): resize to size×size, RGB, scale to 0..1.
  /// The validator and classifier both contain their own Rescaling layer,
  /// so do NOT apply MobileNetV2's −1..1 scaling here.
  static List<List<List<List<double>>>> toInput01(img.Image src, int size) {
    final resized = img.copyResize(
      src,
      width: size,
      height: size,
      interpolation: img.Interpolation.average,
    );
    return [
      List.generate(size, (y) {
        return List.generate(size, (x) {
          final p = resized.getPixel(x, y);
          return [p.r / 255.0, p.g / 255.0, p.b / 255.0];
        });
      }),
    ];
  }

    /// OLD validator input: resize to size×size, RGB, scale to −1..1.
  static List<List<List<List<double>>>> toInputMinus1To1(
    img.Image src,
    int size,
  ) {
    final resized = img.copyResize(
      src,
      width: size,
      height: size,
      interpolation: img.Interpolation.average,
    );
    return [
      List.generate(size, (y) {
        return List.generate(size, (x) {
          final p = resized.getPixel(x, y);
          return [
            (p.r / 127.5) - 1.0,
            (p.g / 127.5) - 1.0,
            (p.b / 127.5) - 1.0,
          ];
        });
      }),
    ];
  }
}
