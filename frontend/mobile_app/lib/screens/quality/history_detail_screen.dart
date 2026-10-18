// lib/screens/quality/history_detail_screen.dart
import 'package:flutter/material.dart';
import '../../l10n/d_app_strings.dart' as d;
import '../../l10n/q_app_strings.dart';
import '../../models/grading_result.dart';
import '../../theme/app_theme.dart';
import '../../widgets/grading_image.dart';
import '../../widgets/grading/low_quality_disease_popup.dart'
    show DiseaseTreatmentPanel;

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
    // Rebuild when the language is changed on the Profile page.
    return ListenableBuilder(
      listenable: QStrings.listenable,
      builder: (context, _) => _buildPage(context),
    );
  }

  Widget _buildPage(BuildContext context) {
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
                      title: qt('utilization_recommendation').toUpperCase(),
                      subtitle: qt('rules_subtitle'),
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
          Expanded(
            child: Text(
              qt('result_details'),
              textAlign: TextAlign.center,
              style: const TextStyle(
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
                  qQuality(result.quality),
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
                        '${qt("quality_confidence")} '
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

    // 🔧 FIXED: for disease, show the Disease component name + severity
    // (same numbers as the Disease screen), not the colour estimate.
    final showDisease = isDisease && result.hasDiseaseInfo;
    final title = showDisease
        ? '${qDefect(defect)} · $_diseaseName'
        : (defect == null ? qt('unknown') : qDefect(defect));
    final severityText = showDisease
        ? _diseaseSeverityText
        : result.severityDisplay;

    return _basicInfoCard(
      icon: Icons.warning_amber_rounded,
      iconColor: _red,
      iconBackground: _redLight,
      label: qt('defect_detected').toUpperCase(),
      trailing: isDisease
          ? _eyeButton(() => _showDiseaseDetailsPopup(context))
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
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
              Expanded(
                child: Text(
                  '${qt("severity")}: $severityText',
                  style: const TextStyle(
                    color: _textMid,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          if (showDisease && result.diseaseConfidence != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.verified_outlined, color: _textMid, size: 16),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    '${qt("disease_confidence")}: '
                    '${result.diseaseConfidenceDisplay}',
                    style: const TextStyle(
                      color: _textMid,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
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

  // 🔧 FIXED eye popup: disease name, disease confidence and severity
  // come from the Disease component values saved at grading time (same
  // numbers as the Disease screen). Organic / Chemical treatment and
  // prevention tips are rebuilt in the CURRENT app language (same tips).
  // Older records without disease info show a graceful fallback.
  void _showDiseaseDetailsPopup(BuildContext context) {
    final hasDetails = result.hasDiseaseInfo;

    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26),
          ),
          child: SingleChildScrollView(
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
                          Text(
                            qt('disease_details'),
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                              color: _textDark,
                            ),
                          ),
                          if (hasDetails)
                            Text(
                              _diseaseName,
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
                if (hasDetails)
                  DiseaseTreatmentPanel(
                    confidenceText: result.diseaseConfidenceDisplay,
                    severityText: _diseaseSeverityText,
                    isUncertain: result.isDiseaseUncertain,
                    treatmentFor: result.diseaseTreatmentFor,
                    scheduleFor: result.diseaseScheduleFor,
                    primary: _red,
                    secondary: _green,
                    softBackground: _redLight,
                    textColor: _textMid,
                    titleColor: _textDark,
                  )
                else
                  Text(
                    _noDiseaseNote,
                    textAlign: TextAlign.justify,
                    style: const TextStyle(
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
                    onPressed: () => Navigator.pop(dialogContext),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      qt('got_it'),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Translated disease name, e.g. "ஆந்த்ராக்னோஸ்".
  String get _diseaseName =>
      d.LanguageController.instance.disease(result.diseaseName ?? '');

  /// "Moderate (28.7%)" with the level translated. Uses the Disease
  /// component severity; older records fall back to the saved value.
  String get _diseaseSeverityText {
    final pct = result.diseaseSeverityPercent;
    if (pct == null) return result.severityDisplay;
    final level = result.diseaseSeverityLevel;
    final levelText = level == null
        ? ''
        : '${d.LanguageController.instance.severity(level)} ';
    return '$levelText(${pct.toStringAsFixed(1)}%)';
  }

  /// Message when no disease was identified for this record.
  String get _noDiseaseNote {
    switch (result.diseaseStatus) {
      case 'healthy':
        return qt('disease_healthy_note');
      case 'not_detected':
        return qt('disease_not_detected_note');
      case 'failed':
        return qt('disease_failed_note');
      default:
        return qt('disease_not_captured');
    }
  }

  Widget _weightCard() {
    return _basicInfoCard(
      icon: Icons.scale_rounded,
      iconColor: _blue,
      iconBackground: _blueLight,
      label: qt('fruit_weight').toUpperCase(),
      child: Text(
        qtf('weight_value', {'g': '${result.weightGrams}'}),
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
      title: qt('recommended_usage').toUpperCase(),
      text: result.recommendation,
    );
  }

  Widget _explanationCard() {
    return _recommendationSection(
      icon: Icons.info_outline_rounded,
      color: _blue,
      backgroundColor: _blueLight,
      title: qt('why_recommendation').toUpperCase(),
      text: result.explanation!,
    );
  }

  Widget _wasteUsageCard() {
    return _recommendationSection(
      icon: Icons.recycling_rounded,
      color: _green,
      backgroundColor: _greenLight,
      title: qt('waste_method').toUpperCase(),
      text: result.wasteUsage!,
    );
  }

  Widget _safetyNoteCard() {
    return _recommendationSection(
      icon: Icons.health_and_safety_outlined,
      color: _orange,
      backgroundColor: _orangeLight,
      title: qt('safety_note').toUpperCase(),
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
      label: qt('graded_on').toUpperCase(),
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
}
