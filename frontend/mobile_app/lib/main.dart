import 'package:flutter/material.dart';
import 'screens/quality_grading_screen.dart';

void main() {
  runApp(const AIFarmingApp());
}

class AIFarmingApp extends StatelessWidget {
  const AIFarmingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Farming System',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8B1A2F),
        ),
        useMaterial3: true,
      ),
      home: QualityGradingScreen(),
    );
  }
}