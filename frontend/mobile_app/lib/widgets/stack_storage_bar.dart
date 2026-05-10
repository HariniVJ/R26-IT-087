// lib/widgets/stack_storage_bar.dart
// UI redesigned to match pomegranate app style (white bg, red accents)
// All logic preserved exactly.

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class StackStorageBar extends StatelessWidget {
  final int high;
  final int medium;
  final int low;

  const StackStorageBar({
    super.key,
    required this.high,
    required this.medium,
    required this.low,
  });

  @override
  Widget build(BuildContext context) {
    final total = high + medium + low;
    if (total == 0) return _emptyBar();

    return Container(
      height: 12,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Row(
          children: [
            if (high > 0)
              Expanded(flex: high, child: _segment(AppColors.chartHigh)),
            if (medium > 0)
              Expanded(flex: medium, child: _segment(AppColors.chartMed)),
            if (low > 0)
              Expanded(flex: low, child: _segment(AppColors.chartLow)),
          ],
        ),
      ),
    );
  }

  Widget _emptyBar() => Container(
    height: 12,
    decoration: BoxDecoration(
      color: const Color(0xFFF3F4F6),
      borderRadius: BorderRadius.circular(20),
    ),
  );

  Widget _segment(Color color) => AnimatedContainer(
    duration: const Duration(milliseconds: 800),
    color: color,
  );
}

class StackStorageLegend extends StatelessWidget {
  final int high;
  final int medium;
  final int low;

  const StackStorageLegend({
    super.key,
    required this.high,
    required this.medium,
    required this.low,
  });

  @override
  Widget build(BuildContext context) {
    final total = high + medium + low;
    final hPct = total == 0 ? 0 : ((high / total) * 100).round();
    final mPct = total == 0 ? 0 : ((medium / total) * 100).round();
    final lPct = total == 0 ? 0 : ((low / total) * 100).round();

    return Wrap(
      spacing: 10,
      runSpacing: 8,
      children: [
        _item('High', hPct, AppColors.chartHigh),
        _item('Medium', mPct, AppColors.chartMed),
        _item('Low', lPct, AppColors.chartLow),
      ],
    );
  }

  Widget _item(String label, int pct, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: const Color(0xFFF9FAFB),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFE5E7EB)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF1F2937),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          '$pct%',
          style: const TextStyle(
            color: Color(0xFFC1121F),
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}
