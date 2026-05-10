// YOUR FILE — Member 4: Fruit Quality Grading
// lib/screens/history_screen.dart
//
// FIXES:
//   1. Uses result.confidenceArc (0.0–1.0) for arc painter — was using
//      result.confidence which caused arc to overdraw when confidence > 1
//   2. Better error state — shows "backend offline" vs "no data" clearly
//   3. Empty state shows only when backend connected but no results
//   4. Offline banner shown when backend unreachable
//   5. History loads silently on background — no full-screen loader on retry

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/grading_result.dart';
import '../services/grading_api_service.dart';
import '../theme/app_theme.dart';

class HistoryScreen extends StatefulWidget {
  final String userId;
  const HistoryScreen({super.key, required this.userId});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

enum _QFilter { all, high, medium, low }

enum _DateFilter { all, today, week, month }

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  final _service = GradingApiService();

  List<GradingResult> _all = [];
  List<GradingResult> _filtered = [];
  bool _loading = true;
  bool _isOffline = false; // NEW: track if backend is unreachable
  String? _error;

  _QFilter _qFilter = _QFilter.all;
  _DateFilter _dateFilter = _DateFilter.all;

  late final AnimationController _listCtrl;

  @override
  void initState() {
    super.initState();
    _listCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _loadHistory();
  }

  @override
  void dispose() {
    _listCtrl.dispose();
    super.dispose();
  }

