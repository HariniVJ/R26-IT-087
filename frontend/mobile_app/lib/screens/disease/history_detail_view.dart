import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../common/brand_color.dart';
import '../../common/disease/disease_helpers.dart';
import '../../l10n/d_app_strings.dart';
import '../../models/Disease_prediction_result_model.dart';
import '../../services/disease/treatment_data.dart';
import '../../widgets/disease_widgets.dart';
import '../../widgets/severity_chip.dart';

/// Detail page for one saved detection.
///   Disease  → result rows + Follow-up Schedule + Treatment Plan
///              (only the Organic OR Chemical option chosen on the result page)
///   Healthy  → result rows + "Healthy Fruit" card
/// All text follows the app language (Profile → Language).
class HistoryDetailView extends StatefulWidget {
  final PredictionResultModel result;

  const HistoryDetailView({super.key, required this.result});

  @override
  State<HistoryDetailView> createState() => _HistoryDetailViewState();
}

class _HistoryDetailViewState extends State<HistoryDetailView> {
  TreatmentType _selectedType = TreatmentType.organic;
  bool _choiceLoaded =
      false; // avoid showing Organic before the saved choice loads

  PredictionResultModel get result => widget.result;

  LanguageController get _lang => LanguageController.instance;

  /// Schedule of the CHOSEN option — Organic and Chemical differ.
  TreatmentSchedule get _schedule => TreatmentData.scheduleFor(
    result.diseaseName,
    result.severityLevel,
    type: _selectedType,
  );
  int get _days => _schedule.everyDays;
  int get _times => _schedule.applications;

  /// Chosen option (Organic / Chemical) by severity + the same 3–4 tips
  /// shown on the result page (in the current app language).
  TreatmentContent get _treatment => TreatmentOptionsData.forDisease(
    result.diseaseName,
    _selectedType,
    severityLevel: result.severityLevel,
    seed: TreatmentOptionsData.seedFor(result.predictionId, result.detectedAt),
  );

