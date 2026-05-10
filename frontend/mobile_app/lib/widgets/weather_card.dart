// lib/widgets/weather_card.dart
// Reusable weather display card using GlassBox.
// Shows loading / error / real weather states.

import 'package:flutter/material.dart';
import '../services/weather_service.dart';
import '../theme/app_colors.dart';
import 'glass_box.dart';

class WeatherCard extends StatelessWidget {
  final bool isLoading;
  final String? error;
  final WeatherData? data;
  final VoidCallback onRetry;

  const WeatherCard({
    super.key,
    required this.isLoading,
    required this.error,
    required this.data,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) return _loadingState();
    if (error != null || data == null) return _errorState();
    return _dataState(data!);
  }

  // ── Loading ────────────────────────────────────────────────────────────────
  Widget _loadingState() => GlassBox(
    padding: const EdgeInsets.all(20),
    child: Row(
      children: [
        const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white60,
          ),
        ),
        const SizedBox(width: 14),
        Text(
          'Fetching weather...',
          style: TextStyle(color: Colors.white.withOpacity(0.70), fontSize: 14),
        ),
      ],
    ),
  );

  // ── Error ──────────────────────────────────────────────────────────────────
  Widget _errorState() => GlassBox(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    child: Row(
      children: [
        const Icon(Icons.cloud_off_rounded, color: Colors.white54, size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            error ?? 'Weather unavailable',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
        TextButton(
          onPressed: onRetry,
          child: const Text('Retry', style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );

  // ── Real weather data ──────────────────────────────────────────────────────
  Widget _dataState(WeatherData w) => GlassBox(
    padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
    child: Column(
      children: [
        Row(
          children: [
            // Emoji + temp + description
            Expanded(
              child: Row(
                children: [
                  Text(w.weatherEmoji, style: const TextStyle(fontSize: 46)),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        w.temp,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 38,
                          fontWeight: FontWeight.w800,
                          height: 1.0,
                        ),
                      ),
                      Text(
                        w.description,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.75),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Divider
            Container(
              width: 1,
              height: 70,
              color: Colors.white.withOpacity(0.14),
              margin: const EdgeInsets.symmetric(horizontal: 16),
            ),

            // Details
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _detail('💧', 'Humidity', w.humidity),
                const SizedBox(height: 10),
                _detail('💨', 'Wind', w.wind),
                const SizedBox(height: 10),
                _detail('🌡️', 'Feels', w.feelsLike),
              ],
            ),
          ],
        ),

        const SizedBox(height: 14),

        // Location row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.location_on_rounded,
                  color: const Color.fromARGB(255, 255, 255, 255).withOpacity(0.8),
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  '${w.location}, ${w.country}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.65),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            GestureDetector(
              onTap: onRetry,
              child: Text(
                'Refresh',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.45),
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _detail(String icon, String label, String value) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(icon, style: const TextStyle(fontSize: 14)),
      const SizedBox(width: 6),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.48),
              fontSize: 9,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    ],
  );
}
