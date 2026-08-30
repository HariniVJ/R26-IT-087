import 'package:flutter/material.dart';

import '../../common/brand_color.dart';
import '../../models/Disease_prediction_result_model.dart';
import 'disease_view.dart';

class FeedbackView extends StatefulWidget {
  final PredictionResultModel result;

  const FeedbackView({super.key, required this.result});

  @override
  State<FeedbackView> createState() => _FeedbackViewState();
}

class _FeedbackViewState extends State<FeedbackView> {
  String? selected;
  bool isSubmitting = false;

  Future<void> _submitFeedback() async {
    if (selected == null || isSubmitting) return;

    setState(() {
      isSubmitting = true;
    });

    // Green success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: BrandColor.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Feedback submitted successfully: $selected',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    // Small delay so user can see success message
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    // Go directly to DiseaseView
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const DiseaseView()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BrandColor.background,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: BrandColor.darkText),
        title: const Text(
          'Treatment Feedback',
          style: TextStyle(
            color: BrandColor.darkText,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            children: [
              const SizedBox(height: 20),

              const Text(
                'How is the fruit now after the treatment?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: BrandColor.darkText,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                widget.result.diseaseName.replaceAll('_', ' '),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: BrandColor.lightText,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
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
                  onPressed: selected == null || isSubmitting
                      ? null
                      : _submitFeedback,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BrandColor.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: BrandColor.primary.withOpacity(
                      0.35,
                    ),
                    disabledForegroundColor: Colors.white70,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Submit Feedback',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
              ),
            ],
          ),
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
      onTap: isSubmitting
          ? null
          : () {
              setState(() {
                selected = title;
              });
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: active ? color : BrandColor.border,
            width: active ? 2 : 1,
          ),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.12),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: BrandColor.darkText,
                    ),
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

            if (active)
              Icon(Icons.check_circle_rounded, color: color, size: 24),
          ],
        ),
      ),
    );
  }
}
