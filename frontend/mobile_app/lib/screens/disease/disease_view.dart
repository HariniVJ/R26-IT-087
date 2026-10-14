import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show compute, debugPrint;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

import '../../common/brand_color.dart';
import '../../common/disease/disease_helpers.dart';
import '../../config/disease_ml_config.dart';
import '../../l10n/d_app_strings.dart';
import '../../models/Disease_prediction_result_model.dart';
import '../../services/disease/disease_service.dart'; // also exports NotPomegranateException
import '../../services/disease/history_service.dart';
import '../../services/ml/binary_validator_service.dart';
import '../../services/ml/fruit_segmentation_service.dart';
import '../../services/ml/image_utils.dart';
import '../../widgets/app_bottom_nav_bar.dart';
import '../../widgets/disease_widgets.dart';
import '../../widgets/severity_chip.dart';
import 'classification_result_view.dart';
import 'history_detail_view.dart';
import 'history_view.dart';

/// Runs in a background isolate (top-level function for compute()).
/// Returns the decoded photo + the preprocessed (resized model input) JPEG.
(img.Image, Uint8List) _decodeAndPreprocess(String path) {
  final image = ImageUtils.loadForInference(File(path));
  const size = DiseaseImageConfig.cnnInputSize;
  final pre = img.copyResize(
    image,
    width: size,
    height: size,
    interpolation: img.Interpolation.average,
  );
  return (image, Uint8List.fromList(img.encodeJpg(pre, quality: 92)));
}

/// Disease detection home.
///   Pick photo → quick check (fruit + pomegranate validator, ~1–2 s)
///     ✗ invalid → popup with reason + Retake (page resets)
///     ✓ valid   → preview (Original / Preprocessed) → Analyze → Result
/// All text follows the app language (Profile → Language) — see dt().
class DiseaseView extends StatefulWidget {
  const DiseaseView({super.key});

  @override
  State<DiseaseView> createState() => _DiseaseViewState();
}

enum _PickSource { none, camera, gallery }

