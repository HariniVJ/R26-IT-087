// frontend/mobile_app/lib/screens/capture_screen.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'detecting_screen.dart';

class CaptureScreen extends StatefulWidget {
  const CaptureScreen({super.key});

  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen>
    with TickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();

  // ── Brand colors ─────────────────────────────────────────────
  static const Color primary      = Color(0xFFC13B57);
  static const Color primaryDark  = Color(0xFFB22222);
  static const Color primaryBg    = Color(0xFFFBEAF0);
  static const Color primaryLight = Color(0xFFF4C0D1);

  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late Animation<double>   _pulseAnim;
  late Animation<double>   _rotateAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.96, end: 1.04).animate(
        CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));

    _rotateController = AnimationController(
        vsync: this, duration: const Duration(seconds: 8))
      ..repeat();
    _rotateAnim = Tween<double>(begin: 0, end: 1).animate(_rotateController);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  Future<void> _openCamera() async {
    final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera, imageQuality: 85);
    if (photo != null && mounted) _navigate(photo);
  }

  Future<void> _openGallery() async {
    final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery, imageQuality: 85);
    if (image != null && mounted) _navigate(image);
  }

  void _navigate(XFile xfile) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => DetectingScreen(xfile: xfile),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [

            // ── Top bar ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: const BoxDecoration(
                        color: primary, shape: BoxShape.circle),
                    child: const Center(
                      child: Text('PK',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w800)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Pomegranate Farm',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1A1A1A))),
                        Text('Fri, 16 May 2026',
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                        color: primaryBg,
                        borderRadius: BorderRadius.circular(20)),
                    child: const Row(children: [
                      Icon(Icons.wb_sunny_rounded,
                          color: primary, size: 14),
                      SizedBox(width: 4),
                      Text('27°/41°M',
                          style: TextStyle(
                              fontSize: 11,
                              color: primary,
                              fontWeight: FontWeight.w700)),
                    ]),
                  ),
                ],
              ),
            ),

            // ── Hero section ────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 4),

                    // ── 2-column layout ────────────────────────
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // LEFT: text 58%
                        Expanded(
                          flex: 58,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              RichText(
                                text: const TextSpan(
                                  style: TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF1A1A1A),
                                    height: 1.2,
                                    letterSpacing: -0.5,
                                  ),
                                  children: [
                                    TextSpan(text: 'Scan Your\n'),
                                    TextSpan(
                                      text: 'Pomegranate\n',
                                      style: TextStyle(color: primary),
                                    ),
                                    TextSpan(text: 'Fruit Stage'),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Capture or select an image to identify the fruit stage using AI.',
                                style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[500],
                                    height: 1.55),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 8),

                        // RIGHT: real pomegranate image 42%
                        Expanded(
                          flex: 42,
                          child: SizedBox(
                            height: 170,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Soft pink glow circle behind image
                                Positioned(
                                  right: 0,
                                  child: Container(
                                    width: 140,
                                    height: 140,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: primaryBg,
                                    ),
                                  ),
                                ),
                                // ── Real pomegranate image ──────
                                Positioned(
                                  right: 0,
                                  top: 4,
                                  child: Image.asset(
                                    'assets/images/pomegranate.jpeg',
                                    width: 155,
                                    height: 162,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 22),

                    // ── Scanner card ────────────────────────────
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          vertical: 28, horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                            color: primary.withOpacity(0.15), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: primary.withOpacity(0.08),
                            blurRadius: 24,
                            spreadRadius: 2,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          ScaleTransition(
                            scale: _pulseAnim,
                            child: SizedBox(
                              width: 160, height: 160,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Rotating dotted ring
                                  RotationTransition(
                                    turns: _rotateAnim,
                                    child: CustomPaint(
                                      size: const Size(160, 160),
                                      painter: _DottedRingPainter(
                                          color: primary.withOpacity(0.35)),
                                    ),
                                  ),
                                  // Mid ring
                                  Container(
                                    width: 128, height: 128,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: primary.withOpacity(0.12),
                                          width: 1.5),
                                      color: primaryBg.withOpacity(0.5),
                                    ),
                                  ),
                                  // Corner marks
                                  ..._buildCorners(),
                                  // Camera button
                                  Container(
                                    width: 76, height: 76,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: primary,
                                      boxShadow: [
                                        BoxShadow(
                                          color: primary.withOpacity(0.4),
                                          blurRadius: 18,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                        Icons.camera_alt_rounded,
                                        color: Colors.white,
                                        size: 32),
                                  ),
                                  // Sparkle dots
                                  Positioned(top: 8, right: 24,
                                      child: _dot(5)),
                                  Positioned(top: 24, left: 16,
                                      child: _dot(4)),
                                  Positioned(bottom: 16, right: 18,
                                      child: _dot(4)),
                                  Positioned(bottom: 8, left: 24,
                                      child: _dot(5)),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 8, height: 8,
                                decoration: const BoxDecoration(
                                    color: Color(0xFF22C55E),
                                    shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 6),
                              const Text('Ready to Scan',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1A1A1A))),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Position the fruit in the frame for best results',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[500]),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── Action buttons ──────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: _openCamera,
                            child: Container(
                              height: 58,
                              decoration: BoxDecoration(
                                color: primary,
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color: primary.withOpacity(0.4),
                                    blurRadius: 14,
                                    offset: const Offset(0, 5)),
                                ],
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.camera_alt_rounded,
                                      color: Colors.white, size: 20),
                                  SizedBox(width: 8),
                                  Text('Capture Image',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: GestureDetector(
                            onTap: _openGallery,
                            child: Container(
                              height: 58,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                    color: primary.withOpacity(0.4),
                                    width: 1.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 8),
                                ],
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.photo_library_rounded,
                                      color: primary, size: 20),
                                  SizedBox(width: 8),
                                  Text('Select Image',
                                      style: TextStyle(
                                          color: primary,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // ── Bottom nav ──────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.07),
                    blurRadius: 16,
                    offset: const Offset(0, -4)),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _navItem(Icons.home_rounded, 'Home', false),
                  _navItem(Icons.history_rounded, 'History', false),
                  GestureDetector(
                    onTap: _openCamera,
                    child: Container(
                      width: 54, height: 54,
                      decoration: BoxDecoration(
                        color: primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: primary.withOpacity(0.4),
                            blurRadius: 14,
                            offset: const Offset(0, 4)),
                        ],
                      ),
                      child: const Icon(Icons.document_scanner_rounded,
                          color: Colors.white, size: 24),
                    ),
                  ),
                  _navItem(Icons.bar_chart_rounded, 'Reports', false),
                  _navItem(Icons.person_rounded, 'Profile', false),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dot(double size) => Container(
    width: size, height: size,
    decoration: BoxDecoration(
        color: primary.withOpacity(0.4), shape: BoxShape.circle),
  );

  List<Widget> _buildCorners() {
    Widget c(bool top, bool left) => Align(
      alignment: top && left
          ? Alignment.topLeft
          : top && !left
              ? Alignment.topRight
              : !top && left
                  ? Alignment.bottomLeft
                  : Alignment.bottomRight,
      child: SizedBox(
        width: 20, height: 20,
        child: CustomPaint(
          painter: _CornerPainter(
              isTop: top, isLeft: left,
              thickness: 2.5, color: primary)),
      ),
    );
    return [c(true,true), c(true,false), c(false,true), c(false,false)];
  }

  Widget _navItem(IconData icon, String label, bool active) {
    final color = active ? primary : Colors.grey[400]!;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: color, size: 22),
      const SizedBox(height: 3),
      Text(label,
          style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight:
                  active ? FontWeight.w700 : FontWeight.normal)),
    ]);
  }
}

class _DottedRingPainter extends CustomPainter {
  final Color color;
  _DottedRingPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;
    const dashCount = 24;
    const dashAngle = 3.14159 * 2 / dashCount;

    for (int i = 0; i < dashCount; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        i * dashAngle,
        dashAngle * 0.55,
        false, paint,
      );
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

class _CornerPainter extends CustomPainter {
  final bool isTop;
  final bool isLeft;
  final double thickness;
  final Color color;
  _CornerPainter({
    required this.isTop, required this.isLeft,
    required this.thickness, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final x = isLeft ? 0.0 : size.width;
    final y = isTop  ? 0.0 : size.height;
    canvas.drawLine(Offset(x, y), Offset(x + (isLeft ? 1 : -1) * size.width * 0.6, y), paint);
    canvas.drawLine(Offset(x, y), Offset(x, y + (isTop ? 1 : -1) * size.height * 0.6), paint);
  }

  @override
  bool shouldRepaint(_) => false;
}