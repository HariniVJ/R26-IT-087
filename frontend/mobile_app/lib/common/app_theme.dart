import 'package:flutter/material.dart';
import 'brand_color.dart';

// ─────────────────────────────────────────────────────────────────────────────
// GLOBAL THEME NOTIFIER
// No extra packages needed — any widget can read or toggle the theme via:
//   appThemeNotifier.value = ThemeMode.light / ThemeMode.dark
// ─────────────────────────────────────────────────────────────────────────────
final appThemeNotifier = ValueNotifier<ThemeMode>(ThemeMode.dark);

class AppTheme {
  // ── Dark ThemeData ─────────────────────────────────────────
  static ThemeData dark() => ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    scaffoldBackgroundColor: const Color(0xFF0D0507),
    colorScheme: ColorScheme.dark(
      primary: BrandColor.primary,
      secondary: BrandColor.secondary,
      surface: const Color(0xFF1A050A),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
    ),
    dialogBackgroundColor: const Color(0xFF1A050A),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: BrandColor.primary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  );

  // ── Light ThemeData ────────────────────────────────────────
  static ThemeData light() => ThemeData(
    brightness: Brightness.light,
    useMaterial3: true,
    scaffoldBackgroundColor: const Color(0xFFFFF0F3),
    colorScheme: ColorScheme.light(
      primary: BrandColor.primary,
      secondary: BrandColor.secondary,
      surface: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
    ),
    dialogBackgroundColor: Colors.white,
    snackBarTheme: SnackBarThemeData(
      backgroundColor: BrandColor.primary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  );
}
