// lib/widgets/smart_insights_card.dart
// UI redesigned to match pomegranate app style (white bg, red accents)
// All logic preserved exactly.

import 'package:flutter/material.dart';

class SmartInsightsCard extends StatelessWidget {
  final int high;
  final int medium;
  final int low;

  const SmartInsightsCard({
    super.key,
    required this.high,
    required this.medium,
    required this.low,
  });

  static const _red = Color(0xFFC1121F);
  static const _redLight = Color(0xFFFFEEEE);
  static const _textDark = Color(0xFF1F2937);
  static const _textMid = Color(0xFF6B7280);
  static const _border = Color(0xFFE5E7EB);

  @override
  Widget build(BuildContext context) {
    final total = high + medium + low;

    String insight = 'No grading data available yet.';

    if (total > 0) {
      if (high >= medium && high >= low) {
        insight = 'Most fruits are high quality. Suitable for premium market.';
      } else if (medium >= high && medium >= low) {
        insight = 'Medium quality fruits are dominant. Good for processing.';
      } else {
        insight =
            'Low quality fruits detected more frequently. Check farming conditions.';
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _redLight,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: _red,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SMART INSIGHTS',
                  style: TextStyle(
                    color: _textMid,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  insight,
                  style: const TextStyle(
                    color: _textDark,
                    fontSize: 13,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
