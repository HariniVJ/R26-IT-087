import 'package:flutter/material.dart';

import '../../common/brand_color.dart';
import '../../l10n/d_app_strings.dart';
import '../../models/Disease_prediction_result_model.dart';
import '../../services/disease/reminder_notification_service.dart';
import '../../services/disease/treatment_data.dart';
import 'disease_view.dart';
import 'history_detail_view.dart'; // TreatmentChoiceStore

/// Follow-up reminder screen (opened only for a confident disease result).
/// Shows: re-apply interval (from treatment_data.dart), next date,
/// disease name and how many times the treatment should be applied.
/// All text follows the app language (Profile → Language).
class ReminderSetupView extends StatefulWidget {
  final PredictionResultModel result;

  /// Organic or Chemical — chosen on the result page. If null, the saved
  /// choice (TreatmentChoiceStore) is loaded.
  final TreatmentType? treatmentType;

  const ReminderSetupView({
    super.key,
    required this.result,
    this.treatmentType,
  });

  @override
  State<ReminderSetupView> createState() => _ReminderSetupViewState();
}

class _ReminderSetupViewState extends State<ReminderSetupView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  bool _saving = false;
  bool _reminderSet = false;

  static const _green = Color(0xFF2DBE72);

  PredictionResultModel get r => widget.result;

  late TreatmentType _type = widget.treatmentType ?? TreatmentType.organic;

  /// Schedule of the chosen option — from treatment_data.dart.
  TreatmentSchedule get _schedule =>
      TreatmentData.scheduleFor(r.diseaseName, r.severityLevel, type: _type);

  /// Days between applications.
  int get _days => _schedule.everyDays;

  /// How many times to apply.
  int get _times => _schedule.applications;

  /// Next application date = detection date + interval.
  DateTime get _reminderDate => r.detectedAt.add(Duration(days: _days));

  @override
  void initState() {
    super.initState();
    if (widget.treatmentType == null) {
      TreatmentChoiceStore.load(r.predictionId).then((type) {
        if (mounted) setState(() => _type = type);
      });
    }
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  void _goHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const DiseaseView()),
      (route) => false,
    );
  }

  Future<void> _setReminder() async {
    setState(() => _saving = true);
    try {
      await ReminderNotificationService.instance.scheduleFollowUpReminder(
        diseaseName: r.diseaseName,
        followUpDate: _reminderDate,
        predictionId: r.predictionId,
      );
      if (!mounted) return;
      setState(() => _reminderSet = true);
      await _showSuccessDialog();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(dtf('reminder_failed', {'error': '$e'}))),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _showSuccessDialog() {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 78,
                height: 78,
                decoration: const BoxDecoration(
                  color: _green,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.notifications_active_rounded,
                  color: Colors.white,
                  size: 38,
                ),
              ),
              const SizedBox(height: 22),
              Text(
                dt('reminder_set_title'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  color: BrandColor.darkText,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                dtf('reminder_set_msg', {'date': dShortDate(_reminderDate)}),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: BrandColor.lightText,
                  fontSize: 13.5,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _goHome();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _green,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    dt('continue_btn'),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
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

  @override
  Widget build(BuildContext context) {
    // Rebuild when the language changes (Profile → Language).
    return ListenableBuilder(
      listenable: LanguageController.instance,
      builder: (context, _) => Scaffold(
        backgroundColor: BrandColor.background,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: BrandColor.primary,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            dt('follow_up_reminder'),
            style: const TextStyle(
              color: BrandColor.darkText,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                  child: Column(
                    children: [
                      _pulsingBell(),
                      const SizedBox(height: 26),
                      Text(
                        dt('reapply_after'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: BrandColor.lightText,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        dtf('n_days', {'n': '$_days'}),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: BrandColor.primary,
                          fontSize: 40,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _dateChip(),
                      const SizedBox(height: 26),
                      _infoCard(),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                child: Column(
                  children: [
                    if (_reminderSet) ...[
                      _scheduledBanner(),
                      const SizedBox(height: 12),
                    ],
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton.icon(
                        onPressed: (_saving || _reminderSet)
                            ? null
                            : _setReminder,
                        icon: _saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: Colors.white,
                                ),
                              )
                            : Icon(
                                _reminderSet
                                    ? Icons.check_rounded
                                    : Icons.notifications_rounded,
                                size: 20,
                              ),
                        label: Text(
                          _reminderSet
                              ? dt('reminder_set_btn')
                              : dt('set_reminder'),
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: BrandColor.primary,
                          foregroundColor: Colors.white,
                          // grey when already set, faded red while saving
                          disabledBackgroundColor: _reminderSet
                              ? Colors.grey.shade300
                              : BrandColor.primary.withOpacity(0.6),
                          disabledForegroundColor: _reminderSet
                              ? Colors.grey.shade600
                              : Colors.white,
                          elevation: _reminderSet ? 0 : 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: OutlinedButton(
                        onPressed: _saving ? null : _goHome,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: BrandColor.primary,
                          side: const BorderSide(
                            color: BrandColor.primary,
                            width: 1.4,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          dt('skip_for_now'),
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Green "Reminder scheduled" banner (after setting) ──
  Widget _scheduledBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: _green.withOpacity(0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _green.withOpacity(0.45)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle_rounded, color: _green, size: 20),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              dt('reminder_scheduled'),
              style: const TextStyle(
                color: _green,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Pulsing bell ──
  Widget _pulsingBell() {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final t = _pulse.value; // 0..1
        return Container(
          width: 150 + t * 10,
          height: 150 + t * 10,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: BrandColor.primary.withOpacity(0.18 + t * 0.10),
          ),
          child: child,
        );
      },
      child: Container(
        width: 110,
        height: 110,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [BrandColor.primary, Color(0xFFD6325A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: BrandColor.primary.withOpacity(0.35),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Icon(
          Icons.notifications_none_rounded,
          color: Colors.white,
          size: 46,
        ),
      ),
    );
  }

  // ── "📅 20 Oct 2026" chip ──
  Widget _dateChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      decoration: BoxDecoration(
        color: BrandColor.softPink,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: BrandColor.borderPink),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.event_rounded, size: 15, color: BrandColor.primary),
          const SizedBox(width: 6),
          Text(
            dShortDate(_reminderDate),
            style: const TextStyle(
              color: BrandColor.primary,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // ── Disease + how many applications ──
  Widget _infoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: BrandColor.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.eco_rounded,
                color: BrandColor.primary,
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  dtf('disease_with_name', {
                    'name': LanguageController.instance.disease(r.diseaseName),
                  }),
                  style: const TextStyle(
                    color: BrandColor.darkText,
                    fontWeight: FontWeight.w800,
                    fontSize: 14.5,
                  ),
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: BrandColor.border),
          ),
          _scheduleRow(
            Icons.repeat_rounded,
            dt('apply_every'),
            dtf('n_days_lower', {'n': '$_days'}),
          ),
          const SizedBox(height: 10),
          _scheduleRow(
            Icons.format_list_numbered_rounded,
            dt('number_of_applications'),
            dtf('n_times', {'n': '$_times'}),
          ),
          const SizedBox(height: 10),
          _scheduleRow(
            Icons.date_range_rounded,
            dt('total_treatment_period'),
            dtf('n_days_lower', {'n': '${_days * _times}'}),
          ),
        ],
      ),
    );
  }

  Widget _scheduleRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 17, color: BrandColor.lightText),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: BrandColor.lightText, fontSize: 13.5),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: BrandColor.darkText,
            fontWeight: FontWeight.w800,
            fontSize: 13.5,
          ),
        ),
      ],
    );
  }
}
