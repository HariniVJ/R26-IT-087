// lib/screens/grading/history_detail_screen.dart
import 'package:flutter/material.dart';
import '../../models/grading_result.dart';
import '../../theme/app_theme.dart';
import '../../widgets/grading_image.dart';

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
                      _defectCard(context),
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
          // url -> local file -> emoji fallback, consistent with the
          // list screens, so the detail view never shows "Image
          // unavailable" just because image_url happened to be null.
          child: GradingImage(
            imageUrl: result.imageUrl,
            imagePath: result.imagePath,
            background: backgroundColor,
            emoji: QualityTheme.emoji(result.quality),
            emojiSize: 64,
          ),
        ),
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

  // 🆕 defect card now takes context so the eye icon can open the
  // disease-details popup. The eye icon only appears when
  // defectType == 'disease' — crack/rot/sunburn are unaffected.
  Widget _defectCard(BuildContext context) {
    final defect = result.defectType?.trim();
    final isDisease = defect == 'disease';

    return _basicInfoCard(
      icon: Icons.warning_amber_rounded,
      iconColor: _red,
      iconBackground: _redLight,
      label: 'DEFECT DETECTED',
      trailing: isDisease
          ? _eyeButton(() => _showDiseaseDetailsPopup(context))
          : null,
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

  // 🆕 small circular "view" button, right side of the defect card.
  Widget _eyeButton(VoidCallback onTap) {
    return Material(
      color: _redLight,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const Padding(
          padding: EdgeInsets.all(9),
          child: Icon(Icons.visibility_outlined, color: _red, size: 19),
        ),
      ),
    );
  }

  // 🆕 popup showing the disease name + treatment + prevention that was
  // captured at grading time (see quality_grading_screen.dart ->
  // GradingService.attachDiseaseInfo). If an older record doesn't have
  // this saved, shows a graceful fallback instead of an empty popup.
  void _showDiseaseDetailsPopup(BuildContext context) {
    final hasDetails = _hasValue(result.diseaseName);

    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: const BoxDecoration(
                      color: _redLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.coronavirus_rounded,
                      color: _red,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Disease Details',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                            color: _textDark,
                          ),
                        ),
                        if (hasDetails)
                          Text(
                            result.diseaseName!.replaceAll('_', ' '),
                            style: const TextStyle(
                              color: _textMid,
                              fontSize: 12.5,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              if (hasDetails) ...[
                if (_hasValue(result.diseaseTreatment)) ...[
                  Row(
                    children: [
                      const Icon(
                        Icons.medication_liquid_rounded,
                        color: _blue,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Recommended Treatment',
                        style: TextStyle(
                          color: _blue,
                          fontWeight: FontWeight.w900,
                          fontSize: 13.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    result.diseaseTreatment!,
                    style: const TextStyle(
                      color: _textMid,
                      fontSize: 12.5,
                      height: 1.5,
                    ),
                  ),
                ],
                if (result.diseasePrevention != null &&
                    result.diseasePrevention!.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  const Text(
                    'Prevention Tips',
                    style: TextStyle(
                      color: _green,
                      fontWeight: FontWeight.w900,
                      fontSize: 13.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...result.diseasePrevention!.map(
                    (tip) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Container(
                              width: 5,
                              height: 5,
                              decoration: const BoxDecoration(
                                color: _blue,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              tip,
                              style: const TextStyle(
                                color: _textMid,
                                fontSize: 12,
                                height: 1.45,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ] else
                const Text(
                  'Detailed disease information was not captured for '
                  'this result. Scan the fruit again to get the disease '
                  'name and treatment.',
                  style: TextStyle(
                    color: _textMid,
                    fontSize: 12.5,
                    height: 1.5,
                  ),
                ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Got It',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
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

  // 🆕 optional `trailing` widget (e.g. the eye button), shown at the
  // top-right of the card row, next to the icon+label+value content.
  Widget _basicInfoCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBackground,
    required String label,
    required Widget child,
    Widget? trailing,
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
          if (trailing != null) ...[const SizedBox(width: 8), trailing],
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
