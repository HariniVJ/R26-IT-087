import 'package:flutter/material.dart';
import '../models/dashboard_item.dart';
import '../theme/app_colors.dart';
import '../config/app_constants.dart';
import 'glass_box.dart';

class ModuleButton extends StatefulWidget {
  final DashboardItem item;
  final VoidCallback onTap;

  const ModuleButton({super.key, required this.item, required this.onTap});

  @override
  State<ModuleButton> createState() => _ModuleButtonState();
}

class _ModuleButtonState extends State<ModuleButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _pressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 100),

        // ── Uses GlassBox with module's own tint color ───────────────────
        // Same glass style as weather card — same opacity, same border logic
        child: GlassBox(
          padding: const EdgeInsets.all(18),
          radius: AppConstants.cardRadius,
          opacity: AppColors.glassOpacity,
          tintColor: item.color, // each button tinted with its color
          child: Stack(
            children: [
              // ── Bottom-left glow blob ──────────────────────────────────────
              Positioned(
                bottom: -35,
                left: -35,
                child: _glowBlob(size: 115, color: item.color, opacity: 0.16),
              ),

              // ── Content column ─────────────────────────────────────────────
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [_iconBox(item), _labelSection(item)],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Emoji icon box ─────────────────────────────────────────────────────────
  Widget _iconBox(DashboardItem item) => Container(
    width: 56,
    height: 56,
    decoration: BoxDecoration(
      color: item.color.withOpacity(0.18),
      borderRadius: BorderRadius.circular(AppConstants.iconBoxRadius),
      border: Border.all(color: item.color.withOpacity(0.36), width: 1.2),
    ),
    child: Center(
      child: Text(item.emoji, style: const TextStyle(fontSize: 28)),
    ),
  );

  // ── Title + subtitle + open chip ──────────────────────────────────────────
  Widget _labelSection(DashboardItem item) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(item.title, style: _buttonTitle),
      const SizedBox(height: 4),
      Text(item.subtitle, style: _buttonSubtitle),
      const SizedBox(height: 10),
      _openChip(item.color),
    ],
  );

  // ── "Open →" chip ──────────────────────────────────────────────────────────
  Widget _openChip(Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
    decoration: BoxDecoration(
      color: color.withOpacity(0.22),
      borderRadius: BorderRadius.circular(AppConstants.chipRadius),
    ),
    child: const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Open',
          style: TextStyle(
            color: Color.fromARGB(255, 0, 0, 0),
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(width: 4),
        Icon(
          Icons.arrow_forward_rounded,
          color: Color.fromARGB(255, 0, 0, 0),
          size: 12,
        ),
      ],
    ),
  );

  // ── Glow blob ──────────────────────────────────────────────────────────────
  Widget _glowBlob({
    required double size,
    required Color color,
    required double opacity,
  }) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: color.withOpacity(opacity),
    ),
  );

  // ── Local text styles (use AppTextStyles if you prefer) ───────────────────
  static const _buttonTitle = TextStyle(
    color: Color.fromARGB(255, 0, 0, 0),
    fontWeight: FontWeight.w700,
    fontSize: 14,
    height: 1.2,
  );

  static final _buttonSubtitle = TextStyle(
    color: Color.fromARGB(255, 0, 0, 0),
    fontWeight: FontWeight.w700,
    fontSize: 12,
  );
}
