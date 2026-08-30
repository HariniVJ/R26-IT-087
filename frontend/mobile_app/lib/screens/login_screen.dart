import 'package:flutter/material.dart';

import '../../common/brand_color.dart';
import '../../common/common_widgets.dart';
import '../../services/auth/auth_service.dart';
import 'dashboard_screen.dart';
import 'forgot_password_screen.dart';
import 'registration_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  Map<String, String> _errors = {};
  String? _formError;
  bool _loading = false;

  Future<void> _login() async {
    final validation = AuthService.instance.validateLogin(
      email: _emailController.text,
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
      email: _emailController.text,
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
    _emailController.dispose();
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
                'Sign in with your farmer account. Irrigation and fertilizer predictions still run on this phone if the internet drops.',
                style: TextStyle(color: Color(0xFF6B7280), fontSize: 15),
              ),
              const SizedBox(height: 40),
              AppTextField(
                label: 'Email',
                controller: _emailController,
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                errorText: _errors['email'],
              ),
              const SizedBox(height: 18),
              AppTextField(
                label: 'Password',
                controller: _passwordController,
                icon: Icons.lock_outline,
                obscure: true,
                errorText: _errors['password'],
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ForgotPasswordScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    'Forgot password?',
                    style: TextStyle(
                      color: BrandColor.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              if (_formError != null) ...[
                const SizedBox(height: 8),
                AppBanner(
                  message: _formError!,
                  color: BrandColor.primary,
                  icon: Icons.error_outline,
                ),
              ],
              const SizedBox(height: 18),
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
