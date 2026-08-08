// lib/screens/coming_soon_screen.dart
// Shown when a team member's screen is not yet integrated.
// Replace in dashboard_screen.dart switch case when ready.

import 'package:flutter/material.dart';

class ComingSoonScreen extends StatelessWidget {
  final String title;
  final Color color;

  const ComingSoonScreen({super.key, required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: color.withOpacity(0.06),
      appBar: AppBar(
        title: Text(title),
        backgroundColor: color,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            '$title\n\nThis page will be connected by the team member.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              height: 1.6,
            ),
          ),
        ),
      ),
    );
  }
}
