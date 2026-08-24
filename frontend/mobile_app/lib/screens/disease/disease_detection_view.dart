import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../common/brand_color.dart';
import 'image_preview_view.dart';

class DiseaseDetectionView extends StatefulWidget {
  const DiseaseDetectionView({super.key});

  @override
  State<DiseaseDetectionView> createState() => _DiseaseDetectionViewState();
}

class _DiseaseDetectionViewState extends State<DiseaseDetectionView> {
  final ImagePicker _picker = ImagePicker();

  Future<void> pickImage(ImageSource source) async {
    final XFile? file = await _picker.pickImage(
      source: source,
      imageQuality: 90,
      maxWidth: 1200,
      maxHeight: 1200,
    );

    if (file == null || !mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ImagePreviewView(imageFile: File(file.path)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BrandColor.background,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Capture or Upload',
          style: TextStyle(
            color: BrandColor.darkText,
            fontWeight: FontWeight.w800,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: BrandColor.primary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            const SizedBox(height: 18),

            const Text(
              'Choose an option',
              style: TextStyle(color: BrandColor.lightText),
            ),

            const SizedBox(height: 26),

            _imageOption(
              icon: Icons.camera_alt_rounded,
              title: 'Capture Photo',
              subtitle: 'Use camera to take photo',
              highlight: true,
              onTap: () => pickImage(ImageSource.camera),
            ),

            const SizedBox(height: 16),

            _imageOption(
              icon: Icons.photo_library_rounded,
              title: 'Choose from Gallery',
              subtitle: 'Select from your photos',
              highlight: false,
              onTap: () => pickImage(ImageSource.gallery),
            ),

            const SizedBox(height: 16),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: BrandColor.softPink,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: BrandColor.borderPink),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline_rounded,
                    color: BrandColor.primary,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Use a clear image in good lighting for best results.',
                      style: TextStyle(
                        color: BrandColor.lightText,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imageOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool highlight,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
        decoration: BoxDecoration(
          color: highlight ? BrandColor.softPink : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: highlight ? BrandColor.borderPink : BrandColor.border,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: BrandColor.primary, size: 48),
            const SizedBox(height: 15),
            Text(
              title,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 5),
            Text(
              subtitle,
              style: const TextStyle(color: BrandColor.lightText, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
