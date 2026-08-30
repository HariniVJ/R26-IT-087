import 'dart:io';

import 'package:flutter/material.dart';

import '../../common/brand_color.dart';
import '../../models/Disease_prediction_result_model.dart';
import '../../services/disease/history_service.dart';
import 'history_detail_view.dart';

class HistoryView extends StatefulWidget {
  const HistoryView({super.key});

  @override
  State<HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends State<HistoryView> {
  late Future<List<PredictionResultModel>> futureHistory;
  String _selectedFilter = 'All';

  bool _selectionMode = false;
  final Set<String> _selectedIds = {};

  static const List<String> _filterOptions = [
    'All',
    'Healthy',
    'Alternaria',
    'Anthracnose',
    'Bacterial_Blight',
    'Cercospora',
  ];

  @override
  void initState() {
    super.initState();
    futureHistory = HistoryService.getFirebaseHistory();
  }

  Future<void> _refresh() async {
    setState(() => futureHistory = HistoryService.getFirebaseHistory());
    await futureHistory;
  }

  List<PredictionResultModel> _applyFilter(List<PredictionResultModel> data) {
    if (_selectedFilter == 'All') return data;
    return data.where((item) => item.diseaseName == _selectedFilter).toList();
  }

  void _toggleSelectionMode() {
    setState(() {
      _selectionMode = !_selectionMode;
      if (!_selectionMode) _selectedIds.clear();
    });
  }

  void _toggleSelectItem(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }


  void _selectAll(List<PredictionResultModel> data) {
    setState(() {
      final allIds = data
          .where((e) => e.predictionId != null)
          .map((e) => e.predictionId!)
          .toSet();
      if (_selectedIds.length == allIds.length) {
        _selectedIds.clear(); // tapped again -> deselect all
      } else {
        _selectedIds
          ..clear()
          ..addAll(allIds);
      }
    });
  }

  // ── Single-item delete confirmation ─────────────────────────────────
 Future<void> _confirmDeleteSingle(PredictionResultModel item) async {
    final confirmed = await _showDeleteDialog(
      title: 'Delete this record?',
      message:
          'This detection record for "${item.diseaseName.replaceAll('_', ' ')}" '
          'will be permanently deleted. This cannot be undone.',
    );

    if (confirmed != true || item.predictionId == null) return;

    try {
      // Do the async work FIRST, before touching setState.
      await HistoryService.deleteFirebaseHistory(item.predictionId!);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFE53935),
          behavior: SnackBarBehavior.floating,
          elevation: 8,
          margin: const EdgeInsets.fromLTRB(18, 0, 18, 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          duration: const Duration(seconds: 2),
          content: const Row(
            children: [
              Icon(Icons.delete_forever_rounded, color: Colors.white, size: 22),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Record deleted successfully',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
      // Refresh triggers its own setState internally — safe to call here.
      await _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
    }
  } 
  
  // ── Multi-select delete confirmation ────────────────────────────────
  Future<void> _confirmDeleteSelected() async {
    if (_selectedIds.isEmpty) return;

    final confirmed = await _showDeleteDialog(
      title: 'Delete ${_selectedIds.length} record(s)?',
      message:
          'These detection records will be permanently deleted. '
          'This cannot be undone.',
    );

    if (confirmed != true) return;

    try {
      for (final id in _selectedIds) {
        await HistoryService.deleteFirebaseHistory(id);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${_selectedIds.length} record(s) deleted')),
      );
      setState(() {
        _selectedIds.clear();
        _selectionMode = false;
      });
      _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
    }
  }

  Future<bool?> _showDeleteDialog({
    required String title,
    required String message,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        icon: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: BrandColor.softPink,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.delete_outline_rounded,
            color: BrandColor.primary,
            size: 30,
          ),
        ),
        title: Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
        ),
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: BrandColor.lightText, fontSize: 13),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context, false),
            style: OutlinedButton.styleFrom(
              foregroundColor: BrandColor.darkText,
              side: const BorderSide(color: BrandColor.border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: BrandColor.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Delete'),
          ),
        ],
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
        title: Text(
          _selectionMode
              ? '${_selectedIds.length} selected'
              : 'Detection History',
          style: const TextStyle(
            color: BrandColor.darkText,
            fontWeight: FontWeight.w800,
          ),
        ),
        leading: _selectionMode
            ? IconButton(
                icon: const Icon(
                  Icons.close_rounded,
                  color: BrandColor.darkText,
                ),
                onPressed: _toggleSelectionMode,
              )
            : null,
        actions: [
          if (!_selectionMode)
            IconButton(
              icon: const Icon(
                Icons.checklist_rounded,
                color: BrandColor.primary,
              ),
              tooltip: 'Select items',
              onPressed: _toggleSelectionMode,
            )
          else
            IconButton(
              icon: Icon(
                _selectedIds.isEmpty
                    ? Icons.delete_outline_rounded
                    : Icons.delete_rounded,
                color: _selectedIds.isEmpty
                    ? BrandColor.lightText
                    : BrandColor.primary,
              ),
              tooltip: 'Delete selected',
              onPressed: _selectedIds.isEmpty ? null : _confirmDeleteSelected,
            ),
        ],
      ),
      body: Column(
        children: [
          _filterBar(),
          Expanded(
            child: RefreshIndicator(
              color: BrandColor.primary,
              onRefresh: _refresh,
              child: FutureBuilder<List<PredictionResultModel>>(
                future: futureHistory,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: BrandColor.primary,
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return _errorState(snapshot.error.toString());
                  }

                  final allData = snapshot.data ?? [];
                  final data = _applyFilter(allData);

                  if (allData.isEmpty) {
                    return _emptyState();
                  }

                  if (data.isEmpty) {
                    return _noMatchState();
                  }

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    children: [
                      _buildStats(allData),
                      const SizedBox(height: 18),
                      if (_selectionMode) _selectAllRow(data),
                      ...data.map((item) => _historyCard(item)),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Filter chip bar — unchanged ──────────────────────────────────────
  Widget _filterBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: SizedBox(
        height: 38,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _filterOptions.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final option = _filterOptions[index];
            final selected = _selectedFilter == option;
            final displayName = option.replaceAll('_', ' ');

            return GestureDetector(
              onTap: () => setState(() => _selectedFilter = option),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? BrandColor.primary : BrandColor.softPink,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected
                        ? BrandColor.primary
                        : BrandColor.borderPink,
                  ),
                ),
                child: Text(
                  displayName,
                  style: TextStyle(
                    color: selected ? Colors.white : BrandColor.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ── "Select all" row — only visible in selection mode ────────────────
  Widget _selectAllRow(List<PredictionResultModel> data) {
    final allIds = data
        .where((e) => e.predictionId != null)
        .map((e) => e.predictionId!)
        .toSet();
    final allSelected =
        allIds.isNotEmpty && _selectedIds.length == allIds.length;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () => _selectAll(data),
        child: Row(
          children: [
            Icon(
              allSelected
                  ? Icons.check_box_rounded
                  : Icons.check_box_outline_blank_rounded,
              color: BrandColor.primary,
              size: 20,
            ),
            const SizedBox(width: 8),
            const Text(
              'Select all',
              style: TextStyle(
                color: BrandColor.darkText,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Summary stats — changed from squares to rounded rectangles ───────
  Widget _buildStats(List<PredictionResultModel> data) {
    final total = data.length;
    final healthy = data.where((d) => d.isHealthy).length;
    final diseased = total - healthy;

    return Row(
      children: [
        Expanded(
          child: _statTile(
            icon: Icons.fact_check_rounded,
            label: 'Total Scans',
            value: '$total',
            color: BrandColor.primary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statTile(
            icon: Icons.eco_rounded,
            label: 'Healthy',
            value: '$healthy',
            color: const Color(0xFF2DBE72),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statTile(
            icon: Icons.warning_amber_rounded,
            label: 'Diseased',
            value: '$diseased',
            color: const Color(0xFFF59E0B),
          ),
        ),
      ],
    );
  }

  Widget _statTile({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      // Rectangle shape (wider than tall) instead of a square tile.
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        // Small corner radius -> reads as a rectangle, not a rounded square.
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: BrandColor.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: BrandColor.darkText,
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  color: BrandColor.lightText,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── History card — with checkbox in selection mode ───────────────────
  Widget _historyCard(PredictionResultModel item) {
    final isHealthy = item.isHealthy;
    final statusColor = isHealthy
        ? const Color(0xFF2DBE72)
        : _severityColor(item.severityLevel);
    final id = item.predictionId;
    final isSelected = id != null && _selectedIds.contains(id);

    return GestureDetector(
      onTap: () {
        if (_selectionMode) {
          if (id != null) _toggleSelectItem(id);
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => HistoryDetailView(result: item)),
          ).then((_) {
            if (mounted) _refresh();
          });
        }
      },
      onLongPress: () {
        if (!_selectionMode) {
          setState(() => _selectionMode = true);
          if (id != null) _toggleSelectItem(id);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? BrandColor.primary : BrandColor.border,
            width: isSelected ? 1.6 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            if (_selectionMode)
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Icon(
                  isSelected
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: isSelected ? BrandColor.primary : BrandColor.lightText,
                  size: 22,
                ),
              )
            else
              Container(
                width: 5,
                height: 96,
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    bottomLeft: Radius.circular(20),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(13),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: _thumbnail(item, size: 66),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 12, top: 13, bottom: 13),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.diseaseName.replaceAll('_', ' '),
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 14.5,
                              color: BrandColor.darkText,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isHealthy)
                          Icon(
                            Icons.check_circle_rounded,
                            color: statusColor,
                            size: 16,
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        _miniBadge(
                          icon: Icons.speed_rounded,
                          text:
                              '${item.severityLevel} · ${item.severityPercentage.toStringAsFixed(0)}%',
                          color: statusColor,
                        ),
                        _miniBadge(
                          icon: Icons.verified_rounded,
                          text: '${item.confidence.toStringAsFixed(0)}% conf.',
                          color: BrandColor.lightText,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
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
            ),
            if (!_selectionMode)
              IconButton(
                icon: Icon(
                  Icons.delete_outline_rounded,
                  color: BrandColor.lightText,
                  size: 20,
                ),
                onPressed: () => _confirmDeleteSingle(item),
              )
            else
              const SizedBox(width: 12),
          ],
        ),
      ),
    );
  }

  Widget _thumbnail(PredictionResultModel item, {required double size}) {
    if (item.imageUrl != null && item.imageUrl!.isNotEmpty) {
      return Image.network(
        item.imageUrl!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            width: size,
            height: size,
            color: BrandColor.softPink,
            child: const Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: BrandColor.primary,
                ),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) =>
            _localOrPlaceholder(item, size),
      );
    }
    return _localOrPlaceholder(item, size);
  }

  Widget _localOrPlaceholder(PredictionResultModel item, double size) {
    final hasLocal =
        item.imagePath.isNotEmpty && File(item.imagePath).existsSync();

    if (hasLocal) {
      return Image.file(
        File(item.imagePath),
        width: size,
        height: size,
        fit: BoxFit.cover,
      );
    }

    return Container(
      width: size,
      height: size,
      color: BrandColor.softPink,
      child: Icon(
        Icons.image_rounded,
        color: BrandColor.primary,
        size: size * 0.4,
      ),
    );
  }

  Widget _miniBadge({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 3),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Color _severityColor(String level) {
    switch (level.toLowerCase()) {
      case 'mild':
        return const Color(0xFF2DBE72);
      case 'moderate':
        return const Color(0xFFF59E0B);
      case 'severe':
        return BrandColor.primary;
      default:
        return BrandColor.lightText;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _emptyState() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      children: [
        const SizedBox(height: 80),
        Container(
          width: 90,
          height: 90,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: BrandColor.softPink,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.history_rounded,
            color: BrandColor.primary,
            size: 40,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'No detections yet',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 17,
            color: BrandColor.darkText,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Your scanned pomegranates will show up here\nonce you run a detection.',
          textAlign: TextAlign.center,
          style: TextStyle(color: BrandColor.lightText, fontSize: 12.5),
        ),
      ],
    );
  }

  Widget _noMatchState() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      children: [
        const SizedBox(height: 80),
        Icon(
          Icons.filter_alt_off_rounded,
          color: BrandColor.lightText,
          size: 40,
        ),
        const SizedBox(height: 16),
        Text(
          'No results for "${_selectedFilter.replaceAll('_', ' ')}"',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 15,
            color: BrandColor.darkText,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Try a different filter above.',
          textAlign: TextAlign.center,
          style: TextStyle(color: BrandColor.lightText, fontSize: 12.5),
        ),
      ],
    );
  }

  Widget _errorState(String message) {
    final isIndexError =
        message.contains('failed-precondition') ||
        message.contains('requires an index');
    final isPermissionError = message.contains('permission-denied');

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      children: [
        const SizedBox(height: 80),
        Container(
          width: 90,
          height: 90,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: BrandColor.softPink,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.error_outline_rounded,
            color: BrandColor.primary,
            size: 40,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          isIndexError
              ? 'Setting things up…'
              : isPermissionError
              ? 'Access issue'
              : 'Could not load history',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 17,
            color: BrandColor.darkText,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          isIndexError
              ? 'The database index is still building. This usually '
                    'takes a minute — pull down to refresh shortly.'
              : isPermissionError
              ? 'You may need to sign in again, or the database '
                    'permissions need to be updated.'
              : message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: BrandColor.lightText, fontSize: 12.5),
        ),
        const SizedBox(height: 20),
        Center(
          child: OutlinedButton.icon(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Retry'),
            style: OutlinedButton.styleFrom(
              foregroundColor: BrandColor.primary,
              side: const BorderSide(color: BrandColor.primary),
            ),
          ),
        ),
      ],
    );
  }
}