class _DiseaseViewState extends State<DiseaseView>
    with TickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  _PickSource _activePick = _PickSource.none;

  late final AnimationController _scanLineController;
  late final AnimationController _fruitFloatController;

  late Future<List<PredictionResultModel>> _recentHistoryFuture;

  // ── Selected image ──
  File? _selectedImage;
  bool _isChecking = false; // quick validation right after upload
  bool _imageValid = false;
  bool _showProcessed = false;
  Uint8List? _processedBytes; // 224×224 model input preview

  // ── Analysis progress ──
  bool _isAnalyzing = false;
  int _currentStep = 0;
  Timer? _stepTimer;

  static const _analysisTimeout = Duration(seconds: 60);
  static const _stepDuration = Duration(milliseconds: 700);

  /// Step texts (keys for dt()).
  static const _stepKeys = [
    'step_quality',
    'step_find',
    'step_validate',
    'step_identify',
    'step_severity',
  ];

  /// Steps are always shown for at least this long (so the result does
  /// not jump in too fast).
  static final _minAnalysisTime =
      _stepDuration * _stepKeys.length + const Duration(milliseconds: 300);

  // Warm gold accent — only inside the scan card, for contrast with brand red.
  static const _gold = Color(0xFFE8A33D);

  // Header colours (change here only)
  static const _headerBg = BrandColor.primary;
  static const _headerFg = Colors.white;

  @override
  void initState() {
    super.initState();
    _scanLineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _fruitFloatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);

    _recentHistoryFuture = _loadRecentHistory();

    // Load the models in the background so the first check is faster.
    DiseaseService.warmUpModels().catchError((_) {});
  }

  @override
  void dispose() {
    _stepTimer?.cancel();
    _scanLineController.dispose();
    _fruitFloatController.dispose();
    super.dispose();
  }

  // ── Data ────────────────────────────────────────────────────────────
  Future<List<PredictionResultModel>> _loadRecentHistory() async {
    try {
      final all = await HistoryService.getFirebaseHistory();
      return all.take(3).toList();
    } catch (_) {
      return [];
    }
  }

  void _refreshHistory() {
    setState(() {
      _recentHistoryFuture = _loadRecentHistory();
    });
  }

  bool get _isBusy =>
      _activePick != _PickSource.none || _isAnalyzing || _isChecking;

  // ── Navigation ──────────────────────────────────────────────────────
  /// "<" arrow → back to the app home page.
  void _goBackHome() {
    final nav = Navigator.of(context);
    if (nav.canPop()) {
      nav.popUntil((route) => route.isFirst);
    } else {
      nav.pushNamedAndRemoveUntil('/', (route) => false);
    }
  }

  Future<void> _openHistory() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const HistoryView()),
    );
    if (mounted) _refreshHistory();
  }

  Future<void> _openHistoryItem(PredictionResultModel item) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => HistoryDetailView(result: item)),
    );
    if (mounted) _refreshHistory();
  }

  // ── Pick image ──────────────────────────────────────────────────────
  Future<void> _pickImage(ImageSource source, _PickSource which) async {
    if (_isBusy) return;
    setState(() => _activePick = which);
    File? picked;
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        imageQuality: 90,
        maxWidth: 1200,
        maxHeight: 1200,
      );
      debugPrint('📷 Picked: ${file?.path}');
      if (file == null || !mounted) return;
      picked = File(file.path);

      setState(() {
        _selectedImage = picked;
        _imageValid = false;
        _showProcessed = false;
        _processedBytes = null;
      });
    } catch (e, st) {
      debugPrint('❌ Pick failed: $e\n$st');
    } finally {
      if (mounted) setState(() => _activePick = _PickSource.none);
    }

    if (picked == null || !mounted) return;

    // Check straight away — invalid images are rejected before "Analyze".
    await _checkImage(picked);

    // Camera photo → save a copy to the phone gallery AFTER the check,
    // in the background, so it can never block or break the upload.
    if (source == ImageSource.camera) {
      unawaited(_saveToGallery(picked.path));
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

  void _clearImage() {
    setState(() {
      _selectedImage = null;
      _imageValid = false;
      _showProcessed = false;
      _processedBytes = null;
    });
  }

  // ── Quick check right after upload (same first steps as the pipeline) ─
  Future<void> _checkImage(File file) async {
    setState(() => _isChecking = true);
    debugPrint('🔎 Checking image…');

    try {
      // Decode + resize in the background so the screen does not freeze.
      final (image, preBytes) = await compute(_decodeAndPreprocess, file.path);
      if (!mounted || file != _selectedImage) return;

      // 1) Is there a fruit at all?
      final fruit = await FruitSegmentationService.instance.analyze(image);
      if (!mounted || file != _selectedImage) return;
      if (fruit == null) {
        await _reject(file, NotPomegranateReason.noFruitDetected, null);
        return;
      }

      // 2) Is it a pomegranate? (same validator input as the pipeline)
      final v = await BinaryValidatorService.instance.validateCrop(
        DiseaseModels.validatorLegacyMode ? image : fruit.crop,
      );
      if (!mounted || file != _selectedImage) return;
      if (!v.isPomegranate) {
        await _reject(
          file,
          NotPomegranateReason.notPomegranate,
          1 - v.pomegranateProbability,
        );
        return;
      }

      setState(() {
        _processedBytes = preBytes;
        _imageValid = true;
      });
    } catch (e, st) {
      // Quick check could not run (e.g. model loading problem).
      // Allow "Analyze" — the full pipeline will report any real error.
      debugPrint('❌ Image check failed: $e\n$st');
      if (mounted && file == _selectedImage) setState(() => _imageValid = true);
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  Future<void> _reject(
    File file,
    NotPomegranateReason reason,
    double? notPomConfidence,
  ) async {
    if (!mounted) return;
    setState(() => _isChecking = false);
    _clearImage();

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _InvalidImageDialog(
        message: dt(
          reason == NotPomegranateReason.noFruitDetected
              ? 'no_fruit_detected'
              : 'not_pomegranate',
        ),
      ),
    );
    // "Retake" → page is already reset, user picks a new photo.
  }

  // ── Analyze ─────────────────────────────────────────────────────────
  void _startStepTimer() {
    _currentStep = 0;
    _stepTimer?.cancel();
    _stepTimer = Timer.periodic(_stepDuration, (_) {
      if (!mounted) return;
      // Stay on the last step until the real result arrives.
      if (_currentStep < _stepKeys.length - 1) setState(() => _currentStep++);
    });
  }

  Future<void> _analyze() async {
    final file = _selectedImage;
    if (file == null || !_imageValid || _isBusy) return;

    setState(() => _isAnalyzing = true);
    _startStepTimer();

    // Let the button animation + first step show before the model runs.
    await Future.delayed(const Duration(milliseconds: 500));

    try {
      final minTime = Future.delayed(_minAnalysisTime);
      final result = await DiseaseService.predictDisease(
        file,
        language: LanguageController.instance.language,
      ).timeout(_analysisTimeout);
      await minTime;

      _stepTimer?.cancel();
      if (!mounted) return;
      setState(() => _currentStep = _stepKeys.length); // all steps done ✓
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ClassificationResultView(result: result),
        ),
      );

      // Back from the result → fresh screen
      if (mounted) {
        _clearImage();
        _refreshHistory();
      }
    } on NotPomegranateException catch (e) {
      // Normally caught by the quick check already; kept as a safety net.
      _stepTimer?.cancel();
      if (mounted) {
        setState(() => _isAnalyzing = false);
        await _reject(file, e.reason, e.confidence);
      }
    } on TimeoutException {
      if (mounted) {
        _showMessageDialog(
          icon: Icons.timer_off_rounded,
          title: dt('analysis_timeout_title'),
          message: dt('analysis_timeout_msg'),
        );
      }
    } catch (e) {
      if (mounted) {
        _showMessageDialog(
          icon: Icons.error_outline_rounded,
          title: dt('analysis_failed'),
          message: e.toString().replaceFirst('Exception: ', ''),
        );
      }
    } finally {
      _stepTimer?.cancel();
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  void _showMessageDialog({
    required IconData icon,
    required String title,
    required String message,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(icon, color: BrandColor.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(color: BrandColor.lightText, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              dt('ok'),
              style: const TextStyle(
                color: BrandColor.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Build ───────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    // Rebuild when the language changes (Profile → Language).
    return ListenableBuilder(
      listenable: LanguageController.instance,
      builder: (context, _) => Scaffold(
        backgroundColor: BrandColor.background,
        appBar: AppBar(
          backgroundColor: _headerBg,
          elevation: 0,
          centerTitle: false,
          leading: IconButton(
            tooltip: dt('home_label'),
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: _headerFg,
            ),
            onPressed: _goBackHome,
          ),
          title: Text(
            dt('disease_detection'),
            style: const TextStyle(
              color: _headerFg,
              fontWeight: FontWeight.w800,
              fontSize: 19,
            ),
          ),
          actions: [
            IconButton(
              tooltip: dt('detection_history'),
              icon: const Icon(
                Icons.receipt_long_rounded,
                color: _headerFg,
                size: 25,
              ),
              onPressed: _openHistory,
            ),
            const SizedBox(width: 4),
          ],
        ),
        bottomNavigationBar: const AppBottomNavBar(current: AppNavTab.home),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _scanFrameCard(),
                const SizedBox(height: 22),
                // Full width — same left/right edges as the card above and tiles below
                _actionButtons(),
                if (_selectedImage != null && _imageValid) ...[
                  const SizedBox(height: 12),
                  _AnalyzeButton(
                    loading: _isAnalyzing,
                    enabled: !_isBusy,
                    onPressed: _analyze,
                  ),
                ],
                if (_isAnalyzing) ...[
                  const SizedBox(height: 16),
                  _analysisStepsCard(),
                ],
                const SizedBox(height: 22),
                _infoStrip(),
                const SizedBox(height: 24),
                _recentHistorySection(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Scan card (viewfinder / selected image) ─────────────────────────
  Widget _scanFrameCard() {
    final hasImage = _selectedImage != null;

    String? statusText;
    Color statusDot = const Color(0xFF4ADE80);
    if (_isChecking) {
      statusText = dt('checking_image');
      statusDot = _gold;
    } else if (_isAnalyzing) {
      statusText = dt('analyzing_short');
      statusDot = _gold;
    } else if (!hasImage) {
      statusText = dt('ready_to_scan');
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: BrandColor.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: _gold.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _gold.withOpacity(0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.auto_awesome_rounded,
                      color: _gold,
                      size: 12,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      dt('scanner'),
                      style: TextStyle(
                        color: _gold.withOpacity(0.95),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.9,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (statusText != null) ...[
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: statusDot,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    statusText,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: BrandColor.darkText,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (hasImage && _imageValid) ...[
            const SizedBox(height: 16),
            _previewToggle(),
          ],
          SizedBox(height: hasImage ? 14 : 22),
          GestureDetector(
            // Empty frame → tap to upload from gallery
            onTap: (!hasImage && !_isBusy)
                ? () => _pickImage(ImageSource.gallery, _PickSource.gallery)
                : null,
            child: Container(
              width: double.infinity,
              height: hasImage ? 260 : 210,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [BrandColor.softPink, Colors.white],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(22),
              ),
              clipBehavior: Clip.antiAlias,
              child: LayoutBuilder(
                builder: (context, box) => Stack(
                  alignment: Alignment.center,
                  children: [
                    // Content: floating pomegranate OR the selected photo
                    if (hasImage)
                      Positioned.fill(child: _selectedPreview())
                    else
                      _floatingFruit(),

                    // "Tap to upload" hint on the empty frame
                    if (!hasImage)
                      Positioned(
                        bottom: 16,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.touch_app_rounded,
                              size: 14,
                              color: BrandColor.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              dt('tap_to_upload'),
                              style: const TextStyle(
                                color: BrandColor.primary,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Sweeping scan line (idle, checking, analyzing)
                    if (!hasImage || _isAnalyzing || _isChecking)
                      AnimatedBuilder(
                        animation: _scanLineController,
                        builder: (context, _) => Positioned(
                          top:
                              14 +
                              (_scanLineController.value *
                                  (box.maxHeight - 28)),
                          left: 14,
                          right: 14,
                          child: Container(
                            height: 2.4,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              gradient: LinearGradient(
                                colors: [
                                  _gold.withOpacity(0.0),
                                  _gold.withOpacity(0.9),
                                  _gold.withOpacity(0.0),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: _gold.withOpacity(0.6),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                    // "Checking image..." pill (photo stays visible)
                    if (_isChecking)
                      Positioned(
                        bottom: 14,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  color: BrandColor.primary,
                                  strokeWidth: 2,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                dt('checking_image'),
                                style: const TextStyle(
                                  color: BrandColor.darkText,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Corner brackets
                    const Positioned(
                      top: 12,
                      left: 12,
                      child: _CornerBracket(top: true, left: true),
                    ),
                    const Positioned(
                      top: 12,
                      right: 12,
                      child: _CornerBracket(top: true, left: false),
                    ),
                    const Positioned(
                      bottom: 12,
                      left: 12,
                      child: _CornerBracket(top: false, left: true),
                    ),
                    const Positioned(
                      bottom: 12,
                      right: 12,
                      child: _CornerBracket(top: false, left: false),
                    ),

                    // Remove-photo button
                    if (hasImage && !_isBusy)
                      Positioned(
                        top: 10,
                        right: 10,
                        child: GestureDetector(
                          onTap: _clearImage,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.45),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            hasImage ? dt('ready_to_analyze') : dt('scan_your_pomegranate'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: BrandColor.darkText,
              fontWeight: FontWeight.w900,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            hasImage ? dt('ready_hint') : dt('scan_hint'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: BrandColor.lightText,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _floatingFruit() {
    return AnimatedBuilder(
      animation: _fruitFloatController,
      builder: (context, _) => Transform.translate(
        offset: Offset(0, (_fruitFloatController.value - 0.5) * 10 - 8),
        child: Container(
          width: 104,
          height: 104,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(color: BrandColor.borderPink, width: 2),
            boxShadow: [
              BoxShadow(
                color: BrandColor.primary.withOpacity(0.22),
                blurRadius: 22,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: const Center(child: _PomegranateIcon(size: 66)),
        ),
      ),
    );
  }

  Widget _selectedPreview() {
    if (_showProcessed && _processedBytes != null) {
      // Preprocessed = the resized image the model receives
      return Image.memory(
        _processedBytes!,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        filterQuality: FilterQuality.medium,
      );
    }
    return Image.file(_selectedImage!, fit: BoxFit.cover);
  }

  // ── Original / Preprocessed switch ──
  Widget _previewToggle() {
    Widget tab(String label, bool processed) {
      final selected = _showProcessed == processed;
      return Expanded(
        child: GestureDetector(
          onTap: _isBusy
              ? null
              : () => setState(() => _showProcessed = processed),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 9),
            decoration: BoxDecoration(
              color: selected ? BrandColor.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: selected ? Colors.white : BrandColor.darkText,
                fontWeight: FontWeight.w800,
                fontSize: 12.5,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: BrandColor.softPink,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BrandColor.borderPink),
      ),
      child: Row(
        children: [tab(dt('original'), false), tab(dt('preprocessed'), true)],
      ),
    );
  }

  // ── Analysis steps (shown while analyzing) ──────────────────────────
  Widget _analysisStepsCard() {
    return SectionCard(
      icon: Icons.auto_awesome_rounded,
      title: dt('analyzing_your_image'),
      child: Column(
        children: [
          for (var i = 0; i < _stepKeys.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  SizedBox(width: 22, height: 22, child: _stepIcon(i)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      dt(_stepKeys[i]),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: i == _currentStep
                            ? FontWeight.w800
                            : FontWeight.w600,
                        color: i <= _currentStep
                            ? BrandColor.darkText
                            : BrandColor.lightText,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _stepIcon(int i) {
    if (i < _currentStep) {
      return const Icon(
        Icons.check_circle_rounded,
        color: DiseaseHelpers.healthyColor,
        size: 22,
      );
    }
    if (i == _currentStep) {
      return const Padding(
        padding: EdgeInsets.all(3),
        child: CircularProgressIndicator(
          strokeWidth: 2.2,
          color: BrandColor.primary,
        ),
      );
    }
    return const Icon(
      Icons.radio_button_unchecked_rounded,
      color: BrandColor.lightText,
      size: 22,
    );
  }

  // ── Capture / Gallery buttons (icon + text side by side) ────────────
  Widget _actionButtons() {
    final hasImage = _selectedImage != null;
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            icon: Icons.camera_alt_rounded,
            label: hasImage ? dt('retake') : dt('capture'),
            filled: !hasImage,
            loading: _activePick == _PickSource.camera,
            disabled: _isBusy && _activePick != _PickSource.camera,
            onTap: () => _pickImage(ImageSource.camera, _PickSource.camera),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionButton(
            icon: Icons.photo_library_rounded,
            label: dt('gallery'),
            filled: false,
            loading: _activePick == _PickSource.gallery,
            disabled: _isBusy && _activePick != _PickSource.gallery,
            onTap: () => _pickImage(ImageSource.gallery, _PickSource.gallery),
          ),
        ),
      ],
    );
  }

  // ── Info strip ──────────────────────────────────────────────────────
  Widget _infoStrip() {
    return Row(
      children: [
        Expanded(
          child: _InfoTile(
            icon: Icons.biotech_rounded,
            title: dt('five_classes'),
            subtitle: dt('disease_types'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _InfoTile(
            icon: Icons.speed_rounded,
            title: dt('severity_label'),
            subtitle: dt('auto_analysis'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _InfoTile(
            icon: Icons.medication_liquid_rounded,
            title: dt('treatment'),
            subtitle: dt('care_guide'),
          ),
        ),
      ],
    );
  }

  // ── Recent detections ───────────────────────────────────────────────
  Widget _recentHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                dt('recent_detections'),
                style: const TextStyle(
                  color: BrandColor.darkText,
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
              ),
            ),
            GestureDetector(
              onTap: _openHistory,
              child: Row(
                children: [
                  Text(
                    dt('view_all'),
                    style: const TextStyle(
                      color: BrandColor.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 12.5,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 11,
                    color: BrandColor.primary,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        FutureBuilder<List<PredictionResultModel>>(
          future: _recentHistoryFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SmallLoader();
            }
            final items = snapshot.data ?? [];
            if (items.isEmpty) {
              return AppCard(
                padding: EdgeInsets.zero,
                child: EmptyState(
                  icon: Icons.receipt_long_rounded,
                  text: dt('no_detections'),
                ),
              );
            }
            return Column(
              children: items
                  .map(
                    (item) => HistoryPreviewCard(
                      item: item,
                      onTap: () => _openHistoryItem(item),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
//  Small widgets used only on this screen (+ HistoryPreviewCard, public so
//  history_view.dart can reuse it)
// ═══════════════════════════════════════════════════════════════════════

/// Simple error popup for an invalid photo: icon + title + message + Retake.
class _InvalidImageDialog extends StatelessWidget {
  final String message;

  const _InvalidImageDialog({required this.message});

  static const _red = Color(0xFFDC2626);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 26, 22, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _red.withOpacity(0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: _red,
                size: 34,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              dt('invalid_image'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: BrandColor.darkText,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: BrandColor.lightText,
                fontSize: 13.5,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.refresh_rounded, size: 20),
                label: Text(
                  dt('retake'),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: BrandColor.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnalyzeButton extends StatefulWidget {
  final bool loading;
  final bool enabled;
  final VoidCallback onPressed;

  const _AnalyzeButton({
    required this.loading,
    required this.enabled,
    required this.onPressed,
  });

  @override
  State<_AnalyzeButton> createState() => _AnalyzeButtonState();
}

class _AnalyzeButtonState extends State<_AnalyzeButton>
    with TickerProviderStateMixin {
  late final AnimationController _pulse;
  late final AnimationController _spin;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _spin = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    if (widget.loading) _spin.repeat();
  }

  @override
  void didUpdateWidget(covariant _AnalyzeButton old) {
    super.didUpdateWidget(old);
    if (widget.loading && !_spin.isAnimating) {
      _spin.repeat();
    } else if (!widget.loading && _spin.isAnimating) {
      _spin.stop();
      _spin.reset();
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    _spin.dispose();
    super.dispose();
  }

  void _tap() {
    if (!widget.enabled || widget.loading) return;
    HapticFeedback.mediumImpact();
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    final active = widget.enabled || widget.loading;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: _tap,
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 110),
        child: AnimatedBuilder(
          animation: _pulse,
          builder: (context, child) {
            final glow = widget.loading ? 0.45 : 0.20 + _pulse.value * 0.20;
            return Container(
              height: 52,
              decoration: BoxDecoration(
                color: active
                    ? BrandColor.primary
                    : BrandColor.primary.withOpacity(0.4),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: BrandColor.primary.withOpacity(glow),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: child,
            );
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              widget.loading
                  ? RotationTransition(
                      turns: _spin,
                      child: const Icon(
                        Icons.autorenew_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    )
                  : ScaleTransition(
                      scale: Tween(begin: 0.9, end: 1.1).animate(_pulse),
                      child: const Icon(
                        Icons.biotech_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  widget.loading ? dt('analyzing_short') : dt('analyze_image'),
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One row in "Recent Detections".
/// Uses the same badges as the History page (SeverityChip + ConfidenceBadge).
class HistoryPreviewCard extends StatelessWidget {
  final PredictionResultModel item;
  final VoidCallback onTap;

  const HistoryPreviewCard({
    super.key,
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AppCard(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            DiseaseImage(
              path: item.imagePath,
              width: 54,
              height: 54,
              radius: 12,
              iconSize: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    LanguageController.instance.disease(item.diseaseName),
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: BrandColor.darkText,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      // Same badges as the History page
                      SeverityChip(result: item),
                      ConfidenceBadge(result: item),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dRelativeDate(item.detectedAt),
                    style: const TextStyle(
                      color: BrandColor.lightText,
                      fontSize: 10.5,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 13,
              color: BrandColor.lightText,
            ),
          ],
        ),
      ),
    );
  }
}

/// Hand-drawn pomegranate (there is no pomegranate emoji).
class _PomegranateIcon extends StatelessWidget {
  final double size;
  const _PomegranateIcon({required this.size});

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.square(size), painter: _PomegranatePainter());
}

class _PomegranatePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width;
    final center = Offset(w * 0.5, w * 0.58);
    final r = w * 0.38;

    // Crown (calyx) — drawn first so the fruit overlaps its base
    final crown = Path()
      ..moveTo(w * 0.36, w * 0.26)
      ..lineTo(w * 0.33, w * 0.08)
      ..lineTo(w * 0.42, w * 0.17)
      ..lineTo(w * 0.50, w * 0.05)
      ..lineTo(w * 0.58, w * 0.17)
      ..lineTo(w * 0.67, w * 0.08)
      ..lineTo(w * 0.64, w * 0.26)
      ..close();
    canvas.drawPath(crown, Paint()..color = const Color(0xFF8E1230));

    // Fruit body with a soft radial gradient
    final body = Paint()
      ..shader = const RadialGradient(
        center: Alignment(-0.35, -0.4),
        radius: 0.95,
        colors: [Color(0xFFF0506A), Color(0xFFC8193F), Color(0xFF8E1230)],
        stops: [0.0, 0.55, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: r));
    canvas.drawCircle(center, r, body);

    // Seeds hint
    final seed = Paint()..color = Colors.white.withOpacity(0.18);
    for (var i = 0; i < 6; i++) {
      final a = i * math.pi / 3 + 0.4;
      canvas.drawCircle(
        center + Offset(math.cos(a) * r * 0.45, math.sin(a) * r * 0.45),
        w * 0.025,
        seed,
      );
    }

    // Shine
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.37, w * 0.46),
        width: w * 0.14,
        height: w * 0.22,
      ),
      Paint()..color = Colors.white.withOpacity(0.45),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CornerBracket extends StatelessWidget {
  final bool top;
  final bool left;

  const _CornerBracket({required this.top, required this.left});

  @override
  Widget build(BuildContext context) {
    const side = BorderSide(color: BrandColor.primary, width: 3);
    const r = Radius.circular(8);
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: top && left ? r : Radius.zero,
          topRight: top && !left ? r : Radius.zero,
          bottomLeft: !top && left ? r : Radius.zero,
          bottomRight: !top && !left ? r : Radius.zero,
        ),
        border: Border(
          top: top ? side : BorderSide.none,
          bottom: top ? BorderSide.none : side,
          left: left ? side : BorderSide.none,
          right: left ? BorderSide.none : side,
        ),
      ),
    );
  }
}

/// Compact button: icon and text side by side.
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool filled;
  final bool loading;
  final bool disabled;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.filled,
    required this.loading,
    required this.disabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fg = filled ? Colors.white : BrandColor.primary;
    return Opacity(
      opacity: disabled ? 0.45 : 1.0,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: (!loading && !disabled) ? onTap : null,
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: filled ? BrandColor.primary : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: filled ? Colors.transparent : BrandColor.borderPink,
            ),
            boxShadow: filled
                ? [
                    BoxShadow(
                      color: BrandColor.primary.withOpacity(0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: loading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: fg),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, color: fg, size: 20),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          label,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: fg,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
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
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _InfoTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      radius: 16,
      child: Column(
        children: [
          Icon(icon, color: BrandColor.primary, size: 19),
          const SizedBox(height: 6),
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 11,
              color: BrandColor.darkText,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 8.8, color: BrandColor.lightText),
          ),
        ],
      ),
    );
  }
}
