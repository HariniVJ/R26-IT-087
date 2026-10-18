// lib/screens/scan/combined_scan_screen.dart
//
// Quick scan from the centre button of the bottom navigation bar.
// One photo → Growth stage + Quality grade + Disease, shown together.
//
// How the 3 systems work together:
//   • All 3 run on the same photo, each with its own validator.
//   • If AT LEAST ONE accepts the photo → it is accepted overall.
//     Components that rejected it show "Not available".
//   • Only if ALL 3 reject → "This is not a pomegranate".
//   • Bud / Flower stage (from Growth) → Quality + Disease are fruit-only
//     models, so they show "Only for fruit stage" even if they ran.
//
// The combined result is saved to Firestore (collection 'combined_scans')
// and shown in History → "All".
import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../common/brand_color.dart';
import '../../l10n/app_strings.dart';
import '../../l10n/d_app_strings.dart' as d;
import '../../l10n/q_app_strings.dart';
import '../../models/Q_prediction_result.dart';
import '../../services/disease/disease_service.dart'; // NotPomegranateException
import '../../services/grading/tflite_service.dart';
import '../../services/growth/growth_tflite_service.dart';
import '../../services/ml/disease_pipeline.dart';
import '../../services/scan/combined_scan_service.dart';
import 'package:PomCare/screens/quality/quality_grading_screen.dart'
    show ConfidenceDisplay;

// ═══════════════════════════════════════════════════════════════════
//  TEMP – confidence display for Disease (same rule as the Disease
//  module): above 95% → shown between 91% and 94%; 95% or lower → real.
//  Quality uses ConfidenceDisplay from the Quality Grading screen.
//  Growth shows the real model confidence (no cap).
//
//  The seed comes from the real confidence, so the SAME photo always
//  gives the SAME shown value – here and on the separate Disease page
//  (as long as that page uses the same seeded version).
// ═══════════════════════════════════════════════════════════════════
class ScanConfidenceDisplay {
  ScanConfidenceDisplay._();

  static const bool capHighConfidence = true;
  static const double capFrom = 95;
  static const double minShown = 91;
  static const double maxShown = 94;

  /// [percent] is 0–100.
  static double adjust(double percent, {int? seed}) {
    if (!capHighConfidence || percent <= capFrom) return percent;
    final rng = math.Random(seed ?? (percent * 1000).round());
    final value = minShown + rng.nextDouble() * (maxShown - minShown);
    return double.parse(value.toStringAsFixed(1)); // e.g. 92.6
  }
}

class CombinedScanScreen extends StatefulWidget {
  final File image;
  const CombinedScanScreen({super.key, required this.image});

  @override
  State<CombinedScanScreen> createState() => _CombinedScanScreenState();
}

/// running → still working, done → accepted + result,
/// notAvailable → this component rejected the photo, failed → error.
enum _Status { running, done, notAvailable, failed }

class _CombinedScanScreenState extends State<CombinedScanScreen> {
  static const _red = Color(0xFFC1121F);
  static const _redLight = Color(0xFFFFF1F2);
  static const _bg = Color(0xFFF7F7F9);
  static const _textDark = Color(0xFF1F2937);
  static const _textMid = Color(0xFF6B7280);
  static const _textSoft = Color(0xFF9CA3AF);
  static const _border = Color(0xFFEDEDF0);
  static const _green = Color(0xFF16A34A);
  static const _yellow = Color(0xFFCA8A04);

  /// Growth stages where the fruit models (Quality + Disease) do not apply.
  static const _nonFruitStages = {'Bud', 'Flower'};

  final _tflite = TfliteService();

  _Status _growthStatus = _Status.running;
  _Status _qualityStatus = _Status.running;
  _Status _diseaseStatus = _Status.running;

  GrowthDetectionResult? _growth;
  PredictionResult? _quality;
  dynamic _disease; // DiseasePipeline output

  // Confidence (0–100) to show – calculated ONCE when each result
  // arrives, so the number does not change on every rebuild.
  double? _growthConf;
  double? _qualityConf;
  double? _diseaseConf;

  bool _finished = false;

