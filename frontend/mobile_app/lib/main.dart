import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'common/brand_color.dart';
import 'firebase_options.dart';
import 'l10n/app_strings.dart';
import 'screens/splash_view/splash_view.dart';
import 'services/auth/auth_service.dart';
import 'screens/disease/disease_view.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_handler/permission_handler.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }

    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
    
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }

  await Permission.notification.request();
  await AuthService.instance.loadSession();
  await LanguageController.instance.load();

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
    return ListenableBuilder(
      listenable: LanguageController.instance,
      builder: (context, _) {
        return MaterialApp(
          title: 'Pomegranate Farming',
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
            useMaterial3: true,
          ),
          home: const SplashView(),
        );
      },
    );
  }
}
