import 'package:flutter/material.dart';

import '../../common/brand_color.dart';
import '../../models/Disease_prediction_result_model.dart';
import 'treatment_options_view.dart';

class SeverityAnalysisView extends StatelessWidget {
  final PredictionResultModel result;

  const SeverityAnalysisView({super.key, required this.result});

  Color get severityColor {
    switch (result.severityLevel.toLowerCase()) {
      case 'mild':
        return BrandColor.green;

      case 'moderate':
        return BrandColor.orange;

      default:
        return BrandColor.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BrandColor.background,

      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'Severity Analysis',
          style: TextStyle(
            color: BrandColor.darkText,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            const SizedBox(height: 10),

            SizedBox(
              width: 190,
              height: 190,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 180,
                    height: 180,
                    child: CircularProgressIndicator(
                      value: result.severityPercentage / 100,
                      strokeWidth: 16,
                      backgroundColor: const Color(0xFFF1F1F1),
                      color: severityColor,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${result.severityPercentage.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const Text(
                        'Affected Area',
                        style: TextStyle(
                          color: BrandColor.lightText,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
              decoration: BoxDecoration(
                color: severityColor.withOpacity(.10),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: severityColor.withOpacity(.30)),
              ),
              child: Text(
                result.severityLevel,
                style: TextStyle(
                  color: severityColor,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),

            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: BrandColor.border),
              ),
              child: const Row(
                children: [
                  Expanded(
                    child: _SeverityLegend(
                      name: 'Mild',
                      range: '0 - 38%',
                      color: BrandColor.green,
                    ),
                  ),
                  Expanded(
                    child: _SeverityLegend(
                      name: 'Moderate',
                      range: '>38 - 58%',
                      color: BrandColor.orange,
                    ),
                  ),
                  Expanded(
                    child: _SeverityLegend(
                      name: 'Severe',
                      range: '>58%',
                      color: BrandColor.primary,
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              height: 58,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TreatmentOptionsView(result: result),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: BrandColor.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('View Treatment Options'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SeverityLegend extends StatelessWidget {
  final String name;
  final String range;
  final Color color;

  const _SeverityLegend({
    required this.name,
    required this.range,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          range,
          style: const TextStyle(color: BrandColor.lightText, fontSize: 10),
        ),
        const SizedBox(height: 6),
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      ],
    );
  }
}
