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
    final hours = w.rainExpectedInHours;
    final rainLine = hours == null
        ? t('noRainSoon')
        : LanguageController.instance.tf('rainInHours', {
            'h': '${hours < 1 ? 1 : hours}',
          });
    final updated =
        '${w.updatedAt.hour.toString().padLeft(2, '0')}:${w.updatedAt.minute.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t('currentWeather'),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${t('temperature')}: ${w.temp}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${t('humidity')}: ${w.humidityText}',
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
          Text(
            '${t('rainProbability')}: ${w.rainProbabilityText}',
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
          Text(
            '${t('condition')}: ${w.condition}',
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
          Text(
            '${t('precipitation')}: ${w.precipitation}',
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
          const SizedBox(height: 10),
          Text(
            t('upcomingRain'),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            rainLine,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 10),
          Text(
            '${t('location')}: ${w.locationLabel}',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          Text(
            '${t('updated')}: $updated',
            style: const TextStyle(color: Colors.white54, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
