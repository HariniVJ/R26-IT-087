import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'common/brand_color.dart';
import 'screens/splash_view/splash_view.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
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
        colorScheme: const ColorScheme.light(
          primary: BrandColor.primary,
          surface: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          centerTitle: false,
          elevation: 0,
          surfaceTintColor: Colors.white,
          iconTheme: IconThemeData(color: BrandColor.primary),
          titleTextStyle: TextStyle(
            color: BrandColor.darkText,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      home: const SplashView(),
    );
  }
}
