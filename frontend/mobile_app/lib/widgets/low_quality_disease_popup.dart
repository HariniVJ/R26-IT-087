import 'package:flutter/material.dart';

import '../common/brand_color.dart';
import '../models/Disease_prediction_result_model.dart';
import '../services/grading/grading_service.dart';

/// Shows a popup ONLY for the "disease" low-quality case. Physical
/// defects (crack / rot / sunburn) intentionally show NO popup — the
/// grading result screen already displays the recommendation cards for
/// those, so a popup on top would just be repetitive.
Future<void> showLowQualityPopup(BuildContext context, LowQualityInfo info) {
  if (!info.isDiseaseCase) {
    // 🆕 crack / rot / sunburn — no popup at all.
    return Future.value();
  }

  if (info.diseaseResult == null) {
    // Disease pipeline failed (e.g. binary validator rejected the
    // image) — show a graceful fallback instead of a crash/blank popup.
    return _showFallbackPopup(context);
  }
  return _showDiseasePopup(context, info.diseaseResult!);
}

// ── Disease case — full disease name + severity % + treatment ───────
Future<void> _showDiseasePopup(
  BuildContext context,
  PredictionResultModel diseaseResult,
) {
  final isHealthy = diseaseResult.diseaseName == 'Healthy';

  return showDialog(
    context: context,
    builder: (_) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: BrandColor.softPink,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.coronavirus_rounded,
                    color: BrandColor.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Low Quality — Disease Detected',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                          color: BrandColor.darkText,
                        ),
                      ),
                      Text(
                        diseaseResult.diseaseName.replaceAll('_', ' '),
                        style: const TextStyle(
                          color: BrandColor.lightText,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            if (!isHealthy) ...[
              Row(
                children: [
                  Icon(
                    Icons.medication_liquid_rounded,
                    color: BrandColor.primary,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Recommended Treatment',
                    style: TextStyle(
                      color: BrandColor.primary,
                      fontWeight: FontWeight.w900,
                      fontSize: 13.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                diseaseResult.treatment,
                style: const TextStyle(
                  color: BrandColor.lightText,
                  fontSize: 12.5,
                  height: 1.5,
                ),
              ),

              if (diseaseResult.prevention.isNotEmpty) ...[
                const SizedBox(height: 14),
                const Text(
                  'Prevention Tips',
                  style: TextStyle(
                    color: BrandColor.secondary,
                    fontWeight: FontWeight.w900,
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: 8),
                ...diseaseResult.prevention.map(
                  (tip) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              color: BrandColor.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            tip,
                            style: const TextStyle(
                              color: BrandColor.lightText,
                              fontSize: 12,
                              height: 1.45,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ] else
              const Text(
                'The fruit was graded low quality due to a disease '
                'category, but re-analysis found it healthy on closer '
                'inspection — you may want to re-check the fruit '
                'manually.',
                style: TextStyle(
                  color: BrandColor.lightText,
                  fontSize: 12.5,
                  height: 1.5,
                ),
              ),

            const SizedBox(height: 20),
            _closeButton(context),
          ],
        ),
      ),
    ),
  );
}

// ── Fallback if disease pipeline failed (e.g. validator rejected image) ──
Future<void> _showFallbackPopup(BuildContext context) {
  return showDialog(
    context: context,
    builder: (_) => AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      title: const Text('Low Quality Detected'),
      content: const Text(
        'The fruit was graded low quality due to a possible disease, '
        'but we could not confirm the exact type from this photo. '
        'Please try capturing a clearer image of the affected area.',
        style: TextStyle(color: BrandColor.lightText, fontSize: 13),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('OK', style: TextStyle(color: BrandColor.primary)),
        ),
      ],
    ),
  );
}

Widget _closeButton(BuildContext context) {
  return SizedBox(
    width: double.infinity,
    height: 48,
    child: ElevatedButton(
      onPressed: () => Navigator.pop(context),
      style: ElevatedButton.styleFrom(
        backgroundColor: BrandColor.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: const Text(
        'Got It',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
    ),
  );
}