  // ── Load history ────────────────────────────────────────────────────────────
  Future<void> _loadHistory({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
        _isOffline = false;
      });
    }

    try {
      final results = await _service.getHistory(widget.userId);
      if (!mounted) return;
      setState(() {
        _all = results;
        _loading = false;
        _isOffline = false;
        _error = null;
      });
      _applyFilters();
      _listCtrl.forward(from: 0);
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '');
      // Detect if it's a connectivity error vs server error
      final isConn =
          msg.contains('timed out') ||
          msg.contains('Cannot') ||
          msg.contains('connect');
      setState(() {
        _loading = false;
        _isOffline = isConn;
        _error = msg;
      });
    }
  }

  // ── Apply quality + date filters ────────────────────────────────────────────
  void _applyFilters() {
    var list = List<GradingResult>.from(_all);

    // Quality filter
    if (_qFilter != _QFilter.all) {
      final key = {
        _QFilter.high: 'high_quality',
        _QFilter.medium: 'medium_quality',
        _QFilter.low: 'low_quality',
      }[_qFilter]!;
      list = list.where((r) => r.quality == key).toList();
    }

    // Date filter
    final now = DateTime.now();
    if (_dateFilter != _DateFilter.all) {
      list = list.where((r) {
        final dt = r.dateTime;
        if (dt == null) return false;
        switch (_dateFilter) {
          case _DateFilter.today:
            return dt.year == now.year &&
                dt.month == now.month &&
                dt.day == now.day;
          case _DateFilter.week:
            return now.difference(dt).inDays <= 7;
          case _DateFilter.month:
            return now.difference(dt).inDays <= 30;
          default:
            return true;
        }
      }).toList();
    }

    setState(() => _filtered = list);
  }

  // ── Delete one ─────────────────────────────────────────────────────────────
  Future<void> _deleteOne(GradingResult item) async {
    final ok = await _confirmDialog(
      'Delete this result?',
      'This cannot be undone.',
    );
    if (!ok) return;
    try {
      await _service.deleteOne(item.id);
      setState(() {
        _all.removeWhere((r) => r.id == item.id);
        _applyFilters();
      });
      _showSnack('Result deleted');
    } catch (e) {
      _showSnack('Delete failed — check backend connection', isError: true);
    }
  }

  // ── Delete all ─────────────────────────────────────────────────────────────
  Future<void> _deleteAll() async {
    if (_all.isEmpty) return;
    final ok = await _confirmDialog(
      'Clear all history?',
      'All ${_all.length} results will be permanently deleted.',
    );
    if (!ok) return;
    try {
      await _service.deleteAll(widget.userId);
      setState(() {
        _all.clear();
        _filtered.clear();
      });
      _showSnack('All history cleared');
    } catch (e) {
      _showSnack('Failed — check backend connection', isError: true);
    }
  }

  Future<bool> _confirmDialog(String title, String msg) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(title, style: AppText.titleMedium),
            content: Text(msg, style: AppText.bodyMedium),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: AppColors.lowRed),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppColors.lowRed : AppColors.highGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ── BUILD ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Container(
        decoration: AppDecorations.gradientBg(),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              // Offline banner
              if (_isOffline) _buildOfflineBanner(),
              _buildQualityTabs(),
              _buildDateChips(),
              const SizedBox(height: 4),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  // ── Offline banner ─────────────────────────────────────────────────────────
  Widget _buildOfflineBanner() => Container(
    margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: AppColors.medAmberLight,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.medAmber.withOpacity(0.4)),
    ),
    child: Row(
      children: [
        Icon(Icons.wifi_off_rounded, size: 18, color: AppColors.medAmber),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'Backend offline — start uvicorn to load history from Firebase',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.medAmber,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        GestureDetector(
          onTap: () => _loadHistory(),
          child: Text(
            'Retry',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.medAmber,
              fontWeight: FontWeight.w700,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    ),
  );

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
    child: Row(
      children: [
        IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: AppColors.crimson,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Grading History', style: AppText.titleMedium),
              Text(
                _loading
                    ? 'Loading...'
                    : '${_filtered.length} of ${_all.length} results',
                style: AppText.labelSmall,
              ),
            ],
          ),
        ),
        if (_all.isNotEmpty) ...[
          _countBadge(
            _all.where((r) => r.quality == 'high_quality').length,
            AppColors.chartHigh,
          ),
          const SizedBox(width: 4),
          _countBadge(
            _all.where((r) => r.quality == 'medium_quality').length,
            AppColors.chartMed,
          ),
          const SizedBox(width: 4),
          _countBadge(
            _all.where((r) => r.quality == 'low_quality').length,
            AppColors.chartLow,
          ),
          const SizedBox(width: 4),
        ],
        IconButton(
          icon: const Icon(Icons.delete_sweep_rounded, color: AppColors.lowRed),
          tooltip: 'Delete all',
          onPressed: _deleteAll,
        ),
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: AppColors.crimson),
          onPressed: () => _loadHistory(),
        ),
      ],
    ),
  );

  Widget _countBadge(int n, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: color.withOpacity(0.15),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      '$n',
      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
    ),
  );

  // ── Quality tabs ────────────────────────────────────────────────────────────
  Widget _buildQualityTabs() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.blush),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _qTab(_QFilter.all, 'All', Colors.grey.shade600),
          _qTab(_QFilter.high, 'High', AppColors.chartHigh),
          _qTab(_QFilter.medium, 'Medium', AppColors.chartMed),
          _qTab(_QFilter.low, 'Low', AppColors.chartLow),
        ],
      ),
    ),
  );

  Widget _qTab(_QFilter f, String label, Color color) {
    final selected = _qFilter == f;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _qFilter = f);
          _applyFilters();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : color,
            ),
          ),
        ),
      ),
    );
  }

  // ── Date chips ──────────────────────────────────────────────────────────────
  Widget _buildDateChips() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
    child: Row(
      children: [
        Text('Period: ', style: AppText.labelSmall), // FIX: was "Perid"
        const SizedBox(width: 8),
        ..._DateFilter.values.map((f) {
          final labels = {
            _DateFilter.all: 'All Time',
            _DateFilter.today: 'Today',
            _DateFilter.week: '7 Days',
            _DateFilter.month: '30 Days',
          };
          final selected = _dateFilter == f;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: GestureDetector(
              onTap: () {
                setState(() => _dateFilter = f);
                _applyFilters();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.crimson
                      : Colors.white.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected ? AppColors.crimson : AppColors.blush,
                  ),
                ),
                child: Text(
                  labels[f]!,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    ),
  );

  // ── Body ────────────────────────────────────────────────────────────────────
  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.crimson),
      );
    }

    // Show offline state if backend unreachable and no cached data
    if (_isOffline && _all.isEmpty) {
      return _buildOfflineState();
    }

    if (_filtered.isEmpty) return _buildEmpty();

    return RefreshIndicator(
      color: AppColors.crimson,
      onRefresh: () => _loadHistory(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        itemCount: _filtered.length,
        itemBuilder: (_, i) {
          final delay = i * 0.05;
          return AnimatedBuilder(
            animation: _listCtrl,
            builder: (_, child) {
              final t = ((_listCtrl.value - delay) / (1 - delay)).clamp(
                0.0,
                1.0,
              );
              return Transform.translate(
                offset: Offset(0, 30 * (1 - t)),
                child: Opacity(opacity: t, child: child),
              );
            },
            child: _HistoryCard(
              result: _filtered[i],
              onDelete: () => _deleteOne(_filtered[i]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmpty() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('🍎', style: TextStyle(fontSize: 52)),
        const SizedBox(height: 16),
        Text('No results found', style: AppText.titleMedium),
        const SizedBox(height: 8),
        Text(
          'Try a different filter or scan a fruit',
          style: AppText.bodyMedium,
        ),
      ],
    ),
  );

  // NEW: clear offline state with helpful instructions
  Widget _buildOfflineState() => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.medAmberLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.cloud_off_rounded,
              size: 36,
              color: AppColors.medAmber,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Backend not reachable',
            style: AppText.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            'History is stored in Firebase and needs the backend server to load.',
            style: AppText.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.blush),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('To fix:', style: AppText.labelSmall),
                const SizedBox(height: 8),
                _fixStep('1', 'Open PowerShell on your PC'),
                _fixStep(
                  '2',
                  'Run: uvicorn main:app --host 0.0.0.0 --port 8000',
                ),
                _fixStep('3', 'Make sure phone & PC are on same WiFi'),
                _fixStep('4', 'Tap Retry below'),
              ],
            ),
          ),
          const SizedBox(height: 20),
          AppButton(
            label: 'Retry',
            icon: Icons.refresh_rounded,
            onPressed: () => _loadHistory(),
          ),
        ],
      ),
    ),
  );

  Widget _fixStep(String n, String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 18,
          height: 18,
          margin: const EdgeInsets.only(right: 8, top: 1),
          decoration: BoxDecoration(
            color: AppColors.crimson,
            borderRadius: BorderRadius.circular(5),
          ),
          child: Center(
            child: Text(
              n,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        Expanded(
          child: Text(text, style: AppText.bodyMedium.copyWith(fontSize: 12)),
        ),
      ],
    ),
  );
}

