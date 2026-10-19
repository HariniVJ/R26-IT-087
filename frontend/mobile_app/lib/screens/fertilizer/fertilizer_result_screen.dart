import 'package:flutter/material.dart';

import '../../common/brand_color.dart';
import '../../l10n/app_strings.dart';
import '../../models/fertilizer_advice.dart';
import 'fertilizer_history_screen.dart';

class FertilizerResultScreen extends StatelessWidget {
  final FertilizerAdvice advice;

  const FertilizerResultScreen({super.key, required this.advice});

  String _cleanStageName(String value) {
    if (value == '-') return '-';
    return value.replaceAll('_', ' ');
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LanguageController.instance,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(t('fertilizerRecommendation')),
            ),
            backgroundColor: BrandColor.primary,
            foregroundColor: Colors.white,
            iconTheme: const IconThemeData(color: Colors.white),
            automaticallyImplyLeading: false,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                tooltip: 'Fertilizer history',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const FertilizerHistoryScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.history, color: Colors.white),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _summaryCard(),
                const SizedBox(height: 18),
                _amountCard(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _summaryCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Color(0xFFF8F1F3)],
        ),
        border: Border.all(color: const Color(0xFFE8D4D8)),
        boxShadow: [
          BoxShadow(
            color: BrandColor.primary.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  'assets/images/pomegranate.jpeg',
                  width: 58,
                  height: 58,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t('cropType'),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      t('cropValue'),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _summaryItem(t('trees'), '1'),
              _summaryItem(t('treeAge'), '${advice.treeAge} ${t('years')}'),
              _summaryItem(t('stage'), _cleanStageName(advice.stageName)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _amountCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE8D4D8)),
        boxShadow: [
          BoxShadow(
            color: BrandColor.primary.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t('fertilizerAmount'),
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${t('requirementClass')}: ${advice.fertilizerClass}',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF4B5563),
            ),
          ),
          if (advice.modelConfidence != null) ...[
            const SizedBox(height: 6),
            Text(
              '${t('confidence')}: ${(advice.modelConfidence! * 100).toStringAsFixed(0)}%',
              style: const TextStyle(color: Color(0xFF6B7280)),
            ),
          ],
          const SizedBox(height: 8),
          _fertilizerRow(
            'U',
            t('urea'),
            '${advice.ureaG} g',
            const Color(0xFF0EA5E9),
          ),
          _fertilizerRow(
            'T',
            t('tsp'),
            '${advice.tspG} g',
            const Color(0xFFF59E0B),
          ),
          _fertilizerRow('M', t('mop'), '${advice.mopG} g', BrandColor.primary),
        ],
      ),
    );
  }

  Widget _summaryItem(String title, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 14,
              color: Color(0xFF111827),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fertilizerRow(
    String letter,
    String name,
    String amount,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF3E6E9))),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 17,
            backgroundColor: color,
            child: Text(
              letter,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF111827),
              ),
            ),
          ),
          Text(
            amount,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: Color(0xFF111827),
            ),
          ),
        ],
      ),
    );
  }
}
