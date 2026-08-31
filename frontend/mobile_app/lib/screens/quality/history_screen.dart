// lib/screens/history_screen.dart
import 'package:flutter/material.dart';
import '../../models/grading_result.dart';
import '../../services/grading/grading_service.dart';
import '../../theme/app_theme.dart';
import 'history_detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  final String userId;
  const HistoryScreen({super.key, required this.userId});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

enum _QFilter { all, high, medium, low }

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  final _service = GradingService();

  List<GradingResult> _all = [];
  List<GradingResult> _filtered = [];
  bool _loading = true;
  bool _isOffline = false;
  String? _error;

  _QFilter _qFilter = _QFilter.all;
  late final AnimationController _listCtrl;

  // 🆕 Multi-select state
  bool _selectionMode = false;
  final Set<String> _selectedIds = {};

  static const _red = Color(0xFFC1121F);
  static const _redSoft = Color(0xFFFFEEF3);
  static const _textDark = Color(0xFF1F2937);
  static const _textSoft = Color(0xFF6B7280);
  static const _border = Color(0xFFE5E7EB);

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
      final isConn =
          msg.contains('unavailable') ||
          msg.contains('network') ||
          msg.contains('timed out') ||
          msg.contains('DEADLINE_EXCEEDED');
      setState(() {
        _loading = false;
        _isOffline = isConn;
        _error = msg;
      });
    }
  }

  void _applyFilters() {
    var list = List<GradingResult>.from(_all);
    if (_qFilter != _QFilter.all) {
      final key = {
        _QFilter.high: 'high_quality',
        _QFilter.medium: 'medium_quality',
        _QFilter.low: 'low_quality',
      }[_qFilter]!;
      list = list.where((r) => r.quality == key).toList();
    }
    setState(() => _filtered = list);
  }

  // ══════════════════════════════════════════════════════════════
  // 🆕 SELECTION MODE
  // ══════════════════════════════════════════════════════════════

  void _enterSelectionMode(String id) {
    setState(() {
      _selectionMode = true;
      _selectedIds
        ..clear()
        ..add(id);
    });
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
      if (_selectedIds.isEmpty) _selectionMode = false;
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _selectionMode = false;
      _selectedIds.clear();
    });
  }

  bool get _allSelected =>
      _filtered.isNotEmpty && _selectedIds.length == _filtered.length;

  void _toggleSelectAll() {
    setState(() {
      if (_allSelected) {
        _selectedIds.clear();
        _selectionMode = false;
      } else {
        _selectedIds
          ..clear()
          ..addAll(_filtered.map((r) => r.id));
        _selectionMode = true;
      }
    });
  }

  Future<void> _deleteSelected() async {
    if (_selectedIds.isEmpty) return;
    final count = _selectedIds.length;
    final ok = await _confirmDialog(
      'Delete $count result${count > 1 ? "s" : ""}?',
      'This cannot be undone.',
    );
    if (!ok) return;

    final idsToDelete = Set<String>.from(_selectedIds);
    try {
      for (final id in idsToDelete) {
        await _service.deleteOne(id);
      }
      setState(() {
        _all.removeWhere((r) => idsToDelete.contains(r.id));
        _selectedIds.clear();
        _selectionMode = false;
      });
      _applyFilters();
      _showSnack('$count result${count > 1 ? "s" : ""} deleted');
    } catch (e) {
      _showSnack('Delete failed — check your connection', isError: true);
    }
  }

  // ══════════════════════════════════════════════════════════════

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
      _showSnack('Delete failed — check your connection', isError: true);
    }
  }

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
        _selectionMode = false;
        _selectedIds.clear();
      });
      _showSnack('All history cleared');
    } catch (e) {
      _showSnack('Failed — check your connection', isError: true);
    }
  }

  Future<bool> _confirmDialog(String title, String msg) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              title,
              style: const TextStyle(
                color: _textDark,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            content: Text(
              msg,
              style: const TextStyle(color: _textSoft, fontSize: 13),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel', style: TextStyle(color: _textSoft)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete', style: TextStyle(color: _red)),
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
        backgroundColor: isError ? _red : AppColors.highGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_selectionMode,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _selectionMode) _exitSelectionMode();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              if (_isOffline) _buildOfflineBanner(),
              if (!_selectionMode) _buildQualityTabs(),
              const SizedBox(height: 8),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // HEADER — switches between normal view and selection view
  // ══════════════════════════════════════════════════════════════

  Widget _buildHeader() {
    if (_selectionMode) return _buildSelectionHeader();
    return _buildNormalHeader();
  }

  Widget _buildNormalHeader() => Container(
    key: const ValueKey('normal-header'),
    padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
    decoration: const BoxDecoration(
      color: Colors.white,
      border: Border(bottom: BorderSide(color: _border)),
    ),
    child: Row(
      children: [
        IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: _textDark,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        const Expanded(
          child: Text(
            'Grading History',
            style: TextStyle(
              color: _textDark,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
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
          icon: const Icon(Icons.delete_sweep_rounded, color: _red),
          tooltip: 'Delete all',
          onPressed: _deleteAll,
        ),
      ],
    ),
  );

  Widget _buildSelectionHeader() => Container(
    key: const ValueKey('selection-header'),
    padding: const EdgeInsets.fromLTRB(4, 10, 12, 10),
    decoration: BoxDecoration(
      color: _red,
      border: const Border(bottom: BorderSide(color: _border)),
    ),
    child: Row(
      children: [
        IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white, size: 22),
          onPressed: _exitSelectionMode,
        ),
        Expanded(
          child: Text(
            '${_selectedIds.length} selected',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        TextButton.icon(
          onPressed: _toggleSelectAll,
          icon: Icon(
            _allSelected
                ? Icons.check_box_rounded
                : Icons.check_box_outline_blank_rounded,
            color: Colors.white,
            size: 18,
          ),
          label: Text(
            _allSelected ? 'Unselect All' : 'Select All',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(
            Icons.delete_outline_rounded,
            color: Colors.white,
            size: 22,
          ),
          tooltip: 'Delete selected',
          onPressed: _selectedIds.isEmpty ? null : _deleteSelected,
        ),
      ],
    ),
  );

  Widget _countBadge(int n, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      '$n',
      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
    ),
  );

  Widget _buildOfflineBanner() => Container(
    margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: _redSoft,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: _red.withOpacity(0.2)),
    ),
    child: const Row(
      children: [
        Icon(Icons.wifi_off_rounded, size: 18, color: _red),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            'Weak or no connection — showing cached results',
            style: TextStyle(
              fontSize: 12,
              color: _red,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _buildQualityTabs() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
    child: Container(
      decoration: BoxDecoration(
        color: _redSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _red.withOpacity(0.12)),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _qTab(_QFilter.all, 'All', _red),
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
            borderRadius: BorderRadius.circular(12),
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

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: _red));
    }
    if (_filtered.isEmpty) return _buildEmpty();

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      itemCount: _filtered.length,
      itemBuilder: (_, i) {
        final item = _filtered[i];
        final delay = i * 0.05;
        return AnimatedBuilder(
          animation: _listCtrl,
          builder: (_, child) {
            final t = ((_listCtrl.value - delay) / (1 - delay)).clamp(0.0, 1.0);
            return Transform.translate(
              offset: Offset(0, 30 * (1 - t)),
              child: Opacity(opacity: t, child: child),
            );
          },
          child: _HistoryCard(
            result: item,
            selectionMode: _selectionMode,
            selected: _selectedIds.contains(item.id),
            onDelete: () => _deleteOne(item),
            onTap: () {
              if (_selectionMode) {
                _toggleSelection(item.id);
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => HistoryDetailScreen(result: item),
                  ),
                );
              }
            },
            onLongPress: () {
              if (!_selectionMode) _enterSelectionMode(item.id);
            },
          ),
        );
      },
    );
  }

  Widget _buildEmpty() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        Text('🍎', style: TextStyle(fontSize: 52)),
        SizedBox(height: 16),
        Text(
          'No results found',
          style: TextStyle(
            color: _textDark,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Scan a fruit to view grading history',
          style: TextStyle(color: _textSoft, fontSize: 13),
        ),
      ],
    ),
  );
}

