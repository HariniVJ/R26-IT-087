import 'package:flutter/material.dart';

import '../../common/brand_color.dart';
import '../../common/common_widgets.dart';
import '../../services/auth_service.dart';
import '../dashboard_screen.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  Map<String, String> _errors = {};
  String? _formError;
  bool _loading = false;

  Future<void> _register() async {
    final validation = AuthService.instance.validateRegistration(
      fullName: _nameController.text,
      mobile: _mobileController.text,
      email: _emailController.text,
      password: _passwordController.text,
      confirmPassword: _confirmController.text,
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

    final error = await AuthService.instance.register(
      fullName: _nameController.text,
      mobile: _mobileController.text,
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

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const DashboardScreen()),
      (_) => false,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
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
              const SizedBox(height: 28),
              const Text(
                'Create Account',
                style: TextStyle(
                  color: BrandColor.darkText,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Create a separate farmer account. Predictions still run on this phone after you sign in once.',
                style: TextStyle(color: Color(0xFF6B7280), fontSize: 15),
              ),
              const SizedBox(height: 32),
              AppTextField(
                label: 'Full Name',
                controller: _nameController,
                icon: Icons.badge_outlined,
                errorText: _errors['fullName'],
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Mobile Number',
                controller: _mobileController,
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                errorText: _errors['mobile'],
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Email',
                controller: _emailController,
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                errorText: _errors['email'],
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Password',
                controller: _passwordController,
                icon: Icons.lock_outline,
                obscure: true,
                errorText: _errors['password'],
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Confirm Password',
                controller: _confirmController,
                icon: Icons.lock_reset,
                obscure: true,
                errorText: _errors['confirmPassword'],
              ),
              if (_formError != null) ...[
                const SizedBox(height: 16),
                AppBanner(
                  message: _formError!,
                  color: BrandColor.primary,
                  icon: Icons.error_outline,
                ),
              ],
              const SizedBox(height: 28),
              AppPrimaryButton(
                label: 'Create Account',
                icon: Icons.person_add_alt_1,
                isLoading: _loading,
                onPressed: _register,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
