import 'package:flutter/material.dart';

import '../../common/brand_color.dart';
import 'disease_detection_view.dart';
import 'history_view.dart';
import 'profile_view.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BrandColor.background,

      bottomNavigationBar: _bottomNav(context),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Akaran Farm',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: BrandColor.darkText,
                          ),
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_rounded,
                              color: BrandColor.primary,
                              size: 15,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Sri Lanka',
                              style: TextStyle(
                                color: BrandColor.lightText,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.notifications_none_rounded,
                    color: BrandColor.darkText,
                  ),
                ],
              ),

              const SizedBox(height: 20),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFF0F3), Color(0xFFFFFAFB)],
                  ),
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: BrandColor.borderPink),
                ),
                child: const Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AI Powered',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Pomegranate Care',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: BrandColor.darkText,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Detect, treat and grow better',
                            style: TextStyle(
                              color: BrandColor.lightText,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text('🍎', style: TextStyle(fontSize: 70)),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 1.05,
                children: [
                  _dashboardCard(
                    context,
                    icon: Icons.camera_alt_rounded,
                    title: 'Start\nDetection',
                    subtitle: 'Analyze fruit',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const DiseaseDetectionView(),
                        ),
                      );
                    },
                  ),

                  _dashboardCard(
                    context,
                    icon: Icons.history_rounded,
                    title: 'History',
                    subtitle: 'View past results',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const HistoryView()),
                      );
                    },
                  ),

                  _dashboardCard(
                    context,
                    icon: Icons.bar_chart_rounded,
                    title: 'Reports',
                    subtitle: 'Monthly reports',
                    onTap: () {},
                  ),

                  _dashboardCard(
                    context,
                    icon: Icons.person_rounded,
                    title: 'Profile',
                    subtitle: 'Settings & language',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ProfileView()),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dashboardCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: BrandColor.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: BrandColor.primary, size: 30),

            const Spacer(),

            Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: BrandColor.darkText,
              ),
            ),

            const SizedBox(height: 4),

            Text(
              subtitle,
              style: const TextStyle(fontSize: 11, color: BrandColor.lightText),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bottomNav(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: 0,
      selectedItemColor: BrandColor.primary,
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
        BottomNavigationBarItem(
          icon: Icon(Icons.history_rounded),
          label: 'History',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.bar_chart_rounded),
          label: 'Reports',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline_rounded),
          label: 'Profile',
        ),
      ],
    );
  }
}