// ══════════════════════════════════════════════════════════════════
// HISTORY CARD — cleaner layout: image on the left, no confidence
// arc (just a compact percentage chip), long-press to multi-select,
// checkbox overlay on the thumbnail while in selection mode.
// ══════════════════════════════════════════════════════════════════

class _HistoryCard extends StatelessWidget {
  final GradingResult result;
  final bool selectionMode;
  final bool selected;
  final VoidCallback onDelete;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _HistoryCard({
    required this.result,
    required this.selectionMode,
    required this.selected,
    required this.onDelete,
    required this.onTap,
    required this.onLongPress,
  });

  static const _red = Color(0xFFC1121F);
  static const _textDark = Color(0xFF1F2937);
  static const _textSoft = Color(0xFF6B7280);
  static const _border = Color(0xFFE5E7EB);

  @override
  Widget build(BuildContext context) {
    final fg = QualityTheme.fgColor(result.quality);
    final bg = QualityTheme.bgColor(result.quality);
    final qualityLabel = QualityTheme.label(result.quality);

    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: selected ? _red.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: selected ? _red : _border,
          width: selected ? 1.6 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: _red.withOpacity(selected ? 0.10 : 0.06),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(19),
        child: Column(
          children: [
            Container(height: 4, color: fg),
            InkWell(
              onTap: onTap,
              onLongPress: onLongPress,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _thumbnail(bg),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: fg.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  qualityLabel,
                                  style: TextStyle(
                                    color: fg,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              // 🔧 simple confidence chip — replaces the
                              // circular arc, just plain % text.
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF3F4F6),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  result.confidencePercent,
                                  style: const TextStyle(
                                    color: _textSoft,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 7),
                          Text(
                            result.recommendation,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _textDark,
                              fontSize: 12,
                              height: 1.3,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (result.defectType != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              '${result.defectType} · ${result.severityDisplay}',
                              style: const TextStyle(
                                color: _textSoft,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                          const SizedBox(height: 4),
                          Text(
                            result.displayDate,
                            style: const TextStyle(
                              color: _textSoft,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!selectionMode)
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          size: 20,
                          color: _red,
                        ),
                        onPressed: onDelete,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      )
                    else
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.transparent,
                        size: 20,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );

    // Swipe-to-delete only when NOT in selection mode, so it doesn't
    // fight with the long-press / checkbox selection gestures.
    if (selectionMode) return card;

    return Dismissible(
      key: Key(result.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: _red,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: Colors.white,
          size: 28,
        ),
      ),
      child: card,
    );
  }

  Widget _thumbnail(Color bg) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            width: 64,
            height: 64,
            child: result.imageUrl != null && result.imageUrl!.isNotEmpty
                ? Image.network(
                    result.imageUrl!,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) =>
                        progress == null
                        ? child
                        : Container(
                            color: bg,
                            child: const Center(
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                          ),
                    errorBuilder: (_, __, ___) => Container(
                      color: bg,
                      child: Center(
                        child: Text(
                          QualityTheme.emoji(result.quality),
                          style: const TextStyle(fontSize: 26),
                        ),
                      ),
                    ),
                  )
                : Container(
                    color: bg,
                    child: Center(
                      child: Text(
                        QualityTheme.emoji(result.quality),
                        style: const TextStyle(fontSize: 26),
                      ),
                    ),
                  ),
          ),
        ),
        // 🆕 selection checkbox overlay
        if (selectionMode)
          Positioned(
            top: -4,
            left: -4,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? _red : Colors.white,
                border: Border.all(
                  color: selected ? _red : _border,
                  width: 1.6,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: selected
                  ? const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 14,
                    )
                  : null,
            ),
          ),
        // dim the image slightly when selected, like gallery apps
        if (selectionMode && selected)
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Container(color: _red.withOpacity(0.18)),
            ),
          ),
      ],
    );
  }
}
