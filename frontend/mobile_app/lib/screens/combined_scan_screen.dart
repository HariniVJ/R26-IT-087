// lib/screens/scan/combined_scan_screen.dart
//
// Quick scan from the centre button of the bottom navigation bar.
// One photo → Growth stage + Quality grade + Disease, shown together.
// Nothing is saved to history here (the full screens still do that).
import 'dart:io';

import 'package:flutter/material.dart';

import '../../common/brand_color.dart';
import '../../l10n/app_strings.dart';
import '../../l10n/d_app_strings.dart' as d;
import '../../l10n/q_app_strings.dart';
import '../../models/Q_prediction_result.dart';
import '../../services/disease/disease_service.dart'; // NotPomegranateException
import '../../services/grading/tflite_service.dart';
import '../../services/ml/disease_pipeline.dart';
import 'package:PomCare/screens/quality/quality_grading_screen.dart'
    show ConfidenceDisplay;

// ═══════════════════════════════════════════════════════════════════
//  GROWTH – connect the Growth component here (ONE place only).
//
//  How the 3 systems work together:
//   1. Growth runs FIRST. It knows flowers, buds and fruits, so it is the
//      one that decides if the photo is a valid pomegranate plant / fruit.
//   2. Flower / bud / early stage → only the growth stage is shown.
//      Quality + Disease are skipped ("Only for fruit stage"), so a flower
//      is NOT rejected as "not a pomegranate".
//   3. Fruit stage → Quality validator → Quality grade → Disease.
//   4. If Growth is not connected (returns null) the old flow is used.
// ═══════════════════════════════════════════════════════════════════
class GrowthResult {
  final String stage; // label shown on the screen, e.g. "Mature"
  final double? confidence; // 0–1, optional
  final bool isValid; // false → Growth model says "not a pomegranate"
  final bool isFruitStage; // true → run Quality + Disease

  const GrowthResult(
    this.stage, {
    this.confidence,
    this.isValid = true,
    this.isFruitStage = true,
  });
}

class GrowthAdapter {
  /// Growth stage labels that are a FRUIT (Quality + Disease run).
  /// Change these to match the Growth model's class names (lower case).
  static const fruitStages = {'immature', 'mature', 'ripe', 'fruit'};

  /// Labels the Growth model uses for an invalid / non-pomegranate photo.
  static const invalidLabels = {'invalid', 'not_pomegranate', 'other'};

  static Future<GrowthResult?> predict(File image) async {
    // TODO: replace with the Growth component's service, for example:
    //
    // final out = await GrowthService.instance.predict(image);
    // final label = out.stageName.toLowerCase();
    // return GrowthResult(
    //   out.stageName,
    //   confidence: out.confidence,
    //   isValid: !invalidLabels.contains(label),
    //   isFruitStage: fruitStages.any(label.contains),
    // );
    return null; // not connected yet → old flow
  }
}

// ═══════════════════════════════════════════════════════════════════

class CombinedScanScreen extends StatefulWidget {
  final File image;
  const CombinedScanScreen({super.key, required this.image});

  @override
  State<CombinedScanScreen> createState() => _CombinedScanScreenState();
}

enum _Status { running, done, failed, skipped }

class _CombinedScanScreenState extends State<CombinedScanScreen> {
  static const _red = Color(0xFFC1121F);
  static const _redLight = Color(0xFFFFF1F2);
  static const _bg = Color(0xFFF7F7F9);
  static const _textDark = Color(0xFF1F2937);
  static const _textMid = Color(0xFF6B7280);
  static const _border = Color(0xFFEDEDF0);
  static const _green = Color(0xFF16A34A);
  static const _yellow = Color(0xFFCA8A04);

  final _tflite = TfliteService();

  bool _checking = true;
  bool _notPomegranate = false;

  _Status _growthStatus = _Status.running;
  _Status _qualityStatus = _Status.running;
  _Status _diseaseStatus = _Status.running;

  GrowthResult? _growth;
  PredictionResult? _quality;
  dynamic _disease; // DiseasePipeline output