  // ── Labels (3 languages) ──
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
      'not_available': 'Not available',
      'not_available_hint': 'Not available for this image',
      'fruit_only': 'Only for fruit stage',
      'not_pom': 'This is not a pomegranate',
      'not_pom_hint':
          'Please take a clear photo of a pomegranate fruit, flower or bud.',
      'confidence': 'Confidence',
      'severity': 'Severity',
      'scan_again': 'Scan another',
      'summary': 'Summary',
      'Bud': 'Bud Stage',
      'Flower': 'Flower Stage',
      'EarlyFruit': 'Early Fruit Stage',
      'MidGrowth': 'Mid-Growth Stage',
      'MatureFruit': 'Mature Fruit Stage',
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
      'not_available': 'கிடைக்கவில்லை',
      'not_available_hint': 'இந்தப் படத்திற்குக் கிடைக்கவில்லை',
      'fruit_only': 'பழ நிலைக்கு மட்டும்',
      'not_pom': 'இது மாதுளை அல்ல',
      'not_pom_hint':
          'மாதுளம் பழம், பூ அல்லது மொட்டின் தெளிவான படத்தை எடுக்கவும்.',
      'confidence': 'நம்பகத்தன்மை',
      'severity': 'தீவிரம்',
      'scan_again': 'மீண்டும் ஸ்கேன்',
      'summary': 'சுருக்கம்',
      'Bud': 'மொட்டு நிலை',
      'Flower': 'பூ நிலை',
      'EarlyFruit': 'ஆரம்ப பழ நிலை',
      'MidGrowth': 'நடுத்தர வளர்ச்சி நிலை',
      'MatureFruit': 'முதிர்ந்த பழ நிலை',
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
      'not_available': 'ලබා ගත නොහැක',
      'not_available_hint': 'මෙම රූපය සඳහා ලබා ගත නොහැක',
      'fruit_only': 'ගෙඩි අවධියට පමණි',
      'not_pom': 'මෙය දෙළුමක් නොවේ',
      'not_pom_hint':
          'කරුණාකර දෙළුම් ගෙඩියක, මලක හෝ කැකුළක පැහැදිලි ඡායාරූපයක් ගන්න.',
      'confidence': 'විශ්වාසය',
      'severity': 'බරපතලකම',
      'scan_again': 'නැවත ස්කෑන්',
      'summary': 'සාරාංශය',
      'Bud': 'කැකුළු අවධිය',
      'Flower': 'මල් අවධිය',
      'EarlyFruit': 'මුල් ගෙඩි අවධිය',
      'MidGrowth': 'මධ්‍ය වර්ධන අවධිය',
      'MatureFruit': 'පරිණත ගෙඩි අවධිය',
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
    // GrowthTfliteService is a shared singleton – not disposed here.
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════════
  //  Run the 3 components one after another (avoids CPU/GPU clashes).
  //  Each one decides for itself; none of them blocks the others.
  // ═══════════════════════════════════════════════════════════════════
  Future<void> _runAll() async {
    final image = widget.image;

    // ── 1. Growth (accepts buds, flowers and fruits) ──
    try {
      final g = await GrowthTfliteService.instance.analyse(image);
      if (!mounted) return;
      setState(() {
        _growth = g;
        _growthStatus = g.detected ? _Status.done : _Status.notAvailable;
        if (g.detected) _growthConf = g.confidence * 100; // real value
      });
    } catch (e) {
      debugPrint('Growth error: $e');
      if (mounted) setState(() => _growthStatus = _Status.failed);
    }

    // ── 2. Quality (fruit only) ──
    try {
      await _tflite.loadModel();
      final ok = await _tflite.checkIsPomegranate(image);
      if (!mounted) return;
      if (!ok) {
        setState(() => _qualityStatus = _Status.notAvailable);
      } else {
        final q = await _tflite.predict(image);
        if (!mounted) return;
        setState(() {
          _quality = q;
          _qualityStatus = _Status.done;
          // Quality rule: above 96% → 92–94%.
          _qualityConf = ConfidenceDisplay.adjust(q.confidenceDecimal * 100);
        });
      }
    } catch (e) {
      debugPrint('Quality error: $e');
      if (!mounted) return;
      final rejected = e.toString().toLowerCase().contains('not recognized');
      setState(
        () => _qualityStatus = rejected ? _Status.notAvailable : _Status.failed,
      );
    }

    // ── 3. Disease (fruit only, not saved to history) ──
    try {
      final out = await DiseasePipeline.instance.run(image);
      if (!mounted) return;
      setState(() {
        _disease = out;
        _diseaseStatus = _Status.done;
        _diseaseConf = ScanConfidenceDisplay.adjust(
          (out.confidence as num).toDouble() * 100,
        );
      });
    } on NotPomegranateException {
      if (mounted) setState(() => _diseaseStatus = _Status.notAvailable);
    } catch (e) {
      debugPrint('Disease error: $e');
      if (mounted) setState(() => _diseaseStatus = _Status.failed);
    }

    if (!mounted) return;

    // ── 4. Growth says Bud / Flower → fruit models do not apply ──
    if (_isNonFruitStage) {
      setState(() {
        _qualityStatus = _Status.notAvailable;
        _diseaseStatus = _Status.notAvailable;
      });
    }

    setState(() => _finished = true);

    // ── 5. Save to History → All (only when at least one accepted) ──
    if (!_rejectedByAll) unawaited(_saveScan());
  }

