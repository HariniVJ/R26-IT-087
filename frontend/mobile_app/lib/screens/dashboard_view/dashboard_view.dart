import 'package:flutter/material.dart';

import '../../common/brand_color.dart';
import '../disease_detection_view/disease_detection_view.dart';
import '../history_view/history_view.dart';
import '../info_detail_view/info_detail_view.dart';
import '../monthly_report_view/monthly_report_view.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} '
        '${now.hour >= 12 ? 'PM' : 'AM'}';
    final months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final weekdays = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final dateStr =
        '${weekdays[now.weekday]}, ${now.day} ${months[now.month]} ${now.year}';

    return Scaffold(
      backgroundColor: BrandColor.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile card matching the image
              _ProfileCard(timeStr: timeStr, dateStr: dateStr),
              const SizedBox(height: 28),

              // Title
              const Text(
                'Pomegranate Care',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: BrandColor.darkText,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'AI-Based Intelligent Farming System',
                style: TextStyle(fontSize: 13, color: BrandColor.lightText),
              ),
              const SizedBox(height: 24),

              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.78,
                children: [
                  _HomeComponentCard(
                    icon: Icons.search_rounded,
                    title: 'Start\nDetection',
                    subtitle: 'Upload fruit image',
                    color: BrandColor.primary,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const DiseaseDetectionView(),
                      ),
                    ),
                  ),
                  _HomeComponentCard(
                    icon: Icons.history_rounded,
                    title: 'Detection\nHistory',
                    subtitle: 'View past results',
                    color: BrandColor.green,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const HistoryView()),
                    ),
                  ),
                  _HomeComponentCard(
                    icon: Icons.bar_chart_rounded,
                    title: 'Monthly\nReport',
                    subtitle: 'Disease vs date chart',
                    color: const Color(0xFFFF7043),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MonthlyReportView(),
                      ),
                    ),
                  ),
                  _HomeComponentCard(
                    icon: Icons.smart_toy_rounded,
                    title: 'AI\nResult',
                    subtitle: 'Prediction details',
                    color: const Color(0xFF7C3AED),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const InfoDetailView(
                          emoji: '🤖',
                          title: 'AI Result',
                          description:
                              'This section explains AI prediction results, confidence percentage, disease classification, and detected date details.',
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),
              _tipCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tipCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: BrandColor.primary.withOpacity(0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          const Text('💡', style: TextStyle(fontSize: 24)),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'Tip: Capture fruit image in good lighting for better disease detection accuracy.',
              style: TextStyle(
                color: BrandColor.lightText,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final String timeStr;
  final String dateStr;

  const _ProfileCard({required this.timeStr, required this.dateStr});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: BrandColor.primary.withOpacity(0.20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: BrandColor.primary,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Center(
              child: Text(
                'PK',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Name & date
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pomegranate Farm',
                  style: TextStyle(
                    color: BrandColor.darkText,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  dateStr,
                  style: TextStyle(
                    color: BrandColor.lightText,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          // Time chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: BrandColor.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: BrandColor.primary.withOpacity(0.20)),
            ),
            child: Text(
              timeStr,
              style: const TextStyle(
                color: BrandColor.primary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeComponentCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _HomeComponentCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withOpacity(0.14)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.08),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 52,
              width: 52,
              decoration: BoxDecoration(
                color: color.withOpacity(0.10),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(
                color: BrandColor.darkText,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: TextStyle(
                color: BrandColor.lightText,
                fontSize: 12,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  'Open',
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.arrow_forward_rounded, color: color, size: 16),
              ],
            ),
          ],
        ),
      ),
    );
  }
}