import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

import '../../common/brand_color.dart';
import '../../services/disease/disease_service.dart';
import '../../services/ml/binary_validator_service.dart';
import '../../services/ml/model_inference_service.dart';
import 'classification_result_view.dart';
import 'disease_view.dart';

class ImagePreviewView extends StatefulWidget {
  final File imageFile;

  const ImagePreviewView({super.key, required this.imageFile});

  @override
  State<ImagePreviewView> createState() => _ImagePreviewViewState();
}

enum _PreviewMode { original, preprocessed }

class _ImagePreviewViewState extends State<ImagePreviewView> {
  bool loading = false;

  _PreviewMode _mode = _PreviewMode.original;

  Uint8List? _preprocessedBytes;

  bool _generatingPreview = false;

  String? _previewError;

  // ============================================================
  // ANALYZE IMAGE
  // ============================================================

  Future<void> analyze() async {
    if (loading) return;

    setState(() {
      loading = true;
    });

    try {
      debugPrint('========================================');
      debugPrint('🚀 ANALYZE IMAGE STARTED');
      debugPrint('Image: ${widget.imageFile.path}');
      debugPrint('========================================');

      // STEP 1 — POMEGRANATE VALIDATION

      debugPrint('🔍 STEP 1: Binary validator started');

      final validator = BinaryValidatorService.instance;

      final validationResult = await validator
          .validate(widget.imageFile)
          .timeout(
            const Duration(seconds: 20),
            onTimeout: () {
              throw Exception(
                'Pomegranate validation took too long. Please try again.',
              );
            },
          );

      debugPrint('✅ STEP 1 COMPLETE');
      debugPrint('Pomegranate: ${validationResult.isPomegranate}');

      if (!validationResult.isPomegranate) {
        if (!mounted) return;

        setState(() {
          loading = false;
        });

        _showRejectionDialog('Please upload a valid pomegranate image.');

        return;
      }

      // STEP 2 — DISEASE CLASSIFICATION

      debugPrint('🧠 STEP 2: Disease classification started');

      final result = await DiseaseService.predictDisease(widget.imageFile)
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception(
                'Disease analysis took too long. Please try again.',
              );
            },
          );

      debugPrint('✅ STEP 2 COMPLETE');
      debugPrint('Disease: ${result.diseaseName}');
      debugPrint('Confidence: ${result.confidence}');

      if (!mounted) return;