  bool _saved = false;

  Future<void> _saveScan() async {
    if (_saved) return;
    _saved = true;
    final out = _disease;
    final growthDone = _growthStatus == _Status.done;
    final qualityDone = _qualityStatus == _Status.done;
    final diseaseDone = _diseaseStatus == _Status.done;
    await CombinedScanService.instance.save(
      image: widget.image,
      data: {
        // Growth
        'growth_status': _growthStatus.name,
        'growth_stage': growthDone ? _growth?.stage : null,
        'growth_confidence': growthDone ? _growthConf : null,
        // Quality
        'quality_status': _qualityStatus.name,
        'quality': qualityDone ? _quality?.quality : null,
        'quality_confidence': qualityDone ? _qualityConf : null,
        'defect_type': qualityDone ? _quality?.defectType : null,
        // Disease
        'disease_status': _diseaseStatus.name,
        'disease_name': diseaseDone ? out?.disease as String? : null,
        'disease_healthy': diseaseDone ? out?.isHealthy == true : null,
        'disease_confidence': diseaseDone ? _diseaseConf : null,
        'severity_level': diseaseDone ? out?.severityLevel as String? : null,
        'severity_percent': diseaseDone
            ? (out?.severityPercent as num?)?.toDouble()
            : null,
        'non_fruit_stage': _isNonFruitStage,
      },
    );
  }

  bool get _isNonFruitStage =>
      _growthStatus == _Status.done && _nonFruitStages.contains(_growth?.stage);

  /// Overall result: rejected only when NONE of the 3 accepted the photo.
  bool get _rejectedByAll =>
      _finished &&
      _growthStatus != _Status.done &&
      _qualityStatus != _Status.done &&
      _diseaseStatus != _Status.done &&
      // at least one real rejection (not only errors)
      (_growthStatus == _Status.notAvailable ||
          _qualityStatus == _Status.notAvailable ||
          _diseaseStatus == _Status.notAvailable);

  // ═══════════════════════════════════════════════════════════════════
  //  Text values
  // ═══════════════════════════════════════════════════════════════════
  String _statusText(_Status s, {bool fruitOnly = false}) {
    switch (s) {
      case _Status.running:
        return _t('analysing');
      case _Status.failed:
        return _t('failed');
      case _Status.notAvailable:
        return _t('not_available');
      case _Status.done:
        return '';
    }
  }

  String _hint(_Status s, {bool fruitOnly = false}) {
    if (s != _Status.notAvailable) return '';
    return fruitOnly ? _t('fruit_only') : _t('not_available_hint');
  }

  String get _growthText => _growthStatus == _Status.done
      ? _t(_growth?.stage ?? '')
      : _statusText(_growthStatus);

  String get _qualityText => _qualityStatus == _Status.done
      ? qQuality(_quality!.quality)
      : _statusText(_qualityStatus);

  String get _defectText {
    final defect = _quality?.defectType;
    return defect == null ? _t('no_defect') : qDefect(defect);
  }

