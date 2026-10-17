// lib/screens/quality/quality_grading_screen.dart
import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/grading_result.dart';
import '../../models/Q_prediction_result.dart';
import '../../services/grading/grading_service.dart';
import '../../services/grading/recommendation_service.dart';
import '../../services/grading/tflite_service.dart';
import '../../common/brand_color.dart';
import '../../theme/app_theme.dart';
import '../../widgets/stack_storage_bar.dart';
import '../../widgets/date_range_pill.dart';
import '../../widgets/grading/grading_history_tile.dart';
import '../../widgets/grading/low_quality_disease_popup.dart';
import '../../l10n/q_app_strings.dart';
import 'history_screen.dart';
import 'history_detail_screen.dart';

// ═══════════════════════════════════════════════════════════════════
//  TEMP – confidence display cap (remove later)
//  Only confidence ABOVE 96% is changed to a value between 92% and 94%.
//  96% or lower is kept exactly as the model gives it.
//  To switch off: set capHighConfidence = false.
// ═══════════════════════════════════════════════════════════════════
class ConfidenceDisplay {
  ConfidenceDisplay._();

  static const bool capHighConfidence = true;
  static const double capFrom = 96; // only values > 96 are changed
  static const double minShown = 92;
  static const double maxShown = 94;

  static final math.Random _random = math.Random();

  /// [percent] is 0–100. Returns the value to show and save.
  static double adjust(double percent, {int? seed}) {
    if (!capHighConfidence || percent <= capFrom) return percent;
    final rng = seed == null ? _random : math.Random(seed);
    final value = minShown + rng.nextDouble() * (maxShown - minShown);
    return double.parse(value.toStringAsFixed(1)); // e.g. 93.4
  }

  /// Same as [adjust] but for 0–1 values (e.g. 0.987 → 0.934).
  static double adjustDecimal(double decimal, {int? seed}) =>
      adjust(decimal * 100, seed: seed) / 100;
}

class QualityGradingScreen extends StatefulWidget {
  const QualityGradingScreen({super.key});
  @override
  State<QualityGradingScreen> createState() => _QualityGradingScreenState();
}

enum _Phase { idle, analysing, result, rejected }

