// lib/screens/quality_grading_screen.dart
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/grading_result.dart';
import '../../models/Q_prediction_result.dart';
import '../../services/grading/grading_service.dart';
import '../../services/grading/recommendation_service.dart';
import '../../services/grading/tflite_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_box.dart';
import '../../widgets/stack_storage_bar.dart';
import '../../widgets/date_range_pill.dart';
import '../../widgets/grading_image.dart';
import '../../widgets/low_quality_disease_popup.dart';
import '../../l10n/q_app_strings.dart';
import 'history_screen.dart';
import 'history_detail_screen.dart';

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

  final _steps = [
    'Image preprocessing',
    'Feature extraction',
    'CNN classification',
    'Generating result',
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
  static const _redLight = Color(0xFFFFEEEE);
  static const _redMid = Color(0xFFFFD6D6);
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
    _tflite.loadModel().catchError((e) => debugPrint('⚠️ TFLite: $e'));
    _loadStats();
  }

  @override
  void dispose() {
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
              AppStrings.get("not_pomegranate"),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _textDark,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Please retake a clear photo showing the whole fruit.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _textMid, fontSize: 13),
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
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.camera_alt_rounded, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Retake Photo',
                    style: TextStyle(
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
      setState(() => _error = 'Please log in before analysing a fruit.');
      return;
    }
    setState(() {
      _phase = _Phase.analysing;
      _progress = 0;
      _stepIndex = 0;
      _error = null;
      _savedOk = null;
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
        _error = 'Model error: $msg';
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

    // Compute the full recommendation (usage + explanation + waste
    // usage + safety note) right now — this is a local, in-memory rule
    // lookup (see RecommendationService), not a network call, so it's
    // effectively instant. No need to wait for the Firestore save to
    // come back before these sections can show.
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
      confidence: prediction.confidenceDecimal,
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
    _saveToHistory(prediction, uid);
  }

  Future<void> _saveToHistory(PredictionResult p, String uid) async {
    if (!mounted) return;
    setState(() => _saving = true);

    // The disease check doesn't depend on the save's result at all, so
    // kick it off right now, in parallel with the save, using the
    // quality/defectType we already have from `p`.
    Future<LowQualityInfo?>? diseaseInfoFuture;
    if (p.quality == 'low_quality' && _image != null) {
      diseaseInfoFuture = _service.checkDiseaseIfLowQuality(
        quality: p.quality,
        defectType: p.defectType,
        imageFile: _image!,
      );
    }

    GradingResult? savedResult;
    try {
      savedResult = await _service.saveResult(
        userId: uid,
        quality: p.quality,
        confidence: p.confidenceDecimal,
        imageFile: _image,
        defectType: p.defectType,
        severityPercent: p.severityPercent,
        weightGrams: _weightGrams,
      );
      if (!mounted) return;
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
        _error =
            'Could not save result: ${e.toString().replaceFirst("Exception: ", "")}';
      });
    }

    if (diseaseInfoFuture != null) {
      final lowQualityInfo = await diseaseInfoFuture;

      // 🆕 Persist disease name/treatment/prevention onto the saved
      // history record (if the save succeeded) so the "eye" icon on
      // the history detail screen can show this later without
      // re-running the disease pipeline.
      if (lowQualityInfo != null &&
          lowQualityInfo.isDiseaseCase &&
          lowQualityInfo.diseaseResult != null &&
          savedResult != null) {
        final dr = lowQualityInfo.diseaseResult!;
        try {
          await _service.attachDiseaseInfo(
            resultId: savedResult.id,
            diseaseName: dr.diseaseName,
            treatment: dr.treatment,
            prevention: dr.prevention,
          );
          if (mounted) {
            setState(() {
              _result = GradingResult(
                id: savedResult!.id,
                userId: savedResult.userId,
                quality: savedResult.quality,
                confidence: savedResult.confidence,
                defectType: savedResult.defectType,
                severityPercent: savedResult.severityPercent,
                weightGrams: savedResult.weightGrams,
                recommendation: savedResult.recommendation,
                explanation: savedResult.explanation,
                wasteUsage: savedResult.wasteUsage,
                safetyNote: savedResult.safetyNote,
                diseaseName: dr.diseaseName,
                diseaseTreatment: dr.treatment,
                diseasePrevention: dr.prevention,
                imageUrl: savedResult.imageUrl,
                imagePath: savedResult.imagePath,
                createdAt: savedResult.createdAt,
              );
            });
          }
        } catch (e) {
          debugPrint('Disease info attach failed: $e');
        }
      }

      if (lowQualityInfo != null && mounted) {
        await showLowQualityPopup(context, lowQualityInfo);
      }
    }
  }

  void _reset() {
    setState(() {
      _image = null;
      _result = null;
      _prediction = null;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _appBar(),
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      if (_phase == _Phase.idle || _phase == _Phase.analysing)
                        _storageStatsCard(),
                      const SizedBox(height: 16),
                      if (_phase == _Phase.idle) _idleBody(),
                      if (_phase == _Phase.analysing) _analysingBody(),
                      if (_phase == _Phase.result) _resultBody(),
                      if (_phase == _Phase.rejected) _rejectedBody(),
                      if (_error != null) _errorBanner(),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _appBar() => Container(
    color: Colors.white,
    child: SafeArea(
      bottom: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: _border, width: 1)),
        ),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: _textDark,
                size: 18,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            Expanded(
              child: Text(
                AppStrings.get("quality_grading"),
                style: const TextStyle(
                  color: _textDark,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.history_rounded,
                    color: _textDark,
                    size: 22,
                  ),
                  onPressed: () {
                    final uid = _userId;
                    if (uid == null) {
                      setState(() => _error = 'Please log in to view history.');
                      return;
                    }
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => HistoryScreen(userId: uid),
                      ),
                    );
                  },
                ),
                if (_phase != _Phase.idle || _image != null)
                  IconButton(
                    icon: const Icon(
                      Icons.refresh_rounded,
                      color: _red,
                      size: 22,
                    ),
                    onPressed: _reset,
                  ),
              ],
            ),
          ],
        ),
      ),
    ),
  );

  Widget _storageStatsCard() {
    final total = _highCount + _mediumCount + _lowCount;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'STORAGE OVERVIEW',
                  style: TextStyle(
                    color: _textMid,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
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
          const SizedBox(height: 12),
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
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'graded ${_selectedRange.label.toLowerCase()}',
                style: const TextStyle(
                  color: _textMid,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
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
          const SizedBox(height: 10),
          StackStorageLegend(
            high: _highCount,
            medium: _mediumCount,
            low: _lowCount,
          ),
        ],
      ),
    );
  }

  Widget _idleBody() => Column(
    children: [
      _uploadBox(),
      const SizedBox(height: 12),
      if (_validatingImage)
        Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: _red),
              ),
              SizedBox(width: 10),
              Text(
                'Checking image...',
                style: TextStyle(
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
                AppStrings.get("camera"),
                ImageSource.camera,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _pickButton(
                Icons.photo_library_rounded,
                AppStrings.get("gallery"),
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
              hintText: AppStrings.get("enter_weight"),
              filled: true,
              fillColor: Colors.white,
              prefixIcon: const Icon(
                Icons.scale_rounded,
                color: _red,
                size: 18,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: _border),
              ),
            ),
          ),
        ],
        const SizedBox(height: 12),
        if (_image != null) _primaryButton(),
      ],
      const SizedBox(height: 16),
      _recentHistoryCard(),
    ],
  );

  Widget _uploadBox() {
    if (_image == null) {
      // 🆕 Same concept (tap-to-upload placeholder), just livelier:
      // the icon card gently floats up/down and scales, a soft glow
      // ring pulses outward behind it, and two small sparkles twinkle
      // — all driven by the existing _pulseCtrl, so no extra
      // AnimationController/dispose plumbing is needed.
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
                  AppStrings.get("tap_to_upload"),
                  style: const TextStyle(
                    color: _textDark,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'JPG · PNG · Max 10 MB',
                  style: TextStyle(color: _textMid, fontSize: 12),
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
                        _showPreprocessed
                            ? 'Original'
                            : 'Preprocessed (224×224)',
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
                child: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Image ready — tap Analyse',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
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

  Widget _pickButton(IconData icon, String label, ImageSource src) =>
      GestureDetector(
        onTap: () => _pick(src),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: _red, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: _textDark,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );

  Widget _primaryButton() => GestureDetector(
    onTap: _analyse,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: BoxDecoration(
        color: _red,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _red.withOpacity(0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text(
            AppStrings.get("analyse_quality"),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _analysingBody() => Column(
    children: [
      AnimatedBuilder(
        animation: _pulseCtrl,
        builder: (_, __) => Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(28),
          child: Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Transform.scale(
                  scale: 1.0 + 0.12 * _pulseCtrl.value,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _red.withOpacity(0.08 + 0.06 * _pulseCtrl.value),
                    ),
                  ),
                ),
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _red,
                    boxShadow: [
                      BoxShadow(
                        color: _red.withOpacity(0.35),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      const SizedBox(height: 14),
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Analyzing Quality...',
                  style: TextStyle(
                    color: _textDark,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _redLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${(_progress * 100).toInt()}%',
                    style: const TextStyle(
                      color: _red,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: _progress,
                minHeight: 8,
                backgroundColor: _redLight,
                valueColor: const AlwaysStoppedAnimation(_red),
              ),
            ),
            const SizedBox(height: 16),
            ..._steps.asMap().entries.map((e) => _stepRow(e.key, e.value)),
          ],
        ),
      ),
    ],
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
            width: 24,
            height: 24,
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
              size: 13,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              color: done || running ? _textDark : _textMid,
              fontSize: 13,
              fontWeight: running ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _rejectedBody() => Column(
    children: [
      if (_image != null)
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
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
        decoration: BoxDecoration(
          color: _redLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _red.withOpacity(0.25)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(
                color: Colors.white,
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
              AppStrings.get("not_pomegranate"),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _textDark,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Please retake a clear photo showing the whole fruit.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _textMid, fontSize: 13),
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      _primaryActionButton('Retake Photo', Icons.camera_alt_rounded, _reset),
    ],
  );

  Widget _resultBody() {
    final r = _result!;
    final fg = QualityTheme.fgColor(r.quality);
    return ScaleTransition(
      scale: _resultAnim,
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: _border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_image != null)
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                    child: Image.file(
                      _image!,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.get("detected_result"),
                        style: const TextStyle(
                          color: _textDark,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'AI-powered pomegranate quality detection',
                        style: TextStyle(color: _textMid, fontSize: 11),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: fg.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: fg.withOpacity(0.2)),
                        ),
                        child: Row(
                          children: [
                            Text(
                              QualityTheme.emoji(r.quality),
                              style: const TextStyle(fontSize: 36),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    QualityTheme.label(r.quality),
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: _textDark,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: fg,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Confidence Score ${_prediction?.confidencePercent ?? r.confidencePercent}',
                                        style: TextStyle(
                                          color: fg,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
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
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (_prediction?.defectType != null) ...[
            _defectInfoCard(),
            const SizedBox(height: 14),
          ],
          if (r.weightGrams != null) ...[
            _weightInfoCard(r),
            const SizedBox(height: 14),
          ],

          _sectionTitleWidget(
            title: 'UTILIZATION RECOMMENDATION',
            subtitle: 'Generated using the configured recommendation rules',
          ),
          const SizedBox(height: 10),

          // ── Recommendation section (usage + explanation + waste + safety) ──
          _recommendationUsageCard(r),
          if (_hasValue(r.explanation)) ...[
            const SizedBox(height: 12),
            _recommendationSectionCard(
              icon: Icons.info_outline_rounded,
              color: _blue,
              backgroundColor: _blueLight,
              title: 'WHY THIS RECOMMENDATION?',
              text: r.explanation!,
            ),
          ],
          if (_hasValue(r.wasteUsage)) ...[
            const SizedBox(height: 12),
            _recommendationSectionCard(
              icon: Icons.recycling_rounded,
              color: _green,
              backgroundColor: _greenLight,
              title: 'WASTE UTILIZATION METHOD',
              text: r.wasteUsage!,
            ),
          ],
          if (_hasValue(r.safetyNote)) ...[
            const SizedBox(height: 12),
            _recommendationSectionCard(
              icon: Icons.health_and_safety_outlined,
              color: _orange,
              backgroundColor: _orangeLight,
              title: 'SAFETY NOTE',
              text: r.safetyNote!,
            ),
          ],

          const SizedBox(height: 14),
          _dateInfoCard(r),

          const SizedBox(height: 16),
          _primaryActionButton(
            AppStrings.get("scan_another"),
            Icons.camera_alt_rounded,
            _reset,
          ),
        ],
      ),
    );
  }

  bool _hasValue(String? value) => value != null && value.trim().isNotEmpty;

  Widget _recommendationUsageCard(GradingResult r) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
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
            child: const Icon(
              Icons.lightbulb_outline_rounded,
              color: _red,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.get("recommendation").toUpperCase(),
                  style: const TextStyle(
                    color: _textMid,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  r.recommendation,
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

  // shared card style for explanation / waste usage / safety note,
  // shown right below the recommended usage card — all populated the
  // moment the result screen appears (see _analyse()).
  Widget _recommendationSectionCard({
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
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
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
              color: backgroundColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
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
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
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
    );
  }

  // mirrors history_detail_screen.dart's FRUIT WEIGHT card, so the
  // same info shown in history is also shown right after grading.
  Widget _weightInfoCard(GradingResult r) {
    return _basicInfoCard(
      icon: Icons.scale_rounded,
      iconColor: _blue,
      iconBackground: _blueLight,
      label: 'FRUIT WEIGHT',
      child: Text(
        '${r.weightGrams} g',
        style: const TextStyle(
          color: _textDark,
          fontSize: 17,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  // mirrors history_detail_screen.dart's GRADED ON card.
  Widget _dateInfoCard(GradingResult r) {
    return _basicInfoCard(
      icon: Icons.calendar_today_rounded,
      iconColor: _textMid,
      iconBackground: const Color(0xFFF3F4F6),
      label: 'GRADED ON',
      child: Text(
        r.displayDate,
        style: const TextStyle(
          color: _textDark,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // generic icon + label + value card, same look as
  // history_detail_screen.dart's _basicInfoCard.
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
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
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

  // mirrors history_detail_screen.dart's _sectionTitle.
  Widget _sectionTitleWidget({
    required String title,
    required String subtitle,
  }) {
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

  Widget _defectInfoCard() {
    final defectType = _prediction!.defectType!;
    final severity = _prediction!.severityDisplay;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
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
            child: const Icon(
              Icons.warning_amber_rounded,
              color: _red,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.get("defect_detected").toUpperCase(),
                  style: const TextStyle(
                    color: _textMid,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  defectType[0].toUpperCase() + defectType.substring(1),
                  style: const TextStyle(
                    color: _textDark,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${AppStrings.get("severity")}: $severity',
                  style: const TextStyle(
                    color: _textMid,
                    fontSize: 13,
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

  Widget _recentHistoryCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  AppStrings.get("grading_history").toUpperCase(),
                  style: const TextStyle(
                    color: _textMid,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  final uid = _userId;
                  if (uid == null) {
                    setState(() => _error = 'Please log in to view history.');
                    return;
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => HistoryScreen(userId: uid),
                    ),
                  );
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text(
                      'View All',
                      style: TextStyle(
                        color: _red,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: _red, size: 18),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_recentResults.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  AppStrings.get("no_results"),
                  style: const TextStyle(color: _textMid, fontSize: 12),
                ),
              ),
            )
          else
            ..._recentResults.map((r) => _recentHistoryRow(r)),
        ],
      ),
    );
  }

  Widget _recentHistoryRow(GradingResult r) {
    final fg = QualityTheme.fgColor(r.quality);
    final bg = QualityTheme.bgColor(r.quality);
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => HistoryDetailScreen(result: r)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 56,
              height: 56,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: 1.0, // forces a perfect square crop
                  // url -> local file -> emoji fallback, so a
                  // null/failed image_url never leaves this blank.
                  child: GradingImage(
                    imageUrl: r.imageUrl,
                    imagePath: r.imagePath,
                    background: bg,
                    emoji: QualityTheme.emoji(r.quality),
                    emojiSize: 22,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: fg.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      QualityTheme.label(r.quality),
                      style: TextStyle(
                        color: fg,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    r.recommendation,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _textDark,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    r.displayDate,
                    style: const TextStyle(color: _textMid, fontSize: 10),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: _textMid, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _primaryActionButton(
    String label,
    IconData icon,
    VoidCallback onTap,
  ) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: BoxDecoration(
        color: _red,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _red.withOpacity(0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _errorBanner() => Padding(
    padding: const EdgeInsets.only(top: 10),
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
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
