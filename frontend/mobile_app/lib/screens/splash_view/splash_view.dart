import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../common/brand_color.dart';
import '../../services/auth/auth_service.dart';
import '../dashboard_screen.dart';
import '../onboarding_auth_flow.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ringController;
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();

    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();

    _navigationTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => AuthService.instance.isLoggedIn
              ? const DashboardScreen()
              : const OnboardingAuthFlow(),
        ),
      );
    });
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _ringController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final treeSize = (size.shortestSide * 0.72).clamp(240.0, 340.0);
    final ringSize = treeSize * 0.92;

    return Scaffold(
      backgroundColor: const Color(0xFFFDF8F7),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const CustomPaint(painter: _MistPainter()),
          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 3),
                SizedBox(
                  width: treeSize,
                  height: treeSize,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(18),
                        child: Image.asset(
                          'assets/images/Splash_Screen.png',
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                        ),
                      ),
                      AnimatedBuilder(
                        animation: _ringController,
                        builder: (context, child) {
                          return Transform.rotate(
                            angle: _ringController.value * 2 * math.pi,
                            child: child,
                          );
                        },
                        child: SizedBox(
                          width: ringSize,
                          height: ringSize,
                          child: const CustomPaint(painter: _GlowRingPainter()),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                ShaderMask(
                  blendMode: BlendMode.srcIn,
                  shaderCallback: (bounds) {
                    return const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFF6B0C20),
                        BrandColor.primary,
                        Color(0xFFC41E3A),
                      ],
                    ).createShader(bounds);
                  },
                  child: const Text(
                    'AI',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 72,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'serif',
                      height: 0.9,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                const SizedBox(
                  width: 168,
                  height: 22,
                  child: CustomPaint(painter: _DividerPainter()),
                ),
                const Text(
                  'AI BASED INTELLIGENT SYSTEM',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: BrandColor.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.4,
                  ),
                ),
                const Spacer(flex: 2),
                const Text(
                  'Loading...',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: BrandColor.primary,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'serif',
                  ),
                ),
                const SizedBox(height: 28),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowRingPainter extends CustomPainter {
  const _GlowRingPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.46;
    final ringRect = Rect.fromCircle(center: center, radius: radius);

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = BrandColor.primary.withValues(alpha: 0.10),
    );

    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        colors: [
          BrandColor.primary.withValues(alpha: 0.0),
          const Color(0xFFFF7F9F),
          BrandColor.primary,
          BrandColor.primary.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.28, 0.55, 0.82],
      ).createShader(ringRect);

    canvas.drawArc(ringRect, -math.pi / 2, 2.35, false, arcPaint);

    final orbAngle = -math.pi / 2 + 2.35;
    final orb = Offset(
      center.dx + math.cos(orbAngle) * radius,
      center.dy + math.sin(orbAngle) * radius,
    );
    canvas.drawCircle(
      orb,
      7,
      Paint()..color = BrandColor.primary.withValues(alpha: 0.18),
    );
    canvas.drawCircle(orb, 3.4, Paint()..color = const Color(0xFFFF8FA3));
    canvas.drawCircle(orb, 1.6, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DividerPainter extends CustomPainter {
  const _DividerPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height / 2;
    final line = Paint()
      ..color = BrandColor.primary.withValues(alpha: 0.55)
      ..strokeWidth = 1;

    canvas.drawLine(Offset(0, y), Offset(size.width * 0.38, y), line);
    canvas.drawLine(Offset(size.width * 0.62, y), Offset(size.width, y), line);

    final mid = Offset(size.width / 2, y);
    final fruit = Path()
      ..moveTo(mid.dx, mid.dy - 7)
      ..cubicTo(mid.dx + 7, mid.dy - 2, mid.dx + 6, mid.dy + 6, mid.dx, mid.dy + 8)
      ..cubicTo(mid.dx - 6, mid.dy + 6, mid.dx - 7, mid.dy - 2, mid.dx, mid.dy - 7);
    canvas.drawPath(fruit, Paint()..color = BrandColor.primary);

    canvas.drawLine(
      Offset(mid.dx - 2.2, mid.dy - 7.5),
      Offset(mid.dx, mid.dy - 10),
      Paint()
        ..color = BrandColor.primary
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      Offset(mid.dx + 2.2, mid.dy - 7.5),
      Offset(mid.dx, mid.dy - 10),
      Paint()
        ..color = BrandColor.primary
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MistPainter extends CustomPainter {
  const _MistPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFFFFF), Color(0xFFFDF8F7), Color(0xFFF6E8EC)],
          stops: [0.0, 0.55, 1.0],
        ).createShader(rect),
    );

    void wave(double top, Color color) {
      final path = Path()
        ..moveTo(0, top)
        ..cubicTo(
          size.width * 0.25,
          top - 28,
          size.width * 0.55,
          top + 36,
          size.width,
          top + 8,
        )
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)
        ..close();
      canvas.drawPath(path, Paint()..color = color);
    }

    wave(size.height * 0.78, const Color(0x22C41E3A));
    wave(size.height * 0.86, const Color(0x189B1230));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
