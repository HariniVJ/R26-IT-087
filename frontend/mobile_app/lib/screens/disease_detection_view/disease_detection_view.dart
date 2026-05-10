import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../common/brand_color.dart';
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

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final weekdays = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final dateStr =
        '${weekdays[now.weekday]}, ${now.day} ${months[now.month]} ${now.year}';
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} '
        '${now.hour >= 12 ? 'PM' : 'AM'}';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile card
              _ProfileCard(timeStr: timeStr, dateStr: dateStr),
              const SizedBox(height: 28),

              // Header row: title + pomegranate image
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Scan Your',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: BrandColor.darkText,
                          ),
                        ),
                        Text(
                          'Pomegranate',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: BrandColor.primary,
                          ),
                        ),
                        Text(
                          'Fruit Stage',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: BrandColor.darkText,
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Capture or select an image to\nidentify the fruit stage using AI.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF9CA3AF),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Pomegranate fruit image thumbnail
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 110,
                      height: 110,
                      color: const Color(0xFFFFF4F6),
                      child: selectedImage != null
                          ? Image.file(selectedImage!, fit: BoxFit.cover)
                          : const _PomegranateIllustration(),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // Scan frame area
              GestureDetector(
                onTap: () => pickImage(ImageSource.camera),
                child: Container(
                  height: 280,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8F9),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: const Color(0xFFFFE4E8)),
                  ),
                  child: selectedImage == null
                      ? const _ScanFrameEmpty()
                      : _ScanFramePreview(
                          image: selectedImage!,
                          onClear: () => setState(() => selectedImage = null),
                        ),
                ),
              ),

              const SizedBox(height: 24),

              // Capture + Select buttons
              Row(
                children: [
                  Expanded(
                    child: _PrimaryButton(
                      title: 'Capture Image',
                      icon: Icons.camera_alt_rounded,
                      onTap: () => pickImage(ImageSource.camera),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _OutlineButton(
                      title: 'Select Image',
                      icon: Icons.photo_library_outlined,
                      onTap: () => pickImage(ImageSource.gallery),
                    ),
                  ),
                ],
              ),

              if (selectedImage != null) ...[
                const SizedBox(height: 20),
                _DetectButton(
                  isLoading: isLoading,
                  onTap: isLoading ? null : detectDisease,
                ),
              ],

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
                    style: TextStyle(fontSize: 12, color: BrandColor.softText),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final String timeStr;
  final String dateStr;

  const _ProfileCard({required this.timeStr, required this.dateStr});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: BrandColor.primary.withOpacity(0.20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: BrandColor.primary,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Center(
              child: Text(
                'PK',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pomegranate Farm',
                  style: TextStyle(
                    color: BrandColor.darkText,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  dateStr,
                  style: TextStyle(color: BrandColor.lightText, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: BrandColor.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: BrandColor.primary.withOpacity(0.20)),
            ),
            child: Text(
              timeStr,
              style: const TextStyle(
                color: BrandColor.primary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Placeholder illustration for the pomegranate thumbnail
class _PomegranateIllustration extends StatelessWidget {
  const _PomegranateIllustration();

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('🍎', style: TextStyle(fontSize: 56)));
  }
}

/// Empty scan frame with corner brackets and dashed circle
class _ScanFrameEmpty extends StatelessWidget {
  const _ScanFrameEmpty();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Corner brackets
        const _CornerBrackets(),
        // Center content
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Dashed circle with camera icon
              CustomPaint(
                painter: _DashedCirclePainter(
                  color: BrandColor.primary.withOpacity(0.25),
                ),
                child: SizedBox(
                  width: 140,
                  height: 140,
                  child: Center(
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: BrandColor.primary.withOpacity(0.15),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.camera_alt_outlined,
                        color: BrandColor.primary,
                        size: 30,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Ready to Scan',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: BrandColor.darkText,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Position the fruit in the frame for best results',
                style: TextStyle(fontSize: 12, color: BrandColor.softText),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Corner bracket decoration matching the image
class _CornerBrackets extends StatelessWidget {
  const _CornerBrackets();

  @override
  Widget build(BuildContext context) {
    const color = BrandColor.primary;
    const size = 22.0;
    const stroke = 3.0;
    const radius = 8.0;
    const padding = 16.0;

    Widget bracket({
      required Alignment align,
      required bool flipX,
      required bool flipY,
    }) {
      return Align(
        alignment: align,
        child: Padding(
          padding: EdgeInsets.only(
            left: flipX ? 0 : padding,
            right: flipX ? padding : 0,
            top: flipY ? 0 : padding,
            bottom: flipY ? padding : 0,
          ),
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..scale(flipX ? -1.0 : 1.0, flipY ? -1.0 : 1.0),
            child: CustomPaint(
              size: const Size(size, size),
              painter: _BracketPainter(
                color: color,
                strokeWidth: stroke,
                radius: radius,
              ),
            ),
          ),
        ),
      );
    }

    return Stack(
      children: [
        bracket(align: Alignment.topLeft, flipX: false, flipY: false),
        bracket(align: Alignment.topRight, flipX: true, flipY: false),
        bracket(align: Alignment.bottomLeft, flipX: false, flipY: true),
        bracket(align: Alignment.bottomRight, flipX: true, flipY: true),
      ],
    );
  }
}

class _BracketPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double radius;

  const _BracketPainter({
    required this.color,
    required this.strokeWidth,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(0, size.height);
    path.lineTo(0, radius);
    path.arcToPoint(
      Offset(radius, 0),
      radius: Radius.circular(radius),
      clockwise: true,
    );
    path.lineTo(size.width, 0);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_BracketPainter old) => false;
}

class _DashedCirclePainter extends CustomPainter {
  final Color color;

  const _DashedCirclePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    const dashCount = 24;
    const dashAngle = 3.14159 * 2 / dashCount;
    const gapFraction = 0.4;

    for (int i = 0; i < dashCount; i++) {
      final startAngle = i * dashAngle;
      final sweepAngle = dashAngle * (1 - gapFraction);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DashedCirclePainter old) => false;
}

class _ScanFramePreview extends StatelessWidget {
  final File image;
  final VoidCallback onClear;

  const _ScanFramePreview({required this.image, required this.onClear});

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
      ],
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _PrimaryButton({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        height: 58,
        decoration: BoxDecoration(
          color: BrandColor.primary,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: BrandColor.primary.withOpacity(0.30),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 19, color: Colors.white),
            const SizedBox(width: 9),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OutlineButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _OutlineButton({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        height: 58,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 19, color: BrandColor.primary),
            const SizedBox(width: 9),
            Text(
              title,
              style: const TextStyle(
                color: BrandColor.darkText,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetectButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onTap;

  const _DetectButton({required this.isLoading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: onTap == null
              ? BrandColor.primary.withOpacity(0.45)
              : BrandColor.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
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
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
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
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
      ),
    );
  }
}
