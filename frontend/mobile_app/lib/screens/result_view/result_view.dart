import 'dart:io';
import 'package:flutter/material.dart';
import '../../common/brand_color.dart';
import '../../common/glass_container.dart';
import '../../models/prediction_result_model.dart';

class ResultView extends StatelessWidget {
  final PredictionResultModel result;
  const ResultView({super.key, required this.result});

  // ── Logic unchanged ────────────────────────────────────────
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

  // ── UI ─────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BrandColor.background,
      extendBodyBehindAppBar: true,
      appBar: const DarkAppBar(title: 'Detection Result'),
      body: Stack(
        children: [
          const DarkBackground(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // ── Fruit image ──────────────────────────
                  ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: Stack(
                      children: [
                        Image.file(
                          File(result.imagePath),
                          width: double.infinity,
                          height: 240,
                          fit: BoxFit.cover,
                        ),
                        // Subtle dark vignette bottom
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            height: 80,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  Colors.black.withOpacity(0.5),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Result Card ──────────────────────────
                  GlassContainer(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Disease name + status icon
                        Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: _statusColor.withOpacity(0.14),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: _statusColor.withOpacity(0.28),
                                ),
                              ),
                              child: Icon(
                                _statusIcon,
                                color: _statusColor,
                                size: 26,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Disease Detected',
                                    style: TextStyle(
                                      color: BrandColor.softText,
                                      fontSize: 11,
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
                        Divider(color: BrandColor.glassBorder),
                        const SizedBox(height: 14),

                        // Confidence + Date chips
                        Row(
                          children: [
                            Expanded(
                              child: _GlassInfoChip(
                                icon: Icons.analytics_rounded,
                                label: 'Confidence',
                                value: '${result.confidence}%',
                                color: BrandColor.green,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _GlassInfoChip(
                                icon: Icons.access_time_rounded,
                                label: 'Detected',
                                value: _formatDateTime(result.detectedAt),
                                color: BrandColor.softText,
                                valueSize: 11,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Treatment recommendation
                        GlassContainer(
                          fillColor: BrandColor.dangerFill,
                          borderColor: BrandColor.dangerBorder,
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.medical_services_rounded,
                                    color: BrandColor.accent,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Treatment Recommendation',
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.bold,
                                      color: BrandColor.accent,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                result.treatment,
                                style: TextStyle(
                                  fontSize: 13.5,
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

                  // Back to Home button
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
                      onPressed: () =>
                          Navigator.popUntil(context, (r) => r.isFirst),
                      icon: const Icon(Icons.home_rounded, size: 22),
                      label: const Text(
                        'Back to Home',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Glass Info Chip ────────────────────────────────────────────
class _GlassInfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final double valueSize;

  const _GlassInfoChip({
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
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10.5,
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
