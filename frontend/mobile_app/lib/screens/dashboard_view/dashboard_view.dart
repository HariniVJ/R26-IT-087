import 'package:flutter/material.dart';
import '../../common/brand_color.dart';
import '../disease_detection_view/disease_detection_view.dart';
import '../history_view/history_view.dart';
import '../info_detail_view/info_detail_view.dart';
import '../treatment_chat_view/treatment_chat_view.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BrandColor.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top bar ─────────────────────────────────
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [BrandColor.primary, BrandColor.secondary],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Center(
                      child: Text('🍎', style: TextStyle(fontSize: 22)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pomegranate Care',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: BrandColor.darkText,
                          ),
                        ),
                        Text(
                          'AI-Powered Detection',
                          style: TextStyle(
                            fontSize: 12,
                            color: BrandColor.lightText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: BrandColor.primary.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.notifications_outlined,
                        color: BrandColor.primary,
                      ),
                      onPressed: () {},
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ── Greeting ─────────────────────────────────
              const Text(
                'Hello, Farmer! 👋',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: BrandColor.darkText,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Check your pomegranate fruit health\nusing AI technology.',
                style: TextStyle(
                  color: BrandColor.lightText,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 24),

              // ── Hero Banner ──────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: const LinearGradient(
                    colors: [BrandColor.primary, BrandColor.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Disease\nDetection',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Upload fruit photo\nand get instant results',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Text('🍎', style: TextStyle(fontSize: 72)),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ── Section title ────────────────────────────
              const Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: BrandColor.darkText,
                ),
              ),
              const SizedBox(height: 14),

              // ── Feature Cards ────────────────────────────
              _FeatureCard(
                title: 'Start Detection',
                subtitle: 'Upload fruit image for AI analysis',
                icon: Icons.document_scanner_rounded,
                iconBg: BrandColor.primary.withOpacity(0.10),
                iconColor: BrandColor.primary,
                badge: 'NEW',
                badgeColor: BrandColor.primary,
                onTap:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const DiseaseDetectionView(),
                      ),
                    ),
              ),
              const SizedBox(height: 14),
              _FeatureCard(
                title: 'Detection History',
                subtitle: 'View your past scan results',
                icon: Icons.history_rounded,
                iconBg: BrandColor.green.withOpacity(0.10),
                iconColor: BrandColor.green,
                onTap:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const HistoryView()),
                    ),
              ),

              const SizedBox(height: 28),

              // ── Smart Tools ──────────────────────────────
              const Text(
                'Smart Farming Tools',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: BrandColor.darkText,
                ),
              ),
              const SizedBox(height: 14),

              Row(
                children: [
                  _MiniCard(
                    emoji: '🍎',
                    title: 'Fruit\nHealth',
                    onTap:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => const InfoDetailView(
                                  emoji: '🍎',
                                  title: 'Fruit Health',
                                  description:
                                      'This section helps farmers understand pomegranate fruit health and identify whether the fruit looks healthy or diseased.',
                                ),
                          ),
                        ),
                  ),
                  const SizedBox(width: 12),
                  _MiniCard(
                    emoji: '💊',
                    title: 'Treatment\nChat',
                    onTap:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const TreatmentChatView(),
                          ),
                        ),
                  ),
                  const SizedBox(width: 12),
                  _MiniCard(
                    emoji: '📊',
                    title: 'AI\nResult',
                    onTap:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => const InfoDetailView(
                                  emoji: '📊',
                                  title: 'AI Result',
                                  description:
                                      'This section explains AI prediction result, confidence percentage, detected date, and disease classification details.',
                                ),
                          ),
                        ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ── Tip Card ─────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: BrandColor.primary.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: BrandColor.primary.withOpacity(0.15),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: BrandColor.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Center(
                        child: Text('💡', style: TextStyle(fontSize: 22)),
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
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
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Feature Card ───────────────────────────────────────────────
class _FeatureCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String? badge;
  final Color? badgeColor;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.onTap,
    this.badge,
    this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: iconColor.withOpacity(0.10),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: BrandColor.darkText,
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: (badgeColor ?? BrandColor.primary)
                                .withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            badge!,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: badgeColor ?? BrandColor.primary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: BrandColor.lightText,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: iconColor, size: 16),
          ],
        ),
      ),
    );
  }
}

// ── Mini Card ──────────────────────────────────────────────────
class _MiniCard extends StatelessWidget {
  final String emoji;
  final String title;
  final VoidCallback onTap;

  const _MiniCard({
    required this.emoji,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: BrandColor.primary.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 30)),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: BrandColor.darkText,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
