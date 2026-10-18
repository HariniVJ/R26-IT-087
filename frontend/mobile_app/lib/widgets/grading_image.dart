// lib/widgets/grading_image.dart
import 'dart:io';
import 'package:flutter/material.dart';

/// Displays a grading result's photo with a safe fallback chain:
///
///   1) Remote Firebase Storage URL (`imageUrl`), if present and it
///      loads successfully.
///   2) Local device file (`imagePath`), if that file still exists on
///      this device — covers the case where the Storage upload hasn't
///      finished yet, failed, or the device was offline when saving.
///   3) A quality-colored placeholder with an emoji, so the UI never
///      shows a blank/broken box.
///
/// Use this everywhere a grading photo is shown (recent history row,
/// history list, history detail) instead of a raw Image.network, so
/// the fallback behaviour stays consistent across the whole app.
class GradingImage extends StatelessWidget {
  final String? imageUrl;
  final String? imagePath;
  final Color background;
  final String emoji;
  final BoxFit fit;
  final double emojiSize;

  const GradingImage({
    super.key,
    required this.imageUrl,
    required this.imagePath,
    required this.background,
    required this.emoji,
    this.fit = BoxFit.cover,
    this.emojiSize = 26,
  });

  bool get _hasUrl => imageUrl != null && imageUrl!.trim().isNotEmpty;

  bool get _hasLocalFile {
    final path = imagePath;
    if (path == null || path.trim().isEmpty) return false;
    try {
      return File(path).existsSync();
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasUrl) {
      return Image.network(
        imageUrl!,
        fit: fit,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return _loadingBox();
        },
        errorBuilder: (_, __, ___) => _fallback(),
      );
    }
    return _fallback();
  }

  Widget _fallback() {
    if (_hasLocalFile) {
      return Image.file(
        File(imagePath!),
        fit: fit,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }
    return _placeholder();
  }

  Widget _loadingBox() => Container(
    color: background,
    child: const Center(
      child: SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    ),
  );

  Widget _placeholder() => Container(
    color: background,
    child: Center(
      child: Text(emoji, style: TextStyle(fontSize: emojiSize)),
    ),
  );
}