  // Labels that are not in the existing string files (3 languages).
  static const _txt = {
    AppLang.en: {
      'title': 'Scan Result',
      'growth': 'Growth Stage',
      'quality': 'Quality Grade',
      'disease': 'Disease',
      'no_disease': 'No disease',
      'no_defect': 'No defect',
      'defect': 'Defect',
      'analysing': 'Analysing...',
      'failed': 'Could not analyse',
      'not_connected': 'Not available yet',
      'not_pom': 'This is not a pomegranate',
      'not_pom_hint': 'Please take a clear photo of one pomegranate fruit.',
      'confidence': 'Confidence',
      'scan_again': 'Scan another',
      'summary': 'Summary',
      'fruit_only': 'Only for fruit stage',
    },
    AppLang.ta: {
      'title': 'ஸ்கேன் முடிவு',
      'growth': 'வளர்ச்சி நிலை',
      'quality': 'தர நிலை',
      'disease': 'நோய்',
      'no_disease': 'நோய் இல்லை',
      'no_defect': 'குறைபாடு இல்லை',
      'defect': 'குறைபாடு',
      'analysing': 'பகுப்பாய்வு செய்கிறது...',
      'failed': 'பகுப்பாய்வு செய்ய முடியவில்லை',
      'not_connected': 'இன்னும் கிடைக்கவில்லை',
      'not_pom': 'இது மாதுளை அல்ல',
      'not_pom_hint': 'ஒரு மாதுளம் பழத்தின் தெளிவான படத்தை எடுக்கவும்.',
      'confidence': 'நம்பகத்தன்மை',
      'scan_again': 'மீண்டும் ஸ்கேன்',
      'summary': 'சுருக்கம்',
      'fruit_only': 'பழ நிலைக்கு மட்டும்',
    },
    AppLang.si: {
      'title': 'ස්කෑන් ප්‍රතිඵලය',
      'growth': 'වර්ධන අවධිය',
      'quality': 'ගුණාත්මක ශ්‍රේණිය',
      'disease': 'රෝගය',
      'no_disease': 'රෝගයක් නැත',
      'no_defect': 'දෝෂයක් නැත',
      'defect': 'දෝෂය',
      'analysing': 'විශ්ලේෂණය කරමින්...',
      'failed': 'විශ්ලේෂණය කළ නොහැක',
      'not_connected': 'තවම නොමැත',
      'not_pom': 'මෙය දෙළුමක් නොවේ',
      'not_pom_hint': 'කරුණාකර එක් දෙළුම් ගෙඩියක පැහැදිලි ඡායාරූපයක් ගන්න.',
      'confidence': 'විශ්වාසය',
      'scan_again': 'නැවත ස්කෑන්',
      'summary': 'සාරාංශය',
      'fruit_only': 'ගෙඩි අවධියට පමණි',
    },
  };

  String _t(String key) =>
      _txt[LanguageController.instance.lang]?[key] ??
      _txt[AppLang.en]![key] ??
      key;

  @override
  void initState() {
    super.initState();
    LanguageController.instance.addListener(_refresh);
    _runAll();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    LanguageController.instance.removeListener(_refresh);
    _tflite.dispose();
    super.dispose();
  }

  // ── Run the 3 components one after another (avoids GPU/CPU clashes) ──
  Future<void> _runAll() async {
    final image = widget.image;

    // 1. Growth FIRST – it accepts flowers, buds and fruits.
    GrowthResult? growth;
    try {
      growth = await GrowthAdapter.predict(image);
    } catch (e) {
      debugPrint('Growth error: $e');
      if (mounted) setState(() => _growthStatus = _Status.failed);
    }
    if (!mounted) return;

    // Growth model says this is not a pomegranate at all.
    if (growth != null && !growth.isValid) {
      setState(() {
        _checking = false;
        _notPomegranate = true;
      });
      return;
    }

    setState(() {
      _checking = false;
      _growth = growth;
      if (_growthStatus != _Status.failed) _growthStatus = _Status.done;
    });

    // Flower / bud / early stage → only growth result, nothing rejected.
    if (growth != null && !growth.isFruitStage) {
      _skipFruitChecks();
      return;
    }

    // 2. Fruit (or growth not connected) → quality validator.
    try {
      await _tflite.loadModel();
      final ok = await _tflite.checkIsPomegranate(image);
      if (!mounted) return;
      if (!ok) {
        if (growth == null) {
          // Old flow: no growth result → reject like before.
          setState(() => _notPomegranate = true);
        } else {
          // Growth says fruit, but the fruit models can't use this photo.
          _skipFruitChecks();
        }
        return;
      }
    } catch (e) {
      debugPrint('Validator error: $e');
    }

    // 3. Quality grade.
    try {
      final q = await _tflite.predict(image);
      if (!mounted) return;
      setState(() {
        _quality = q;
        _qualityStatus = _Status.done;
      });
    } catch (e) {
      debugPrint('Quality error: $e');
      if (mounted) setState(() => _qualityStatus = _Status.failed);
    }

    // 4. Disease (on-device pipeline, not saved to history).
    try {
      final out = await DiseasePipeline.instance.run(image);
      if (!mounted) return;
      setState(() {
        _disease = out;
        _diseaseStatus = _Status.done;
      });
    } on NotPomegranateException {
      if (!mounted) return;
      setState(() {
        if (growth == null) {
          _notPomegranate = true;
        } else {
          _diseaseStatus = _Status.skipped;
        }
      });
    } catch (e) {
      debugPrint('Disease error: $e');
      if (mounted) setState(() => _diseaseStatus = _Status.failed);
    }
  }

