import 'package:flutter/material.dart';

import '../../common/brand_color.dart';
import '../../common/common_widgets.dart';
import '../../l10n/app_strings.dart';
import '../../services/weather/weather_service.dart';
import '../../utils/format_datetime.dart';

class WeatherDetailsScreen extends StatelessWidget {
  final WeatherData data;

  const WeatherDetailsScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final hours = data.rainExpectedInHours;
    final rainText = hours == null
        ? t('noRainSoon')
        : LanguageController.instance.tf('rainInHours', {
            'h': '${hours < 1 ? 1 : hours}',
          });

    return Scaffold(
      backgroundColor: BrandColor.background,
      appBar: AppBar(title: Text(t('weatherDetails'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t('currentWeather'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                _row(t('temperature'), data.temp),
                _row(t('humidity'), data.humidityText),
                _row(t('rainProbability'), data.rainProbabilityText),
                _row(t('condition'), data.condition),
                _row(t('precipitation'), data.precipitation),
                _row(t('location'), data.locationLabel),
                _row(t('updated'), formatFarmDateTime(data.updatedAt)),
                const SizedBox(height: 12),
                Text(
                  t('upcomingRain'),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(rainText, style: const TextStyle(height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.black54)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
