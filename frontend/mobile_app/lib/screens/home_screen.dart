import 'package:flutter/material.dart';
import 'irrigation_screen.dart';
import 'fertilizer_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Widget menuCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 3,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Icon(
          icon,
          size: 38,
          color: Colors.green,
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pomegranate Farming'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.local_florist,
              size: 80,
              color: Colors.green,
            ),
            const SizedBox(height: 12),
            const Text(
              'Smart Farming Assistant',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Online weather-aware mode and offline rural mode',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 28),
            menuCard(
              icon: Icons.water_drop,
              title: 'Irrigation Advice',
              subtitle: 'Check whether irrigation is suitable now',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const IrrigationScreen(),
                  ),
                );
              },
            ),
            menuCard(
              icon: Icons.eco,
              title: 'Fertilizer Recommendation',
              subtitle: 'Check NPK and fertilizer amount',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const FertilizerScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}