class _QualityGradingScreenState extends State<QualityGradingScreen>
    with TickerProviderStateMixin {
  String? get _userId => FirebaseAuth.instance.currentUser?.uid;

  File? _image;
  GradingResult? _result;
  PredictionResult? _prediction;
  _Phase _phase = _Phase.idle;
  String? _error;
  double _progress = 0;
  int _stepIndex = 0;
  bool _saving = false;
  bool? _savedOk;
  bool _validatingImage = false;
  int? _weightGrams;
  final _weightController = TextEditingController();
  Uint8List? _preprocessedBytes;
  bool _showPreprocessed = false;
  int _highCount = 0;
  int _mediumCount = 0;
  int _lowCount = 0;
  DateRange _selectedRange = DateRange.week;
  List<GradingResult> _recentResults = [];

  // 🆕 Disease component result for "low quality + disease".
  // Severity / confidence shown on the screen come from HERE (Disease
  // YOLO severity + disease classifier confidence), not from the grading
  // model's colour estimate — so the numbers match the Disease module.
  DiseaseFinding? _disease;
  bool _checkingDisease = false;

  // Step labels follow the app language.
  List<String> get _steps => [
    qt('step_preprocess'),
    qt('step_features'),
    qt('step_cnn'),
    qt('step_result'),
  ];

  late final AnimationController _pulseCtrl;
  late final AnimationController _resultCtrl;
  late final Animation<double> _resultAnim;

  final _picker = ImagePicker();
  final _service = GradingService();
  final _tflite = TfliteService();
  // Same rule engine GradingService uses internally — calling it
  // directly here means explanation / waste usage / safety note are
  // ready the instant the result screen appears, instead of waiting
  // for the Firestore save round-trip to come back.
  final _recommendation = RecommendationService.instance;

  static const _red = Color(0xFFC1121F);
  static const _redDark = Color(0xFF8E0B16);
  static const _bg = Color(0xFFF7F7F9);
  static const _redLight = Color(0xFFFFF1F2);
  static const _redMid = Color(0xFFFFD6D6);
  static const _textDark = Color(0xFF1F2937);
  static const _textMid = Color(0xFF6B7280);
  static const _border = Color(0xFFEDEDF0);
  static const _blue = Color(0xFF2563EB);
  static const _blueLight = Color(0xFFEFF6FF);
  static const _green = Color(0xFF16803A);
  static const _greenLight = Color(0xFFECFDF3);
  static const _orange = Color(0xFFEA580C);
  static const _orangeLight = Color(0xFFFFF7ED);

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _resultCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _resultAnim = CurvedAnimation(
      parent: _resultCtrl,
      curve: Curves.elasticOut,
    );
    // Rebuild when the language is changed on the Profile page.
    QStrings.listenable.addListener(_onLanguageChanged);
    _tflite.loadModel().catchError((e) => debugPrint('⚠️ TFLite: $e'));
    _loadStats();
  }

  void _onLanguageChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    QStrings.listenable.removeListener(_onLanguageChanged);
    _pulseCtrl.dispose();
    _resultCtrl.dispose();
    _weightController.dispose();
    _tflite.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    final uid = _userId;
    if (uid == null) return;
    try {
      final all = await _service.getHistory(uid);
      if (!mounted) return;
      final filtered = all.where((r) {
        final dt = r.dateTime;
        if (dt == null) return false;
        return _selectedRange.contains(dt);
      }).toList();
      setState(() {
        _highCount = filtered.where((r) => r.quality == 'high_quality').length;
        _mediumCount = filtered
            .where((r) => r.quality == 'medium_quality')
            .length;
        _lowCount = filtered.where((r) => r.quality == 'low_quality').length;
        _recentResults = all.take(3).toList();
      });
    } catch (e) {
      debugPrint('Stats load error: $e');
    }
  }

  Future<void> _pick(ImageSource src) async {
    final x = await _picker.pickImage(
      source: src,
      imageQuality: 85,
      maxWidth: 1024,
    );
    if (x == null) return;
    final pickedFile = File(x.path);
    setState(() {
      _image = pickedFile;
      _result = null;
      _prediction = null;
      _disease = null;
      _checkingDisease = false;
      _error = null;
      _phase = _Phase.idle;
      _savedOk = null;
      _preprocessedBytes = null;
      _showPreprocessed = false;
      _validatingImage = true;
    });
    bool isPomegranate;
    try {
      isPomegranate = await _tflite.checkIsPomegranate(pickedFile);
    } catch (e) {
      debugPrint('⚠️ Validation error: $e');
      isPomegranate = true;
    }
    if (!mounted) return;
    setState(() => _validatingImage = false);
    if (!isPomegranate) {
      _showNotPomegranatePopup();
      return;
    }
    // Camera photo → save a copy to the phone gallery AFTER the check
    // (same as the Disease module, album "Pomegranate").
    if (src == ImageSource.camera) {
      unawaited(_saveToGallery(pickedFile.path));
    }
  }

  /// Saves the captured photo to the phone gallery (album "Pomegranate").
  Future<void> _saveToGallery(String path) async {
    try {
      if (!await Gal.hasAccess()) {
        final granted = await Gal.requestAccess();
        if (!granted) {
          debugPrint('🖼️ Gallery permission denied');
          return;
        }
      }
      await Gal.putImage(path, album: 'Pomegranate');
      debugPrint('🖼️ Saved to gallery');
    } catch (e) {
      debugPrint('❌ Gallery save failed: $e');
    }
  }

  void _showNotPomegranatePopup() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(
                color: _redLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: _red,
                size: 30,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              qt('not_pomegranate'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _textDark,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              qt('retake_hint'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: _textMid, fontSize: 13),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                setState(() {
                  _image = null;
                  _preprocessedBytes = null;
                  _showPreprocessed = false;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _red,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.camera_alt_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    qt('retake_photo'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _togglePreprocessedView() async {
    if (_image == null) return;
    if (_preprocessedBytes == null) {
      final bytes = await _tflite.getPreprocessedPreview(_image!);
      if (!mounted) return;
      setState(() {
        _preprocessedBytes = bytes;
        _showPreprocessed = true;
      });
    } else {
      setState(() => _showPreprocessed = !_showPreprocessed);
    }
  }

  Future<void> _analyse() async {
    if (_image == null) return;
    final uid = _userId;
    if (uid == null) {
      setState(() => _error = qt('login_analyse'));
      return;
    }
    setState(() {
      _phase = _Phase.analysing;
      _progress = 0;
      _stepIndex = 0;
      _error = null;
      _savedOk = null;
      _disease = null;
      _checkingDisease = false;
    });
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    setState(() {
      _stepIndex = 0;
      _progress = 0.25;
    });
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    setState(() {
      _stepIndex = 1;
      _progress = 0.50;
    });

    PredictionResult prediction;
    try {
      prediction = await _tflite.predict(_image!);
    } catch (e) {
      final msg = e.toString().replaceFirst("Exception: ", "");
      if (!mounted) return;
      if (msg.toLowerCase().contains('not recognized')) {
        setState(() {
          _error = null;
          _phase = _Phase.rejected;
        });
        return;
      }
      setState(() {
        _error = qtf('model_error', {'msg': msg});
        _phase = _Phase.idle;
      });
      return;
    }

    if (!mounted) return;
    setState(() {
      _stepIndex = 2;
      _progress = 0.75;
    });
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    setState(() {
      _stepIndex = 3;
      _progress = 1.0;
    });

    _weightGrams = int.tryParse(_weightController.text.trim());

    // TEMP – confidence cap. Calculated ONCE so the screen, the local
    // result and the saved Firestore record all show the same number.
    // ≤ 96% → unchanged (real model value). > 96% → 92–94%.
    final shownConfidence = ConfidenceDisplay.adjustDecimal(
      prediction.confidenceDecimal,
    );

    // Compute the full recommendation (usage + explanation + waste
    // usage + safety note) right now — local, in-memory rule lookup.
    // For "low quality + disease" this is only a first estimate; it is
    // replaced with the Disease-severity version as soon as the disease
    // check finishes (see _saveToHistory).
    final ruleRow = await _recommendation.getRecommendation(
      quality: prediction.quality,
      defectType: prediction.defectType,
      severityPercent: prediction.severityPercent,
      weightGrams: _weightGrams,
    );

    final recommendedUsage =
        ruleRow?['recommended_usage'] as String? ?? prediction.recommendation;
    final explanation = ruleRow?['explanation'] as String?;
    final wasteUsage = ruleRow?['waste_usage'] as String?;
    final safetyNote = ruleRow?['safety_note'] as String?;

    final localResult = GradingResult(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: uid,
      quality: prediction.quality,
      confidence: shownConfidence, // TEMP (was prediction.confidenceDecimal)
      defectType: prediction.defectType,
      severityPercent: prediction.severityPercent,
      weightGrams: _weightGrams,
      recommendation: recommendedUsage,
      explanation: explanation,
      wasteUsage: wasteUsage,
      safetyNote: safetyNote,
      imageUrl: null,
      // local path available immediately, before any upload happens
      imagePath: _image?.path,
      createdAt: DateTime.now().toIso8601String(),
    );

    if (!mounted) return;
    setState(() {
      _prediction = prediction;
      _result = localResult;
      _phase = _Phase.result;
    });
    _resultCtrl.forward(from: 0);
    _saveToHistory(prediction, uid, shownConfidence);
  }

  /// 🔧 FIXED FLOW
  /// 1. low quality → run the Disease component FIRST (disease case) or
  ///    note the physical defect (crack / rot / sunburn).
  /// 2. Save ONCE — for the disease case the Disease YOLO severity is
  ///    used for the waste-use rule, and disease name / confidence /
  ///    severity / Organic + Chemical treatment / tips are saved with
  ///    the record (history "eye" icon shows the same values).
  /// 3. Show the low-quality popup.
  Future<void> _saveToHistory(
    PredictionResult p,
    String uid,
    double confidence,
  ) async {
    if (!mounted) return;
    final image = _image;
    setState(() => _saving = true);

    // ── 1. Disease / defect check ──
    LowQualityInfo? lowQualityInfo;
    if (p.quality == 'low_quality' && image != null) {
      final isDiseaseCase = GradingService.needsDiseaseCheck(
        p.quality,
        p.defectType,
      );
      if (isDiseaseCase) setState(() => _checkingDisease = true);
      try {
        lowQualityInfo = await _service.checkDiseaseIfLowQuality(
          quality: p.quality,
          defectType: p.defectType,
          imageFile: image,
        );
      } catch (e) {
        debugPrint('Disease check failed: $e');
      }
      // User pressed reset / picked another photo meanwhile → stop.
      if (!mounted || _image?.path != image.path) return;
      final f = lowQualityInfo?.finding;
      setState(() {
        _disease = f;
        _checkingDisease = false;
        // Disease info on the page right away (before the save finishes).
        if (f != null && _result != null) {
          _result = f.hasDisease
              ? _result!.copyWith(
                  diseaseStatus: f.statusKey,
                  diseaseName: f.diseaseName,
                  diseaseConfidence: f.confidence,
                  diseaseSeverityPercent: f.severityPercent,
                  diseaseSeverityLevel: f.severityLevel,
                  diseaseTreatment: f.organic.recommendation,
                  diseaseChemicalTreatment: f.chemical.recommendation,
                  diseasePrevention: f.prevention,
                  diseaseTipsSeed: f.tipsSeed,
                )
              : _result!.copyWith(diseaseStatus: f.statusKey);
        }
      });
      // Disease popup opens IMMEDIATELY — the save continues behind it.
            // Show the result page first, then open the popup after a short delay.
      // The save continues in the background meanwhile.
      if (lowQualityInfo != null) {
        unawaited(_showPopupLater(lowQualityInfo, image.path));
      }
    }

    // ── 2. Save once (with disease info when available) ──
    try {
      final savedResult = await _service.saveResult(
        userId: uid,
        quality: p.quality,
        confidence: confidence, // TEMP (was p.confidenceDecimal)
        imageFile: image,
        defectType: p.defectType,
        severityPercent: p.severityPercent,
        weightGrams: _weightGrams,
        disease: lowQualityInfo?.finding,
      );
      if (!mounted || _image?.path != image?.path) return;
      setState(() {
        _result = savedResult;
        _savedOk = true;
        _saving = false;
      });
      _loadStats();
    } catch (e) {
      debugPrint('🔴 SAVE ERROR: $e');
      if (!mounted) return;
      setState(() {
        _savedOk = false;
        _saving = false;
        _error = qtf('could_not_save', {
          'msg': e.toString().replaceFirst("Exception: ", ""),
        });
      });
    }
  }
    /// Waits so the user can see the result page, then opens the
  /// low-quality popup – only if the user is still on the same result.
  Future<void> _showPopupLater(LowQualityInfo info, String imagePath) async {
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;
    if (_phase != _Phase.result || _image?.path != imagePath) return;
    await showLowQualityPopup(context, info);
  }

  void _reset() {
    setState(() {
      _image = null;
      _result = null;
      _prediction = null;
      _disease = null;
      _checkingDisease = false;
      _phase = _Phase.idle;
      _error = null;
      _savedOk = null;
      _saving = false;
      _weightController.clear();
      _weightGrams = null;
      _preprocessedBytes = null;
      _showPreprocessed = false;
      _validatingImage = false;
    });
    _resultCtrl.reset();
  }

  // ═══════════════════════════════════════════════════════════════════
  //  UI
  // ═══════════════════════════════════════════════════════════════════

  void _openHistory() {
    final uid = _userId;
    if (uid == null) {
      setState(() => _error = qt('login_history'));
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => HistoryScreen(userId: uid)),
    ).then((_) => _loadStats());
  }

  void _openDetail(GradingResult r) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => HistoryDetailScreen(result: r)),
    ).then((_) => _loadStats());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          _appBar(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                if (_phase == _Phase.idle || _phase == _Phase.analysing) ...[
                  _storageStatsCard(),
                  const SizedBox(height: 16),
                ],
                if (_phase == _Phase.idle) _idleBody(),
                if (_phase == _Phase.analysing) _analysingBody(),
                if (_phase == _Phase.result) _resultBody(),
                if (_phase == _Phase.rejected) _rejectedBody(),
                if (_error != null) _errorBanner(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── App bar ──
  Widget _appBar() => Container(
    color: Colors.white,
    child: SafeArea(
      bottom: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: _border)),
        ),
        child: Row(
          children: [
            _barIcon(
              Icons.arrow_back_ios_new_rounded,
              () => Navigator.pop(context),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    qt('quality_grading'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _textDark,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            _barIcon(Icons.history_rounded, _openHistory),
            if (_phase != _Phase.idle || _image != null) ...[
              const SizedBox(width: 8),
              _barIcon(Icons.refresh_rounded, _reset),
            ],
          ],
        ),
      ),
    ),
  );

  Widget _barIcon(IconData icon, VoidCallback onTap) => Material(
    color: _redLight,
    borderRadius: BorderRadius.circular(12),
    child: InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: SizedBox(
        width: 40,
        height: 40,
        child: Icon(icon, color: _red, size: 19),
      ),
    ),
  );

  // ── Storage overview: simple white card ──
  Widget _storageStatsCard() {
    final total = _highCount + _mediumCount + _lowCount;
    return Container(
      decoration: _cardDecoration(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _redLight,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.inventory_2_outlined,
                  color: _red,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  qt('storage_overview'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _textDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              DateRangePill(
                selected: _selectedRange,
                onChanged: (r) {
                  setState(() => _selectedRange = r);
                  _loadStats();
                },
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$total',
                style: const TextStyle(
                  color: _textDark,
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  qtf('graded_range', {
                    'range': _selectedRange.label.toLowerCase(),
                  }),
                  style: const TextStyle(
                    color: _textMid,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          StackStorageBar(
            high: _highCount,
            medium: _mediumCount,
            low: _lowCount,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _legendItem(qt('high'), _highCount, AppColors.chartHigh),
              _legendItem(qt('medium'), _mediumCount, AppColors.chartMed),
              _legendItem(qt('low'), _lowCount, AppColors.chartLow),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendItem(String label, int count, Color color) => Expanded(
    child: Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _textMid,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '$count',
          style: const TextStyle(
            color: _textDark,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );

  // ── Idle: upload + pick + weight + analyse + recent history ──
  Widget _idleBody() => Column(
    children: [
      _uploadBox(),
      const SizedBox(height: 12),
      if (_validatingImage)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: _red),
              ),
              const SizedBox(width: 10),
              Text(
                qt('checking_image'),
                style: const TextStyle(
                  color: _textMid,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        )
      else ...[
        Row(
          children: [
            Expanded(
              child: _pickButton(
                Icons.camera_alt_rounded,
                qt('camera'),
                ImageSource.camera,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _pickButton(
                Icons.photo_library_rounded,
                qt('gallery'),
                ImageSource.gallery,
              ),
            ),
          ],
        ),
        if (_image != null) ...[
          const SizedBox(height: 12),
          TextField(
            controller: _weightController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: qt('enter_weight'),
              filled: true,
              fillColor: Colors.white,
              prefixIcon: const Icon(
                Icons.scale_rounded,
                color: _red,
                size: 18,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: _border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: _red, width: 1.4),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _primaryButton(),
        ],
      ],
      const SizedBox(height: 22),
      _recentHistorySection(),
    ],
  );

  Widget _uploadBox() {
    if (_image == null) {
      // Tap-to-upload placeholder: icon floats / scales, glow ring
      // pulses, sparkles twinkle — all driven by _pulseCtrl.
      return AnimatedBuilder(
        animation: _pulseCtrl,
        builder: (_, __) {
          final t = _pulseCtrl.value; // 0 -> 1 -> 0, looping
          final bounce = math.sin(t * math.pi) * 6;
          final iconScale = 1.0 + 0.06 * math.sin(t * math.pi);
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 44, horizontal: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_redLight, Colors.white],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _red.withOpacity(0.25 + 0.2 * t),
                width: 1.6,
              ),
            ),
            child: Column(
              children: [
                SizedBox(
                  height: 96,
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      // soft glow ring, expands and fades out on loop
                      Transform.scale(
                        scale: 1.2 + 0.5 * t,
                        child: Opacity(
                          opacity: (1 - t) * 0.35,
                          child: Container(
                            width: 82,
                            height: 82,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _red.withOpacity(0.18),
                            ),
                          ),
                        ),
                      ),
                      // the icon card itself — floats up/down, scales
                      Transform.translate(
                        offset: Offset(0, -bounce),
                        child: Transform.scale(
                          scale: iconScale,
                          child: Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: _redMid, width: 1.5),
                              boxShadow: [
                                BoxShadow(
                                  color: _red.withOpacity(0.18 + 0.1 * t),
                                  blurRadius: 18,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.add_photo_alternate_rounded,
                              color: _red,
                              size: 30,
                            ),
                          ),
                        ),
                      ),
                      // twinkling sparkle accents
                      Positioned(
                        top: 6 - bounce,
                        right: 28,
                        child: Opacity(
                          opacity: (0.25 + 0.65 * t).clamp(0.0, 1.0),
                          child: Icon(
                            Icons.auto_awesome_rounded,
                            color: _red.withOpacity(0.85),
                            size: 13,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 8 + bounce,
                        left: 26,
                        child: Opacity(
                          opacity: (0.85 - 0.55 * t).clamp(0.0, 1.0),
                          child: Icon(
                            Icons.auto_awesome_rounded,
                            color: _red.withOpacity(0.5),
                            size: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  qt('tap_to_upload'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _textDark,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  qt('file_types'),
                  style: const TextStyle(color: _textMid, fontSize: 12),
                ),
              ],
            ),
          );
        },
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        children: [
          if (_showPreprocessed && _preprocessedBytes != null)
            Container(
              height: 240,
              width: double.infinity,
              color: const Color(0xFFF3F4F6),
              child: Center(
                child: AspectRatio(
                  aspectRatio: 1.0,
                  child: Image.memory(_preprocessedBytes!, fit: BoxFit.contain),
                ),
              ),
            )
          else
            Image.file(
              _image!,
              height: 240,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          if (!_validatingImage)
            Positioned(
              top: 10,
              right: 10,
              child: GestureDetector(
                onTap: _togglePreprocessedView,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.55),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _showPreprocessed
                            ? Icons.image_rounded
                            : Icons.grid_view_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _showPreprocessed ? qt('original') : qt('preprocessed'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (!_validatingImage)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.65),
                      Colors.transparent,
                    ],
                  ),
                ),
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        qt('image_ready'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _pickButton(IconData icon, String label, ImageSource src) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    child: InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _pick(src),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _redMid),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: const BoxDecoration(
                color: _redLight,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: _red, size: 16),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _textDark,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _primaryButton() => _primaryActionButton(
    qt('analyse_quality'),
    Icons.auto_awesome_rounded,
    _analyse,
  );

  // ── Analysing: one card with pulse + progress + steps ──
  Widget _analysingBody() => Container(
    decoration: _cardDecoration(),
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (_, __) => SizedBox(
              width: 120,
              height: 120,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Transform.scale(
                    scale: 1.0 + 0.12 * _pulseCtrl.value,
                    child: Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _red.withOpacity(0.08 + 0.06 * _pulseCtrl.value),
                      ),
                    ),
                  ),
                  Container(
                    width: 74,
                    height: 74,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(colors: [_red, _redDark]),
                      boxShadow: [
                        BoxShadow(
                          color: _red.withOpacity(0.35),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Text(
                qt('analysing_quality'),
                style: const TextStyle(
                  color: _textDark,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Text(
              '${(_progress * 100).toInt()}%',
              style: const TextStyle(
                color: _red,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: _progress,
            minHeight: 7,
            backgroundColor: _redLight,
            valueColor: const AlwaysStoppedAnimation(_red),
          ),
        ),
        const SizedBox(height: 14),
        ..._steps.asMap().entries.map((e) => _stepRow(e.key, e.value)),
      ],
    ),
  );

  Widget _stepRow(int idx, String label) {
    final done = idx < _stepIndex;
    final running = idx == _stepIndex;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: done
                  ? AppColors.chartHigh
                  : running
                  ? _red
                  : const Color(0xFFE5E7EB),
            ),
            child: Icon(
              done
                  ? Icons.check
                  : running
                  ? Icons.hourglass_top_rounded
                  : Icons.circle,
              size: 12,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: done || running ? _textDark : _textMid,
                fontSize: 13,
                fontWeight: running ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Not a pomegranate ──
  Widget _rejectedBody() => Column(
    children: [
      if (_image != null)
        ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: ColorFiltered(
            colorFilter: const ColorFilter.mode(
              Colors.grey,
              BlendMode.saturation,
            ),
            child: Image.file(
              _image!,
              height: 220,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
        ),
      const SizedBox(height: 16),
      Container(
        width: double.infinity,
        decoration: _cardDecoration(borderColor: _redMid),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: const BoxDecoration(
                color: _redLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: _red,
                size: 30,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              qt('not_pomegranate'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _textDark,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              qt('retake_hint'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: _textMid, fontSize: 13),
            ),
          ],
        ),
      ),
      const SizedBox(height: 18),
      _primaryActionButton(
        qt('retake_photo'),
        Icons.camera_alt_rounded,
        _reset,
      ),
    ],
  );

  // ═══════════════════════════════════════════════════════════════════
  //  RESULT
  // ═══════════════════════════════════════════════════════════════════
  Widget _resultBody() {
    final r = _result!;
    final fg = QualityTheme.fgColor(r.quality);
    // TEMP – r.confidence already holds the capped value (see _analyse),
    // so the screen, Firestore and history all show the same number.
    final confText = r.confidencePercent;

    return ScaleTransition(
      scale: _resultAnim,
      child: Column(
        children: [
          // ── Hero: image + quality + quality confidence ──
          Container(
            decoration: _cardDecoration(),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_image != null)
                  Image.file(
                    _image!,
                    height: 270,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        qt('detected_result').toUpperCase(),
                        style: const TextStyle(
                          color: _textMid,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.9,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              qQuality(r.quality),
                              style: TextStyle(
                                color: fg,
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Quality-model confidence — small oval.
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: fg.withOpacity(0.10),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: fg.withOpacity(0.35)),
                            ),
                            child: Text(
                              confText,
                              style: TextStyle(
                                color: fg,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
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
          ),
          const SizedBox(height: 12),

          // ── Defect / disease ──
          if (_prediction?.defectType != null) ...[
            _defectInfoCard(),
            const SizedBox(height: 12),
          ],

          // ── Weight + date side by side ──
          Row(
            children: [
              if (r.weightGrams != null) ...[
                Expanded(
                  child: _miniInfo(
                    Icons.scale_rounded,
                    qt('fruit_weight'),
                    qtf('weight_value', {'g': '${r.weightGrams}'}),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: _miniInfo(
                  Icons.calendar_today_rounded,
                  qt('graded_on'),
                  r.displayDate,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Recommendation section ──
          _sectionTitleWidget(
            title: qt('utilization_recommendation'),
            subtitle: qt('rules_subtitle'),
          ),
          const SizedBox(height: 10),
          _recommendationUsageCard(r),
          if (_hasValue(r.explanation)) ...[
            const SizedBox(height: 10),
            _recommendationSectionCard(
              icon: Icons.info_outline_rounded,
              color: _blue,
              backgroundColor: _blueLight,
              title: qt('why_recommendation'),
              text: r.explanation!,
            ),
          ],
          if (_hasValue(r.wasteUsage)) ...[
            const SizedBox(height: 10),
            _recommendationSectionCard(
              icon: Icons.recycling_rounded,
              color: _green,
              backgroundColor: _greenLight,
              title: qt('waste_method'),
              text: r.wasteUsage!,
            ),
          ],
          if (_hasValue(r.safetyNote)) ...[
            const SizedBox(height: 10),
            _recommendationSectionCard(
              icon: Icons.health_and_safety_outlined,
              color: _orange,
              backgroundColor: _orangeLight,
              title: qt('safety_note'),
              text: r.safetyNote!,
            ),
          ],
          const SizedBox(height: 20),
          _primaryActionButton(
            qt('scan_another'),
            Icons.camera_alt_rounded,
            _reset,
          ),
        ],
      ),
    );
  }

  bool _hasValue(String? value) => value != null && value.trim().isNotEmpty;

  /// Main recommendation — light red card with primary-colour accents.
  Widget _recommendationUsageCard(GradingResult r) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _redLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: BrandColor.primary.withOpacity(0.25)),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.lightbulb_outline_rounded,
              color: BrandColor.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  qt('recommendation').toUpperCase(),
                  style: const TextStyle(
                    color: BrandColor.primary,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.9,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  r.recommendation,
                  style: const TextStyle(
                    color: _textDark,
                    fontSize: 14,
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Explanation / waste usage / safety note — white card, coloured strip.
  Widget _recommendationSectionCard({
    required IconData icon,
    required Color color,
    required Color backgroundColor,
    required String title,
    required String text,
  }) {
    return Container(
      width: double.infinity,
      decoration: _cardDecoration(),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 4, color: color),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: backgroundColor,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Icon(icon, color: color, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              color: color,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            text,
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Small icon + label + value tile (weight / date).
  Widget _miniInfo(IconData icon, String label, String value) {
    return Container(
      decoration: _cardDecoration(),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _redLight,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: _red, size: 17),
          ),
          const SizedBox(width: 10),
          Expanded(
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
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _textDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Section heading with a red accent bar.
  Widget _sectionTitleWidget({
    required String title,
    required String subtitle,
    Widget? trailing,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 4,
          height: 30,
          decoration: BoxDecoration(
            color: _red,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: _textDark,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(color: _textMid, fontSize: 11),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  /// Note shown when the Disease component did not confirm a disease.
  String _diseaseStatusNote(DiseaseCheckStatus status) {
    switch (status) {
      case DiseaseCheckStatus.healthy:
        return qt('disease_healthy_note');
      case DiseaseCheckStatus.notDetected:
        return qt('disease_not_detected_note');
      case DiseaseCheckStatus.failed:
        return qt('disease_failed_note');
      case DiseaseCheckStatus.uncertain:
        return qt('disease_uncertain_note');
      case DiseaseCheckStatus.confirmed:
        return '';
    }
  }

  /// Defect card. For "low quality + disease" severity and confidence
  /// come from the Disease component (same numbers as the Disease
  /// screen). For crack / rot / sunburn the grading estimate is shown.
  Widget _defectInfoCard() {
    final p = _prediction!;
    final defectType = p.defectType!;
    final isDiseaseCase = GradingService.needsDiseaseCheck(
      p.quality,
      defectType,
    );
    final d = _disease;

    String title = qDefect(defectType);
    String? severity;
    String? confidence;
    String? note;

    if (isDiseaseCase) {
      if (_checkingDisease) {
        note = null; // spinner row below
      } else if (d != null && d.hasDisease) {
        title = d.displayName;
        severity = d.severityDisplay;
        confidence = d.confidenceDisplay;
        if (d.isUncertain) note = qt('disease_uncertain_note');
      } else if (d != null) {
        note = _diseaseStatusNote(d.status);
      } else {
        severity = p.severityDisplay;
      }
    } else {
      severity = p.severityDisplay;
    }

    return Container(
      width: double.infinity,
      decoration: _cardDecoration(borderColor: _redMid),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _redLight,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  defectType == 'disease'
                      ? Icons.coronavirus_rounded
                      : Icons.warning_amber_rounded,
                  color: _red,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isDiseaseCase && d != null && d.hasDisease
                          ? '${qt("defect_detected")} · ${qDefect(defectType)}'
                          : qt('defect_detected'),
                      style: const TextStyle(
                        color: _textMid,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      title,
                      style: const TextStyle(
                        color: _textDark,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (isDiseaseCase && _checkingDisease) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: _red),
                ),
                const SizedBox(width: 8),
                Text(
                  qt('checking_disease'),
                  style: const TextStyle(color: _textMid, fontSize: 12.5),
                ),
              ],
            ),
          ],
          if (severity != null || confidence != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                if (severity != null)
                  Expanded(
                    child: _metricBox(
                      isDiseaseCase && confidence == null
                          ? qt('severity_estimate')
                          : qt('severity'),
                      severity,
                    ),
                  ),
                if (severity != null && confidence != null)
                  const SizedBox(width: 8),
                if (confidence != null)
                  Expanded(
                    child: _metricBox(qt('disease_confidence'), confidence),
                  ),
              ],
            ),
          ],
          if (note != null && note.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _orangeLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                note,
                style: const TextStyle(
                  color: _orange,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _metricBox(String label, String value) => Container(
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
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );

  // ── Recent history (same tile as View All screen) ──
  Widget _recentHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitleWidget(
          title: qt('grading_history'),
          subtitle: '',
          trailing: Material(
            color: _red,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: _openHistory,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      qt('view_all'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (_recentResults.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28),
            decoration: _cardDecoration(),
            child: Column(
              children: [
                const Icon(
                  Icons.inventory_2_outlined,
                  color: _redMid,
                  size: 34,
                ),
                const SizedBox(height: 8),
                Text(
                  qt('no_results'),
                  style: const TextStyle(color: _textMid, fontSize: 12.5),
                ),
              ],
            ),
          )
        else
          ..._recentResults.map(
            (r) => GradingHistoryTile(result: r, onTap: () => _openDetail(r)),
          ),
      ],
    );
  }

  Widget _primaryActionButton(
    String label,
    IconData icon,
    VoidCallback onTap,
  ) => Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      color: BrandColor.primary,
      boxShadow: [
        BoxShadow(
          color: BrandColor.primary.withOpacity(0.30),
          blurRadius: 14,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  BoxDecoration _cardDecoration({Color borderColor = _border}) => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: borderColor),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.04),
        blurRadius: 14,
        offset: const Offset(0, 4),
      ),
    ],
  );

  Widget _errorBanner() => Padding(
    padding: const EdgeInsets.only(top: 12),
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _error!,
              style: const TextStyle(
                color: Color(0xFFDC2626),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
