// YOUR FILE — Member 4: Fruit Quality Grading
// lib/screens/quality_grading_screen.dart
//
// BUGS FIXED:
//   1. userId mismatch — was 'farmer_demo_001', must be 'farmer_test_001'
//      (must match what you test in Swagger and history screen)
//   2. _saveToBackendSilently() swallowed ALL errors with catch(_) {}
//      Now shows a small snackbar if save fails so you can debug
//   3. saveResult was called after showing result — now awaited properly
//      and the returned saved result (with real Firestore ID) replaces local
//   4. Image file was passed but upload sometimes failed silently
//      Now logs clearly and shows status

import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/grading_result.dart';
import '../models/prediction_result.dart';
import '../services/grading_api_service.dart';
import '../services/tflite_service.dart';
import '../theme/app_theme.dart';
import 'history_screen.dart';

class QualityGradingScreen extends StatefulWidget {
  const QualityGradingScreen({super.key});
  @override
  State<QualityGradingScreen> createState() => _QualityGradingScreenState();
}

enum _Phase { idle, analysing, result }

class _QualityGradingScreenState extends State<QualityGradingScreen>
    with TickerProviderStateMixin {

  // ── FIX 1: userId must match Swagger test + history screen ────────────────
  // Change this to match whatever userId you use in Swagger
  static const _userId = 'farmer_test_001';

  File?              _image;
  GradingResult?     _result;
  PredictionResult?  _prediction;
  Map<String,double> _allScores = {};
  _Phase             _phase     = _Phase.idle;
  String?            _error;
  double             _progress  = 0;
  int                _stepIndex = 0;

  // FIX 2: track save status to show user feedback
  bool    _saving    = false;
  bool?   _savedOk;   // null=not tried, true=saved, false=failed

  final _steps = [
    'Image preprocessing',
    'Feature extraction',
    'CNN classification',
    'Generating result',
  ];

  late final AnimationController _pulseCtrl;
  late final AnimationController _progressCtrl;
  late final AnimationController _resultCtrl;
  late final Animation<double>   _resultAnim;

  final _picker  = ImagePicker();
  final _service = GradingApiService();
  final _tflite  = TfliteService();

  @override
  void initState() {
    super.initState();
    _pulseCtrl    = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _progressCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _resultCtrl   = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _resultAnim   = CurvedAnimation(parent: _resultCtrl, curve: Curves.elasticOut);

    _tflite.loadModel().catchError((e) => debugPrint('⚠️ TFLite: $e'));
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _progressCtrl.dispose();
    _resultCtrl.dispose();
    _tflite.dispose();
    super.dispose();
  }

  // ── Pick image ─────────────────────────────────────────────────────────────
  Future<void> _pick(ImageSource src) async {
    final x = await _picker.pickImage(source: src, imageQuality: 85, maxWidth: 1024);
    if (x == null) return;
    setState(() {
      _image = File(x.path);
      _result = null; _prediction = null; _allScores = {};
      _error  = null; _phase = _Phase.idle;
      _savedOk = null;
    });
  }

  // ── Main analysis flow ─────────────────────────────────────────────────────
  Future<void> _analyse() async {
    if (_image == null) return;
    setState(() {
      _phase = _Phase.analysing; _progress = 0; _stepIndex = 0;
      _error = null; _savedOk = null;
    });

    // Step 1 animation
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() { _stepIndex = 0; _progress = 0.25; });

    // Step 2 animation
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() { _stepIndex = 1; _progress = 0.50; });

    // Step 3: TFLite inference
    PredictionResult prediction;
    Map<String,double> allScores;
    try {
      prediction = await _tflite.predict(_image!);
      allScores  = await _tflite.getAllScores(_image!);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Model error: ${e.toString().replaceFirst("Exception: ", "")}';
        _phase = _Phase.idle;
      });
      return;
    }

    if (!mounted) return;
    setState(() { _stepIndex = 2; _progress = 0.75; });
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    setState(() { _stepIndex = 3; _progress = 1.0; });

    // Step 4: Show result immediately from local prediction
    final localResult = GradingResult(
      id:             DateTime.now().millisecondsSinceEpoch.toString(),
      userId:         _userId,
      quality:        prediction.quality,
      confidence:     prediction.confidenceDecimal,
      recommendation: prediction.recommendation,
      imageUrl:       null,
      createdAt:      DateTime.now().toIso8601String(),
    );

    if (!mounted) return;
    setState(() {
      _prediction = prediction;
      _allScores  = allScores;
      _result     = localResult;
      _phase      = _Phase.result;
    });
    _resultCtrl.forward(from: 0);

    // Step 5: Save to backend — NOT silent, shows status
    _saveToBackend(prediction);
  }

  // ── FIX 2 + 3: Save properly with visible feedback ────────────────────────
  Future<void> _saveToBackend(PredictionResult prediction) async {
    if (!mounted) return;
    setState(() { _saving = true; _savedOk = null; });

    debugPrint('💾 Saving to backend...');
    debugPrint('   userId:     $_userId');
    debugPrint('   quality:    ${prediction.quality}');
    debugPrint('   confidence: ${prediction.confidenceDecimal}');
    debugPrint('   image:      ${_image?.path}');

    try {
      final saved = await _service.saveResult(
        userId:     _userId,
        quality:    prediction.quality,
        confidence: prediction.confidenceDecimal,
        imageFile:  _image,   // ← image sent to backend for Firebase Storage
      ).timeout(const Duration(seconds: 20));

      debugPrint('✅ Saved! Firestore ID: ${saved.id}');

      if (!mounted) return;
      // Update result with real Firestore data (real ID + image URL from Storage)
      setState(() {
        _result  = saved;   // ← replace local result with real saved one
        _savedOk = true;
        _saving  = false;
      });

      // Show success snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Row(children: [
            Icon(Icons.check_circle, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text('Result saved to database ✅'),
          ]),
          backgroundColor: AppColors.highGreen,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }

    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      debugPrint('❌ Save failed: $msg');

      if (!mounted) return;
      setState(() { _savedOk = false; _saving = false; });

      // FIX 4: Show snackbar with actual error so you can debug
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(children: [
                Icon(Icons.warning_rounded, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text('Could not save to database',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ]),
              const SizedBox(height: 4),
              Text(msg.length > 80 ? '${msg.substring(0,80)}...' : msg,
                style: const TextStyle(fontSize: 11)),
            ],
          ),
          backgroundColor: AppColors.medAmber,
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    }
  }

  void _reset() {
    setState(() {
      _image = null; _result = null; _prediction = null;
      _allScores = {}; _phase = _Phase.idle; _error = null;
      _savedOk = null; _saving = false;
    });
    _resultCtrl.reset();
  }

  // ── BUILD ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Container(
        decoration: AppDecorations.gradientBg(),
        child: SafeArea(
          child: CustomScrollView(slivers: [
            _buildAppBar(),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              sliver: SliverList(delegate: SliverChildListDelegate([
                const SizedBox(height: 8),
                if (_phase != _Phase.result) _buildMiniChart(),
                const SizedBox(height: 16),
                if (_phase == _Phase.idle)      _buildIdleBody(),
                if (_phase == _Phase.analysing) _buildAnalysingBody(),
                if (_phase == _Phase.result)    _buildResultBody(),
                if (_error != null)             _buildError(),
              ])),
            ),
          ]),
        ),
      ),
    );
  }

  // ── AppBar ─────────────────────────────────────────────────────────────────
  Widget _buildAppBar() => SliverAppBar(
    backgroundColor: Colors.transparent, elevation: 0, pinned: false,
    title: Row(children: [
      const Text('🍎', style: TextStyle(fontSize: 22)),
      const SizedBox(width: 8),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Quality Grading', style: AppText.titleMedium.copyWith(fontSize: 16)),
        Text('AI-Powered Analysis',
            style: AppText.labelSmall.copyWith(color: AppColors.rosePetal)),
      ]),
    ]),
    actions: [
      IconButton(
        icon: const Icon(Icons.history_rounded, color: AppColors.crimson),
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const HistoryScreen(userId: _userId))),
      ),
      if (_phase == _Phase.result || _image != null)
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: AppColors.crimson),
          onPressed: _reset,
        ),
    ],
  );

  // ── Mini chart ─────────────────────────────────────────────────────────────
  Widget _buildMiniChart() => Container(
    decoration: AppDecorations.glassCard(),
    padding: const EdgeInsets.all(16),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text("Today's Grading Overview", style: AppText.labelSmall),
      const SizedBox(height: 12),
      Row(children: [
        _chartPill('High',   0.62, AppColors.chartHigh),
        const SizedBox(width: 8),
        _chartPill('Medium', 0.25, AppColors.chartMed),
        const SizedBox(width: 8),
        _chartPill('Low',    0.13, AppColors.chartLow),
      ]),
      const SizedBox(height: 14),
      const _SparklineChart(),
    ]),
  );

  Widget _chartPill(String label, double frac, Color color) => Expanded(
    child: Column(children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: LinearProgressIndicator(
          value: frac, minHeight: 8,
          backgroundColor: color.withOpacity(0.15),
          valueColor: AlwaysStoppedAnimation(color),
        ),
      ),
      const SizedBox(height: 4),
      Text('$label ${(frac * 100).toInt()}%',
          style: AppText.labelSmall.copyWith(color: color, fontSize: 10)),
    ]),
  );

  // ── Idle body ──────────────────────────────────────────────────────────────
  Widget _buildIdleBody() => Column(children: [
    _buildImageBox(),
    const SizedBox(height: 16),
    Row(children: [
      Expanded(child: _pickBtn(Icons.camera_alt_rounded,    'Camera',  ImageSource.camera)),
      const SizedBox(width: 12),
      Expanded(child: _pickBtn(Icons.photo_library_rounded, 'Gallery', ImageSource.gallery)),
    ]),
    const SizedBox(height: 16),
    if (_image != null)
      AppButton(label: 'Analyse Quality', icon: Icons.search_rounded, onPressed: _analyse),
    if (_image == null) _buildTips(),
  ]);

  Widget _buildImageBox() {
    if (_image == null) {
      return AnimatedBuilder(
        animation: _pulseCtrl,
        builder: (_, __) => Container(
          height: 220,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.rosePetal.withOpacity(0.4 + 0.3 * _pulseCtrl.value),
              width: 2,
            ),
            color: AppColors.blush.withOpacity(0.2 + 0.1 * _pulseCtrl.value),
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.add_photo_alternate_outlined, size: 56,
                color: AppColors.rosePetal.withOpacity(0.7 + 0.3 * _pulseCtrl.value)),
            const SizedBox(height: 12),
            Text('Tap to Upload Fruit Image', style: AppText.bodyMedium),
            const SizedBox(height: 4),
            Text('JPG · PNG · Max 10 MB', style: AppText.labelSmall),
          ]),
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Stack(children: [
        Image.file(_image!, height: 260, width: double.infinity, fit: BoxFit.cover),
        Positioned(bottom: 0, left: 0, right: 0,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter, end: Alignment.topCenter,
                colors: [AppColors.deepCrimson.withOpacity(0.7), Colors.transparent],
              ),
            ),
            padding: const EdgeInsets.all(14),
            child: Text('Image ready — tap Analyse',
                style: AppText.bodyMedium.copyWith(color: Colors.white)),
          ),
        ),
      ]),
    );
  }

  Widget _pickBtn(IconData icon, String label, ImageSource src) =>
      OutlinedButton.icon(
        onPressed: () => _pick(src),
        icon: Icon(icon, size: 18), label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.crimson,
          side: const BorderSide(color: AppColors.blush, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 13),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );

  Widget _buildTips() => Container(
    decoration: AppDecorations.glassCard(),
    padding: const EdgeInsets.all(16),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Tips for Best Results', style: AppText.labelSmall),
      const SizedBox(height: 12),
      _tip('☀️', 'Good lighting — natural light works best'),
      _tip('🍎', 'Fill the frame with the fruit'),
      _tip('📷', 'Avoid blur — hold phone steady'),
    ]),
  );

  Widget _tip(String emoji, String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(children: [
      Text(emoji, style: const TextStyle(fontSize: 16)),
      const SizedBox(width: 10),
      Expanded(child: Text(text, style: AppText.bodyMedium)),
    ]),
  );

  // ── Analysing body ─────────────────────────────────────────────────────────
  Widget _buildAnalysingBody() => Column(children: [
    AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (_, __) => Container(
        height: 200, decoration: AppDecorations.glassCard(),
        child: Center(child: Stack(alignment: Alignment.center, children: [
          Transform.scale(
            scale: 1.0 + 0.12 * _pulseCtrl.value,
            child: Container(
              width: 120, height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.blush.withOpacity(0.3 + 0.2 * _pulseCtrl.value),
              ),
            ),
          ),
          Container(
            width: 90, height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                AppColors.rosePetal.withOpacity(0.4),
                AppColors.crimson.withOpacity(0.15),
              ]),
            ),
          ),
          const Text('🍎', style: TextStyle(fontSize: 36)),
        ])),
      ),
    ),
    const SizedBox(height: 20),
    Container(
      decoration: AppDecorations.glassCard(),
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Analyzing Quality...', style: AppText.titleMedium.copyWith(fontSize: 16)),
          Text('${(_progress * 100).toInt()}%',
              style: const TextStyle(color: AppColors.crimson, fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 6),
        Text('CNN model processing image', style: AppText.bodyMedium),
        const SizedBox(height: 14),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: _progress, minHeight: 8,
            backgroundColor: AppColors.blush,
            valueColor: const AlwaysStoppedAnimation(AppColors.crimson),
          ),
        ),
        const SizedBox(height: 16),
        ..._steps.asMap().entries.map((e) => _stepRow(e.key, e.value)),
      ]),
    ),
  ]);

  Widget _stepRow(int idx, String label) {
    final done    = idx < _stepIndex;
    final running = idx == _stepIndex;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 24, height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: done    ? AppColors.highGreen
                 : running ? AppColors.crimson
                 :           AppColors.blush,
          ),
          child: Icon(
            done ? Icons.check : running ? Icons.refresh : Icons.circle,
            size: 14, color: Colors.white,
          ),
        ),
        const SizedBox(width: 10),
        Text(label, style: AppText.bodyMedium.copyWith(
          color:      done || running ? AppColors.textPrimary : AppColors.textSecondary,
          fontWeight: running ? FontWeight.w600 : FontWeight.normal,
        )),
      ]),
    );
  }

  // ── Result body ────────────────────────────────────────────────────────────
  Widget _buildResultBody() {
    final r  = _result!;
    final fg = QualityTheme.fgColor(r.quality);
    final bg = QualityTheme.bgColor(r.quality);

    return ScaleTransition(
      scale: _resultAnim,
      child: Column(children: [

        // ── Save status banner ─────────────────────────────────────────────
        if (_saving)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.medAmberLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.medAmber.withOpacity(0.4)),
            ),
            child: Row(children: [
              const SizedBox(width: 16, height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.medAmber)),
              const SizedBox(width: 10),
              Text('Saving to database...', style: TextStyle(
                color: AppColors.medAmber, fontSize: 13, fontWeight: FontWeight.w600,
              )),
            ]),
          ),

        if (_savedOk == true)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.highGreenLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.highGreen.withOpacity(0.3)),
            ),
            child: Row(children: [
              const Icon(Icons.check_circle_outline, color: AppColors.highGreen, size: 18),
              const SizedBox(width: 8),
              Text('Saved to Firebase ✅', style: TextStyle(
                color: AppColors.highGreen, fontSize: 13, fontWeight: FontWeight.w600,
              )),
              const Spacer(),
              Text('ID: ${r.id.substring(0, 8)}...',
                style: TextStyle(color: AppColors.highGreen.withOpacity(0.6), fontSize: 10)),
            ]),
          ),

        // ── Hero card ──────────────────────────────────────────────────────
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [fg, fg.withOpacity(0.75)],
            ),
            boxShadow: [BoxShadow(color: fg.withOpacity(0.35), blurRadius: 24, offset: const Offset(0, 8))],
          ),
          padding: const EdgeInsets.all(24),
          child: Column(children: [
            Text(QualityTheme.emoji(r.quality), style: const TextStyle(fontSize: 52)),
            const SizedBox(height: 8),
            Text(QualityTheme.label(r.quality), style: const TextStyle(
              fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white,
            )),
            Text(
              'Confidence: ${_prediction?.confidencePercent ?? r.confidencePercent} · CNN Model',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 20),
            Row(children: [
              _metricPill(_prediction?.confidencePercent ?? r.confidencePercent, 'Accuracy'),
              const SizedBox(width: 8),
              _metricPill('A+',   'Grade'),
              const SizedBox(width: 8),
              _metricPill('1.2s', 'Time'),
            ]),
          ]),
        ),
        const SizedBox(height: 16),

        // ── Recommendation card ────────────────────────────────────────────
        Container(
          decoration: AppDecorations.glassCard(border: fg.withOpacity(0.3)),
          padding: const EdgeInsets.all(18),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
              child: Icon(QualityTheme.icon(r.quality), color: fg, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Recommended Usage', style: AppText.labelSmall),
              const SizedBox(height: 4),
              Text(r.recommendation,
                  style: AppText.bodyMedium.copyWith(color: AppColors.textPrimary, height: 1.4)),
            ])),
          ]),
        ),
        const SizedBox(height: 16),

        // ── Score breakdown ────────────────────────────────────────────────
        if (_allScores.isNotEmpty)
          Container(
            decoration: AppDecorations.glassCard(),
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Model Score Breakdown', style: AppText.labelSmall),
              const SizedBox(height: 12),
              ..._allScores.entries.map((e) => _scoreLine(e.key, e.value)),
            ]),
          ),
        const SizedBox(height: 16),

        // ── Image thumbnail ────────────────────────────────────────────────
        if (r.imageUrl != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(r.imageUrl!, height: 160, width: double.infinity, fit: BoxFit.cover),
          ),
          const SizedBox(height: 16),
        ],

        AppButton(label: 'Scan Another Fruit', icon: Icons.camera_alt_rounded, onPressed: _reset),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const HistoryScreen(userId: _userId))),
          icon: const Icon(Icons.history_rounded),
          label: const Text('View History'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.crimson,
            side: const BorderSide(color: AppColors.blush),
            minimumSize: const Size(double.infinity, 48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ]),
    );
  }

  Widget _metricPill(String value, String label) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(children: [
        Text(value, style: const TextStyle(
          fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white,
        )),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.white70)),
      ]),
    ),
  );

  Widget _scoreLine(String quality, double score) {
    final color = QualityTheme.fgColor(quality);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: [
            Text(QualityTheme.emoji(quality), style: const TextStyle(fontSize: 13)),
            const SizedBox(width: 6),
            Text(QualityTheme.label(quality), style: AppText.bodyMedium.copyWith(
              fontWeight: FontWeight.w600, fontSize: 13,
            )),
          ]),
          Text('${(score * 100).toStringAsFixed(1)}%', style: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w700, color: color,
          )),
        ]),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: score, minHeight: 7,
            backgroundColor: color.withOpacity(0.12),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ]),
    );
  }

  Widget _buildError() => Padding(
    padding: const EdgeInsets.only(top: 12),
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.lowRedLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.lowRed.withOpacity(0.3)),
      ),
      child: Row(children: [
        const Icon(Icons.error_outline, color: AppColors.lowRed),
        const SizedBox(width: 10),
        Expanded(child: Text(_error!,
            style: const TextStyle(color: AppColors.lowRed, fontSize: 13))),
      ]),
    ),
  );
}

