import 'package:flutter/material.dart';

class BrandColor {
  static const Color primary = Color(0xFF9B1B30);
  static const Color secondary = Color(0xFFC0294A);
  static const Color accent = Color(0xFFF4A0B0);
  static const Color green = Color(0xFF3DBE78);

  static const Color background = Color(0xFF0D0507);
  static const Color bgDeep = Color(0xFF1A050A);

  // Forest image style glass
  static Color get glassFill => const Color(0xFF0F1A14).withOpacity(0.34);
  static Color get glassBorder => Colors.white.withOpacity(0.30);
  static Color get glassSheen => Colors.white.withOpacity(0.20);

  static Color get glassWarmFill => Colors.white.withOpacity(0.13);
  static Color get glassWarmBorder => Colors.white.withOpacity(0.32);

  static const Color darkText = Color(0xFFFFFFFF);
  static Color get lightText => Colors.white.withOpacity(0.82);
  static Color get softText => Colors.white.withOpacity(0.58);

  static Color get successFill => green.withOpacity(0.15);
  static Color get successBorder => green.withOpacity(0.28);
  static Color get dangerFill => primary.withOpacity(0.15);
  static Color get dangerBorder => primary.withOpacity(0.28);

  static Color get orb1 => primary.withOpacity(0.22);
  static Color get orb2 => secondary.withOpacity(0.16);
  static Color get orb3 => accent.withOpacity(0.10);

  static const Color card = Color(0xFF1A050A);
}

class BrandTexts {
  static const String appName = "Pomegranate Care";
  static const String subTitle = "AI-Based Intelligent Farming System";
}