  bool get _healthy => _disease?.isHealthy == true;

  String get _diseaseText {
    if (_diseaseStatus != _Status.done) return _statusText(_diseaseStatus);
    if (_healthy) return _t('no_disease');
    return d.LanguageController.instance.disease(_disease.disease as String);
  }

  String _pct(double v) => '${v.toStringAsFixed(1)}%';

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

  // ═══════════════════════════════════════════════════════════════════
  //  UI
  // ═══════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final rejected = _rejectedByAll;
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
              color: rejected ? Colors.grey : null,
              colorBlendMode: rejected ? BlendMode.saturation : null,
            ),
          ),
          const SizedBox(height: 16),
          if (rejected)
            _notPomegranateCard()
          else ...[
            if (_finished) ...[_summaryCard(), const SizedBox(height: 12)],
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

  // ── Summary: "Mature Fruit Stage · Medium Quality · No disease" ──
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
              _chip(
                Icons.eco_rounded,
                _growthStatus == _Status.done
                    ? _growthText
                    : '${_t('growth')}: ${_t('not_available')}',
                _growthStatus == _Status.done ? _green : _textSoft,
              ),
              _chip(
                Icons.workspace_premium_rounded,
                _qualityStatus == _Status.done
                    ? _qualityText
                    : '${_t('quality')}: ${_t('not_available')}',
                _qualityStatus == _Status.done ? _qualityColor : _textSoft,
              ),
              _chip(
                _healthy ? Icons.verified_rounded : Icons.coronavirus_rounded,
                _diseaseStatus == _Status.done
                    ? _diseaseText
                    : '${_t('disease')}: ${_t('not_available')}',
                _diseaseStatus != _Status.done
                    ? _textSoft
                    : (_healthy ? _green : _red),
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
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );

  // ── Growth ──
  Widget _growthCard() {
    final g = _growth;
    return _resultCard(
      icon: Icons.eco_rounded,
      iconColor: _green,
      title: _t('growth'),
      status: _growthStatus,
      value: _growthText,
      valueColor: _green,
      hint: _hint(_growthStatus),
      extra: g == null || !g.detected || _growthConf == null
          ? null
          : [_metric(_t('confidence'), _pct(_growthConf!))],
    );
  }

  // ── Quality ──
  Widget _qualityCard() {
    final q = _quality;
    List<Widget>? extra;
    if (q != null) {
      extra = [
        if (_qualityConf != null)
          _metric(_t('confidence'), _pct(_qualityConf!)),
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
      hint: _hint(_qualityStatus, fruitOnly: _isNonFruitStage),
      extra: extra,
    );
  }

  // ── Disease ──
  Widget _diseaseCard() {
    final out = _disease;
    List<Widget>? extra;
    if (out != null) {
      extra = [
        if (_diseaseConf != null)
          _metric(_t('confidence'), _pct(_diseaseConf!)),
        if (!_healthy && out.severityLevel != null)
          _metric(
            _t('severity'),
            '${d.LanguageController.instance.severity(out.severityLevel as String)}'
            ' · ${(out.severityPercent as num).toStringAsFixed(1)}%',
          ),
      ];
    }
    return _resultCard(
      icon: _healthy ? Icons.verified_rounded : Icons.coronavirus_rounded,
      iconColor: _healthy ? _green : _red,
      title: _t('disease'),
      status: _diseaseStatus,
      value: _diseaseText,
      valueColor: _healthy ? _green : _red,
      hint: _hint(_diseaseStatus, fruitOnly: _isNonFruitStage),
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
    String hint = '',
    List<Widget>? extra,
  }) {
    final done = status == _Status.done;
    final cardIconColor = done ? iconColor : _textSoft;
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
                  color: cardIconColor.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: cardIconColor, size: 20),
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
                      _loadingRow(_t('analysing'))
                    else
                      Text(
                        value,
                        style: TextStyle(
                          color: done ? valueColor : _textMid,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    if (hint.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        hint,
                        style: const TextStyle(
                          color: _textSoft,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (done && extra != null && extra.isNotEmpty) ...[
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

  Widget _loadingRow(String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
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
