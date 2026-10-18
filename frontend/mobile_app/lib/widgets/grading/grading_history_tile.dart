// lib/widgets/grading_history_tile.dart
//
// ONE history-row design for Quality Grading, used in BOTH places:
//   • main screen  → "Grading History" (latest 3)
//   • View All     → history_screen.dart (with select / delete)
//
// Shows: image · quality level · defect / disease chip · date & time.
// (Recommendation text is NOT shown here on purpose.)
import 'package:flutter/material.dart';

import '../../l10n/d_app_strings.dart' as d;
import '../../l10n/q_app_strings.dart';
import '../../models/grading_result.dart';
import '../../theme/app_theme.dart';
import '../grading_image.dart';

class GradingHistoryTile extends StatelessWidget {
  final GradingResult result;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool selectionMode;
  final bool selected;

  /// Optional widget on the right (e.g. delete button). When null a
  /// chevron is shown.
  final Widget? trailing;

  /// TEMP: when given, a small edit icon appears on the image.
  final VoidCallback? onEditImage;
  final EdgeInsetsGeometry margin;

  const GradingHistoryTile({
    super.key,
    required this.result,
    this.onTap,
    this.onLongPress,
    this.selectionMode = false,
    this.selected = false,
    this.trailing,
    this.onEditImage,
    this.margin = const EdgeInsets.only(bottom: 10),
  });

  static const _red = Color(0xFFC1121F);
  static const _textSoft = Color(0xFF6B7280);
  static const _border = Color(0xFFEDEDF0);

  // ── Quality colours: High → green · Medium → yellow · Low → red ──
  static const highGreen = Color(0xFF16A34A);
  static const mediumYellow = Color(0xFFEAB308); // ring / border
  static const mediumYellowText = Color(0xFFCA8A04); // readable text
  static const lowRed = Color(0xFFDC2626);

  /// Main colour (ring / border).
  static Color qualityColor(String quality) {
    switch (quality) {
      case 'high_quality':
        return highGreen;
      case 'medium_quality':
        return mediumYellow;
      default:
        return lowRed;
    }
  }

  /// Text colour (yellow is darkened a little so it is readable on white).
  static Color qualityTextColor(String quality) =>
      quality == 'medium_quality' ? mediumYellowText : qualityColor(quality);

  @override
  Widget build(BuildContext context) {
    final ring = qualityColor(result.quality);
    final textColor = qualityTextColor(result.quality);
    final bg = QualityTheme.bgColor(result.quality);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      margin: margin,
      decoration: BoxDecoration(
        color: selected ? _red.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: selected ? _red : _border,
          width: selected ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          onLongPress: onLongPress,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                _thumbnail(ring, bg),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        qQuality(result.quality),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 5),
                      _issueChip(textColor),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.schedule_rounded,
                            size: 12,
                            color: _textSoft,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              _dateText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _textSoft,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (trailing != null) ...[
                  trailing!,
                ] else if (!selectionMode) ...[
                  const SizedBox(width: 2),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: _textSoft,
                    size: 20,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── image with quality-colour ring + selection overlay ──
  Widget _thumbnail(Color ring, Color bg) {
    return SizedBox(
      width: 60,
      height: 60,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: ring, width: 2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox.expand(
                child: GradingImage(
                  imageUrl: result.imageUrl,
                  imagePath: result.imagePath,
                  background: bg,
                  emoji: QualityTheme.emoji(result.quality),
                  emojiSize: 22,
                ),
              ),
            ),
          ),
          // TEMP: edit image button (bottom-right of the image)
          if (onEditImage != null && !selectionMode)
            Positioned(
              right: -6,
              bottom: -6,
              child: GestureDetector(
                onTap: onEditImage,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: _red,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.edit_rounded,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          if (selectionMode && selected)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: _red.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          if (selectionMode)
            Positioned(
              top: -5,
              left: -5,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? _red : Colors.white,
                  border: Border.all(
                    color: selected ? _red : const Color(0xFFD1D5DB),
                    width: 1.6,
                  ),
                ),
                child: selected
                    ? const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 14,
                      )
                    : null,
              ),
            ),
        ],
      ),
    );
  }

  // ── defect / disease chip ──
  //   Low + disease (name known) → disease NAME · severity   (red)
  //   Low + crack / rot / sunburn → that category            (red)
  //   everything else             → "No defect"              (quality colour)
   // ── defect / disease chip ──
  //   High / Medium               → "No defect"              (quality colour)
  //   Low + disease (name known)  → disease NAME · severity   (red)
  //   Low + crack / rot / sunburn → that category            (red)
  //   Low + anything else         → "Other defect"           (red)
  Widget _issueChip(Color qualityText) {
    final defect = result.defectType;
    final isLow = result.quality == 'low_quality';

    // Default for High / Medium.
    IconData icon = Icons.verified_rounded;
    String text = qt('no_defect');
    Color color = qualityText;

    if (isLow) {
      color = lowRed;
      if (defect == 'disease' && result.hasDiseaseInfo) {
        icon = Icons.coronavirus_rounded;
                // Disease name only (severity is shown on the detail page).
        text = d.LanguageController.instance.disease(result.diseaseName ?? '');
      } else if (defect == 'crack' || defect == 'rot' || defect == 'sunburn') {
        icon = Icons.warning_amber_rounded;
        text = qDefect(defect!);
      } else {
        // Low quality, but the exact defect is not known.
        icon = Icons.warning_amber_rounded;
        text = qt('other_defect');
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.09),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
  /// "14 Oct 2026 · 18:05"
  String get _dateText {
    final dt = result.dateTime;
    if (dt == null) return result.displayDate;
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${result.displayDate} · $h:$m';
  }
}
