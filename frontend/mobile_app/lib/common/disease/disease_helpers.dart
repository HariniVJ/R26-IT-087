import 'package:flutter/material.dart';

import '../../models/Disease_prediction_result_model.dart';
import '../brand_color.dart';

/// Small shared helpers for the disease screens (formatting, colours, icons).
/// Use these instead of re-writing the same switch / date code in each screen.
class DiseaseHelpers {
  DiseaseHelpers._();

  // ── Status colours (one place for the whole app) ──
  static const Color healthyColor = Color(0xFF16A34A); // green
  static const Color mildColor = Color(0xFF65A30D); // light (lime) green
  static const Color moderateColor = Color(0xFFEAB308); // yellow
  static const Color severeColor = Color(0xFFDC2626); // red
  static const Color uncertainColor = Color(0xFFF59E0B); // amber

  /// Marked image saved next to the photo:
  ///   .../detection_123.jpg → .../detection_123_marked.jpg
  static String markedImagePath(String imagePath) {
    final dot = imagePath.lastIndexOf('.');
    final base = dot > 0 ? imagePath.substring(0, dot) : imagePath;
    return '${base}_marked.jpg';
  }

  /// "Bacterial_Blight" → "Bacterial Blight"
  static String displayName(String name) => name.replaceAll('_', ' ');

  static Color severityColor(String level) {
    switch (level.toLowerCase()) {
      case 'healthy':
        return healthyColor;
      case 'mild':
        return mildColor;
      case 'moderate':
        return moderateColor;
      case 'severe':
        return severeColor;
      default:
        return BrandColor.lightText;
    }
  }

  static IconData severityIcon(String level) {
    switch (level.toLowerCase()) {
      case 'healthy':
        return Icons.check_circle_rounded;
      case 'mild':
        return Icons.info_outline_rounded;
      case 'moderate':
        return Icons.warning_amber_rounded;
      case 'severe':
        return Icons.error_outline_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  // ── Status for a whole result (healthy → green tick, else by severity) ──
  static Color statusColor(PredictionResultModel r) =>
      r.isHealthy ? healthyColor : severityColor(r.severityLevel);

  static IconData statusIcon(PredictionResultModel r) =>
      r.isHealthy ? Icons.check_circle_rounded : severityIcon(r.severityLevel);

  static String statusLabel(PredictionResultModel r) =>
      r.isHealthy ? 'Healthy' : r.severityLevel;

  /// "Moderate (41%)" — or "No Disease" for a healthy fruit.
  static String severityText(PredictionResultModel r, {int decimals = 1}) {
    if (r.isHealthy) return 'No Disease';
    return '${r.severityLevel} (${r.severityPercentage.toStringAsFixed(decimals)}%)';
  }

  /// Today / Yesterday / 3 days ago / 12/10/2026 (calendar days)
    /// Always the actual date — e.g. 15/10/2026
  static String relativeDate(DateTime date) {
    final d = date.toLocal();
    return '${d.day}/${d.month}/${d.year}';
  }

  /// Today, 09:30 / Tomorrow, 09:30 / 12/10/2026, 09:30
    /// Today, 09:30 / Tomorrow, 09:30 / 12/10/2026, 09:30 (calendar days)
  static String reminderDate(DateTime date) {
    final d = date.toLocal();
    final days = _calendarDays(d, DateTime.now());
    final time =
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    if (days == 0) return 'Today, $time';
    if (days == 1) return 'Tomorrow, $time';
    return '${d.day}/${d.month}/${d.year}, $time';
  }

  /// Whole calendar days from [b] to [a] (time of day ignored).
  static int _calendarDays(DateTime a, DateTime b) => DateTime(
    a.year,
    a.month,
    a.day,
  ).difference(DateTime(b.year, b.month, b.day)).inDays;
}
