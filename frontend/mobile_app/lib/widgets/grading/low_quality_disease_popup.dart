// lib/widgets/low_quality_disease_popup.dart
import 'package:flutter/material.dart';

import '../../common/brand_color.dart';
import '../../l10n/q_app_strings.dart';
import '../../services/disease/treatment_data.dart';
import '../../services/grading/grading_service.dart';

/// Shows a popup ONLY for the "disease" low-quality case. Physical
/// defects (crack / rot / sunburn) intentionally show NO popup — the
/// grading result screen already displays the recommendation cards for
/// those, so a popup on top would just be repetitive.
///
/// 🔧 Uses the Disease component's DiseaseFinding directly, so the
/// disease name, confidence and severity here are the SAME numbers the
/// Disease screen shows. All text follows the app language.
Future<void> showLowQualityPopup(BuildContext context, LowQualityInfo info) {
  if (!info.isDiseaseCase) {
    // crack / rot / sunburn — no popup at all.
    return Future.value();
  }

  final finding = info.finding;
  if (finding == null) return _showFallbackPopup(context, null);

  switch (finding.status) {
    case DiseaseCheckStatus.confirmed:
    case DiseaseCheckStatus.uncertain:
      return _showDiseasePopup(context, finding);
    case DiseaseCheckStatus.healthy:
      return _showHealthyPopup(context);
    case DiseaseCheckStatus.notDetected:
    case DiseaseCheckStatus.failed:
      return _showFallbackPopup(context, finding.status);
  }
}

// ── Disease case — name + confidence + severity + Organic/Chemical ──
Future<void> _showDiseasePopup(BuildContext context, DiseaseFinding finding) {
  return showDialog(
    context: context,
    builder: (dialogContext) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _popupHeader(
                title: qt('lq_disease_title'),
                subtitle: finding.displayName,
              ),
              const SizedBox(height: 18),
              DiseaseTreatmentPanel(
                confidenceText: finding.confidenceDisplay,
                severityText: finding.severityDisplay,
                isUncertain: finding.isUncertain,
                treatmentFor: finding.treatmentFor,
                scheduleFor: finding.scheduleFor,
                primary: BrandColor.primary,
                secondary: BrandColor.secondary,
                softBackground: BrandColor.softPink,
                textColor: BrandColor.lightText,
                titleColor: BrandColor.darkText,
              ),
              const SizedBox(height: 20),
              _closeButton(dialogContext),
            ],
          ),
        ),
      ),
    ),
  );
}

// ── Disease model says the fruit is healthy ──
Future<void> _showHealthyPopup(BuildContext context) {
  return showDialog(
    context: context,
    builder: (dialogContext) => Dialog(
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
            _popupHeader(
              title: qt('lq_disease_title'),
              subtitle: qt('healthy'),
            ),
            const SizedBox(height: 18),
            Text(
              qt('lq_healthy_body'),
              textAlign: TextAlign.justify,
              style: const TextStyle(
                color: BrandColor.lightText,
                fontSize: 12.5,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            _closeButton(dialogContext),
          ],
        ),
      ),
    ),
  );
}

// ── Fallback if disease pipeline failed / no fruit found ──
Future<void> _showFallbackPopup(
  BuildContext context,
  DiseaseCheckStatus? status,
) {
  final body = status == DiseaseCheckStatus.failed
      ? qt('disease_failed_note')
      : qt('lq_fallback_body');
  return showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      title: Text(qt('low_quality_detected')),
      content: Text(
        body,
        style: const TextStyle(color: BrandColor.lightText, fontSize: 13),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: Text(
            qt('ok'),
            style: const TextStyle(color: BrandColor.primary),
          ),
        ),
      ],
    ),
  );
}