  @override
  void initState() {
    super.initState();
    // Show the same Organic / Chemical choice the user picked on the result page.
    TreatmentChoiceStore.load(result.predictionId).then((type) {
      if (mounted) {
        setState(() {
          _selectedType = type;
          _choiceLoaded = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _lang,
      builder: (context, _) => Scaffold(
        backgroundColor: BrandColor.background,
        appBar: AppBar(
          backgroundColor: Colors.white,
          title: Text(
            dt('detection_detail'),
            style: const TextStyle(
              color: BrandColor.darkText,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── IMAGE: photo + "?" button → affected-area popup ──
              MarkedDiseaseImage(result: result, height: 200, radius: 20),

              const SizedBox(height: 18),

              // ── RESULT ──
              _row(dt('disease_label'), _lang.disease(result.diseaseName)),
              _rowWidget(
                dt('severity_label'),
                SeverityChip(result: result, showPercent: true, large: true),
              ),
              _row(
                dt('confidence_label'),
                '${result.confidence.toStringAsFixed(1)}%',
              ),
              _row(dt('detected'), dRelativeDate(result.detectedAt)),

              const SizedBox(height: 14),

              if (result.needsTreatment) ...[
                // ── FOLLOW-UP SCHEDULE ──
                _sectionTitle(dt('follow_up_schedule')),
                const SizedBox(height: 10),
                _scheduleCard(),

                const SizedBox(height: 22),

                // ── TREATMENT PLAN (only the option chosen on the result page) ──
                Row(
                  children: [
                    Expanded(child: _sectionTitle(dt('treatment_plan'))),
                    if (_choiceLoaded) _chosenTypeChip(),
                  ],
                ),
                const SizedBox(height: 12),
                if (!_choiceLoaded)
                  const SmallLoader()
                else ...[
                  SectionCard(
                    icon: _selectedType == TreatmentType.organic
                        ? Icons.eco_rounded
                        : Icons.science_rounded,
                    title: _selectedType == TreatmentType.organic
                        ? dt('organic_treatment')
                        : dt('chemical_treatment'),
                    child: RecommendationBody(
                      text: _treatment.recommendation,
                      image: _treatment.image,
                    ),
                  ),
                  const SizedBox(height: 14),
                  SectionCard(
                    icon: Icons.health_and_safety_rounded,
                    title: dt('prevention_tips'),
                    color: BrandColor.secondary,
                    child: BulletList(items: _treatment.prevention),
                  ),
                ],
              ] else
                // Healthy / uncertain → simple message card
                SectionCard(
                  icon: result.isHealthy
                      ? Icons.eco_rounded
                      : Icons.info_outline_rounded,
                  title: result.isHealthy ? dt('healthy_fruit') : dt('note'),
                  color: result.isHealthy
                      ? DiseaseHelpers.healthyColor
                      : BrandColor.primary,
                  child: BodyText(
                    result.isHealthy
                        ? dt('healthy_no_action')
                        : result.treatment,
                  ),
                ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ── Follow-up schedule card ──
  Widget _scheduleCard() {
    // Next follow-up = detection date + interval of the chosen option.
    final due = result.followUpDueDate == null
        ? null
        : result.detectedAt.add(Duration(days: _days));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: BrandColor.border),
      ),
      child: Column(
        children: [
          // 3 big numbers
          Row(
            children: [
              Expanded(
                child: _scheduleStat('$_days', dt('days'), dt('apply_every')),
              ),
              _vDivider(),
              Expanded(
                child: _scheduleStat(
                  '$_times',
                  dt('times'),
                  dt('applications'),
                ),
              ),
              _vDivider(),
              Expanded(
                child: _scheduleStat(
                  '${_days * _times}',
                  dt('days'),
                  dt('total_period'),
                ),
              ),
            ],
          ),
          if (due != null) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Divider(height: 1, color: BrandColor.border),
            ),
            Row(
              children: [
                Icon(
                  result.followUpDone
                      ? Icons.task_alt_rounded
                      : Icons.event_rounded,
                  size: 18,
                  color: result.followUpDone
                      ? DiseaseHelpers.healthyColor
                      : BrandColor.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    result.followUpDone
                        ? dt('follow_up_completed')
                        : dt('next_follow_up'),
                    style: const TextStyle(
                      color: BrandColor.lightText,
                      fontSize: 13,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: BrandColor.softPink,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: BrandColor.borderPink),
                  ),
                  child: Text(
                    dShortDate(due),
                    style: const TextStyle(
                      color: BrandColor.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 12.5,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _scheduleStat(String value, String unit, String label) {
    return Column(
      children: [
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: value,
                style: const TextStyle(
                  color: BrandColor.primary,
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                ),
              ),
              TextSpan(
                text: ' $unit',
                style: const TextStyle(
                  color: BrandColor.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(color: BrandColor.lightText, fontSize: 11),
        ),
      ],
    );
  }

  /// "🌿 Organic" or "🧪 Chemical" — the type chosen on the result page.
  Widget _chosenTypeChip() {
    final organic = _selectedType == TreatmentType.organic;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: BrandColor.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            organic ? Icons.eco_rounded : Icons.science_rounded,
            size: 15,
            color: Colors.white,
          ),
          const SizedBox(width: 6),
          Text(
            organic ? dt('organic') : dt('chemical'),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _vDivider() =>
      Container(width: 1, height: 38, color: BrandColor.border);

  Widget _sectionTitle(String text) => Text(
    text,
    style: const TextStyle(
      color: BrandColor.darkText,
      fontWeight: FontWeight.w900,
      fontSize: 16,
    ),
  );

  /// "Title ........ Value" row with text value.
  Widget _row(String title, String value) {
    return _rowWidget(
      title,
      Text(
        value,
        textAlign: TextAlign.right,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
    );
  }

  /// "Title ........ [widget]" row (used for the severity chip).
  Widget _rowWidget(String title, Widget trailing) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BrandColor.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(color: BrandColor.lightText),
            ),
          ),
          Flexible(
            child: Align(alignment: Alignment.centerRight, child: trailing),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
//  Organic / Chemical selector + saved choice
//  (also used by classification_result_view.dart)
// ═══════════════════════════════════════════════════════════════════════

/// Organic / Chemical switch (icon + text side by side).
/// Used on the Result page only (History Detail shows just the chosen one).
class TreatmentTypeSelector extends StatelessWidget {
  final TreatmentType selected;
  final ValueChanged<TreatmentType> onChanged;

  const TreatmentTypeSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  /// Key for dt() + icon.
  static const _labels = {
    TreatmentType.organic: ('organic', Icons.eco_rounded),
    TreatmentType.chemical: ('chemical', Icons.science_rounded),
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: BrandColor.softPink,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BrandColor.borderPink),
      ),
      child: Row(
        children: TreatmentType.values.map((type) {
          final isSelected = selected == type;
          final (labelKey, icon) = _labels[type]!;
          final fg = isSelected ? Colors.white : BrandColor.darkText;

          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(type),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? BrandColor.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 18, color: fg),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        dt(labelKey),
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: fg,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Remembers which treatment (Organic / Chemical) the user picked for each
/// detection, so the History Detail page can show the same choice.
/// Saved on the phone (works offline). Default = Organic.
class TreatmentChoiceStore {
  TreatmentChoiceStore._();

  static String _key(String predictionId) => 'treatment_type_$predictionId';

  static Future<void> save(String? predictionId, TreatmentType type) async {
    if (predictionId == null || predictionId.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key(predictionId), type.name);
  }

  static Future<TreatmentType> load(String? predictionId) async {
    if (predictionId == null || predictionId.isEmpty) {
      return TreatmentType.organic;
    }
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key(predictionId));
    return TreatmentType.values.firstWhere(
      (t) => t.name == saved,
      orElse: () => TreatmentType.organic,
    );
  }
}
