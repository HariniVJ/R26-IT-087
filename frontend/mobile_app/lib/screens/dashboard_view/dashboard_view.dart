import 'package:flutter/material.dart';
import '../../common/brand_color.dart';
import '../../common/glass_container.dart';
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
      body: Stack(
        children: [
          // ── Dark background with orbs ─────────────────────
          const DarkBackground(),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Top bar ─────────────────────────────────
                  Row(
                    children: [
                      GlassContainer(
                        borderRadius: BorderRadius.circular(16),
                        padding: const EdgeInsets.all(10),
                        fillColor: BrandColor.glassWarmFill,
                        borderColor: BrandColor.glassWarmBorder,
                        child: const Text('🍎', style: TextStyle(fontSize: 22)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
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
                                color: BrandColor.softText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GlassContainer(
                        borderRadius: BorderRadius.circular(50),
                        child: IconButton(
                          icon: Icon(
                            Icons.notifications_outlined,
                            color: BrandColor.accent,
                          ),
                          onPressed: () {},
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // ── Greeting ─────────────────────────────────
                  // Live badge
                  GlassContainer(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: BrandColor.accent,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: BrandColor.accent,
                                blurRadius: 5,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'AI POWERED · LIVE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: BrandColor.accent,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Hello, Farmer! 👋',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: BrandColor.darkText,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Check your pomegranate fruit health\nusing AI technology.',
                    style: TextStyle(
                      color: BrandColor.lightText,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Hero Banner ──────────────────────────────
                  GlassContainer(
                    fillColor: BrandColor.glassWarmFill,
                    borderColor: BrandColor.glassWarmBorder,
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Inner badge
                              GlassContainer(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                borderRadius: BorderRadius.circular(20),
                                child: Text(
                                  'Disease Detection',
                                  style: TextStyle(
                                    color: BrandColor.accent,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Disease\nDetection',
                                style: TextStyle(
                                  color: BrandColor.darkText,
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Upload fruit photo\nand get instant results',
                                style: TextStyle(
                                  color: BrandColor.lightText,
                                  fontSize: 13,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 14),
                              // CTA
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 9,
                                ),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      BrandColor.primary,
                                      BrandColor.secondary,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: BrandColor.primary.withOpacity(
                                        0.50,
                                      ),
                                      blurRadius: 14,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: const Text(
                                  'Start Scan  →',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
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

                  // ── Quick Actions ─────────────────────────────
                  const SectionLabel(label: 'Quick Actions'),
                  const SizedBox(height: 14),

                  _GlassFeatureCard(
                    title: 'Start Detection',
                    subtitle: 'Upload fruit image for AI analysis',
                    icon: Icons.document_scanner_rounded,
                    iconColor: BrandColor.primary,
                    badge: 'NEW',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const DiseaseDetectionView(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _GlassFeatureCard(
                    title: 'Detection History',
                    subtitle: 'View your past scan results',
                    icon: Icons.history_rounded,
                    iconColor: BrandColor.green,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const HistoryView()),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ── Smart Farming Tools ───────────────────────
                  const SectionLabel(label: 'Smart Farming Tools'),
                  const SizedBox(height: 14),

                  Row(
                    children: [
                      _GlassMiniCard(
                        emoji: '🍎',
                        title: 'Fruit\nHealth',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const InfoDetailView(
                              emoji: '🍎',
                              title: 'Fruit Health',
                              description:
                                  'This section helps farmers understand pomegranate fruit health and identify whether the fruit looks healthy or diseased.',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      _GlassMiniCard(
                        emoji: '💊',
                        title: 'Treatment\nChat',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const TreatmentChatView(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      _GlassMiniCard(
                        emoji: '📊',
                        title: 'AI\nResult',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const InfoDetailView(
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
                  GlassContainer(
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      children: [
                        GlassContainer(
                          borderRadius: BorderRadius.circular(14),
                          padding: const EdgeInsets.all(10),
                          child: const Text(
                            '💡',
                            style: TextStyle(fontSize: 22),
                          ),
                        ),
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
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Glass Feature Card ─────────────────────────────────────────
class _GlassFeatureCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final String? badge;
  final Color? badgeColor;
  final VoidCallback onTap;

  const _GlassFeatureCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.onTap,
    this.badge,
    this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = badgeColor ?? iconColor;
    return GlassContainer(
      onTap: onTap,
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          // Icon box
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: iconColor.withOpacity(0.25)),
            ),
            child: Icon(icon, color: iconColor, size: 26),
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
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
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
                          color: color.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: color.withOpacity(0.28)),
                        ),
                        child: Text(
                          badge!,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: BrandColor.accent,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12.5, color: BrandColor.softText),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios_rounded,
            color: iconColor.withOpacity(0.55),
            size: 14,
          ),
        ],
      ),
    );
  }
}

// ── Glass Mini Card ────────────────────────────────────────────
class _GlassMiniCard extends StatelessWidget {
  final String emoji;
  final String title;
  final VoidCallback onTap;

  const _GlassMiniCard({
    required this.emoji,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GlassContainer(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: BrandColor.lightText,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
