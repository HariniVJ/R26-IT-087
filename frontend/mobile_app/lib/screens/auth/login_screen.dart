import 'package:flutter/material.dart';

import '../../common/brand_color.dart';
import '../../common/common_widgets.dart';
import '../../services/auth_service.dart';
import '../dashboard_screen.dart';
import 'registration_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  Map<String, String> _errors = {};
  String? _formError;
  bool _loading = false;

  Future<void> _login() async {
    final validation = AuthService.instance.validateLogin(
      identifier: _identifierController.text,
      password: _passwordController.text,
    );

    if (!validation.isValid) {
      setState(() {
        _errors = validation.fieldErrors;
        _formError = null;
      });
      return;
    }

    setState(() {
      _loading = true;
      _errors = {};
      _formError = null;
    });

    final error = await AuthService.instance.login(
      identifier: _identifierController.text,
      password: _passwordController.text,
    );

    if (!mounted) return;
    if (error != null) {
      setState(() {
        _loading = false;
        _formError = error;
      });
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const DashboardScreen()),
    );
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

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
                'Welcome Back',
                style: TextStyle(
                  color: BrandColor.darkText,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Login once on this phone. You can use the app later without internet.',
                style: TextStyle(color: Color(0xFF6B7280), fontSize: 15),
              ),
              const SizedBox(height: 40),
              AppTextField(
                label: 'Email or Mobile Number',
                controller: _identifierController,
                icon: Icons.person_outline,
                errorText: _errors['identifier'],
              ),
              const SizedBox(height: 18),
              AppTextField(
                label: 'Password',
                controller: _passwordController,
                icon: Icons.lock_outline,
                obscure: true,
                errorText: _errors['password'],
              ),
              if (_formError != null) ...[
                const SizedBox(height: 16),
                AppBanner(
                  message: _formError!,
                  color: BrandColor.primary,
                  icon: Icons.error_outline,
                ),
              ],
              const SizedBox(height: 30),
              AppPrimaryButton(
                label: 'Login',
                icon: Icons.login,
                isLoading: _loading,
                onPressed: _login,
              ),
              const SizedBox(height: 26),
              Center(
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RegistrationScreen()),
                    );
                  },
                  child: const Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: "Don't have an account? ",
                          style: TextStyle(color: Color(0xFF6B7280)),
                        ),
                        TextSpan(
                          text: 'Sign Up',
                          style: TextStyle(
                            color: BrandColor.primary,
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
}
