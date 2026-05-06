import 'dart:io';
import 'package:flutter/material.dart';
import '../../common/brand_color.dart';
import '../../services/history_service.dart';

class HistoryView extends StatefulWidget {
  const HistoryView({super.key});

  @override
  State<HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends State<HistoryView> {
  String _formatDateTime(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year}  •  '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }

  bool _isHealthy(String name) => name.toLowerCase() == 'healthy';

  Color _getDiseaseColor(String name) {
    if (_isHealthy(name)) return BrandColor.green;
    return BrandColor.primary;
  }

  void _showTreatmentPopup(dynamic item) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: Row(
              children: [
                Icon(
                  _isHealthy(item.diseaseName)
                      ? Icons.check_circle_rounded
                      : Icons.coronavirus_rounded,
                  color: _getDiseaseColor(item.diseaseName),
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.diseaseName,
                    style: TextStyle(
                      color: _getDiseaseColor(item.diseaseName),
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ],
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

  void _deleteItem(int index) {
    setState(() => HistoryService.deleteItem(index));
  }

  void _clearAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text('Clear All History'),
            content: const Text('This will delete all detection records.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Clear',
                  style: TextStyle(color: BrandColor.primary),
                ),
              ),
            ],
          ),
    );
    if (confirm == true) {
      setState(() => HistoryService.clearAll());
    }
  }

  @override
  Widget build(BuildContext context) {
    final history = HistoryService.getHistory();

    return Scaffold(
      backgroundColor: BrandColor.background,
      appBar: AppBar(
        title: const Text('Detection History'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (history.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded),
              onPressed: _clearAll,
              tooltip: 'Clear all',
            ),
        ],
      ),
      body:
          history.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: BrandColor.primary.withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.history_rounded,
                        size: 36,
                        color: BrandColor.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No detection history yet',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: BrandColor.lightText,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Start scanning pomegranate fruits',
                      style: TextStyle(
                        fontSize: 13,
                        color: BrandColor.lightText,
                      ),
                    ),
                  ],
                ),
              )
              : ListView.builder(
                padding: const EdgeInsets.all(18),
                itemCount: history.length,
                itemBuilder: (context, index) {
                  final item = history[index];
                  final color = _getDiseaseColor(item.diseaseName);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
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
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          // Image
                          ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: Image.file(
                              File(item.imagePath),
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (_, __, ___) => Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      color: color.withOpacity(0.10),
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    child: Icon(
                                      Icons.image_outlined,
                                      color: color,
                                      size: 28,
                                    ),
                                  ),
                            ),
                          ),

                          const SizedBox(width: 14),

                          // Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      _isHealthy(item.diseaseName)
                                          ? Icons.check_circle_rounded
                                          : Icons.coronavirus_rounded,
                                      color: color,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        item.diseaseName,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: color,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: BrandColor.green.withOpacity(0.10),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Confidence ${item.confidence}%',
                                    style: const TextStyle(
                                      color: BrandColor.green,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
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

                          // Action buttons
                          Column(
                            children: [
                              _CircleBtn(
                                icon: Icons.visibility_rounded,
                                color: BrandColor.green,
                                onTap: () => _showTreatmentPopup(item),
                              ),
                              const SizedBox(height: 8),
                              _CircleBtn(
                                icon: Icons.delete_outline_rounded,
                                color: BrandColor.primary,
                                onTap: () => _deleteItem(index),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
    );
  }
}

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _CircleBtn({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color.withOpacity(0.10),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }
}
