// lib/screens/quality/history_screen.dart
import 'package:flutter/material.dart';
import '../../l10n/q_app_strings.dart';
import '../../models/grading_result.dart';
import '../../services/grading/grading_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/grading/grading_history_tile.dart';
import 'history_detail_screen.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

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
  static const _redDark = Color(0xFF8E0B16);
  static const _redSoft = Color(0xFFFFF1F2);
  static const _bg = Color(0xFFF7F7F9);
  static const _textDark = Color(0xFF1F2937);
  static const _textSoft = Color(0xFF6B7280);
  static const _border = Color(0xFFEDEDF0);

  @override
  void initState() {
    super.initState();
    _listCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    // Rebuild when the language is changed on the Profile page.
    QStrings.listenable.addListener(_onLanguageChanged);
    _loadHistory();
  }

  void _onLanguageChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    QStrings.listenable.removeListener(_onLanguageChanged);
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
      qtf('delete_n_title', {'n': '$count'}),
      qt('cannot_undo'),
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
      _showSnack(qtf('n_deleted', {'n': '$count'}));
    } catch (e) {
      _showSnack(qt('delete_failed'), isError: true);
    }
  }

  // ══════════════════════════════════════════════════════════════

  // TEMP: pick a new image for an old record and save it like normal
  Future<void> _editImage(GradingResult item) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(qt('gallery')),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(qt('camera')),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    final picked = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1280,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    bool uploaded = false;
    try {
      uploaded = await _service.replaceImage(
        result: item,
        imageFile: File(picked.path),
      );
    } catch (_) {}

    if (!mounted) return;
    Navigator.pop(context); // close loading
    _showSnack(uploaded ? qt('photo_updated') : qt('photo_saved_offline'));
    _loadHistory(silent: true); // refresh → new image shows
  }
  
  Future<void> _deleteOne(GradingResult item) async {
    final ok = await _confirmDialog(
      qt('delete_this_result'),
      qt('cannot_undo'),
    );
    if (!ok) return;
    try {
      await _service.deleteOne(item.id);
      setState(() {
        _all.removeWhere((r) => r.id == item.id);
        _applyFilters();
      });
      _showSnack(qt('result_deleted'));
    } catch (e) {
      _showSnack(qt('delete_failed'), isError: true);
    }
  }

  Future<void> _deleteAll() async {
    if (_all.isEmpty) return;
    final ok = await _confirmDialog(
      qt('clear_all_title'),
      qtf('clear_all_msg', {'n': '${_all.length}'}),
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
      _showSnack(qt('history_cleared'));
    } catch (e) {
      _showSnack(qt('failed_connection'), isError: true);
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
                child: Text(
                  qt('cancel'),
                  style: const TextStyle(color: _textSoft),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(qt('delete'), style: const TextStyle(color: _red)),
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
        backgroundColor: _bg,
        body: Column(
          children: [
            _buildHeader(),
            if (_isOffline) _buildOfflineBanner(),
            if (!_selectionMode) _buildQualityTabs(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // HEADER — normal view / selection view
  // ══════════════════════════════════════════════════════════════

  Widget _buildHeader() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: _selectionMode ? _buildSelectionHeader() : _buildNormalHeader(),
    );
  }

  Widget _buildNormalHeader() => Container(
    key: const ValueKey('normal-header'),
    color: Colors.white,
    child: SafeArea(
      bottom: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: _border)),
        ),
        child: Row(
          children: [
            _barIcon(
              Icons.arrow_back_ios_new_rounded,
              () => Navigator.pop(context),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    qt('grading_history'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _textDark,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            if (_all.isNotEmpty)
              _barIcon(
                Icons.delete_sweep_rounded,
                _deleteAll,
                tooltip: qt('delete_all'),
              ),
          ],
        ),
      ),
    ),
  );

  Widget _buildSelectionHeader() => Container(
    key: const ValueKey('selection-header'),
    decoration: const BoxDecoration(
      gradient: LinearGradient(colors: [_red, _redDark]),
    ),
    child: SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 8, 8, 8),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(
                Icons.close_rounded,
                color: Colors.white,
                size: 22,
              ),
              onPressed: _exitSelectionMode,
            ),
            Expanded(
              child: Text(
                qtf('n_selected', {'n': '${_selectedIds.length}'}),
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
                _allSelected ? qt('unselect_all') : qt('select_all'),
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
              tooltip: qt('delete_selected'),
              onPressed: _selectedIds.isEmpty ? null : _deleteSelected,
            ),
          ],
        ),
      ),
    ),
  );

  Widget _barIcon(IconData icon, VoidCallback onTap, {String? tooltip}) {
    final button = Material(
      color: _redSoft,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, color: _red, size: 19),
        ),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip, child: button);
  }

  Widget _buildOfflineBanner() => Container(
    margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: _redSoft,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: _red.withOpacity(0.2)),
    ),
    child: Row(
      children: [
        const Icon(Icons.wifi_off_rounded, size: 18, color: _red),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            qt('offline_cached'),
            style: const TextStyle(
              fontSize: 12,
              color: _red,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );

  // ── Filter chips with counts: All · High · Medium · Low ──
  Widget _buildQualityTabs() {
    int count(String q) => _all.where((r) => r.quality == q).length;
    return SizedBox(
      height: 56,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        children: [
          _qTab(_QFilter.all, qt('all'), _all.length, _red),
          _qTab(
            _QFilter.high,
            qt('high'),
            count('high_quality'),
            AppColors.chartHigh,
          ),
          _qTab(
            _QFilter.medium,
            qt('medium'),
            count('medium_quality'),
            AppColors.chartMed,
          ),
          _qTab(
            _QFilter.low,
            qt('low'),
            count('low_quality'),
            AppColors.chartLow,
          ),
        ],
      ),
    );
  }

  Widget _qTab(_QFilter f, String label, int n, Color color) {
    final selected = _qFilter == f;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () {
          setState(() => _qFilter = f);
          _applyFilters();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? color : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? color : color.withOpacity(0.35),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : color,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white.withOpacity(0.25)
                      : color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$n',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: selected ? Colors.white : color,
                  ),
                ),
              ),
            ],
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

    return RefreshIndicator(
      color: _red,
      onRefresh: () => _loadHistory(silent: true),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        itemCount: _filtered.length,
        itemBuilder: (_, i) {
          final item = _filtered[i];
          final delay = (i * 0.05).clamp(0.0, 0.6);
          return AnimatedBuilder(
            animation: _listCtrl,
            builder: (_, child) {
              final t = ((_listCtrl.value - delay) / (1 - delay)).clamp(
                0.0,
                1.0,
              );
              return Transform.translate(
                offset: Offset(0, 24 * (1 - t)),
                child: Opacity(opacity: t, child: child),
              );
            },
            child: _buildItem(item),
          );
        },
      ),
    );
  }

  /// Same tile as the main screen, plus delete / select / swipe.
  Widget _buildItem(GradingResult item) {
    final tile = GradingHistoryTile(
      result: item,
      onEditImage: () => _editImage(item), 
      selectionMode: _selectionMode,
      selected: _selectedIds.contains(item.id),
      trailing: _selectionMode
          ? null
          : IconButton(
              icon: const Icon(
                Icons.delete_outline_rounded,
                size: 20,
                color: _red,
              ),
              tooltip: qt('delete'),
              onPressed: () => _deleteOne(item),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
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
    );

    // Swipe-to-delete only when NOT in selection mode.
    if (_selectionMode) return tile;

    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        await _deleteOne(item);
        return false; // list is updated by _deleteOne
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 22),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: _red,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: Colors.white,
          size: 26,
        ),
      ),
      child: tile,
    );
  }

  Widget _buildEmpty() => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 86,
            height: 86,
            decoration: const BoxDecoration(
              color: _redSoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              color: _red,
              size: 38,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            qt('no_results'),
            style: const TextStyle(
              color: _textDark,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            qt('scan_to_view'),
            textAlign: TextAlign.center,
            style: const TextStyle(color: _textSoft, fontSize: 13),
          ),
        ],
      ),
    ),
  );
}
