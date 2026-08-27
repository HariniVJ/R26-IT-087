import 'package:flutter/material.dart';

import '../../common/brand_color.dart';
import '../../common/common_widgets.dart';
import '../../services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  Map<String, String> _errors = {};
  String? _formError;
  String? _success;
  bool _loading = false;

  Future<void> _send() async {
    final validation = AuthService.instance.validatePasswordReset(
      email: _emailController.text,
    );
    if (!validation.isValid) {
      setState(() {
        _errors = validation.fieldErrors;
        _formError = null;
        _success = null;
      });
      return;
    }

    setState(() {
      _loading = true;
      _errors = {};
      _formError = null;
      _success = null;
    });

    final error = await AuthService.instance.sendPasswordReset(
      _emailController.text,
    );

    if (!mounted) return;
    setState(() {
      _loading = false;
      if (error != null) {
        _formError = error;
      } else {
        _success = 'Password reset email sent. Check your inbox.';
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Reset Password')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter the email you used to register. Firebase will send a reset link.',
                style: TextStyle(color: Color(0xFF6B7280), fontSize: 15),
              ),
              const SizedBox(height: 24),
              AppTextField(
                label: 'Email',
                controller: _emailController,
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                errorText: _errors['email'],
              ),
              if (_formError != null) ...[
                const SizedBox(height: 16),
                AppBanner(
                  message: _formError!,
                  color: BrandColor.primary,
                  icon: Icons.error_outline,
                ),
              ],
              if (_success != null) ...[
                const SizedBox(height: 16),
                AppBanner(
                  message: _success!,
                  color: Colors.green.shade800,
                  icon: Icons.check_circle_outline,
                ),
              ],
              const SizedBox(height: 28),
              AppPrimaryButton(
                label: 'Send Reset Email',
                icon: Icons.mark_email_read_outlined,
                isLoading: _loading,
                onPressed: _send,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
