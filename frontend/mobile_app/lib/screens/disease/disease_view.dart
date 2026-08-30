import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../common/brand_color.dart';
import '../../models/Disease_prediction_result_model.dart';
import '../../services/disease/history_service.dart';
import '../../services/disease/reminder_notification_service.dart';
import '../../widgets/app_bottom_nav_bar.dart';
import 'history_detail_view.dart';
import 'history_view.dart';
import 'image_preview_view.dart';

class DiseaseView extends StatefulWidget {
  const DiseaseView({super.key});

  @override
  State<DiseaseView> createState() => _DiseaseViewState();
}

enum _PickSource { none, camera, gallery }

class _DiseaseViewState extends State<DiseaseView>
    with TickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();

  _PickSource _activePick = _PickSource.none;

  late final AnimationController _scanLineController;
  late final AnimationController _fruitFloatController;

  late Future<List<PredictionResultModel>> _recentHistoryFuture;
  late Future<List<ReminderRecord>> _remindersFuture;

  // Warm gold accent — used only inside the scan card for contrast
  // against the brand red/pink, so the card doesn't read as "red on red".
  static const _gold = Color(0xFFE8A33D);

  @override
  void initState() {
    super.initState();

    _scanLineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _fruitFloatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);

    _recentHistoryFuture = _loadRecentHistory();
    _remindersFuture = ReminderNotificationService.instance.getAllReminders();
  }

  @override
  void dispose() {
    _scanLineController.dispose();
    _fruitFloatController.dispose();
    super.dispose();
  }

  Future<List<PredictionResultModel>> _loadRecentHistory() async {
    try {
      final all = await HistoryService.getFirebaseHistory();
      return all.take(3).toList();
    } catch (_) {
      return [];
    }
  }

  void _refreshHistory() {
    setState(() => _recentHistoryFuture = _loadRecentHistory());
  }

  void _refreshReminders() {
    setState(() {
      _remindersFuture = ReminderNotificationService.instance.getAllReminders();
    });
  }

  String get _farmerName {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName;
    if (displayName != null && displayName.trim().isNotEmpty) {
      return displayName.trim();
    }
    final email = user?.email;
    if (email != null && email.contains('@')) {
      return email.split('@').first;
    }
    return 'Farmer';
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  bool get _isBusy => _activePick != _PickSource.none;

  Future<void> _pickImage(ImageSource source, _PickSource which) async {
    if (_isBusy) return;

    setState(() => _activePick = which);

    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        imageQuality: 90,
        maxWidth: 1200,
        maxHeight: 1200,
      );

      if (file == null || !mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ImagePreviewView(imageFile: File(file.path)),
        ),
      );

      // Refresh the recent-history strip + reminders badge in case a
      // new detection / reminder was saved.
      if (mounted) {
        _refreshHistory();
        _refreshReminders();
      }
    } finally {
      if (mounted) setState(() => _activePick = _PickSource.none);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BrandColor.background,
      bottomNavigationBar: const AppBottomNavBar(current: AppNavTab.home),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _greetingHeader(),
              const SizedBox(height: 22),
              _scanFrameCard(),
              const SizedBox(height: 26),
              _actionButtons(),
              const SizedBox(height: 20),
              _infoStrip(),
              const SizedBox(height: 24),
              _recentHistorySection(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ── Greeting header ─────────────────────────────────────────────────
  Widget _greetingHeader() {
    final initials = _farmerName.trim().isNotEmpty
        ? _farmerName.trim()[0].toUpperCase()
        : 'F';

    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [BrandColor.primary, BrandColor.secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: BrandColor.primary.withOpacity(0.30),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Center(
            child: Text(
              initials,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _greeting,
                style: const TextStyle(
                  color: BrandColor.lightText,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _farmerName,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: BrandColor.darkText,
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        _notificationBell(),
      ],
    );
  }

  // ── Notification bell — unread badge + tap opens reminders popup ──
  Widget _notificationBell() {
    return FutureBuilder<List<ReminderRecord>>(
      future: _remindersFuture,
      builder: (context, snapshot) {
        final reminders = snapshot.data ?? <ReminderRecord>[];
        final unreadCount = reminders.where((r) => !r.isRead).length;

        return GestureDetector(
          onTap: _showRemindersPopup,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: BrandColor.softPink,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.notifications_none_rounded,
                  color: BrandColor.primary,
                  size: 20,
                ),
              ),
              if (unreadCount > 0)
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    decoration: const BoxDecoration(
                      color: Color(0xFFE24C4C),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        unreadCount > 9 ? '9+' : '$unreadCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // ── Reminders popup dialog ──────────────────────────────────────────
  Future<void> _showRemindersPopup() async {
    // Opening the notification center marks existing reminders as read.
    // They remain stored and visible in the popup.
    await ReminderNotificationService.instance.markAllAsRead();

    if (!mounted) return;
    _refreshReminders();

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 60,
          ),
          child: Container(
            constraints: const BoxConstraints(maxHeight: 520),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
            ),
            child: StatefulBuilder(
              builder: (context, setDialogState) {
                return FutureBuilder<List<ReminderRecord>>(
                  future: ReminderNotificationService.instance
                      .getAllReminders(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox(
                        height: 120,
                        child: Center(
                          child: CircularProgressIndicator(
                            color: BrandColor.primary,
                            strokeWidth: 2,
                          ),
                        ),
                      );
                    }

                    final reminders = snapshot.data ?? <ReminderRecord>[];

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(9),
                              decoration: BoxDecoration(
                                color: BrandColor.softPink,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.notifications_active_rounded,
                                color: BrandColor.primary,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Notifications',
                                    style: TextStyle(
                                      color: BrandColor.darkText,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 16,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Treatment follow-up reminders',
                                    style: TextStyle(
                                      color: BrandColor.lightText,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(dialogContext),
                              icon: const Icon(Icons.close_rounded, size: 20),
                              color: BrandColor.lightText,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        if (reminders.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 26),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.notifications_off_outlined,
                                    color: BrandColor.lightText,
                                    size: 32,
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    'No reminders set yet',
                                    style: TextStyle(
                                      color: BrandColor.lightText,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          Flexible(
                            child: ListView.separated(
                              shrinkWrap: true,
                              itemCount: reminders.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final r = reminders[index];
                                final isCompleted = !r.followUpDate.isAfter(
                                  DateTime.now(),
                                );

                                return Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: BrandColor.background,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: BrandColor.border,
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color: isCompleted
                                              ? Colors.grey.shade200
                                              : BrandColor.softPink,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          isCompleted
                                              ? Icons.task_alt_rounded
                                              : Icons.alarm_rounded,
                                          size: 18,
                                          color: isCompleted
                                              ? Colors.grey.shade600
                                              : BrandColor.primary,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              r.diseaseName.replaceAll(
                                                '_',
                                                ' ',
                                              ),
                                              style: const TextStyle(
                                                color: BrandColor.darkText,
                                                fontWeight: FontWeight.w800,
                                                fontSize: 13,
                                              ),
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              _formatReminderDate(
                                                r.followUpDate,
                                              ),
                                              style: const TextStyle(
                                                color: BrandColor.lightText,
                                                fontSize: 11.5,
                                              ),
                                            ),
                                            const SizedBox(height: 7),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 3,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: isCompleted
                                                    ? Colors.grey.shade200
                                                    : BrandColor.softPink,
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: Text(
                                                isCompleted
                                                    ? 'Completed'
                                                    : 'Upcoming',
                                                style: TextStyle(
                                                  color: isCompleted
                                                      ? Colors.grey.shade700
                                                      : BrandColor.primary,
                                                  fontSize: 9.5,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      IconButton(
                                        tooltip: 'Delete reminder',
                                        onPressed: () async {
                                          await ReminderNotificationService
                                              .instance
                                              .cancelReminder(r.id);

                                          if (!mounted) return;

                                          setDialogState(() {});
                                          _refreshReminders();
                                        },
                                        icon: const Icon(
                                          Icons.delete_outline_rounded,
                                          size: 19,
                                        ),
                                        color: BrandColor.lightText,
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );

    if (mounted) {
      _refreshReminders();
    }
  }

  String _formatReminderDate(DateTime date) {
    final now = DateTime.now();
    final diff = date.difference(now);
    final time =
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

    if (diff.inDays == 0) return 'Today, $time';
    if (diff.inDays == 1) return 'Tomorrow, $time';
    return '${date.day}/${date.month}/${date.year}, $time';
  }

  // ── Camera-viewfinder style scan card ───────────────────────────────
  Widget _scanFrameCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: BrandColor.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: _gold.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _gold.withOpacity(0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome_rounded, color: _gold, size: 12),
                    const SizedBox(width: 6),
                    Text(
                      'SCANNER',
                      style: TextStyle(
                        color: _gold.withOpacity(0.95),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.9,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Color(0xFF4ADE80),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Ready to scan',
                    style: TextStyle(
                      color: BrandColor.darkText,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 22),

          // Viewfinder frame — brand-colored corner brackets + sweeping scan line
          Container(
            width: double.infinity,
            height: 210,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [BrandColor.softPink, Colors.white],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Floating fruit illustration
                AnimatedBuilder(
                  animation: _fruitFloatController,
                  builder: (context, _) {
                    final dy = (_fruitFloatController.value - 0.5) * 10;
                    return Transform.translate(
                      offset: Offset(0, dy),
                      child: Container(
                        width: 96,
                        height: 96,
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
                              blurRadius: 22,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text('🍎', style: TextStyle(fontSize: 42)),
                        ),
                      ),
                    );
                  },
                ),

                // Sweeping horizontal scan line
                AnimatedBuilder(
                  animation: _scanLineController,
                  builder: (context, _) {
                    final top = 14 + (_scanLineController.value * 182);
                    return Positioned(
                      top: top,
                      left: 14,
                      right: 14,
                      child: Container(
                        height: 2.4,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          gradient: LinearGradient(
                            colors: [
                              _gold.withOpacity(0.0),
                              _gold.withOpacity(0.9),
                              _gold.withOpacity(0.0),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _gold.withOpacity(0.6),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                // Corner brackets (viewfinder frame)
                Positioned(
                  top: 12,
                  left: 12,
                  child: _cornerBracket(topLeft: true),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: _cornerBracket(topRight: true),
                ),
                Positioned(
                  bottom: 12,
                  left: 12,
                  child: _cornerBracket(bottomLeft: true),
                ),
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: _cornerBracket(bottomRight: true),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          const Text(
            'Scan Your Pomegranate',
            style: TextStyle(
              color: BrandColor.darkText,
              fontWeight: FontWeight.w900,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Position the fruit in frame and capture,\nor upload from your gallery',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: BrandColor.lightText,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _cornerBracket({
    bool topLeft = false,
    bool topRight = false,
    bool bottomLeft = false,
    bool bottomRight = false,
  }) {
    final border = BorderSide(color: BrandColor.primary, width: 3);

    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: topLeft ? const Radius.circular(8) : Radius.zero,
          topRight: topRight ? const Radius.circular(8) : Radius.zero,
          bottomLeft: bottomLeft ? const Radius.circular(8) : Radius.zero,
          bottomRight: bottomRight ? const Radius.circular(8) : Radius.zero,
        ),
        border: Border(
          top: (topLeft || topRight) ? border : BorderSide.none,
          bottom: (bottomLeft || bottomRight) ? border : BorderSide.none,
          left: (topLeft || bottomLeft) ? border : BorderSide.none,
          right: (topRight || bottomRight) ? border : BorderSide.none,
        ),
      ),
    );
  }

  // ── Capture / Gallery buttons — independent loading states ─────────
  Widget _actionButtons() {
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            icon: Icons.camera_alt_rounded,
            label: 'Capture',
            filled: true,
            loading: _activePick == _PickSource.camera,
            disabled: _isBusy && _activePick != _PickSource.camera,
            onTap: () => _pickImage(ImageSource.camera, _PickSource.camera),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionButton(
            icon: Icons.photo_library_rounded,
            label: 'Gallery',
            filled: false,
            loading: _activePick == _PickSource.gallery,
            disabled: _isBusy && _activePick != _PickSource.gallery,
            onTap: () => _pickImage(ImageSource.gallery, _PickSource.gallery),
          ),
        ),
      ],
    );
  }

  // ── Bottom info strip — Multilingual tile removed, 3 tiles now ─────
  Widget _infoStrip() {
    return Row(
      children: [
        Expanded(
          child: _InfoTile(
            icon: Icons.biotech_rounded,
            title: '5 Classes',
            subtitle: 'Disease types',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _InfoTile(
            icon: Icons.speed_rounded,
            title: 'Severity',
            subtitle: 'Auto analysis',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _InfoTile(
            icon: Icons.medication_liquid_rounded,
            title: 'Treatment',
            subtitle: 'Care guide',
          ),
        ),
      ],
    );
  }

  // ── Recent Detections — small preview cards → full detail page ─────
  Widget _recentHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Recent Detections',
              style: TextStyle(
                color: BrandColor.darkText,
                fontWeight: FontWeight.w900,
                fontSize: 15,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HistoryView()),
                );
                if (mounted) _refreshHistory();
              },
              child: Row(
                children: [
                  Text(
                    'View all',
                    style: TextStyle(
                      color: BrandColor.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 12.5,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 11,
                    color: BrandColor.primary,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        FutureBuilder<List<PredictionResultModel>>(
          future: _recentHistoryFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: CircularProgressIndicator(
                    color: BrandColor.primary,
                    strokeWidth: 2,
                  ),
                ),
              );
            }

            final items = snapshot.data ?? [];

            if (items.isEmpty) {
              return _emptyHistoryCard();
            }

            return Column(
              children: items.map((item) => _historyPreviewCard(item)).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _emptyHistoryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: BrandColor.border),
      ),
      child: Column(
        children: [
          Icon(Icons.history_rounded, color: BrandColor.lightText, size: 26),
          const SizedBox(height: 8),
          const Text(
            'No detections yet',
            style: TextStyle(
              color: BrandColor.lightText,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _historyPreviewCard(PredictionResultModel item) {
    final hasImage =
        item.imagePath.isNotEmpty && File(item.imagePath).existsSync();

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => HistoryDetailView(result: item)),
        );
        if (mounted) _refreshHistory();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: BrandColor.border),
        ),
        child: Row(
          children: [
            // 1. Small image thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: hasImage
                  ? Image.file(
                      File(item.imagePath),
                      width: 54,
                      height: 54,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: 54,
                      height: 54,
                      color: BrandColor.softPink,
                      child: Icon(
                        Icons.image_rounded,
                        color: BrandColor.primary,
                        size: 22,
                      ),
                    ),
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 2. Disease name
                  Text(
                    item.diseaseName.replaceAll('_', ' '),
                    style: const TextStyle(
                      color: BrandColor.darkText,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      // 3. Severity level
                      Icon(
                        Icons.speed_rounded,
                        size: 11,
                        color: BrandColor.primary,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        item.severityLevel,
                        style: TextStyle(
                          color: BrandColor.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 10),
                      // 4. Confidence
                      Icon(
                        Icons.verified_rounded,
                        size: 11,
                        color: BrandColor.lightText,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${item.confidence.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          color: BrandColor.lightText,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  // 5. Detected date
                  Text(
                    _formatDate(item.detectedAt),
                    style: const TextStyle(
                      color: BrandColor.lightText,
                      fontSize: 10.5,
                    ),
                  ),
                ],
              ),
            ),

            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 13,
              color: BrandColor.lightText,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';

    return '${date.day}/${date.month}/${date.year}';
  }
}

// ── Reusable pieces ──────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool filled;
  final bool loading;
  final bool disabled;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.filled,
    required this.loading,
    required this.disabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isInteractive = !loading && !disabled;

    return Opacity(
      opacity: disabled ? 0.45 : 1.0,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: isInteractive ? onTap : null,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: filled ? BrandColor.primary : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: filled ? Colors.transparent : BrandColor.border,
            ),
            boxShadow: filled
                ? [
                    BoxShadow(
                      color: BrandColor.primary.withOpacity(0.28),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: loading
              ? Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: filled ? Colors.white : BrandColor.primary,
                    ),
                  ),
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      color: filled ? Colors.white : BrandColor.primary,
                      size: 24,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      label,
                      style: TextStyle(
                        color: filled ? Colors.white : BrandColor.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 13.5,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _InfoTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BrandColor.border),
      ),
      child: Column(
        children: [
          Icon(icon, color: BrandColor.primary, size: 19),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 11,
              color: BrandColor.darkText,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 8.8, color: BrandColor.lightText),
          ),
        ],
      ),
    );
  }
}
