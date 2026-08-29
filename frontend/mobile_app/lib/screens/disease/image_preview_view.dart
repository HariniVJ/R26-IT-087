import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

import '../../common/brand_color.dart';
import '../../services/disease/disease_service.dart';
import '../../services/ml/model_inference_service.dart';
import 'classification_result_view.dart';

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

  Future<void> analyze() async {
    setState(() => loading = true);

    try {
      final result = await DiseaseService.predictDisease(widget.imageFile);

      if (!mounted) return;

      setState(() => loading = false);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ClassificationResultView(result: result),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() => loading = false);

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          icon: const Icon(
            Icons.warning_amber_rounded,
            color: BrandColor.primary,
            size: 45,
          ),
          title: const Text('Image Rejected'),
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Try Another Image',
                style: TextStyle(color: BrandColor.primary),
              ),
            ),
          ],
        ),
      );
    }
  }

  /// Generates a visual preview of what the model actually sees:
  /// resized to the model's input size, same as the real preprocessing
  /// step in ModelInferenceService, but re-encoded as JPEG for display.
  Future<void> _generatePreprocessedPreview() async {
    if (_preprocessedBytes != null || _generatingPreview) return;

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

  void _onModeChanged(_PreviewMode mode) {
    setState(() => _mode = mode);
    if (mode == _PreviewMode.preprocessed) {
      _generatePreprocessedPreview();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BrandColor.background,

      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'Preview Image',
          style: TextStyle(
            color: BrandColor.darkText,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _modeToggle(),

            const SizedBox(height: 14),

            _previewImage(),

            const SizedBox(height: 16),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: BrandColor.border),
              ),
              child: const Column(
                children: [
                  _CheckRow(text: 'Image quality will be checked'),
                  SizedBox(height: 10),
                  _CheckRow(text: 'Pomegranate will be validated'),
                  SizedBox(height: 10),
                  _CheckRow(text: 'Ready for AI analysis'),
                ],
              ),
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              height: 58,
              child: ElevatedButton(
                onPressed: loading ? null : analyze,
                style: ElevatedButton.styleFrom(
                  backgroundColor: BrandColor.primary,
                  foregroundColor: Colors.white,
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
                          Text('Analyzing Image...'),
                        ],
                      )
                    : const Text(
                        'Analyze Image',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Original / Preprocessed segmented toggle ─────────────────────────
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
              onTap: () => _onModeChanged(_PreviewMode.original),
            ),
          ),
          Expanded(
            child: _toggleOption(
              label: 'Preprocessed',
              selected: _mode == _PreviewMode.preprocessed,
              onTap: () => _onModeChanged(_PreviewMode.preprocessed),
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
      onTap: onTap,
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

  // ── Image display area — switches based on selected mode ────────────
  Widget _previewImage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: SizedBox(
        width: double.infinity,
        height: 310,
        child: _mode == _PreviewMode.original
            ? Image.file(
                widget.imageFile,
                width: double.infinity,
                height: 310,
                fit: BoxFit.cover,
              )
            : _preprocessedView(),
      ),
    );
  }

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
      return Container(color: BrandColor.softPink);
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        Image.memory(
          _preprocessedBytes!,
          fit: BoxFit.cover,
          // Pixelated look emphasizes this is the low-res model input,
          // not just a cosmetic filter — helps the badge make sense.
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
              '${MlConfig.classifierInputSize}×${MlConfig.classifierInputSize}',
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

class _CheckRow extends StatelessWidget {
  final String text;

  const _CheckRow({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.check_rounded, color: BrandColor.primary, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: BrandColor.lightText),
          ),
        ),
      ],
    );
  }
}
