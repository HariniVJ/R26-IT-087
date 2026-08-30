import 'package:flutter/material.dart';

import '../../common/brand_color.dart';
import '../../models/Disease_prediction_result_model.dart';
import '../../services/disease/reminder_notification_service.dart';
import 'feedback_view.dart';

class ReminderSetupView extends StatefulWidget {
  final PredictionResultModel result;

  const ReminderSetupView({super.key, required this.result});

  @override
  State<ReminderSetupView> createState() => _ReminderSetupViewState();
}

class _ReminderSetupViewState extends State<ReminderSetupView>
    with SingleTickerProviderStateMixin {
  bool _reminderSet = false;
  bool _saving = false;

  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  int get _days =>
      widget.result.followUpDays > 0 ? widget.result.followUpDays : 7;

  DateTime get _reminderDate =>
      widget.result.detectedAt.add(Duration(days: _days));

  String get _formattedDate {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final d = _reminderDate;
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  Future<void> _handleSetReminder() async {
    setState(() => _saving = true);

    try {
      await ReminderNotificationService.instance.scheduleFollowUpReminder(
        diseaseName: widget.result.diseaseName,
        followUpDate: _reminderDate,
        predictionId: widget.result.predictionId,
      );

      if (!mounted) return;
      setState(() {
        _saving = false;
        _reminderSet = true;
      });

      _showSuccessDialog();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not set reminder: $e')));
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 32),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 74,
                height: 74,
                decoration: const BoxDecoration(
                  color: Color(0xFF2DBE72),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.notifications_active_rounded,
                  color: Colors.white,
                  size: 36,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Reminder Set!',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  color: BrandColor.darkText,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "We'll notify you on $_formattedDate to check "
                'your pomegranate again.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: BrandColor.lightText,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // close dialog
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FeedbackView(result: widget.result),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2DBE72),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BrandColor.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
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
            const SizedBox(height: 12),

            // ── Animated bell badge (replaces the 📅 emoji) ───────────
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, _) {
                final glow = 0.15 + (_pulseController.value * 0.15);
                return SizedBox(
                  width: 150,
                  height: 150,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: BrandColor.primary.withOpacity(glow),
                        ),
                      ),
                      Container(
                        width: 108,
                        height: 108,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [BrandColor.primary, BrandColor.secondary],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: BrandColor.primary.withOpacity(0.30),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Icon(
                          _reminderSet
                              ? Icons.notifications_active_rounded
                              : Icons.notifications_none_rounded,
                          color: Colors.white,
                          size: 46,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 26),

            const Text(
              'Re-apply treatment after',
              style: TextStyle(color: BrandColor.lightText, fontSize: 13),
            ),

            const SizedBox(height: 8),

            Text(
              '$_days Days',
              style: const TextStyle(
                color: BrandColor.primary,
                fontSize: 40,
                fontWeight: FontWeight.w900,
              ),
            ),

            const SizedBox(height: 6),

            // ── Exact reminder date chip ───────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: BrandColor.softPink,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: BrandColor.borderPink),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.event_rounded,
                    size: 15,
                    color: BrandColor.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _formattedDate,
                    style: const TextStyle(
                      color: BrandColor.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Info card ───────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: BrandColor.border),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.eco_rounded,
                        color: BrandColor.primary,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Disease: ${widget.result.diseaseName.replaceAll('_', ' ')}',
                          style: const TextStyle(
                            color: BrandColor.darkText,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 22, color: BrandColor.border),
                  const Text(
                    'We will send you a notification on your phone on the '
                    'follow-up date, reminding you to check whether the '
                    'treatment has worked and re-assess the fruit.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: BrandColor.lightText,
                      fontSize: 12.5,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            if (_reminderSet)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF2DBE72).withOpacity(0.10),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFF2DBE72).withOpacity(0.35),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(
                      Icons.check_circle_rounded,
                      color: Color(0xFF2DBE72),
                      size: 18,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Reminder scheduled',
                      style: TextStyle(
                        color: Color(0xFF2DBE72),
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: (_saving || _reminderSet)
                    ? null
                    : _handleSetReminder,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(
                        _reminderSet
                            ? Icons.check_rounded
                            : Icons.notifications_rounded,
                      ),
                label: Text(_reminderSet ? 'Reminder Set' : 'Set Reminder'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _reminderSet
                      ? const Color(0xFF2DBE72)
                      : BrandColor.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
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
                      builder: (_) => FeedbackView(result: widget.result),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: BrandColor.primary,
                  side: const BorderSide(color: BrandColor.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
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
