import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../common/brand_color.dart';
import '../l10n/app_strings.dart';
import '../screens/history/research_history_screen.dart';
import '../screens/irrigation/irrigation_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/reports/farm_dataset_report_screen.dart';
import '../screens/combined_scan_screen.dart';

enum AppNavTab { home, history, reports, profile }

class AppBottomNavBar extends StatelessWidget {
  final AppNavTab current;

  const AppBottomNavBar({super.key, required this.current});

  static const _red = Color(0xFFC1121F);
  static const _soft = Color(0xFF9CA3AF);
  static const _redLight = Color(0xFFFFF1F2);
  static const _textDark = Color(0xFF1F2937);
  static const _textMid = Color(0xFF6B7280);

  void _open(BuildContext context, Widget page, AppNavTab tab) {
    if (tab == current) return;
    if (tab == AppNavTab.home) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }
    final route = MaterialPageRoute(builder: (_) => page);
    if (current == AppNavTab.home) {
      Navigator.push(context, route);
      return;
    }
    Navigator.pushReplacement(context, route);
  }

  // Labels for the scan sheet (3 languages).
  static const _txt = {
    AppLang.en: {
      'scan_title': 'Scan a pomegranate',
      'scan_sub': 'Growth stage, quality and disease in one scan',
      'camera': 'Take photo',
      'gallery': 'Upload from gallery',
    },
    AppLang.ta: {
      'scan_title': 'மாதுளையை ஸ்கேன் செய்யவும்',
      'scan_sub': 'வளர்ச்சி நிலை, தரம் மற்றும் நோய் ஒரே ஸ்கேனில்',
      'camera': 'புகைப்படம் எடு',
      'gallery': 'கேலரியில் இருந்து பதிவேற்று',
    },
    AppLang.si: {
      'scan_title': 'දෙළුමක් ස්කෑන් කරන්න',
      'scan_sub': 'වර්ධන අවධිය, ගුණාත්මකභාවය සහ රෝග එකම ස්කෑන් එකකින්',
      'camera': 'ඡායාරූපයක් ගන්න',
      'gallery': 'ගැලරියෙන් උඩුගත කරන්න',
    },
  };

  static String _st(String key) =>
      _txt[LanguageController.instance.lang]?[key] ??
      _txt[AppLang.en]![key] ??
      key;

  /// Centre scan button → camera / gallery → combined result screen.
  Future<void> _openScan(BuildContext context) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _st('scan_title'),
                style: const TextStyle(
                  color: _textDark,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _st('scan_sub'),
                style: const TextStyle(color: _textMid, fontSize: 12.5),
              ),
              const SizedBox(height: 16),
              _sheetOption(
                ctx,
                Icons.camera_alt_rounded,
                _st('camera'),
                ImageSource.camera,
              ),
              const SizedBox(height: 10),
              _sheetOption(
                ctx,
                Icons.photo_library_rounded,
                _st('gallery'),
                ImageSource.gallery,
              ),
            ],
          ),
        ),
      ),
    );
    if (source == null) return;

    final picked = await ImagePicker().pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1024,
    );
    if (picked == null || !context.mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CombinedScanScreen(image: File(picked.path)),
      ),
    );
  }

  Widget _sheetOption(
    BuildContext ctx,
    IconData icon,
    String label,
    ImageSource source,
  ) {
    return Material(
      color: _redLight,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.pop(ctx, source),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: _red, size: 19),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: _textDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: _red),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LanguageController.instance,
      builder: (context, _) {
        return Container(
          height: 78,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 18,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                label: t('home'),
                active: current == AppNavTab.home,
                onTap: () =>
                    _open(context, const SizedBox.shrink(), AppNavTab.home),
              ),
              _NavItem(
                icon: Icons.history_rounded,
                label: t('history'),
                active: current == AppNavTab.history,
                onTap: () => _open(
                  context,
                  const ResearchHistoryScreen(),
                  AppNavTab.history,
                ),
              ),
              _ScanButton(onTap: () => _openScan(context)),
              _NavItem(
                icon: Icons.bar_chart_rounded,
                label: t('reports'),
                active: current == AppNavTab.reports,
                onTap: () => _open(
                  context,
                  const FarmDatasetReportScreen(),
                  AppNavTab.reports,
                ),
              ),
              _NavItem(
                icon: Icons.person_outline_rounded,
                label: t('profile'),
                active: current == AppNavTab.profile,
                onTap: () =>
                    _open(context, const ProfileScreen(), AppNavTab.profile),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    this.active = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? BrandColor.primary : AppBottomNavBar._soft;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: active ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanButton extends StatelessWidget {
  final VoidCallback? onTap;

  const _ScanButton({this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          color: BrandColor.primary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppBottomNavBar._red.withOpacity(0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Icon(
          Icons.crop_free_rounded,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }
}
