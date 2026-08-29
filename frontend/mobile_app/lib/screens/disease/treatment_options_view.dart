import 'package:flutter/material.dart';

import '../../common/brand_color.dart';
import '../../models/Disease_prediction_result_model.dart';
import 'reminder_setup_view.dart';

class TreatmentOptionsView extends StatelessWidget {
  final PredictionResultModel result;

  const TreatmentOptionsView({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BrandColor.background,

      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'Treatment Options',
          style: TextStyle(
            color: BrandColor.darkText,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _summaryRow('Disease', result.diseaseName),

            const SizedBox(height: 8),

            _summaryRow(
              'Severity',
              '${result.severityLevel} '
                  '(${result.severityPercentage.toStringAsFixed(1)}%)',
            ),

            const SizedBox(height: 18),

            _treatmentCard(
              title: 'Recommended Treatment',
              icon: Icons.eco_rounded,
              iconColor: BrandColor.green,
              text: result.treatment,
            ),

            if (result.prevention.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: _treatmentCard(
                  title: 'Prevention',
                  icon: Icons.health_and_safety_rounded,
                  iconColor: BrandColor.primary,
                  text: result.prevention.map((e) => '• $e').join('\n'),
                ),
              ),

            const SizedBox(height: 22),

            SizedBox(
              width: double.infinity,
              height: 58,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ReminderSetupView(result: result),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: BrandColor.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Proceed to Reminder'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BrandColor.border),
      ),
      child: Row(
        children: [
          Text('$label:', style: const TextStyle(color: BrandColor.lightText)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _treatmentCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required String text,
  }) {
    return Container(
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
              Icon(icon, color: iconColor),
              const SizedBox(width: 10),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
            ],
          ),

          const SizedBox(height: 14),

          Text(
            text,
            style: const TextStyle(color: BrandColor.lightText, height: 1.6),
          ),
        ],
      ),
    );
  }
}
