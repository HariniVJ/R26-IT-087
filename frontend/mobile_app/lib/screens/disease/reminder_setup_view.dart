import 'package:flutter/material.dart';

import '../../common/brand_color.dart';
import '../../models/prediction_result_model.dart';
import 'feedback_view.dart';

class ReminderSetupView extends StatelessWidget {
  final PredictionResultModel result;

  const ReminderSetupView({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final days = result.followUpDays > 0 ? result.followUpDays : 7;

    return Scaffold(
      backgroundColor: BrandColor.background,

      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'Follow-up Reminder',
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
            const SizedBox(height: 25),

            const Text('📅', style: TextStyle(fontSize: 90)),

            const SizedBox(height: 22),

            const Text(
              'Re-apply treatment after',
              style: TextStyle(color: BrandColor.lightText),
            ),

            const SizedBox(height: 10),

            Text(
              '$days Days',
              style: const TextStyle(
                color: BrandColor.primary,
                fontSize: 40,
                fontWeight: FontWeight.w900,
              ),
            ),

            const SizedBox(height: 24),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: BrandColor.softPink,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: BrandColor.borderPink),
              ),
              child: const Text(
                'We will remind you to check your fruit again.',
                textAlign: TextAlign.center,
                style: TextStyle(color: BrandColor.lightText),
              ),
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Reminder saved')),
                  );
                },
                icon: const Icon(Icons.notifications_rounded),
                label: const Text('Set Reminder'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: BrandColor.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ),

            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              height: 54,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FeedbackView(result: result),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: BrandColor.primary,
                  side: const BorderSide(color: BrandColor.primary),
                ),
                child: const Text('Skip for Now'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
