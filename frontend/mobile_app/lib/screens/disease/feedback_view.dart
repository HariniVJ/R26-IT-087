import 'package:flutter/material.dart';

import '../../common/brand_color.dart';
import '../../models/prediction_result_model.dart';

class FeedbackView extends StatefulWidget {
  final PredictionResultModel result;

  const FeedbackView({super.key, required this.result});

  @override
  State<FeedbackView> createState() => _FeedbackViewState();
}

class _FeedbackViewState extends State<FeedbackView> {
  String? selected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BrandColor.background,

      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'Treatment Feedback',
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

            const Text(
              'How is the fruit now after the treatment?',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),

            const SizedBox(height: 28),

            _feedbackOption(
              title: 'Recovered',
              subtitle: 'Fruit is healthy now',
              icon: Icons.sentiment_very_satisfied_rounded,
              color: BrandColor.green,
            ),

            _feedbackOption(
              title: 'Partially Recovered',
              subtitle: 'Some improvement',
              icon: Icons.sentiment_neutral_rounded,
              color: BrandColor.orange,
            ),

            _feedbackOption(
              title: 'Not Recovered',
              subtitle: 'No improvement',
              icon: Icons.sentiment_dissatisfied_rounded,
              color: BrandColor.primary,
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: selected == null
                    ? null
                    : () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Feedback submitted: $selected'),
                          ),
                        );
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: BrandColor.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Submit Feedback'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _feedbackOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    final active = selected == title;

    return GestureDetector(
      onTap: () {
        setState(() {
          selected = title;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: active ? color : BrandColor.border,
            width: active ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 34),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: BrandColor.lightText,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            if (active) Icon(Icons.check_circle_rounded, color: color),
          ],
        ),
      ),
    );
  }
}
