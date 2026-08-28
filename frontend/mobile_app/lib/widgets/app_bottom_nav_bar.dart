import 'package:flutter/material.dart';

import '../common/brand_color.dart';
import '../l10n/app_strings.dart';
import '../screens/history/research_history_screen.dart';
import '../screens/irrigation/irrigation_screen.dart';
import '../screens/profile_view/profile_view.dart';
import '../screens/reports/research_reports_screen.dart';

enum AppNavTab { home, history, reports, profile }

class AppBottomNavBar extends StatelessWidget {
  final AppNavTab current;

  const AppBottomNavBar({super.key, required this.current});

  static const _red = Color(0xFFC1121F);
  static const _soft = Color(0xFF9CA3AF);

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

  @override
  Widget build(BuildContext context) {
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
            onTap: () => _open(context, const SizedBox.shrink(), AppNavTab.home),
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
          _ScanButton(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const IrrigationScreen()),
              );
            },
          ),
          _NavItem(
            icon: Icons.bar_chart_rounded,
            label: t('reports'),
            active: current == AppNavTab.reports,
            onTap: () => _open(
              context,
              const ResearchReportsScreen(),
              AppNavTab.reports,
            ),
          ),
          _NavItem(
            icon: Icons.person_outline_rounded,
            label: t('profile'),
            active: current == AppNavTab.profile,
            onTap: () => _open(context, const ProfileView(), AppNavTab.profile),
          ),
        ],
      ),
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
  final VoidCallback onTap;

  const _ScanButton({required this.onTap});

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
        child: const Icon(Icons.crop_free_rounded, color: Colors.white, size: 28),
      ),
    );
  }
}
