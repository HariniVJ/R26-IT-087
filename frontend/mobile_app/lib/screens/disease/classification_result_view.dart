import 'dart:io';

import 'package:flutter/material.dart';

import '../../common/brand_color.dart';
import '../../models/Disease_prediction_result_model.dart';
import 'reminder_setup_view.dart';

enum TreatmentType { organic, chemical, hybrid }

class _TreatmentContent {
  final String recommendation;
  final List<String> prevention;
  const _TreatmentContent({
    required this.recommendation,
    required this.prevention,
  });
}

class ClassificationResultView extends StatefulWidget {
  final PredictionResultModel result;

  const ClassificationResultView({super.key, required this.result});

  @override
  State<ClassificationResultView> createState() =>
      _ClassificationResultViewState();
}

class _ClassificationResultViewState extends State<ClassificationResultView> {
  TreatmentType _selectedType = TreatmentType.organic;

  Color get _severityColor {
    switch (widget.result.severityLevel.toLowerCase()) {
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

  IconData get _severityIcon {
    switch (widget.result.severityLevel.toLowerCase()) {
      case 'mild':
        return Icons.check_circle_outline_rounded;
      case 'moderate':
        return Icons.warning_amber_rounded;
      case 'severe':
        return Icons.error_outline_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  // ── Organic / Chemical / Hybrid treatment content per disease ──────
  // NOTE: sample content — replace with agriculturally-verified text
  // (e.g. after expert review) before production use.
  static const Map<String, Map<TreatmentType, _TreatmentContent>>
  _treatmentDatabase = {
    'Alternaria': {
      TreatmentType.organic: _TreatmentContent(
        recommendation:
            'Spray neem oil solution (5ml/litre water) every 7 days. '
            'Apply a Trichoderma-based biofungicide to the soil around '
            'the root zone to boost natural resistance.',
        prevention: [
          'Remove and destroy fallen infected leaves/fruit regularly',
          'Avoid overhead irrigation that wets fruit surface',
          'Maintain wide plant spacing for airflow',
        ],
      ),
      TreatmentType.chemical: _TreatmentContent(
        recommendation:
            'Apply copper oxychloride (0.3%) or Mancozeb (0.25%) spray '
            'every 10-14 days until symptoms subside. Rotate fungicide '
            'groups to avoid resistance buildup.',
        prevention: [
          'Follow pre-harvest interval strictly before selling fruit',
          'Use protective equipment while spraying',
          'Do not exceed recommended dosage',
        ],
      ),
      TreatmentType.hybrid: _TreatmentContent(
        recommendation:
            'Start with neem oil spray for early/mild cases; switch to '
            'copper-based fungicide only if spread continues after '
            '2 organic applications. Alternate organic and chemical '
            'sprays to reduce chemical load.',
        prevention: [
          'Monitor weekly and escalate treatment only if needed',
          'Keep spray records to track what worked',
          'Combine pruning with spray program for best results',
        ],
      ),
    },
    'Anthracnose': {
      TreatmentType.organic: _TreatmentContent(
        recommendation:
            'Apply Bordeaux mixture (organic-approved) or neem-based '
            'spray at first sign of lesions. Introduce Trichoderma '
            'viride as a biological control agent.',
        prevention: [
          'Avoid injuring fruit during handling',
          'Thin fruit clusters to reduce humidity buildup',
          'Store harvested fruit in a cool, dry, ventilated place',
        ],
      ),
      TreatmentType.chemical: _TreatmentContent(
        recommendation:
            'Apply Carbendazim (0.1%) or Azoxystrobin-based fungicide '
            'spray at early symptom onset, repeating every 10-12 days.',
        prevention: [
          'Disinfect pruning tools between plants',
          'Avoid working in the orchard during wet weather',
          'Rotate active ingredients each season',
        ],
      ),
      TreatmentType.hybrid: _TreatmentContent(
        recommendation:
            'Use Bordeaux mixture as a preventive base spray, and add a '
            'targeted chemical fungicide (Carbendazim) only on heavily '
            'affected plants to limit overall chemical use.',
        prevention: [
          'Prioritize sanitation (remove infected debris) over spraying',
          'Reserve chemical spray for confirmed active outbreaks',
        ],
      ),
    },
    'Bacterial_Blight': {
      TreatmentType.organic: _TreatmentContent(
        recommendation:
            'Apply a copper-based organic bactericide (permitted for '
            'organic use) and remove infected plant parts by hand, '
            'burning the debris away from the orchard.',
        prevention: [
          'Avoid orchard work during or right after rain',
          'Use disease-free planting material',
          'Disinfect tools with alcohol/flame between cuts',
        ],
      ),
      TreatmentType.chemical: _TreatmentContent(
        recommendation:
            'Apply Streptocycline (0.02%) combined with copper '
            'oxychloride spray at 10-day intervals during active '
            'infection periods.',
        prevention: [
          'Do not over-irrigate — bacteria spread faster in wet conditions',
          'Isolate severely infected plants if possible',
        ],
      ),
      TreatmentType.hybrid: _TreatmentContent(
        recommendation:
            'Combine copper-based organic spray as the primary control '
            'with a single chemical Streptocycline application only if '
            'infection continues spreading after one week.',
        prevention: [
          'Track spread rate before deciding to escalate to chemical',
          'Maintain field hygiene as the first line of defense',
        ],
      ),
    },
    'Cercospora': {
      TreatmentType.organic: _TreatmentContent(
        recommendation:
            'Spray a neem oil and garlic extract mixture weekly. Apply '
            'compost tea to strengthen plant immunity against fungal spread.',
        prevention: [
          'Avoid excess nitrogen fertilizer, which encourages fungal growth',
          'Improve field drainage to reduce leaf wetness duration',
        ],
      ),
      TreatmentType.chemical: _TreatmentContent(
        recommendation:
            'Apply a systemic fungicide such as Propiconazole (0.1%) '
            'every 10-14 days, rotating with a different chemical class '
            'each cycle to prevent resistance.',
        prevention: [
          'Remove and destroy fallen infected leaves',
          'Rotate fungicide active ingredients each application',
        ],
      ),
      TreatmentType.hybrid: _TreatmentContent(
        recommendation:
            'Use neem-based spray as routine prevention; apply systemic '
            'fungicide only during peak humid season when organic '
            'control alone is insufficient.',
        prevention: [
          'Monitor humidity/weather conditions to time interventions',
          'Combine drainage improvement with spray schedule',
        ],
      ),
    },
  };

  static const _TreatmentContent _healthyContent = _TreatmentContent(
    recommendation:
        'No disease detected. Continue regular monitoring, balanced '
        'irrigation, and fertilization to maintain fruit health.',
    prevention: [
      'Inspect fruit weekly for early signs of disease',
      'Maintain balanced irrigation and fertilization schedule',
      'Prune regularly for good air circulation',
    ],
  );

  _TreatmentContent get _currentTreatment {
    if (widget.result.diseaseName == 'Healthy') return _healthyContent;
    return _treatmentDatabase[widget.result.diseaseName]?[_selectedType] ??
        const _TreatmentContent(
          recommendation:
              'Consult a local agricultural expert for a tailored '
              'treatment plan for this condition.',
          prevention: ['Monitor the fruit regularly for changes'],
        );
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    final hasImage =
        result.imagePath.isNotEmpty && File(result.imagePath).existsSync();
    final isHealthy = result.diseaseName == 'Healthy';

    return Scaffold(
      backgroundColor: BrandColor.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Detection Result',
          style: TextStyle(
            color: BrandColor.darkText,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Image ──────────────────────────────────────────────────
          ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: hasImage
                ? Image.file(
                    File(result.imagePath),
                    height: 220,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  )
                : Container(
                    height: 220,
                    width: double.infinity,
                    color: BrandColor.softPink,
                    child: Icon(
                      Icons.image_rounded,
                      color: BrandColor.primary,
                      size: 50,
                    ),
                  ),
          ),

          const SizedBox(height: 18),

          // ── Disease name ───────────────────────────────────────────
          Text(
            result.diseaseName.replaceAll('_', ' '),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: BrandColor.darkText,
            ),
          ),

          const SizedBox(height: 16),

          // ── AI Model confidence + Severity side-by-side ─────────────
          Row(
            children: [
              Expanded(
                child: _statCard(
                  icon: Icons.smart_toy_outlined,
                  label: 'Confidence',
                  value: '${result.confidence.toStringAsFixed(1)}%',
                  color: BrandColor.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _statCard(
                  icon: _severityIcon,
                  label: 'Severity',
                  // FIX: was the literal string 'result.severityLevel'
                  // (missing $ interpolation) — now correctly shows the
                  // actual level + percentage, e.g. "Moderate (41%)".
                  value: isHealthy
                      ? 'No Disease'
                      : '${result.severityLevel} '
                            '(${result.severityPercentage.toStringAsFixed(0)}%)',
                  color: isHealthy ? BrandColor.lightText : _severityColor,
                ),
              ),
            ],
          ),

          if (!isHealthy) ...[
            const SizedBox(height: 28),
            const Text(
              'Treatment Options',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: BrandColor.darkText,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Choose a treatment approach that fits your farm',
              style: TextStyle(color: BrandColor.lightText, fontSize: 12.5),
            ),
            const SizedBox(height: 14),

            // ── Organic / Chemical / Hybrid selector ──────────────────
            _treatmentTypeSelector(),

            const SizedBox(height: 16),

            // ── Recommendation card for selected type ─────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: BrandColor.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.medication_liquid_rounded,
                        color: BrandColor.primary,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Recommended Treatment',
                        style: TextStyle(
                          color: BrandColor.primary,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _currentTreatment.recommendation,
                    style: const TextStyle(
                      color: BrandColor.lightText,
                      height: 1.55,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // ── Prevention card for selected type ─────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: BrandColor.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.health_and_safety_rounded,
                        color: BrandColor.secondary,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Prevention Tips',
                        style: TextStyle(
                          color: BrandColor.secondary,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ..._currentTreatment.prevention.map(
                    (tip) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
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
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 28),

          // ── Proceed to Reminder — last element on the screen ────────
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ReminderSetupView(result: result),
                  ),
                );
              },
              icon: const Icon(Icons.notifications_active_rounded),
              label: const Text(
                'Proceed to Reminder',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: BrandColor.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _statCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: BrandColor.border),
      ),
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

  Widget _treatmentTypeSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: BrandColor.softPink,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BrandColor.borderPink),
      ),
      child: Row(
        children: TreatmentType.values.map((type) {
          final selected = _selectedType == type;
          final label = switch (type) {
            TreatmentType.organic => 'Organic',
            TreatmentType.chemical => 'Chemical',
            TreatmentType.hybrid => 'Hybrid',
          };
          final icon = switch (type) {
            TreatmentType.organic => Icons.eco_rounded,
            TreatmentType.chemical => Icons.science_rounded,
            TreatmentType.hybrid => Icons.merge_type_rounded,
          };

          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedType = type),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: selected ? BrandColor.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Icon(
                      icon,
                      size: 18,
                      color: selected ? Colors.white : BrandColor.darkText,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: TextStyle(
                        color: selected ? Colors.white : BrandColor.darkText,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
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
