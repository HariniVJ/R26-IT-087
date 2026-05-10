import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const PomegranateApp());
}

class PomegranateApp extends StatelessWidget {
  const PomegranateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pomegranate Farming',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.green,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}