import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../common/brand_color.dart';
import '../../common/glass_container.dart';
import '../../services/disease_service.dart';
import '../../services/history_service.dart';
import '../result_view/result_view.dart';

class DiseaseDetectionView extends StatefulWidget {
  const DiseaseDetectionView({super.key});

  @override
  State<DiseaseDetectionView> createState() => _DiseaseDetectionViewState();
}

class _DiseaseDetectionViewState extends State<DiseaseDetectionView> {
  File? selectedImage;
  bool isLoading = false;
  final ImagePicker picker = ImagePicker();

  // ── Logic unchanged ────────────────────────────────────────
  Future<void> pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      if (pickedFile != null) {
        setState(() => selectedImage = File(pickedFile.path));
      }
    } catch (e) {
      _showSnackBar('Image selection failed: $e');
    }
  }

  Future<void> detectDisease() async {
    if (selectedImage == null) {
      _showSnackBar('Please select an image first');
      return;
    }
    setState(() => isLoading = true);
    try {
      final result = await DiseaseService.predictDisease(selectedImage!);
      HistoryService.addHistory(result);
      if (!mounted) return;
      setState(() => isLoading = false);
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ResultView(result: result)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      _showSnackBar('Error: $e');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: BrandColor.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  void _showSourceSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: BrandColor.bgDeep.withOpacity(0.94),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              border: Border(top: BorderSide(color: BrandColor.glassBorder)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: BrandColor.glassBorder,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Select Image Source',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: BrandColor.darkText,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _GlassActionButton(
                        title: 'Camera',
                        icon: Icons.camera_alt_rounded,
                        color: BrandColor.primary,
                        onTap: () {
                          Navigator.pop(context);
                          pickImage(ImageSource.camera);
                        },
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _GlassActionButton(
                        title: 'Gallery',
                        icon: Icons.photo_library_rounded,
                        color: BrandColor.green,
                        onTap: () {
                          Navigator.pop(context);
                          pickImage(ImageSource.gallery);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── UI ─────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BrandColor.background,
      extendBodyBehindAppBar: true,
      appBar: const DarkAppBar(title: 'Upload Fruit Image'),
      body: Stack(
        children: [
          const DarkBackground(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Upload drop zone
                  GestureDetector(
                    onTap: () => _showSourceSheet(context),
                    child: GlassContainer(
                      padding: EdgeInsets.zero,
                      borderRadius: BorderRadius.circular(28),
                      borderColor: selectedImage != null
                          ? BrandColor.primary.withOpacity(0.45)
                          : BrandColor.glassBorder,
                      child: SizedBox(
                        height: 320,
                        width: double.infinity,
                        child: selectedImage == null
                            ? _EmptyDropZone()
                            : _PreviewStack(
                                image: selectedImage!,
                                onClear: () =>
                                    setState(() => selectedImage = null),
                                onChange: () => _showSourceSheet(context),
                              ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Camera / Gallery
                  Row(
                    children: [
                      Expanded(
                        child: _GlassActionButton(
                          title: 'Camera',
                          icon: Icons.camera_alt_rounded,
                          color: BrandColor.primary,
                          onTap: () => pickImage(ImageSource.camera),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _GlassActionButton(
                          title: 'Gallery',
                          icon: Icons.photo_library_rounded,
                          color: BrandColor.green,
                          onTap: () => pickImage(ImageSource.gallery),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // Detect button
                  SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: BrandColor.primary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: BrandColor.primary.withOpacity(
                          0.35,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 0,
                      ),
                      onPressed: isLoading ? null : detectDisease,
                      child: isLoading
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'Analyzing...',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.document_scanner_rounded, size: 22),
                                SizedBox(width: 10),
                                Text(
                                  'Detect Disease',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 14,
                        color: BrandColor.softText,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Best results with clear, well-lit photos',
                        style: TextStyle(
                          fontSize: 12,
                          color: BrandColor.softText,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty Drop Zone ────────────────────────────────────────────
class _EmptyDropZone extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: BrandColor.primary.withOpacity(0.15),
            shape: BoxShape.circle,
            border: Border.all(color: BrandColor.primary.withOpacity(0.30)),
          ),
          child: Icon(
            Icons.add_photo_alternate_rounded,
            size: 40,
            color: BrandColor.accent,
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Upload Pomegranate Image',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: BrandColor.darkText,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Tap to use camera or gallery',
          style: TextStyle(color: BrandColor.softText, fontSize: 13),
        ),
      ],
    );
  }
}

// ── Preview Stack ──────────────────────────────────────────────
class _PreviewStack extends StatelessWidget {
  final File image;
  final VoidCallback onClear;
  final VoidCallback onChange;

  const _PreviewStack({
    required this.image,
    required this.onClear,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(27),
          child: Image.file(
            image,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
        ),
        Positioned(
          top: 10,
          right: 10,
          child: GestureDetector(
            onTap: onClear,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 10,
          right: 10,
          child: GestureDetector(
            onTap: onChange,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.refresh_rounded, color: Colors.white, size: 14),
                  SizedBox(width: 4),
                  Text(
                    'Change',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Glass Action Button ────────────────────────────────────────
class _GlassActionButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _GlassActionButton({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: color.withOpacity(0.14),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(0.32)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
