import 'dart:io';

import 'package:flutter/foundation.dart' show compute, debugPrint;
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

import '../common/brand_color.dart';
import '../common/disease/disease_helpers.dart';
import '../models/Disease_prediction_result_model.dart';
import '../services/ml/fruit_segmentation_service.dart';
import '../services/ml/image_utils.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  REUSABLE WIDGETS FOR THE DISEASE SCREENS
//  Use these instead of copying the same Container/BoxDecoration code again.
// ═══════════════════════════════════════════════════════════════════════════

/// White rounded card with the standard border.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double radius;
  final Color color;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.margin,
    this.radius = 18,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: BrandColor.border),
      ),
      child: child,
    );
  }
}

/// Image from a local file, with a pink placeholder if it is missing.
class DiseaseImage extends StatelessWidget {
  final String path;
  final double height;
  final double? width;
  final double radius;
  final double iconSize;

  const DiseaseImage({
    super.key,
    required this.path,
    required this.height,
    this.width = double.infinity,
    this.radius = 20,
    this.iconSize = 42,
  });

  @override
  Widget build(BuildContext context) {
    final exists = path.isNotEmpty && File(path).existsSync();
    final placeholder = Container(
      width: width,
      height: height,
      color: BrandColor.softPink,
      child: Icon(
        Icons.image_rounded,
        color: BrandColor.primary,
        size: iconSize,
      ),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: exists
          ? Image.file(
              File(path),
              width: width,
              height: height,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => placeholder,
            )
          : placeholder,
    );
  }
}

/// Small stat box: icon, big value, small label.
class StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const StatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 14,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: BrandColor.lightText,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// "Title ........ Value" row.
class InfoRow extends StatelessWidget {
  final String title;
  final String value;

  const InfoRow({super.key, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      radius: 16,
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(color: BrandColor.lightText),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

/// Card with a coloured icon + title header and any content below.
class SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final Widget child;

  const SectionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.child,
    this.color = BrandColor.primary,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      radius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

/// Grey paragraph text used inside cards.
class BodyText extends StatelessWidget {
  final String text;
  const BodyText(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: BrandColor.lightText,
        height: 1.55,
        fontSize: 13,
      ),
    );
  }
}

/// Recommendation text (justified) with the product image on the right.
/// No image (null) → justified text only.
class RecommendationBody extends StatelessWidget {
  final String text;
  final String? image;
  const RecommendationBody({super.key, required this.text, this.image});

  static const double _imageSize = 116;

  @override
  Widget build(BuildContext context) {
    final body = Text(
      text,
      textAlign: TextAlign.justify,
      style: const TextStyle(
        color: BrandColor.lightText,
        height: 1.55,
        fontSize: 13,
      ),
    );
    if (image == null) return body;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: body),
        const SizedBox(width: 12),
        Image.asset(
          image!,
          width: _imageSize,
          height: _imageSize,
          fit: BoxFit.contain,
          // Missing file → small icon instead of a crash.
          errorBuilder: (_, __, ___) => const SizedBox(
            width: _imageSize,
            height: _imageSize,
            child: Icon(
              Icons.inventory_2_outlined,
              color: BrandColor.lightText,
              size: 32,
            ),
          ),
        ),
      ],
    );
  }
}

/// Bulleted list of short tips.
class BulletList extends StatelessWidget {
  final List<String> items;
  const BulletList({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: items
          .map(
            (tip) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        color: BrandColor.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      tip,
                      style: const TextStyle(
                        color: BrandColor.lightText,
                        fontSize: 12.5,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

/// Coloured banner for warnings (e.g. "Result uncertain").
class StatusBanner extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<String> messages;
  final Color color;

  const StatusBanner({
    super.key,
    required this.icon,
    required this.title,
    this.messages = const [],
    this.color = const Color(0xFFF59E0B),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.45)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w900,
                    fontSize: 13.5,
                  ),
                ),
                for (final m in messages) ...[
                  const SizedBox(height: 4),
                  Text(
                    m,
                    style: const TextStyle(
                      color: BrandColor.darkText,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Full-width brand button.
class PrimaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool loading;

  const PrimaryButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final child = loading
        ? const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: Colors.white,
            ),
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[Icon(icon), const SizedBox(width: 8)],
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ],
          );
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: BrandColor.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: BrandColor.primary.withOpacity(0.35),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: child,
      ),
    );
  }
}

/// Small centred brand-coloured spinner.
class SmallLoader extends StatelessWidget {
  final double height;
  const SmallLoader({super.key, this.height = 80});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: const Center(
        child: CircularProgressIndicator(
          color: BrandColor.primary,
          strokeWidth: 2,
        ),
      ),
    );
  }
}

