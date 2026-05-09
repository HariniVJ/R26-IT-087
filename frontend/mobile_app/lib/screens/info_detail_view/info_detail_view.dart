import 'package:flutter/material.dart';
import '../../common/brand_color.dart';
import '../../common/glass_container.dart';

class InfoDetailView extends StatelessWidget {
  final String emoji;
  final String title;
  final String description;

  const InfoDetailView({
    super.key,
    required this.emoji,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BrandColor.background,
      extendBodyBehindAppBar: true,
      appBar: DarkAppBar(title: title),
      body: Stack(
        children: [
          const DarkBackground(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: GlassContainer(
                padding: const EdgeInsets.all(30),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Emoji circle
                    GlassContainer(
                      borderRadius: BorderRadius.circular(50),
                      padding: const EdgeInsets.all(22),
                      fillColor: BrandColor.glassWarmFill,
                      borderColor: BrandColor.glassWarmBorder,
                      child: Text(emoji, style: const TextStyle(fontSize: 44)),
                    ),

                    const SizedBox(height: 22),

                    // Title
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: BrandColor.accent,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Divider line
                    Container(
                      width: 48,
                      height: 2,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            BrandColor.primary.withOpacity(0.5),
                            Colors.transparent,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Description
                    Text(
                      description,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.7,
                        color: BrandColor.lightText,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