  void _skipFruitChecks() {
    if (!mounted) return;
    setState(() {
      _qualityStatus = _Status.skipped;
      _diseaseStatus = _Status.skipped;
    });
  }

  // ═══════════════════════════════════════════════════════════════════
  //  UI
  // ═══════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        foregroundColor: _textDark,
        title: Text(
          _t('title'),
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.file(
              widget.image,
              height: 250,
              width: double.infinity,
              fit: BoxFit.cover,
              color: _notPomegranate ? Colors.grey : null,
              colorBlendMode: _notPomegranate ? BlendMode.saturation : null,
            ),
          ),
          const SizedBox(height: 16),
          if (_checking)
            _loadingRow(_t('analysing'))
          else if (_notPomegranate)
            _notPomegranateCard()
          else ...[
            if (_allDone) ...[_summaryCard(), const SizedBox(height: 12)],
            _growthCard(),
            const SizedBox(height: 12),
            _qualityCard(),
            const SizedBox(height: 12),
            _diseaseCard(),
          ],
          const SizedBox(height: 20),
          _primaryButton(),
        ],
      ),
    );
  }

  bool get _allDone =>
      _growthStatus != _Status.running &&
      _qualityStatus != _Status.running &&
      _diseaseStatus != _Status.running;

  // ── Text values used by the cards and the summary ──
  String get _growthText {
    if (_growthStatus == _Status.failed) return _t('failed');
    return _growth?.stage ?? _t('not_connected');
  }

  String get _qualityText {
    if (_qualityStatus == _Status.skipped) return _t('fruit_only');
    if (_qualityStatus == _Status.failed || _quality == null) {
      return _t('failed');
    }
    return qQuality(_quality!.quality);
  }

  String get _defectText {
    final defect = _quality?.defectType;
    if (defect == null) return _t('no_defect');
    return qDefect(defect);
  }

  String get _diseaseText {
    if (_diseaseStatus == _Status.skipped) return _t('fruit_only');
    if (_diseaseStatus == _Status.failed || _disease == null) {
      return _t('failed');
    }
    if (_disease.isHealthy == true) return _t('no_disease');
    return d.LanguageController.instance.disease(_disease.disease as String);
  }

  Color get _qualityColor {
    switch (_quality?.quality) {
      case 'high_quality':
        return _green;
      case 'medium_quality':
        return _yellow;
      case 'low_quality':
        return _red;
      default:
        return _textMid;
    }
  }

  // ── Summary: "Mature · Medium quality · No disease" ──
  Widget _summaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _redLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: BrandColor.primary.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _t('summary').toUpperCase(),
            style: const TextStyle(
              color: BrandColor.primary,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.9,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _chip(Icons.eco_rounded, _growthText, _green),
              if (_qualityStatus != _Status.skipped)
                _chip(
                  Icons.workspace_premium_rounded,
                  _qualityText,
                  _qualityColor,
                ),
              if (_diseaseStatus != _Status.skipped)
                _chip(
                  _disease?.isHealthy == true
                      ? Icons.verified_rounded
                      : Icons.coronavirus_rounded,
                  _diseaseText,
                  _disease?.isHealthy == true ? _green : _red,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withOpacity(0.4)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 5),
        Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );

  // ── Growth ──
  Widget _growthCard() {
    final conf = _growth?.confidence;
    return _resultCard(
      icon: Icons.eco_rounded,
      iconColor: _green,
      title: _t('growth'),
      status: _growthStatus,
      value: _growthText,
      valueColor: _growth == null ? _textMid : _textDark,
      extra: conf == null
          ? null
          : [_metric(_t('confidence'), '${(conf * 100).toStringAsFixed(1)}%')],
    );
  }

  // ── Quality ──
  Widget _qualityCard() {
    final q = _quality;
    List<Widget>? extra;
    if (q != null) {
      // TEMP – same confidence cap as the Quality Grading screen.
      final conf = ConfidenceDisplay.adjust(q.confidenceDecimal * 100);
      extra = [
        _metric(_t('confidence'), '${conf.toStringAsFixed(1)}%'),
        _metric(_t('defect'), _defectText),
      ];
    }
    return _resultCard(
      icon: Icons.workspace_premium_rounded,
      iconColor: _qualityColor,
      title: _t('quality'),
      status: _qualityStatus,
      value: _qualityText,
      valueColor: _qualityColor,
      extra: extra,
    );
  }

  // ── Disease ──
  Widget _diseaseCard() {
    final out = _disease;
    List<Widget>? extra;
    if (out != null) {
      final conf = (out.confidence as double) * 100;
      extra = [
        _metric(_t('confidence'), '${conf.toStringAsFixed(1)}%'),
        if (out.isHealthy != true && out.severityLevel != null)
          _metric(
            qt('severity'),
            '${d.LanguageController.instance.severity(out.severityLevel as String)}'
            ' · ${(out.severityPercent as num).toStringAsFixed(1)}%',
          ),
      ];
    }
    final healthy = out?.isHealthy == true;
    return _resultCard(
      icon: healthy ? Icons.verified_rounded : Icons.coronavirus_rounded,
      iconColor: healthy ? _green : _red,
      title: _t('disease'),
      status: _diseaseStatus,
      value: _diseaseText,
      valueColor: healthy ? _green : _red,
      extra: extra,
    );
  }

  // ── Shared card ──
  Widget _resultCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required _Status status,
    required String value,
    required Color valueColor,
    List<Widget>? extra,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: _textMid,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    if (status == _Status.running)
                      _loadingRow(_t('analysing'), small: true)
                    else
                      Text(
                        value,
                        style: TextStyle(
                          color: status == _Status.done ? valueColor : _textMid,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (status == _Status.done && extra != null && extra.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                for (int i = 0; i < extra.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(child: extra[i]),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _metric(String label, String value) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: _redLight,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: _textMid,
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            color: _red,
            fontSize: 13.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );

  Widget _loadingRow(String text, {bool small = false}) => Padding(
    padding: EdgeInsets.symmetric(vertical: small ? 2 : 14),
    child: Row(
      mainAxisAlignment: small
          ? MainAxisAlignment.start
          : MainAxisAlignment.center,
      children: [
        const SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(strokeWidth: 2, color: _red),
        ),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(color: _textMid, fontSize: 13)),
      ],
    ),
  );

  Widget _notPomegranateCard() => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: _card(),
    child: Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: const BoxDecoration(
            color: _redLight,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.error_outline_rounded, color: _red, size: 28),
        ),
        const SizedBox(height: 12),
        Text(
          _t('not_pom'),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: _textDark,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _t('not_pom_hint'),
          textAlign: TextAlign.center,
          style: const TextStyle(color: _textMid, fontSize: 13),
        ),
      ],
    ),
  );

  Widget _primaryButton() => SizedBox(
    width: double.infinity,
    child: ElevatedButton.icon(
      onPressed: () => Navigator.pop(context),
      icon: const Icon(Icons.camera_alt_rounded, color: Colors.white),
      label: Text(
        _t('scan_again'),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: BrandColor.primary,
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
  );

  BoxDecoration _card() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: _border),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.04),
        blurRadius: 14,
        offset: const Offset(0, 4),
      ),
    ],
  );
}
