// lib/models/dashboard_item.dart
// Data model for each module button on the dashboard

import 'package:flutter/material.dart';

class DashboardItem {
  final String title;
  final String subtitle;
  final String emoji;
  final Color color;
  final String screenName; // used in _openScreen() switch

  const DashboardItem({
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.color,
    required this.screenName,
  });
}
