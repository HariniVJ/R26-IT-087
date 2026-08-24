import 'package:flutter/material.dart';

import '../../common/brand_color.dart';
import '../../models/prediction_result_model.dart';

class HistoryDetailView extends StatelessWidget {
  final PredictionResultModel result;

  const HistoryDetailView({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BrandColor.background,

      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'Detection Detail',
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
            if (result.imagePath.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  result.imagePath,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),

            const SizedBox(height: 18),

            _row('Disease', result.diseaseName),

            _row(
              'Severity',
              '${result.severityLevel} '
                  '(${result.severityPercentage.toStringAsFixed(1)}%)',
            ),

            _row('Confidence', '${result.confidence.toStringAsFixed(1)}%'),

            _row('Follow-up', '${result.followUpDays} Days'),

            const SizedBox(height: 12),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: BrandColor.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Treatment',
                    style: TextStyle(
                      color: BrandColor.primary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    result.treatment,
                    style: const TextStyle(
                      color: BrandColor.lightText,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String title, String value) {
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
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
