import 'dart:async';
import 'package:flutter/material.dart';
import '../../common/brand_color.dart';
import '../../common/glass_container.dart';
import '../dashboard_view/dashboard_view.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView>
    with SingleTickerProviderStateMixin {
  // ── Animation (logic unchanged) ───────────────────────────
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnim = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));
    _scaleAnim = Tween<double>(
      begin: 0.7,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

    _controller.forward();

    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DashboardView()),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ── UI ────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BrandColor.background,
      body: Stack(
        children: [
          // Layered dark background with orbs
          const DarkBackground(),

          // Animated content
          FadeTransition(
            opacity: _fadeAnim,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Glass logo circle
                  ScaleTransition(
                    scale: _scaleAnim,
                    child: GlassContainer(
                      borderRadius: BorderRadius.circular(40),
                      padding: const EdgeInsets.all(30),
                      fillColor: BrandColor.glassWarmFill,
                      borderColor: BrandColor.glassWarmBorder,
                      blur: 18,
                      child: const Text('🍎', style: TextStyle(fontSize: 64)),
                    ),
                  ),

                  const SizedBox(height: 36),

                  // App name
                  const Text(
                    BrandTexts.appName,
                    style: TextStyle(
                      color: BrandColor.darkText,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    BrandTexts.subTitle,
                    style: TextStyle(color: BrandColor.lightText, fontSize: 14),
                  ),

                  const SizedBox(height: 20),

                  // Thin divider line
                  Container(
                    width: 48,
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          BrandColor.accent.withOpacity(0.6),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 60),

                  // Loader
                  SizedBox(
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(
                      color: BrandColor.accent.withOpacity(0.55),
                      strokeWidth: 2.5,
                    ),
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
