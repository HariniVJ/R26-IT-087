// lib/theme/app_text.dart
// ALL text styles used across the entire app

import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  static const farmName = TextStyle(
    color: AppColors.textWhite,
    fontWeight: FontWeight.w700,
    fontSize: 15,
  );

  static const farmerName = TextStyle(
    color: AppColors.textWhite,
    fontSize: 34,
    fontWeight: FontWeight.w800,
    height: 1.1,
  );

  static const clock = TextStyle(
    color: AppColors.textWhite,
    fontWeight: FontWeight.w800,
    fontSize: 20,
    letterSpacing: 1.5,
  );

  static const sectionTitle = TextStyle(
    color: AppColors.textWhite,
    fontSize: 20,
    fontWeight: FontWeight.w700,
  );

  static const weatherTemp = TextStyle(
    color: AppColors.textWhite,
    fontSize: 38,
    fontWeight: FontWeight.w800,
    height: 1.0,
  );

  static const weatherValue = TextStyle(
    color: AppColors.textWhite,
    fontWeight: FontWeight.w700,
    fontSize: 13,
  );

  static const buttonTitle = TextStyle(
    color: AppColors.textWhite,
    fontWeight: FontWeight.w700,
    fontSize: 14,
    height: 1.2,
  );

  static const openChip = TextStyle(
    color: AppColors.textWhite,
    fontSize: 10,
    fontWeight: FontWeight.w700,
  );
}
