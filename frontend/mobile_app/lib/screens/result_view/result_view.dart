import 'dart:io';
import 'package:flutter/material.dart';
import '../../common/brand_color.dart';
import '../../models/prediction_result_model.dart';

class ResultView extends StatelessWidget {
  final PredictionResultModel result;

  const ResultView({super.key, required this.result});

  String _formatDateTime(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year}  •  '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }

  bool get _isHealthy => result.diseaseName.toLowerCase() == 'healthy';

  Color get _statusColor => _isHealthy ? BrandColor.green : BrandColor.primary;

  IconData get _statusIcon =>
      _isHealthy ? Icons.check_circle_rounded : Icons.coronavirus_rounded;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BrandColor.background,
      appBar: AppBar(
        title: const Text('Detection Result'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ── Fruit Image ───────────────────────────────
            ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Image.file(
                File(result.imagePath),
                width: double.infinity,
                height: 240,
                fit: BoxFit.cover,
              ),
            ),

            const SizedBox(height: 20),

            // ── Result Card ───────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color: _statusColor.withOpacity(0.12),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Disease name + icon
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: _statusColor.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(_statusIcon, color: _statusColor, size: 26),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Disease Detected',
                              style: TextStyle(
                                color: BrandColor.lightText,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              result.diseaseName,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: _statusColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),
                  Divider(color: Colors.grey.shade100),
                  const SizedBox(height: 14),

                  // Confidence + Date Row
                  Row(
                    children: [
                      Expanded(
                        child: _InfoChip(
                          icon: Icons.analytics_rounded,
                          label: 'Confidence',
                          value: '${result.confidence}%',
                          color: BrandColor.green,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _InfoChip(
                          icon: Icons.access_time_rounded,
                          label: 'Detected',
                          value: _formatDateTime(result.detectedAt),
                          color: BrandColor.lightText,
                          valueSize: 11,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Treatment section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: BrandColor.primary.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: BrandColor.primary.withOpacity(0.12),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.medical_services_rounded,
                              color: BrandColor.primary,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Treatment Recommendation',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: BrandColor.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          result.treatment,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.7,
                            color: BrandColor.lightText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Buttons ───────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: BrandColor.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 0,
                ),
                onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
                icon: const Icon(Icons.home_rounded, size: 22),
                label: const Text(
                  'Back to Home',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final double valueSize;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.valueSize = 14,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: valueSize,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
