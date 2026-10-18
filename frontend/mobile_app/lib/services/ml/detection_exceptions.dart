enum NotPomegranateReason { noFruitDetected, notPomegranate }

/// Thrown when the image is rejected (no fruit found, or not a pomegranate).
class NotPomegranateException implements Exception {
  /// 0..1 confidence of "not_pomegranate".
  final double confidence;
  final NotPomegranateReason reason;

  NotPomegranateException(
    this.confidence, {
    this.reason = NotPomegranateReason.notPomegranate,
  });

  /// Key for AppStrings.translate(...) — use this in the UI for 3 languages.
  String get messageKey => reason == NotPomegranateReason.noFruitDetected
      ? 'no_fruit_detected'
      : 'not_pomegranate';

  @override
  String toString() => reason == NotPomegranateReason.noFruitDetected
      ? 'No pomegranate fruit was detected. '
          'Please capture a clear photo with the fruit in the centre.'
      : 'This does not look like a pomegranate fruit '
          '(${(confidence * 100).toStringAsFixed(1)}% confidence). '
          'Please capture a clear photo of a pomegranate.';
}
