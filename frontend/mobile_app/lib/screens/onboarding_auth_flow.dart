import 'package:flutter/material.dart';

import './dashboard_screen.dart';
import '../../common/brand_color.dart';

const _red = BrandColor.primary;
const _redSoft = Color(0xFFFFEEF3);
const _textDark = Color(0xFF1F2937);
const _textSoft = Color(0xFF6B7280);

class OnboardingAuthFlow extends StatefulWidget {
  const OnboardingAuthFlow({super.key});

  @override
  State<OnboardingAuthFlow> createState() => _OnboardingAuthFlowState();
}

class _OnboardingAuthFlowState extends State<OnboardingAuthFlow> {
  final PageController _controller = PageController();

  int _index = 0;

  final pages = const [
    _IntroData(
      emoji: '🍎',
      title: 'AI Disease Detection',
      subtitle:
          'Detect pomegranate diseases instantly using intelligent AI analysis.',
    ),
    _IntroData(
      emoji: '🌱',
      title: 'Smart Farming',
      subtitle:
          'Get irrigation, fertilizer and crop management recommendations.',
    ),
    _IntroData(
      emoji: '📊',
      title: 'Quality Grading',
      subtitle:
          'Analyze fruit quality with confidence score and recommendations.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: pages.length,
                onPageChanged: (i) {
                  setState(() => _index = i);
                },
                itemBuilder: (_, i) {
                  final item = pages[i];

                  return Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 210,
                          height: 210,
                          decoration: BoxDecoration(
                            color: _redSoft,
                            borderRadius: BorderRadius.circular(40),
                            boxShadow: [
                              BoxShadow(
                                color: _red.withOpacity(0.10),
                                blurRadius: 24,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              item.emoji,
                              style: const TextStyle(fontSize: 90),
                            ),
                          ),
                        ),

                        const SizedBox(height: 50),

                        Text(
                          item.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: _textDark,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                          ),
                        ),

                        const SizedBox(height: 16),

                        Text(
                          item.subtitle,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: _textSoft,
                            fontSize: 15,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                pages.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _index == i ? 26 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _index == i ? _red : _red.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 28),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    },
                    child: const Text(
                      'Skip',
                      style: TextStyle(
                        color: _textSoft,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),

                  const Spacer(),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _red,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 26,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    onPressed: () {
                      if (_index == pages.length - 1) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                        );
                      } else {
                        _controller.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                    child: Text(
                      _index == pages.length - 1 ? 'Get Started' : 'Next',
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

class _IntroData {
  final String emoji;
  final String title;
  final String subtitle;

  const _IntroData({
    required this.emoji,
    required this.title,
    required this.subtitle,
  });
}

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 50),

              const Text(
                'Welcome Back 👋',
                style: TextStyle(
                  color: _textDark,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                'Login to continue smart farming',
                style: TextStyle(color: _textSoft, fontSize: 15),
              ),

              const SizedBox(height: 40),

              _field('Email'),
              const SizedBox(height: 18),
              _field('Password', obscure: true),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _red,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const DashboardScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    'Login',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                ),
              ),

              const SizedBox(height: 26),

              Center(
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SignupScreen()),
                    );
                  },
                  child: RichText(
                    text: const TextSpan(
                      children: [
                        TextSpan(
                          text: 'Don\'t have an account? ',
                          style: TextStyle(color: _textSoft),
                        ),
                        TextSpan(
                          text: 'Sign Up',
                          style: TextStyle(
                            color: _red,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(String hint, {bool obscure = false}) {
    return TextField(
      obscureText: obscure,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: _redSoft,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),

              const Text(
                'Create Account ✨',
                style: TextStyle(
                  color: _textDark,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                'Start your smart farming journey',
                style: TextStyle(color: _textSoft, fontSize: 15),
              ),

              const SizedBox(height: 40),

              _field('Full Name'),
              const SizedBox(height: 18),
              _field('Email'),
              const SizedBox(height: 18),
              _field('Password', obscure: true),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _red,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const DashboardScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    'Create Account',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(String hint, {bool obscure = false}) {
    return TextField(
      obscureText: obscure,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: _redSoft,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
