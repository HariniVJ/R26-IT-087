import 'dart:async';
import 'package:flutter/material.dart';

import '../../common/brand_color.dart';
import '../dashboard_screen.dart';
import '../auth/onboarding_auth_flow.dart';
import '../../services/auth/auth_service.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView>
    with SingleTickerProviderStateMixin {
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
          MaterialPageRoute(
            builder: (_) => AuthService.instance.isLoggedIn
                ? const DashboardScreen()
                : const OnboardingAuthFlow(),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: _scaleAnim,
                child: Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF4F6),
                    borderRadius: BorderRadius.circular(40),
                    border: Border.all(color: const Color(0xFFFFD7DE)),
                    boxShadow: [
                      BoxShadow(
                        color: BrandColor.primary.withOpacity(0.15),
                        blurRadius: 30,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text('🍎', style: TextStyle(fontSize: 64)),
                  ),
                ),
              ),

              const SizedBox(height: 36),

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

              Container(
                width: 48,
                height: 3,
                decoration: BoxDecoration(
                  color: BrandColor.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),

              const SizedBox(height: 60),

              const SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(
                  color: BrandColor.primary,
                  strokeWidth: 2.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