/// Icon + grey text for empty lists.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String text;
  const EmptyState({super.key, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 22),
      child: Center(
        child: Column(
          children: [
            Icon(icon, color: BrandColor.lightText, size: 30),
            const SizedBox(height: 8),
            Text(
              text,
              style: const TextStyle(
                color: BrandColor.lightText,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Detection photo with a round "?" button (top-right).
/// Tapping "?" opens a popup with the MARKED photo
/// (red = affected area, green = fruit outline) and an explanation of the
/// severity level (Mild / Moderate / Severe).
class MarkedDiseaseImage extends StatelessWidget {
  final PredictionResultModel result;
  final double height;
  final double radius;

  const MarkedDiseaseImage({
    super.key,
    required this.result,
    this.height = 220,
    this.radius = 22,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhoto =
        result.imagePath.isNotEmpty && File(result.imagePath).existsSync();

    return SizedBox(
      width: double.infinity,
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          DiseaseImage(path: result.imagePath, height: height, radius: radius),

          // ── "?" button (top-right) ──
          if (hasPhoto)
            Positioned(
              top: 10,
              right: 10,
              child: Material(
                color: Colors.black.withOpacity(0.50),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => showDialog(
                    context: context,
                    builder: (_) => AffectedAreaDialog(result: result),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(
                      Icons.question_mark_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Top-level so it can run in a background isolate.
img.Image _decodeForMarks(String path) =>
    ImageUtils.loadForInference(File(path));

/// Popup: marked photo + severity level and percentage (close with ✕).
/// If the marked photo was not saved (older detections), it is created once
/// from the original photo and saved for next time.
class AffectedAreaDialog extends StatefulWidget {
  final PredictionResultModel result;

  const AffectedAreaDialog({super.key, required this.result});

  @override
  State<AffectedAreaDialog> createState() => _AffectedAreaDialogState();
}

class _AffectedAreaDialogState extends State<AffectedAreaDialog> {
  String? _markedPath;
  bool _loading = true;

  PredictionResultModel get r => widget.result;

  @override
  void initState() {
    super.initState();
    _loadMarked();
  }

  Future<void> _loadMarked() async {
    // Healthy → separate file with the green outline only (no red area).
    final marked = DiseaseHelpers.markedImagePath(r.imagePath);
    final path = r.isHealthy
        ? marked.replaceFirst('_marked.jpg', '_outline.jpg')
        : marked;
    try {
      if (!File(path).existsSync()) {
        // Older detection → make the marked image now and keep it.
        final image = await compute(_decodeForMarks, r.imagePath);
        final analysis = await FruitSegmentationService.instance.analyze(
          image,
          withMarks: true,
          showAffected: !r.isHealthy,
        );
        if (analysis?.marked != null) {
          await File(
            path,
          ).writeAsBytes(img.encodeJpg(analysis!.marked!, quality: 88));
        }
      }
      if (File(path).existsSync()) _markedPath = path;
    } catch (e) {
      debugPrint('Marked image not available: $e');
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final color = DiseaseHelpers.statusColor(r);

    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            Row(
              children: [
                const Icon(
                  Icons.layers_rounded,
                  color: BrandColor.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Affected Area',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: BrandColor.darkText,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.close_rounded,
                    color: BrandColor.lightText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // ── Marked photo ──
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: double.infinity,
                height: 240,
                color: BrandColor.softPink,
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: BrandColor.primary,
                          strokeWidth: 2.4,
                        ),
                      )
                    : Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.file(
                            File(_markedPath ?? r.imagePath),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Center(
                              child: Icon(
                                Icons.image_not_supported_outlined,
                                color: BrandColor.lightText,
                              ),
                            ),
                          ),
                          if (_markedPath != null)
                            Positioned(
                              left: 10,
                              bottom: 10,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.55),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Healthy → only the "Fruit" legend
                                    if (!r.isHealthy) ...const [
                                      _LegendDot(color: Color(0xFFDC2626)),
                                      SizedBox(width: 4),
                                      Text(
                                        'Affected',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                        ),
                                      ),
                                      SizedBox(width: 10),
                                    ],
                                    const _LegendDot(color: Color(0xFF22C55E)),
                                    const SizedBox(width: 4),
                                    const Text(
                                      'Fruit',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
              ),
            ),
            if (!_loading && _markedPath == null) ...[
              const SizedBox(height: 6),
              const Text(
                'Marked image is not available for this photo.',
                style: TextStyle(color: BrandColor.lightText, fontSize: 11.5),
              ),
            ],
            const SizedBox(height: 16),

            // ── Level + % ──
            Row(
              children: [
                Icon(DiseaseHelpers.statusIcon(r), color: color, size: 22),
                const SizedBox(width: 8),
                Text(
                  r.isHealthy ? 'Healthy' : r.severityLevel,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
                const Spacer(),
                if (!r.isHealthy)
                  Text(
                    '${r.severityPercentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  const _LegendDot({required this.color});

  @override
  Widget build(BuildContext context) => Container(
    width: 9,
    height: 9,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}
