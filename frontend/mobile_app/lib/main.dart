import 'package:flutter/material.dart';
import 'common/brand_color.dart';
import 'screens/splash_view/splash_view.dart';

void main() {
  runApp(const PomegranateApp());
}

class PomegranateApp extends StatelessWidget {
  const PomegranateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pomegranate Disease Detection',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: BrandColor.background,
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: BrandColor.primary,
          centerTitle: true,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      home: const SplashView(),
    );
  }
}
