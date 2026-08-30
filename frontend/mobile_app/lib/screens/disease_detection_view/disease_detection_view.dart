import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../common/brand_color.dart';
import '../../services/disease/disease_service.dart';
import '../../services/disease/history_service.dart';
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

    final hour12 = now.hour == 0
        ? 12
        : now.hour > 12
        ? now.hour - 12
        : now.hour;

    final timeStr =
        '${hour12.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} '
        '${now.hour >= 12 ? 'PM' : 'AM'}';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ProfileCard(timeStr: timeStr, dateStr: dateStr),

              const SizedBox(height: 26),

              _ComponentIntroCard(),

              const SizedBox(height: 22),

              GestureDetector(
                onTap: () => pickImage(ImageSource.camera),
                child: Container(
                  height: 330,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFAFB),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: const Color(0xFFFFD7DE)),
                    boxShadow: [
                      BoxShadow(
                        color: BrandColor.primary.withOpacity(0.08),
                        blurRadius: 22,
                        offset: const Offset(0, 10),
                      ),
                    ],
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

              Row(
                children: [
                  Expanded(
                    child: _PrimaryButton(
                      title: 'Capture',
                      icon: Icons.camera_alt_rounded,
                      onTap: () => pickImage(ImageSource.camera),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _OutlineButton(
                      title: 'Gallery',
                      icon: Icons.photo_library_outlined,
                      onTap: () => pickImage(ImageSource.gallery),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              _DetectButton(
                isLoading: isLoading,
                onTap: isLoading ? null : detectDisease,
              ),

              const SizedBox(height: 18),

              _TipBox(),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: BrandColor.primary.withOpacity(0.20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: BrandColor.primary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Text(
                'AK',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Akaran Farm',
                  style: TextStyle(
                    color: BrandColor.darkText,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  dateStr,
                  style: TextStyle(color: BrandColor.lightText, fontSize: 13),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF4F6),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFFD7DE)),
            ),
            child: Text(
              timeStr,
              style: const TextStyle(
                color: BrandColor.primary,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ComponentIntroCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: BrandColor.primary,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: BrandColor.primary.withOpacity(0.28),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.16),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.health_and_safety_rounded,
              color: Colors.white,
              size: 34,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Disease Detection',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Capture or upload a pomegranate fruit image to detect disease and get treatment recommendation.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanFrameEmpty extends StatelessWidget {
  const _ScanFrameEmpty();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const _CornerBrackets(),

        Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 28),
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: const Color(0xFFFFD7DE)),
              boxShadow: [
                BoxShadow(
                  color: BrandColor.primary.withOpacity(0.08),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF4F6),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(
                    Icons.cloud_upload_rounded,
                    color: BrandColor.primary,
                    size: 38,
                  ),
                ),

                const SizedBox(height: 18),

                const Text(
                  'Upload Fruit Image',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    color: BrandColor.darkText,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  'Take a photo or choose from gallery',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: BrandColor.softText),
                ),

                const SizedBox(height: 18),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: BrandColor.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Tap here to capture',
                    style: TextStyle(
                      color: BrandColor.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CornerBrackets extends StatelessWidget {
  const _CornerBrackets();

  @override
  Widget build(BuildContext context) {
    const color = BrandColor.primary;
    const size = 30.0;
    const stroke = 4.0;
    const radius = 8.0;
    const padding = 20.0;

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
                color: const Color.fromARGB(255, 255, 255, 255),
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
  bool shouldRepaint(_BracketPainter oldDelegate) => false;
}

class _DashedCirclePainter extends CustomPainter {
  final Color color;

  const _DashedCirclePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.7
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 5;

    const dashCount = 26;
    const dashAngle = 3.14159 * 2 / dashCount;
    const gapFraction = 0.42;

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
  bool shouldRepaint(_DashedCirclePainter oldDelegate) => false;
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
          borderRadius: BorderRadius.circular(29),
          child: Image.file(
            image,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
        ),
        Positioned(
          top: 12,
          right: 12,
          child: GestureDetector(
            onTap: onClear,
            child: Container(
              padding: const EdgeInsets.all(7),
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
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: BrandColor.primary,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: BrandColor.primary.withOpacity(0.28),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: Colors.white),
            const SizedBox(width: 10),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 16,
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
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: BrandColor.primary),
            const SizedBox(width: 10),
            Text(
              title,
              style: const TextStyle(
                color: BrandColor.darkText,
                fontWeight: FontWeight.w900,
                fontSize: 16,
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
      height: 64,
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
            borderRadius: BorderRadius.circular(22),
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
                    'Analyzing Disease...',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
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
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
      ),
    );
  }
}

class _TipBox extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFAFB),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFFFD7DE)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.lightbulb_rounded,
            color: Color(0xFFFFC107),
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Tip: Use a clear, well-lit pomegranate fruit image for better disease detection accuracy.',
              style: TextStyle(
                color: BrandColor.lightText,
                fontSize: 13,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
