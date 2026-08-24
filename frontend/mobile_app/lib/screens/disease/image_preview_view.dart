import 'dart:io';

import 'package:flutter/material.dart';

import '../../common/brand_color.dart';
import '../../services/disease_service.dart';
import 'classification_result_view.dart';

class ImagePreviewView extends StatefulWidget {
  final File imageFile;

  const ImagePreviewView({super.key, required this.imageFile});

  @override
  State<ImagePreviewView> createState() => _ImagePreviewViewState();
}

class _ImagePreviewViewState extends State<ImagePreviewView> {
  bool loading = false;

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
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.file(
                widget.imageFile,
                width: double.infinity,
                height: 310,
                fit: BoxFit.cover,
              ),
            ),

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
