import 'package:flutter/material.dart';

import '../../common/brand_color.dart';
import '../../models/Disease_prediction_result_model.dart';
import 'severity_analysis_view.dart';

class ClassificationResultView extends StatelessWidget {
  final PredictionResultModel result;

  const ClassificationResultView({super.key, required this.result});

  Color get confidenceColor {
    if (result.confidence >= 80) {
      return BrandColor.green;
    }

    if (result.confidence >= 60) {
      return BrandColor.orange;
    }

    return BrandColor.primary;
  }

  String get confidenceText {
    if (result.confidence >= 80) {
      return 'High Confidence';
    }

    if (result.confidence >= 60) {
      return 'Medium Confidence';
    }

    return 'Low Confidence';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BrandColor.background,

      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'Detection Result',
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
            const SizedBox(height: 20),

            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: BrandColor.softPink,
                shape: BoxShape.circle,
                border: Border.all(color: BrandColor.borderPink),
              ),
              child: const Icon(
                Icons.biotech_rounded,
                color: BrandColor.primary,
                size: 46,
              ),
            ),

            const SizedBox(height: 18),

            const Text(
              'Disease Identified',
              style: TextStyle(color: BrandColor.lightText),
            ),

            const SizedBox(height: 6),

            Text(
              result.diseaseName.replaceAll('_', ' ').toUpperCase(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: BrandColor.primary,
                fontSize: 27,
                fontWeight: FontWeight.w900,
              ),
            ),

            const SizedBox(height: 28),

            const Text(
              'Confidence Score',
              style: TextStyle(color: BrandColor.lightText),
            ),

            const SizedBox(height: 5),

            Text(
              '${result.confidence.toStringAsFixed(1)}%',
              style: TextStyle(
                color: confidenceColor,
                fontSize: 42,
                fontWeight: FontWeight.w900,
              ),
            ),

            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: confidenceColor.withOpacity(.10),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: confidenceColor.withOpacity(.30)),
              ),
              child: Text(
                confidenceText,
                style: TextStyle(
                  color: confidenceColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),

            const SizedBox(height: 28),

            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: BrandColor.border),
              ),
              child: const Row(
                children: [
                  Icon(Icons.psychology_rounded, color: BrandColor.primary),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'AI Model',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  Text(
                    'MobileNet CNN',
                    style: TextStyle(color: BrandColor.lightText),
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
                      builder: (_) => SeverityAnalysisView(result: result),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: BrandColor.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('View Severity Analysis'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
