// lib/widgets/glass_box.dart
// Reusable glass card widget — used for weather, clock, module buttons.
// Change AppColors.glassOpacity or AppColors.borderOpacity to update ALL cards.

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../config/app_constants.dart';

class GlassBox extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final double opacity; // glass fill opacity
  final Color? tintColor; // override base tint (e.g. per-module color)

  const GlassBox({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = AppConstants.cardRadius,
    this.opacity = AppColors.glassOpacity,
    this.tintColor,
  });

  @override
  Widget build(BuildContext context) {
    final fill = (tintColor ?? AppColors.glassBase).withOpacity(opacity);
    final border = (tintColor ?? AppColors.glassBorder).withOpacity(
      AppColors.borderOpacity,
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: border, width: 1.2),
        ),
        child: child,
      ),
    );
  }
}