Widget _popupHeader({required String title, required String subtitle}) {
  return Row(
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
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 15,
                color: BrandColor.darkText,
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(
                color: BrandColor.lightText,
                fontSize: 12.5,
              ),
            ),
          ],
        ),
      ),
    ],
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
      child: Text(
        qt('got_it'),
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════════════
//  SHARED PANEL — used by this popup AND the history-detail "eye" popup,
//  so both always show the same disease numbers and treatment.
//    • Disease confidence + severity (Disease component values)
//    • Organic / Chemical switch → recommendation, product image, schedule
//    • Prevention tips (same for Organic and Chemical)
// ═══════════════════════════════════════════════════════════════════════════
class DiseaseTreatmentPanel extends StatefulWidget {
  final String confidenceText;
  final String severityText;
  final bool isUncertain;
  final TreatmentContent? Function(TreatmentType type) treatmentFor;
  final TreatmentSchedule? Function(TreatmentType type)? scheduleFor;

  final Color primary;
  final Color secondary;
  final Color softBackground;
  final Color textColor;
  final Color titleColor;

  const DiseaseTreatmentPanel({
    super.key,
    required this.confidenceText,
    required this.severityText,
    required this.isUncertain,
    required this.treatmentFor,
    this.scheduleFor,
    required this.primary,
    required this.secondary,
    required this.softBackground,
    required this.textColor,
    required this.titleColor,
  });

  @override
  State<DiseaseTreatmentPanel> createState() => _DiseaseTreatmentPanelState();
}

class _DiseaseTreatmentPanelState extends State<DiseaseTreatmentPanel> {
  TreatmentType _type = TreatmentType.organic;

  @override
  Widget build(BuildContext context) {
    final content = widget.treatmentFor(_type);
    final schedule = widget.scheduleFor?.call(_type);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Confidence + severity ──
        _infoRow(
          Icons.verified_outlined,
          qt('disease_confidence'),
          widget.confidenceText,
        ),
        const SizedBox(height: 6),
        _infoRow(Icons.analytics_outlined, qt('severity'), widget.severityText),
        if (widget.isUncertain) ...[
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              qt('disease_uncertain_note'),
              style: const TextStyle(
                color: Color(0xFFEA580C),
                fontSize: 11.5,
                height: 1.4,
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),

        // ── Organic / Chemical — small icon toggle (right corner) ──
        Align(
          alignment: Alignment.centerRight,
          child: Container(
            height: 26,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: widget.softBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: widget.primary.withOpacity(0.25)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _typeTab(TreatmentType.organic, Icons.eco_rounded),
                _typeTab(TreatmentType.chemical, Icons.science_rounded),
              ],
            ),
          ),
        ),

        if (content != null) ...[
          Row(
            children: [
              Icon(
                Icons.medication_liquid_rounded,
                color: widget.primary,
                size: 16,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _type == TreatmentType.organic
                      ? qt('organic_treatment')
                      : qt('chemical_treatment'),
                  style: TextStyle(
                    color: widget.primary,
                    fontWeight: FontWeight.w900,
                    fontSize: 13.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (content.image != null) ...[
            Center(
              child: Image.asset(
                content.image!,
                height: 116,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
            const SizedBox(height: 8),
          ],
          Text(
            content.recommendation,
            textAlign: TextAlign.justify,
            style: TextStyle(
              color: widget.textColor,
              fontSize: 12.5,
              height: 1.5,
            ),
          ),
          if (schedule != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.event_repeat_rounded,
                  color: widget.primary,
                  size: 15,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    qtf('schedule_every', {
                      'd': '${schedule.everyDays}',
                      'n': '${schedule.applications}',
                    }),
                    style: TextStyle(
                      color: widget.titleColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (content.prevention.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              qt('prevention_tips'),
              style: TextStyle(
                color: widget.secondary,
                fontWeight: FontWeight.w900,
                fontSize: 13.5,
              ),
            ),
            const SizedBox(height: 8),
            ...content.prevention.map(
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
                          color: widget.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        tip,
                        textAlign: TextAlign.justify,
                        style: TextStyle(
                          color: widget.textColor,
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
        ],
      ],
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: widget.textColor, size: 16),
        const SizedBox(width: 6),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(text: '$label: '),
                TextSpan(
                  text: value,
                  style: TextStyle(
                    color: widget.titleColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            style: TextStyle(color: widget.textColor, fontSize: 12.5),
          ),
        ),
      ],
    );
  }

  Widget _typeTab(TreatmentType type, IconData icon) {
    final selected = _type == type;
    return Tooltip(
      message: type == TreatmentType.organic ? qt('organic') : qt('chemical'),
      child: GestureDetector(
        onTap: () => setState(() => _type = type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? widget.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            icon,
            size: 14,
            color: selected ? Colors.white : widget.primary,
          ),
        ),
      ),
    );
  }
}
