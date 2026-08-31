// lib/screens/grading/history_detail_screen.dart

import 'package:flutter/material.dart';

import '../../models/grading_result.dart';
import '../../theme/app_theme.dart';

class HistoryDetailScreen extends StatelessWidget {
  final GradingResult result;

  const HistoryDetailScreen({super.key, required this.result});

  static const _red = Color(0xFFC1121F);
  static const _redLight = Color(0xFFFFEEEE);
  static const _textDark = Color(0xFF1F2937);
  static const _textMid = Color(0xFF6B7280);
  static const _border = Color(0xFFE5E7EB);

  static const _blue = Color(0xFF2563EB);
  static const _blueLight = Color(0xFFEFF6FF);

  static const _green = Color(0xFF16803A);
  static const _greenLight = Color(0xFFECFDF3);

  static const _orange = Color(0xFFEA580C);
  static const _orangeLight = Color(0xFFFFF7ED);

  @override
  Widget build(BuildContext context) {
    final qualityColor = QualityTheme.fgColor(result.quality);
    final imageBackground = QualityTheme.bgColor(result.quality);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            _header(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                child: Column(
                  children: [
                    _imageSquare(imageBackground),
                    const SizedBox(height: 16),

                    _qualityCard(qualityColor),
                    const SizedBox(height: 14),

                    if (result.defectType != null) ...[
                      _defectCard(),
                      const SizedBox(height: 14),
                    ],

                    if (result.weightGrams != null) ...[
                      _weightCard(),
                      const SizedBox(height: 14),
                    ],

                    _sectionTitle(
                      title: 'UTILIZATION RECOMMENDATION',
                      subtitle:
                          'Generated using the configured recommendation rules',
                    ),
                    const SizedBox(height: 10),

                    _recommendedUsageCard(),
                    const SizedBox(height: 12),

                    if (_hasValue(result.explanation)) ...[
                      _explanationCard(),
                      const SizedBox(height: 12),
                    ],

                    if (_hasValue(result.wasteUsage)) ...[
                      _wasteUsageCard(),
                      const SizedBox(height: 12),
                    ],

                    if (_hasValue(result.safetyNote)) ...[
                      _safetyNoteCard(),
                      const SizedBox(height: 14),
                    ],

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

  Widget _header(BuildContext context) {
    return Container(
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
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _textDark,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _imageSquare(Color backgroundColor) {
    final imageUrl = result.imageUrl?.trim();

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: AspectRatio(
          aspectRatio: 1,
          child: imageUrl != null && imageUrl.isNotEmpty
              ? Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) {
                      return child;
                    }

                    return Container(
                      color: backgroundColor,
                      alignment: Alignment.center,
                      child: const CircularProgressIndicator(color: _red),
                    );
                  },
                  errorBuilder: (_, __, ___) {
                    return _imagePlaceholder(backgroundColor);
                  },
                )
              : _imagePlaceholder(backgroundColor),
        ),
      ),
    );
  }

  Widget _imagePlaceholder(Color backgroundColor) {
    return Container(
      color: backgroundColor,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            QualityTheme.emoji(result.quality),
            style: const TextStyle(fontSize: 64),
          ),
          const SizedBox(height: 8),
          const Text(
            'Image unavailable',
            style: TextStyle(
              color: _textMid,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _qualityCard(Color qualityColor) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: qualityColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: qualityColor.withOpacity(0.22)),
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Text(
            QualityTheme.emoji(result.quality),
            style: const TextStyle(fontSize: 42),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  QualityTheme.label(result.quality),
                  style: const TextStyle(
                    color: _textDark,
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 7),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: qualityColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        'Confidence Score '
                        '${result.confidencePercent}',
                        style: TextStyle(
                          color: qualityColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _defectCard() {
    final defect = result.defectType?.trim();

    return _basicInfoCard(
      icon: Icons.warning_amber_rounded,
      iconColor: _red,
      iconBackground: _redLight,
      label: 'DEFECT DETECTED',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _formatName(defect ?? 'Unknown'),
            style: const TextStyle(
              color: _textDark,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              const Icon(Icons.analytics_outlined, color: _textMid, size: 16),
              const SizedBox(width: 5),
              Text(
                'Severity: ${result.severityDisplay}',
                style: const TextStyle(
                  color: _textMid,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _weightCard() {
    return _basicInfoCard(
      icon: Icons.scale_rounded,
      iconColor: _blue,
      iconBackground: _blueLight,
      label: 'FRUIT WEIGHT',
      child: Text(
        '${result.weightGrams} g',
        style: const TextStyle(
          color: _textDark,
          fontSize: 17,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _sectionTitle({required String title, required String subtitle}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: _textDark,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.7,
            ),
          ),
          const SizedBox(height: 3),
          Text(subtitle, style: const TextStyle(color: _textMid, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _recommendedUsageCard() {
    return _recommendationSection(
      icon: Icons.lightbulb_outline_rounded,
      color: _red,
      backgroundColor: _redLight,
      title: 'RECOMMENDED USAGE',
      text: result.recommendation,
    );
  }

  Widget _explanationCard() {
    return _recommendationSection(
      icon: Icons.info_outline_rounded,
      color: _blue,
      backgroundColor: _blueLight,
      title: 'WHY THIS RECOMMENDATION?',
      text: result.explanation!,
    );
  }

  Widget _wasteUsageCard() {
    return _recommendationSection(
      icon: Icons.recycling_rounded,
      color: _green,
      backgroundColor: _greenLight,
      title: 'WASTE UTILIZATION METHOD',
      text: result.wasteUsage!,
    );
  }

  Widget _safetyNoteCard() {
    return _recommendationSection(
      icon: Icons.health_and_safety_outlined,
      color: _orange,
      backgroundColor: _orangeLight,
      title: 'SAFETY NOTE',
      text: result.safetyNote!,
    );
  }

  Widget _recommendationSection({
    required IconData icon,
    required Color color,
    required Color backgroundColor,
    required String title,
    required String text,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
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
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: color, size: 21),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  text,
                  style: const TextStyle(
                    color: _textDark,
                    fontSize: 13,
                    height: 1.55,
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

  Widget _dateCard() {
    return _basicInfoCard(
      icon: Icons.calendar_today_rounded,
      iconColor: _textMid,
      iconBackground: const Color(0xFFF3F4F6),
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
  }

  Widget _basicInfoCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBackground,
    required String label,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
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
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: iconColor, size: 21),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: _textMid,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 7),
                child,
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _hasValue(String? value) {
    return value != null && value.trim().isNotEmpty;
  }

  String _formatName(String value) {
    final words = value
        .replaceAll('_', ' ')
        .replaceAll('-', ' ')
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty);

    return words
        .map((word) {
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');
  }
}
