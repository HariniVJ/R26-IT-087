import 'package:flutter/material.dart';

import '../../common/brand_color.dart';
import './dashboard_view.dart';
import './history_view.dart';
import './disease_detection_view.dart';
import './monthly_report_view.dart';
import './profile_view.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    DashboardView(),
    HistoryView(),
    DiseaseDetectionView(),
    MonthlyReportView(),
    ProfileView(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BrandColor.background,
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: _BottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _BottomNavBar({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                label: 'Home',
                isActive: currentIndex == 0,
                onTap: () => onTap(0),
              ),
              _NavItem(
                icon: Icons.history_outlined,
                activeIcon: Icons.history_rounded,
                label: 'History',
                isActive: currentIndex == 1,
                onTap: () => onTap(1),
              ),
              // Center FAB scan button
              GestureDetector(
                onTap: () => onTap(2),
                child: Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: BrandColor.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: BrandColor.primary.withOpacity(0.40),
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
              ),
              _NavItem(
                icon: Icons.bar_chart_outlined,
                activeIcon: Icons.bar_chart_rounded,
                label: 'Reports',
                isActive: currentIndex == 3,
                onTap: () => onTap(3),
              ),
              _NavItem(
                icon: Icons.person_outline_rounded,
                activeIcon: Icons.person_rounded,
                label: 'Profile',
                isActive: currentIndex == 4,
                onTap: () => onTap(4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive ? BrandColor.primary : BrandColor.softText,
              size: 24,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? BrandColor.primary : BrandColor.softText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
