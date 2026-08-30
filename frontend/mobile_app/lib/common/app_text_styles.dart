import 'package:flutter/material.dart';

import 'brand_color.dart';

class AppTextStyles {
  AppTextStyles._();

  static const heading = TextStyle(
    color: BrandColor.darkText,
    fontSize: 22,
    fontWeight: FontWeight.w800,
    height: 1.2,
  );

  static const title = TextStyle(
    color: BrandColor.darkText,
    fontSize: 18,
    fontWeight: FontWeight.w800,
  );

  static const subtitle = TextStyle(
    color: Color(0xFF6B7280),
    fontSize: 13,
    height: 1.45,
  );

  static const body = TextStyle(
    color: BrandColor.darkText,
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );

  static const label = TextStyle(
    color: Color(0xFF6B7280),
    fontSize: 11,
    fontWeight: FontWeight.w600,
  );

  static const button = TextStyle(
    color: Colors.white,
    fontSize: 15,
    fontWeight: FontWeight.w800,
  );
}
