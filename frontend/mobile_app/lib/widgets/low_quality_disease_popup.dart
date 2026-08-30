import 'package:flutter/material.dart';

import '../common/brand_color.dart';
import '../models/Disease_prediction_result_model.dart';
import '../services/grading/grading_service.dart';

/// Shows the appropriate popup for a "low_quality" grading result:
///   - Physical defect (crack/rot/sunburn): simple explanation, no
///     disease pipeline was run for these.
///   - Disease: full disease name + severity + treatment + prevention,
///     fetched fresh from the Disease component's independent pipeline.
Future<void> showLowQualityPopup(BuildContext context, LowQualityInfo info) {
  if (info.isDiseaseCase) {
    if (info.diseaseResult == null) {
      // Disease pipeline failed (e.g. binary validator rejected the
      // image) — show a graceful fallback instead of a crash/blank popup.
      return _showFallbackPopup(context);
    }
    return _showDiseasePopup(context, info.diseaseResult!);
  }
  return _showPhysicalDefectPopup(context, info.physicalDefectType!);
}

// ── Disease case — full disease name + severity + treatment ─────────
Future<void> _showDiseasePopup(
  BuildContext context,
  PredictionResultModel diseaseResult,
) {
  final isHealthy = diseaseResult.diseaseName == 'Healthy';
  final severityColor = _severityColor(diseaseResult.severityLevel);

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
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: severityColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: severityColor.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.speed_rounded, color: severityColor, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      '${diseaseResult.severityLevel} · ${diseaseResult.severityPercentage.toStringAsFixed(1)}% affected',
                      style: TextStyle(
                        color: severityColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

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

// ── Physical defect case (crack / rot / sunburn) — no disease lookup ─
Future<void> _showPhysicalDefectPopup(BuildContext context, String defectType) {
  final info = _physicalDefectInfo(defectType);

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
                  child: Icon(info.icon, color: BrandColor.primary, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Low Quality Detected',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          color: BrandColor.darkText,
                        ),
                      ),
                      Text(
                        info.title,
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
            const SizedBox(height: 16),
            Text(
              info.description,
              style: const TextStyle(
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

class _DefectDisplayInfo {
  final IconData icon;
  final String title;
  final String description;
  _DefectDisplayInfo(this.icon, this.title, this.description);
}

_DefectDisplayInfo _physicalDefectInfo(String defectType) {
  switch (defectType) {
    case 'crack':
      return _DefectDisplayInfo(
        Icons.broken_image_rounded,
        'Crack',
        'The fruit surface has visible cracking, likely from irregular '
            'watering or fruit growth stress. Cracked fruit should be '
            'harvested promptly and used quickly, as cracks allow pests '
            'and rot organisms to enter.',
      );
    case 'rot':
      return _DefectDisplayInfo(
        Icons.eco_rounded,
        'Rot',
        'Signs of fruit rot were detected. Remove and discard the '
            'affected fruit to prevent spread to nearby fruit. Improve '
            'air circulation and avoid excess moisture around the plant.',
      );
    case 'sunburn':
      return _DefectDisplayInfo(
        Icons.wb_sunny_rounded,
        'Sunburn',
        'The fruit shows sun-scorch damage from prolonged direct sun '
            'exposure. Consider providing partial shade cover during '
            'peak sun hours, especially for exposed outer fruit.',
      );
    default:
      return _DefectDisplayInfo(
        Icons.warning_amber_rounded,
        'Low Quality',
        'This fruit was graded as low quality.',
      );
  }
}

Color _severityColor(String level) {
  switch (level.toLowerCase()) {
    case 'mild':
      return const Color(0xFF2DBE72);
    case 'moderate':
      return const Color(0xFFF59E0B);
    case 'severe':
      return BrandColor.primary;
    default:
      return BrandColor.lightText;
  }
}