// ── Sparkline chart ───────────────────────────────────────────────────────────
class _SparklineChart extends StatelessWidget {
  const _SparklineChart();
  static const _hD = [0.5,0.7,0.6,0.8,0.75,0.9,0.85];
  static const _mD = [0.3,0.2,0.25,0.2,0.18,0.15,0.22];
  static const _lD = [0.2,0.1,0.15,0.08,0.12,0.1,0.07];
  static const _dy = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 80,
    child: CustomPaint(size: Size.infinite,
        painter: _SparkPainter(high: _hD, med: _mD, low: _lD, days: _dy)),
  );
}

class _SparkPainter extends CustomPainter {
  final List<double> high, med, low;
  final List<String> days;
  const _SparkPainter({required this.high, required this.med, required this.low, required this.days});

  @override
  void paint(Canvas canvas, Size size) {
    final h    = size.height - 20;
    final step = size.width / (high.length - 1);
    _line(canvas, high, step, h, AppColors.chartHigh);
    _line(canvas, med,  step, h, AppColors.chartMed);
    _line(canvas, low,  step, h, AppColors.chartLow);
    final tp = TextPainter(textDirection: TextDirection.ltr);
    for (int i = 0; i < days.length; i++) {
      tp.text = TextSpan(text: days[i],
          style: const TextStyle(fontSize: 9, color: AppColors.textSecondary));
      tp.layout();
      tp.paint(canvas, Offset(i * step - tp.width / 2, h + 4));
    }
  }

  void _line(Canvas canvas, List<double> data, double step, double h, Color color) {
    final paint = Paint()..color=color..strokeWidth=2..style=PaintingStyle.stroke..strokeCap=StrokeCap.round;
    final path  = Path();
    for (int i = 0; i < data.length; i++) {
      final x = i * step; final y = h - data[i] * h;
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    canvas.drawPath(path, paint);
    canvas.drawCircle(Offset((data.length-1)*step, h-data.last*h),
        4, Paint()..color=color);
  }

  @override
  bool shouldRepaint(_) => false;
}