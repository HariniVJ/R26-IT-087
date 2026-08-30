import 'package:flutter/material.dart';

import '../../common/brand_color.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BrandColor.background,

      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'Profile',
          style: TextStyle(
            color: BrandColor.darkText,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            const SizedBox(height: 16),

            Container(
              width: 90,
              height: 90,
              decoration: const BoxDecoration(
                color: BrandColor.primary,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text(
                  'AK',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            const Text(
              'Akaran Farm',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),

            const SizedBox(height: 5),

            const Text(
              'AI-Based Intelligent Farming System',
              textAlign: TextAlign.center,
              style: TextStyle(color: BrandColor.lightText, fontSize: 12),
            ),

            const SizedBox(height: 28),

            _info(
              icon: Icons.location_on_outlined,
              title: 'Location',
              value: 'Sri Lanka',
            ),

            _info(
              icon: Icons.eco_outlined,
              title: 'Crop Type',
              value: 'Pomegranate',
            ),

            _info(
              icon: Icons.smart_toy_outlined,
              title: 'AI Model',
              value: 'PomCare v1.0',
            ),

            _info(
              icon: Icons.language_rounded,
              title: 'Language',
              value: 'English',
            ),

            const SizedBox(height: 18),

            SizedBox(
              width: double.infinity,
              height: 54,
              child: OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  foregroundColor: BrandColor.primary,
                  side: const BorderSide(color: BrandColor.primary),
                ),
                child: const Text('Logout'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _info({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BrandColor.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: BrandColor.primary),

          const SizedBox(width: 12),

          Expanded(
            child: Text(
              title,
              style: const TextStyle(color: BrandColor.lightText),
            ),
          ),

          Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
