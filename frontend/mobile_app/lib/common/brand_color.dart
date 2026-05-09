import 'package:flutter/material.dart';

class BrandColor {
  // ── Core Brand ─────────────────────────────────────────────
  static const Color primary = Color(0xFF9B1B30);
  static const Color secondary = Color(0xFFC0294A);
  static const Color accent = Color(0xFFF4A0B0);
  static const Color green = Color(0xFF3DBE78);

  // ── App Backgrounds ────────────────────────────────────────
  static const Color background = Color(0xFF0D0507);
  static const Color bgDeep = Color(0xFF1A050A);

  // ── Glass Surfaces (getters allow .withOpacity) ────────────
  static Color get glassFill => Colors.white.withOpacity(0.09);
  static Color get glassBorder => Colors.white.withOpacity(0.18);
  static Color get glassSheen => Colors.white.withOpacity(0.10);
  static Color get glassWarmFill => const Color(0xFFB42840).withOpacity(0.18);
  static Color get glassWarmBorder => const Color(0xFFFF6478).withOpacity(0.25);

  // ── Text Hierarchy ─────────────────────────────────────────
  static const Color darkText = Color(0xFFFFFFFF);
  static Color get lightText => const Color(0xFFFFE6EB).withOpacity(0.80);
  static Color get softText => const Color(0xFFFFC8D2).withOpacity(0.55);

  // ── Semantic Glass Fills ───────────────────────────────────
  static Color get successFill => const Color(0xFF3DBE78).withOpacity(0.15);
  static Color get successBorder => const Color(0xFF3DBE78).withOpacity(0.28);
  static Color get dangerFill => primary.withOpacity(0.15);
  static Color get dangerBorder => primary.withOpacity(0.28);

  // ── Background Orb Colors ──────────────────────────────────
  static Color get orb1 => primary.withOpacity(0.28);
  static Color get orb2 => const Color(0xFFC8294A).withOpacity(0.18);
  static Color get orb3 => accent.withOpacity(0.12);

  // ── Legacy compatibility ───────────────────────────────────
  static const Color card = Color(0xFF1A050A);
}

class BrandTexts {
  static const String appName = "Pomegranate Care";
  static const String subTitle = "AI-Based Intelligent Farming System";
}
