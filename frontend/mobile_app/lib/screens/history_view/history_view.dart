import 'package:flutter/material.dart';

import '../../common/brand_color.dart';
import '../../models/prediction_result_model.dart';
import '../../services/history_service.dart';

class HistoryView extends StatefulWidget {
  const HistoryView({super.key});

  @override
  State<HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends State<HistoryView> {
  late Future<List<PredictionResultModel>> historyFuture;

  @override
  void initState() {
    super.initState();
    historyFuture = HistoryService.getFirebaseHistory();
  }

  Future<void> _refreshHistory() async {
    setState(() {
      historyFuture = HistoryService.getFirebaseHistory();
    });
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year}  •  '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }

  bool _isHealthy(String name) {
    return name.toLowerCase() == 'healthy';
  }

  Color _getDiseaseColor(String name) {
    return _isHealthy(name) ? BrandColor.green : BrandColor.primary;
  }

  void _showTreatmentPopup(PredictionResultModel item) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          item.diseaseName,
          style: TextStyle(
            color: _getDiseaseColor(item.diseaseName),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          item.treatment,
          style: const TextStyle(
            fontSize: 14,
            height: 1.6,
            color: BrandColor.lightText,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Close',
              style: TextStyle(
                color: BrandColor.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteItem(PredictionResultModel item) async {
    if (item.predictionId == null || item.predictionId!.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Prediction ID not found')));
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text('Delete History'),
        content: const Text('Do you want to delete this detection record?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(
                color: BrandColor.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await HistoryService.deleteFirebaseHistory(item.predictionId!);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('History deleted successfully')),
      );

      _refreshHistory();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Delete error: $e')));
    }
  }

  Widget _imagePlaceholder(Color color) {
    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Icon(Icons.image_outlined, color: color, size: 32),
    );
  }

  Widget _circleButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: color.withOpacity(0.10),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }

  Widget _historyCard(PredictionResultModel item) {
    final color = _getDiseaseColor(item.diseaseName);

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          _imagePlaceholder(color),

          const SizedBox(width: 18),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.diseaseName,
                  style: TextStyle(
                    color: color,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  'Confidence ${item.confidence}%',
                  style: const TextStyle(
                    color: BrandColor.green,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  _formatDateTime(item.detectedAt),
                  style: const TextStyle(
                    color: BrandColor.lightText,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          Column(
            children: [
              _circleButton(
                icon: Icons.visibility_rounded,
                color: BrandColor.green,
                onTap: () => _showTreatmentPopup(item),
              ),

              const SizedBox(height: 12),

              _circleButton(
                icon: Icons.delete_outline_rounded,
                color: BrandColor.primary,
                onTap: () => _deleteItem(item),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _emptyView() {
    return const Center(
      child: Text(
        'No detection history yet',
        style: TextStyle(
          color: BrandColor.lightText,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _errorView(Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          'Error: $error',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: BrandColor.primary,
            fontSize: 14,
            height: 1.5,
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
        title: const Text('Detection History'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _refreshHistory,
          ),
        ],
      ),

      body: FutureBuilder<List<PredictionResultModel>>(
        future: historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: BrandColor.primary),
            );
          }

          if (snapshot.hasError) {
            return _errorView(snapshot.error!);
          }

          final history = snapshot.data ?? [];

          if (history.isEmpty) {
            return _emptyView();
          }

          return RefreshIndicator(
            onRefresh: _refreshHistory,
            child: ListView.builder(
              padding: const EdgeInsets.all(18),
              itemCount: history.length,
              itemBuilder: (context, index) {
                return _historyCard(history[index]);
              },
            ),
          );
        },
      ),
    );
  }
}
