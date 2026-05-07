import 'dart:io';
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
              style: TextStyle(color: BrandColor.primary),
            ),
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
          fontSize: 16,
          color: BrandColor.lightText,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _historyCard(PredictionResultModel item) {
    final color = _getDiseaseColor(item.diseaseName);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.10),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: item.imagePath.isNotEmpty
                ? Image.file(
                    File(item.imagePath),
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _imagePlaceholder(color),
                  )
                : _imagePlaceholder(color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.diseaseName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Confidence ${item.confidence}%',
                  style: const TextStyle(
                    color: BrandColor.green,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _formatDateTime(item.detectedAt),
                  style: const TextStyle(
                    color: BrandColor.lightText,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _showTreatmentPopup(item),
            icon: const Icon(Icons.visibility_rounded),
            color: BrandColor.green,
          ),
        ],
      ),
    );
  }

  Widget _imagePlaceholder(Color color) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Icon(Icons.image_outlined, color: color, size: 28),
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
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Error: ${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: BrandColor.primary),
                ),
              ),
            );
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
