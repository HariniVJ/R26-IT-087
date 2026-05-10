// frontend/mobile_app/lib/main.dart

import 'package:flutter/material.dart';
import 'screens/capture_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PomScanApp());
}

class PomScanApp extends StatelessWidget {
  const PomScanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PomScan',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2D6A4F),
        ),
        useMaterial3: true,
      ),
      home: const CaptureScreen(),
    );
  }
}