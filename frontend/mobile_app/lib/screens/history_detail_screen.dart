// lib/screens/history_detail_screen.dart
import 'package:flutter/material.dart';
import '../models/grading_result.dart';
import '../theme/app_theme.dart';

class HistoryDetailScreen extends StatelessWidget {
  final GradingResult result;
  const HistoryDetailScreen({super.key, required this.result});

  static const _red = Color(0xFFC1121F);
  static const _redLight = Color(0xFFFFEEEE);
  static const _textDark = Color(0xFF1F2937);
  static const _textMid = Color(0xFF6B7280);
  static const _border = Color(0xFFE5E7EB);

  @override
  Widget build(BuildContext context) {
    final fg = QualityTheme.fgColor(result.quality);
    final bg = QualityTheme.bgColor(result.quality);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _header(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
                child: Column(
                  children: [
                    _imageSquare(bg),
                    const SizedBox(height: 16),
                    _qualityCard(fg),
                    const SizedBox(height: 14),
                    if (result.defectType != null) ...[
                      _defectCard(),
                      const SizedBox(height: 14),
                    ],
                    if (result.weightGrams != null) ...[
                      _weightCard(),
                      const SizedBox(height: 14),
                    ],
                    _recommendationCard(),
                    const SizedBox(height: 14),
                    _dateCard(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
    decoration: const BoxDecoration(
      color: Colors.white,
      border: Border(bottom: BorderSide(color: _border)),
    ),
    child: Row(
      children: [
        IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: _textDark,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        const Expanded(
          child: Text(
            'Result Details',
            style: TextStyle(
              color: _textDark,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 48), // balances back button for centered title
      ],
    ),
  );

  // 🆕 Large square image display
  Widget _imageSquare(Color bg) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: AspectRatio(
        aspectRatio: 1.0,
        child: result.imageUrl != null
            ? Image.network(
                result.imageUrl!,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) => progress == null
                    ? child
                    : Container(
                        color: bg,
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                errorBuilder: (_, __, ___) => Container(
                  color: bg,
                  child: Center(
                    child: Text(
                      QualityTheme.emoji(result.quality),
                      style: const TextStyle(fontSize: 64),
                    ),
                  ),
                ),
              )
            : Container(
                color: bg,
                child: Center(
                  child: Text(
                    QualityTheme.emoji(result.quality),
                    style: const TextStyle(fontSize: 64),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _qualityCard(Color fg) => Container(
    width: double.infinity,
    decoration: BoxDecoration(
      color: fg.withOpacity(0.08),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: fg.withOpacity(0.2)),
    ),
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          QualityTheme.label(result.quality),
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: _textDark,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              'Confidence Score ${result.confidencePercent}',
              style: TextStyle(
                color: fg,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _defectCard() => _infoCard(
    icon: Icons.warning_amber_rounded,
    label: 'DEFECT DETECTED',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          result.defectType![0].toUpperCase() + result.defectType!.substring(1),
          style: const TextStyle(
            color: _textDark,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Severity: ${result.severityPercent != null ? '${result.severityPercent!.toStringAsFixed(1)}%' : 'N/A'}',
          style: const TextStyle(
            color: _textMid,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );

  Widget _weightCard() => _infoCard(
    icon: Icons.scale_rounded,
    label: 'FRUIT WEIGHT',
    child: Text(
      '${result.weightGrams}g',
      style: const TextStyle(
        color: _textDark,
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
    ),
  );

  Widget _recommendationCard() => _infoCard(
    icon: Icons.lightbulb_outline_rounded,
    label: 'RECOMMENDATION',
    child: Text(
      result.recommendation,
      style: const TextStyle(
        color: _textDark,
        fontSize: 14,
        height: 1.5,
        fontWeight: FontWeight.w500,
      ),
    ),
  );

  Widget _dateCard() => _infoCard(
    icon: Icons.calendar_today_rounded,
    label: 'GRADED ON',
    child: Text(
      result.displayDate,
      style: const TextStyle(
        color: _textDark,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  Widget _infoCard({
    required IconData icon,
    required String label,
    required Widget child,
  }) => Container(
    width: double.infinity,
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
    padding: const EdgeInsets.all(16),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _redLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: _red, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: _textMid,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 6),
              child,
            ],
          ),
        ),
      ],
    ),
  );
}
