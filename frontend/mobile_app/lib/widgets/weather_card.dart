import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../services/weather/weather_service.dart';

class WeatherCard extends StatelessWidget {
  final bool isLoading;
  final String? error;
  final WeatherData? data;
  final VoidCallback onRetry;
  final VoidCallback? onOpen;

  const WeatherCard({
    super.key,
    required this.isLoading,
    required this.error,
    required this.data,
    required this.onRetry,
    this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: data == null ? null : onOpen,
      child: Container(
        width: double.infinity,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: const Color(0xFF9B1230),
          borderRadius: BorderRadius.circular(22),
        ),
        child: ListenableBuilder(
          listenable: LanguageController.instance,
          builder: (context, _) {
            if (isLoading) return _loading();
            if (error != null || data == null) return _error();
            return _data(data!);
          },
        ),
      ),
    );
  }

  Widget _loading() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white70,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              t('fetchingWeather'),
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _error() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          const Icon(Icons.cloud_off_rounded, color: Colors.white70, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              t('weatherUnavailable'),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: Text(
              t('retry'),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _data(WeatherData w) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 20, 18, 16),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(w.weatherEmoji, style: const TextStyle(fontSize: 44)),
                    const SizedBox(height: 4),
                    Text(
                      w.temp,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 38,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      w.condition,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 124, color: Colors.white24),
              const SizedBox(width: 18),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _metric(
                    Icons.water_drop_rounded,
                    t('humidity'),
                    w.humidityText,
                  ),
                  const SizedBox(height: 12),
                  _metric(Icons.air_rounded, t('wind'), w.wind),
                  const SizedBox(height: 12),
                  _metric(
                    Icons.thermostat_rounded,
                    t('feelsLike'),
                    w.feelsLike,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              const Icon(
                Icons.location_on_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  w.locationLabel,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ),
              TextButton(
                onPressed: onRetry,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white70,
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(t('refresh')),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metric(IconData icon, String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.white60, fontSize: 11),
            ),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