      setState(() {
        loading = false;
      });

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ClassificationResultView(result: result),
        ),
      );
    } catch (e, stackTrace) {
      debugPrint('========================================');
      debugPrint('❌ ANALYZE ERROR');
      debugPrint(e.toString());
      debugPrint(stackTrace.toString());
      debugPrint('========================================');

      if (!mounted) return;

      setState(() {
        loading = false;
      });

      _showErrorDialog(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  // ============================================================
  // IMAGE REJECTED DIALOG
  // ============================================================

  void _showRejectionDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          icon: const Icon(
            Icons.warning_amber_rounded,
            color: BrandColor.primary,
            size: 45,
          ),
          title: const Text(
            'Image Rejected',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: BrandColor.darkText,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: BrandColor.lightText,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();

                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const DiseaseView()),
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: BrandColor.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Try Another Image',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // ERROR DIALOG
  // ============================================================

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          icon: const Icon(
            Icons.error_outline_rounded,
            color: BrandColor.primary,
            size: 45,
          ),
          title: const Text(
            'Analysis Failed',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: BrandColor.darkText,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: BrandColor.lightText),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text(
                'Try Again',
                style: TextStyle(
                  color: BrandColor.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // GENERATE PREPROCESSED PREVIEW
  // ============================================================

  Future<void> _generatePreprocessedPreview() async {
    if (_preprocessedBytes != null || _generatingPreview) {
      return;
    }

    setState(() {
      _generatingPreview = true;
      _previewError = null;
    });

    try {
      final bytes = await widget.imageFile.readAsBytes();

      final decoded = img.decodeImage(bytes);

      if (decoded == null) {
        throw Exception('Could not decode image for preview.');
      }

      final resized = img.copyResize(
        decoded,
        width: MlConfig.classifierInputSize,
        height: MlConfig.classifierInputSize,
        interpolation: img.Interpolation.average,
      );

      final jpg = img.encodeJpg(resized, quality: 92);

      if (!mounted) return;

      setState(() {
        _preprocessedBytes = Uint8List.fromList(jpg);

        _generatingPreview = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _previewError = 'Could not generate preview';

        _generatingPreview = false;
      });
    }
  }

  // ============================================================
  // MODE CHANGE
  // ============================================================

  void _onModeChanged(_PreviewMode mode) {
    if (loading) return;

    setState(() {
      _mode = mode;
    });

    if (mode == _PreviewMode.preprocessed) {
      _generatePreprocessedPreview();
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BrandColor.background,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: BrandColor.darkText),
        title: const Text(
          'Preview Image',
          style: TextStyle(
            color: BrandColor.darkText,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),

      // IMPORTANT:
      // SingleChildScrollView fixes RenderFlex overflow
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ORIGINAL / PREPROCESSED
              _modeToggle(),

              const SizedBox(height: 14),

              // IMAGE
              _previewImage(),

              const SizedBox(height: 16),

              // AI PROCESS
              _analysisProcessCard(),

              // Spacer removed.
              // SizedBox is correct inside scroll view.
              const SizedBox(height: 24),

              // ANALYZE BUTTON
              SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton(
                  onPressed: loading ? null : analyze,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BrandColor.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: BrandColor.primary.withOpacity(
                      0.60,
                    ),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: loading
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Analyzing Image...',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ],
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.auto_awesome_rounded, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Analyze Image',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // MODE TOGGLE
  // ============================================================

  Widget _modeToggle() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: BrandColor.softPink,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BrandColor.borderPink),
      ),
      child: Row(
        children: [
          Expanded(
            child: _toggleOption(
              label: 'Original',
              selected: _mode == _PreviewMode.original,
              onTap: () {
                _onModeChanged(_PreviewMode.original);
              },
            ),
          ),

          Expanded(
            child: _toggleOption(
              label: 'Preprocessed',
              selected: _mode == _PreviewMode.preprocessed,
              onTap: () {
                _onModeChanged(_PreviewMode.preprocessed);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _toggleOption({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? BrandColor.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : BrandColor.darkText,
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // IMAGE PREVIEW
  // ============================================================

  Widget _previewImage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: SizedBox(
        width: double.infinity,

        // Reduced slightly to fit smaller phones better
        height: 240,

        child: _mode == _PreviewMode.original
            ? Image.file(
                widget.imageFile,
                width: double.infinity,
                height: 240,
                fit: BoxFit.cover,
              )
            : _preprocessedView(),
      ),
    );
  }

  // ============================================================
  // AI ANALYSIS PROCESS CARD
  // ============================================================

  Widget _analysisProcessCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: BrandColor.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: BrandColor.softPink,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.psychology_alt_rounded,
                  color: BrandColor.primary,
                  size: 20,
                ),
              ),

              const SizedBox(width: 10),

              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Analysis Process',
                      style: TextStyle(
                        color: BrandColor.darkText,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Your image will go through these steps',
                      style: TextStyle(
                        color: BrandColor.lightText,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          _analysisStep(
            number: '1',
            icon: Icons.image_search_rounded,
            title: 'Image Quality Check',
            subtitle: 'Checks image clarity and quality',
          ),

          _analysisDivider(),

          _analysisStep(
            number: '2',
            icon: Icons.verified_rounded,
            title: 'Pomegranate Validation',
            subtitle: 'Confirms the image contains a pomegranate',
          ),

          _analysisDivider(),

          _analysisStep(
            number: '3',
            icon: Icons.biotech_rounded,
            title: 'Disease Analysis',
            subtitle: 'AI identifies the disease type',
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ANALYSIS STEP
  // ============================================================

  Widget _analysisStep({
    required String number,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 43,
              height: 43,
              decoration: BoxDecoration(
                color: BrandColor.softPink,
                shape: BoxShape.circle,
                border: Border.all(color: BrandColor.primary.withOpacity(0.15)),
              ),
              child: Icon(icon, color: BrandColor.primary, size: 20),
            ),

            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                width: 18,
                height: 18,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: BrandColor.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: Text(
                  number,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(width: 14),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: BrandColor.darkText,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 3),

              Text(
                subtitle,
                style: const TextStyle(
                  color: BrandColor.lightText,
                  fontSize: 10.8,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 8),

        const Icon(
          Icons.check_circle_outline_rounded,
          color: BrandColor.green,
          size: 19,
        ),
      ],
    );
  }

  // ============================================================
  // ANALYSIS DIVIDER
  // ============================================================

  Widget _analysisDivider() {
    return Padding(
      padding: const EdgeInsets.only(left: 21, top: 4, bottom: 4),
      child: Container(
        width: 2,
        height: 14,
        decoration: BoxDecoration(
          color: BrandColor.border,
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  // ============================================================
  // PREPROCESSED IMAGE
  // ============================================================

  Widget _preprocessedView() {
    if (_generatingPreview) {
      return Container(
        color: BrandColor.softPink,
        child: const Center(
          child: CircularProgressIndicator(color: BrandColor.primary),
        ),
      );
    }

    if (_previewError != null) {
      return Container(
        color: BrandColor.softPink,
        child: Center(
          child: Text(
            _previewError!,
            style: const TextStyle(color: BrandColor.lightText),
          ),
        ),
      );
    }

    if (_preprocessedBytes == null) {
      return Container(
        color: BrandColor.softPink,
        child: const Center(
          child: Text(
            'Select Preprocessed to preview',
            style: TextStyle(color: BrandColor.lightText),
          ),
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        Image.memory(
          _preprocessedBytes!,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.none,
        ),

        Positioned(
          top: 10,
          right: 10,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.55),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              '${MlConfig.classifierInputSize}'
              '×'
              '${MlConfig.classifierInputSize}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
