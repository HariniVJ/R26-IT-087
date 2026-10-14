import 'package:flutter/material.dart';

import '../../common/brand_color.dart';
import '../../common/disease/disease_helpers.dart';
import '../../l10n/d_app_strings.dart';
import '../../models/Disease_prediction_result_model.dart';
import '../../services/disease/treatment_data.dart';
import '../../widgets/disease_widgets.dart';
import 'disease_view.dart';
import 'history_detail_view.dart'; // TreatmentTypeSelector + TreatmentChoiceStore
import 'reminder_setup_view.dart';

/// Result screen.
///   Disease → treatment options + "Proceed to Reminder"
///   Healthy → healthy message + "Back to Home" (no treatment, no follow-up)
/// Photo has a "?" button (top-right) that explains the affected area.
/// All text follows the app language (Profile → Language) — see dt().
class ClassificationResultView extends StatefulWidget {
  final PredictionResultModel result;

  const ClassificationResultView({super.key, required this.result});

  @override
  State<ClassificationResultView> createState() =>
      _ClassificationResultViewState();
}

class _ClassificationResultViewState extends State<ClassificationResultView> {
  TreatmentType _selectedType = TreatmentType.organic;

  PredictionResultModel get r => widget.result;

  LanguageController get _lang => LanguageController.instance;

  /// Reminder button only for a disease result (never for healthy).
  bool get _needsFollowUp => r.needsTreatment && r.followUpDueDate != null;

  /// Chosen option by severity + 3–4 tips picked for THIS detection
  /// (in the current app language).
  TreatmentContent get _currentTreatment => TreatmentOptionsData.forDisease(
    r.diseaseName,
    _selectedType,
    severityLevel: r.severityLevel,
    seed: TreatmentOptionsData.seedFor(r.predictionId, r.detectedAt),
  );

  /// "Moderate (28.7%)" / "No Disease" — translated.
  String get _severityText => r.isHealthy
      ? dt('no_disease')
      : '${_lang.severity(r.severityLevel)} '
            '(${r.severityPercentage.toStringAsFixed(1)}%)';

  @override
  void initState() {
    super.initState();
    // Remember the default choice too, so History Detail shows the same.
    if (r.needsTreatment) {
      TreatmentChoiceStore.save(r.predictionId, _selectedType);
    }
  }

  void _selectType(TreatmentType type) {
    setState(() => _selectedType = type);
    TreatmentChoiceStore.save(r.predictionId, type);
  }

  void _goHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const DiseaseView()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Rebuild when the language changes (Profile → Language).
    return ListenableBuilder(
      listenable: _lang,
      builder: (context, _) => Scaffold(
        backgroundColor: BrandColor.background,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: Text(
            dt('detection_result'),
            style: const TextStyle(
              color: BrandColor.darkText,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Photo + "?" button (top-right) → affected-area popup
            MarkedDiseaseImage(result: r, height: 220, radius: 22),
            const SizedBox(height: 18),

            // ── Disease name ──
            Text(
              _lang.disease(r.diseaseName),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: BrandColor.darkText,
              ),
            ),

            const SizedBox(height: 16),

            // ── Confidence + Severity ──
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    icon: Icons.smart_toy_outlined,
                    label: dt('confidence_label'),
                    value: '${r.confidence.toStringAsFixed(1)}%',
                    color: BrandColor.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    icon: DiseaseHelpers.severityIcon(r.severityLevel),
                    label: dt('severity_label'),
                    value: _severityText,
                    color: r.isHealthy
                        ? BrandColor.lightText
                        : DiseaseHelpers.severityColor(r.severityLevel),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ── Body depends on the result type ──
            if (r.needsTreatment)
              ..._treatmentSection()
            else
              SectionCard(
                icon: r.isHealthy
                    ? Icons.eco_rounded
                    : Icons.info_outline_rounded,
                title: r.isHealthy ? dt('healthy_fruit') : dt('note'),
                color: r.isHealthy
                    ? const Color(0xFF2DBE72)
                    : BrandColor.primary,
                // Healthy → shown in the CURRENT language (not the saved text).
                child: BodyText(
                  r.isHealthy ? dt('healthy_no_action') : r.treatment,
                ),
              ),

            const SizedBox(height: 28),

            // ── Last button ──
            if (_needsFollowUp)
              PrimaryButton(
                label: dt('proceed_to_reminder'),
                icon: Icons.notifications_active_rounded,
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ReminderSetupView(
                      result: r,
                      treatmentType: _selectedType,
                    ),
                  ),
                ),
              )
            else
              PrimaryButton(
                label: dt('back_to_home'),
                icon: Icons.home_rounded,
                onPressed: _goHome,
              ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  List<Widget> _treatmentSection() {
    final treatment = _currentTreatment;
    return [
      Text(
        dt('treatment_options'),
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w900,
          color: BrandColor.darkText,
        ),
      ),
      const SizedBox(height: 6),
      Text(
        dt('treatment_options_subtitle'),
        style: const TextStyle(color: BrandColor.lightText, fontSize: 12.5),
      ),
      const SizedBox(height: 14),
      TreatmentTypeSelector(selected: _selectedType, onChanged: _selectType),
      const SizedBox(height: 16),
      SectionCard(
        icon: Icons.medication_liquid_rounded,
        title: dt('recommended_treatment'),
        child: RecommendationBody(
          text: treatment.recommendation,
          image: treatment.image,
        ),
      ),
      const SizedBox(height: 14),
      SectionCard(
        icon: Icons.health_and_safety_rounded,
        title: dt('prevention_tips'),
        color: BrandColor.secondary,
        child: BulletList(items: treatment.prevention),
      ),
    ];
  }
}
