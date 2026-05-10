import 'package:flutter/material.dart';

class BrandColor {
  static const Color primary = Color(0xFF9B1230);
  static const Color secondary = Color(0xFFE73763);
  static const Color accent = Color(0xFFFF7F9F);
  static const Color green = Color(0xFF2DBE72);

  // White background theme
  static const Color background = Color(0xFFFAFAFA);
  static const Color bgDeep = Color(0xFFF5F5F5);

  static const Color card = Color(0xFFFFFFFF);
  static const Color cardDark = Color(0xFFF8F8F8);
  static const Color cardLight = Color(0xFFFFFFFF);

  static const Color buttonPink = Color(0xFF9B1230);
  static const Color buttonDarkPink = Color(0xFF7A0E25);

  static Color get glassFill => Colors.white;
  static Color get glassBorder => const Color(0xFFE8E8E8);
  static Color get glassSheen => Colors.white.withOpacity(0.80);

  static Color get glassWarmFill => Colors.white;
  static Color get glassWarmBorder => const Color(0xFFFFD7DE);

  // Text colors for white background
  static const Color darkText = Color(0xFF1A1A2E);
  static Color get lightText => const Color(0xFF6B7280);
  static Color get softText => const Color(0xFF9CA3AF);

  static const Color titleText = Color(0xFF1A1A2E);
  static Color get subtitleText => const Color(0xFF6B7280);

  static Color get successFill => green.withOpacity(0.10);
  static Color get successBorder => green.withOpacity(0.25);
  static Color get dangerFill => primary.withOpacity(0.08);
  static Color get dangerBorder => primary.withOpacity(0.20);

  static Color get softShadow => const Color(0xFF000000).withOpacity(0.08);

  // Border colors
  static Color get borderLight => const Color(0xFFE5E7EB);
  static Color get borderPink => const Color(0xFFFFD7DE);
}

class BrandTexts {
  static const String appName = "Pomegranate Care";
  static const String subTitle = "AI-Based Intelligent Farming System";
}