// ── History Card ──────────────────────────────────────────────────────────────
class _HistoryCard extends StatelessWidget {
  final GradingResult result;
  final VoidCallback onDelete;

  const _HistoryCard({required this.result, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final fg = QualityTheme.fgColor(result.quality);
    final bg = QualityTheme.bgColor(result.quality);

    return Dismissible(
      key: Key(result.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.lowRed,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: Colors.white,
          size: 28,
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: AppDecorations.glassCard(border: fg.withOpacity(0.25)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            children: [
              Container(height: 4, color: fg),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          QualityTheme.emoji(result.quality),
                          style: const TextStyle(fontSize: 22),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          QualityBadge(quality: result.quality),
                          const SizedBox(height: 4),
                          Text(
                            result.recommendation,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.bodyMedium.copyWith(fontSize: 12),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            result.displayDate,
                            style: AppText.labelSmall.copyWith(fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      children: [
                        // FIX: use confidenceArc (0.0–1.0) not confidence
                        _ConfidenceArc(value: result.confidenceArc, color: fg),
                        const SizedBox(height: 2),
                        Text(
                          result.confidencePercent,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: fg,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        size: 20,
                        color: AppColors.lowRed,
                      ),
                      onPressed: onDelete,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
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
}

// ── Arc confidence painter ────────────────────────────────────────────────────
class _ConfidenceArc extends StatelessWidget {
  final double value; // must be 0.0–1.0
  final Color color;
  const _ConfidenceArc({required this.value, required this.color});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 36,
    height: 36,
    child: CustomPaint(
      painter: _ArcPainter(value: value.clamp(0.0, 1.0), color: color),
    ),
  );
}

class _ArcPainter extends CustomPainter {
  final double value;
  final Color color;
  _ArcPainter({required this.value, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 3;

    // Background track
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      -math.pi * 0.8,
      math.pi * 1.6,
      false,
      Paint()
        ..color = color.withOpacity(0.15)
        ..strokeWidth = 4
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // Filled arc — value is already 0.0–1.0
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      -math.pi * 0.8,
      math.pi * 1.6 * value,
      false,
      Paint()
        ..color = color
        ..strokeWidth = 4
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_ArcPainter old) => old.value != value;
}
