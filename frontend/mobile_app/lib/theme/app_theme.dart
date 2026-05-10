// COMMON FILE — shared by all 4 members
// lib/theme/app_theme.dart
// Import this instead of hardcoding colors/styles anywhere in the app.

import 'package:flutter/material.dart';

// ── Brand Palette ─────────────────────────────────────────────────────────────
class AppColors {
  AppColors._();

  // Pomegranate-inspired primaries
  static const crimson        = Color(0xFF8B1A2F);
  static const deepCrimson    = Color(0xFF5C0E1E);
  static const rosePetal      = Color(0xFFD4547A);
  static const blush          = Color(0xFFF2C4CE);
  static const palePink       = Color(0xFFFCEEF1);

  // Quality badge colours
  static const highGreen      = Color(0xFF1B7A4A);
  static const highGreenLight = Color(0xFFD6F5E5);
  static const medAmber       = Color(0xFFB86E00);
  static const medAmberLight  = Color(0xFFFFF0CC);
  static const lowRed         = Color(0xFFC0392B);
  static const lowRedLight    = Color(0xFFFFE5E2);

  // Neutral
  static const surface        = Color(0xFFFDF5F6);
  static const card           = Color(0xFFFFFFFF);
  static const textPrimary    = Color(0xFF1A0A0E);
  static const textSecondary  = Color(0xFF7A4A54);
  static const divider        = Color(0xFFEDD8DC);

  // Chart line colours (3 quality levels)
  static const chartHigh      = Color(0xFF1B7A4A);
  static const chartMed       = Color(0xFFE6A817);
  static const chartLow       = Color(0xFFE05252);
}

// ── Quality helpers ───────────────────────────────────────────────────────────
class QualityTheme {
  QualityTheme._();

  static Color bgColor(String quality) {
    switch (quality) {
      case 'high_quality':   return AppColors.highGreenLight;
      case 'medium_quality': return AppColors.medAmberLight;
      default:               return AppColors.lowRedLight;
    }
  }

  static Color fgColor(String quality) {
    switch (quality) {
      case 'high_quality':   return AppColors.highGreen;
      case 'medium_quality': return AppColors.medAmber;
      default:               return AppColors.lowRed;
    }
  }

  static String label(String quality) {
    switch (quality) {
      case 'high_quality':   return 'High Quality';
      case 'medium_quality': return 'Medium Quality';
      default:               return 'Low Quality';
    }
  }

  static String emoji(String quality) {
    switch (quality) {
      case 'high_quality':   return '🏆';
      case 'medium_quality': return '🧃';
      default:               return '🌱';
    }
  }

  static IconData icon(String quality) {
    switch (quality) {
      case 'high_quality':   return Icons.verified_rounded;
      case 'medium_quality': return Icons.info_rounded;
      default:               return Icons.eco_rounded;
    }
  }
}

// ── Shared Text Styles ────────────────────────────────────────────────────────
class AppText {
  AppText._();

  static const displayLarge = TextStyle(
    fontFamily: 'Georgia',
    fontSize: 28, fontWeight: FontWeight.w700,
    color: AppColors.textPrimary, height: 1.2,
  );

  static const titleMedium = TextStyle(
    fontFamily: 'Georgia',
    fontSize: 18, fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const bodyMedium = TextStyle(
    fontSize: 14, color: AppColors.textSecondary, height: 1.5,
  );

  static const labelSmall = TextStyle(
    fontSize: 11, fontWeight: FontWeight.w600,
    color: AppColors.textSecondary, letterSpacing: 0.8,
  );
}

// ── Shared Decorations ────────────────────────────────────────────────────────
class AppDecorations {
  AppDecorations._();

  static BoxDecoration glassCard({Color? border}) => BoxDecoration(
    color: Colors.white.withOpacity(0.82),
    borderRadius: BorderRadius.circular(20),
    border: Border.all(
      color: border ?? AppColors.blush.withOpacity(0.6), width: 1.2,
    ),
    boxShadow: [
      BoxShadow(
        color: AppColors.crimson.withOpacity(0.08),
        blurRadius: 20, offset: const Offset(0, 6),
      ),
    ],
  );

  static BoxDecoration gradientBg() => const BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft, end: Alignment.bottomRight,
      colors: [Color(0xFFFDF0F3), Color(0xFFF5E8EB), Color(0xFFFDF5F6)],
    ),
  );
}

// ── Shared Widgets ────────────────────────────────────────────────────────────

/// Pomegranate-styled primary button used across all screens
class AppButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color? color;

  const AppButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.isLoading = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final bg = color ?? AppColors.crimson;
    return SizedBox(
      width: double.infinity, height: 52,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: Colors.white,
          disabledBackgroundColor: bg.withOpacity(0.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(
                width: 22, height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 8)],
                  Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                ],
              ),
      ),
    );
  }
}

/// Quality badge pill chip
class QualityBadge extends StatelessWidget {
  final String quality;
  const QualityBadge({super.key, required this.quality});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: QualityTheme.bgColor(quality),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '${QualityTheme.emoji(quality)} ${QualityTheme.label(quality)}',
        style: TextStyle(
          fontSize: 12, fontWeight: FontWeight.w700,
          color: QualityTheme.fgColor(quality),
        ),
      ),
    );
  }
}