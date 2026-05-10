// lib/theme/app_colors.dart
// ALL colors used across the entire app — change here, updates everywhere

import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Brand / Pomegranate palette ───────────────────────────────────────────
  static const crimson = Color(0xFF8B1A2F); // deep pomegranate red
  static const rose = Color(0xFFD44060); // light rose border
  static const darkBg = Color(0xFF1A0408); // dark background tint

  // ── Glass card settings ───────────────────────────────────────────────────
  // These control the transparency of ALL glass cards in the app
  static const glassBase = crimson; // tint color for all glass
  static const glassBorder = rose; // border color for all glass
  static const glassOpacity = 0.48; // ← lower = more transparent
  static const borderOpacity = 0.30; // ← border transparency

  // ── Module / component button colors ─────────────────────────────────────
  static const soilColor = Color(0xFFBF8F0C); // amber/gold — soil
  static const growthColor = Color(0xFFF05C5C); // red — fruit growth
  static const diseaseColor = Color(0xFF0CBF80); // teal — disease
  static const gradingColor = Color(0xFF8C0CBF); // purple — quality grading

  // ── Overlay gradient (on top of background image) ────────────────────────
  static final overlayTop = darkBg.withOpacity(0.60);
  static final overlayMid = const Color(0xFF3D0C18).withOpacity(0.25);
  static final overlayBottom = darkBg.withOpacity(0.68);

  // ── Text ──────────────────────────────────────────────────────────────────
  static const textWhite = Colors.white;
  static final textWhiteSoft = Colors.white.withOpacity(0.70);
  static final textWhiteFaint = Colors.white.withOpacity(0.55);
  static final textWhiteHint = Colors.white.withOpacity(0.45);
}
