import 'package:flutter/material.dart';

import '../common/brand_color.dart';
import '../common/disease/disease_helpers.dart';
import '../models/Disease_prediction_result_model.dart';

/// Small rounded badge: icon + text in one colour.
/// (Same style as the History page badges — reuse it everywhere.)
class MiniBadge extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  final bool large;

  const MiniBadge({
    super.key,
    required this.icon,
    required this.text,
    required this.color,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? 10 : 8,
        vertical: large ? 5 : 3,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: large ? 14 : 10, color: color),
          SizedBox(width: large ? 5 : 3),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: large ? 12.5 : 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Severity badge used on Home (Recent Detections), History list and
/// History Detail.
///   Healthy  → green  ✓ "Healthy"
///   Mild     → light green  "Mild · 21.4%"
///   Moderate → yellow       "Moderate · 45.3%"
///   Severe   → red          "Severe · 70.8%"
/// Colours come from DiseaseHelpers (one place for the whole app).
class SeverityChip extends StatelessWidget {
  final PredictionResultModel result;

  /// Show "· 45.3%" after the level (never for healthy fruit).
  final bool showPercent;

  /// Decimals for the percentage (1 → "45.3%" actual value, 0 → "45%").
  final int decimals;

  /// Bigger version for the detail page.
  final bool large;

  const SeverityChip({
    super.key,
    required this.result,
    this.showPercent = true,
    this.decimals = 1,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = DiseaseHelpers.statusColor(result);
    final String text;
    if (result.isHealthy) {
      text = 'Healthy';
    } else if (showPercent) {
      text =
          '${result.severityLevel} · '
          '${result.severityPercentage.toStringAsFixed(decimals)}%';
    } else {
      text = result.severityLevel;
    }

    return MiniBadge(
      icon: result.isHealthy ? Icons.check_circle_rounded : Icons.speed_rounded,
      text: text,
      color: color,
      large: large,
    );
  }
}

/// "58.8%" confidence badge — same style, grey. Shows the actual value
/// (1 decimal), not rounded to a whole number.
class ConfidenceBadge extends StatelessWidget {
  final PredictionResultModel result;
  final bool large;

  const ConfidenceBadge({super.key, required this.result, this.large = false});

  @override
  Widget build(BuildContext context) {
    return MiniBadge(
      icon: Icons.verified_rounded,
      text: '${result.confidence.toStringAsFixed(1)}%',
      color: BrandColor.lightText,
      large: large,
    );
  }
}
