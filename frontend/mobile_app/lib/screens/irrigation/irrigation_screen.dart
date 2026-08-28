import 'package:flutter/material.dart';

import '../../common/brand_color.dart';
import '../../common/common_widgets.dart';
import '../../l10n/app_strings.dart';
import '../../models/farm_location.dart';
import '../../models/irrigation_result.dart';
import '../../models/irrigation_weather.dart';
import '../../models/soil_sensor_reading.dart';
import '../../services/irrigation/irrigation_history_service.dart';
import '../../services/irrigation/irrigation_prediction_service.dart';
import '../../services/irrigation/irrigation_weather_service.dart';
import '../../services/irrigation/location_service.dart';
import '../../services/sensor/soil_bluetooth_service.dart';
import '../../services/firebase/firestore_service.dart';
import 'irrigation_history_screen.dart';

class IrrigationScreen extends StatefulWidget {
  const IrrigationScreen({super.key});

  @override
  State<IrrigationScreen> createState() => _IrrigationScreenState();
}

class _IrrigationScreenState extends State<IrrigationScreen> {
  final _locationService = FarmLocationService();
  final _weatherService = IrrigationWeatherService();
  final _predictionService = IrrigationPredictionService();
  final _ble = SoilBluetoothService.instance;

  FarmLocation? _location;
  IrrigationWeather? _weather;
  IrrigationResult? _result;

  bool _loadingLocation = false;
  bool _loadingWeather = false;
  bool _predicting = false;
  String? _locationError;
  String? _message;

  @override
  void initState() {
    super.initState();
    _prepareLocationAndWeather();
    _connectSensorIfNeeded();
  }

  Future<void> _connectSensorIfNeeded() async {
    if (!_ble.isConnected.value && !_ble.isScanning.value) {
      await _ble.connect();
    }
  }

  Future<void> _prepareLocationAndWeather() async {
    setState(() {
      _loadingLocation = true;
      _loadingWeather = true;
      _locationError = null;
    });

    final snapshot = await _weatherService.loadForFarm(_locationService);
    if (!mounted) return;
    setState(() {
      _location = snapshot.location;
      _weather = snapshot.weather;
      _locationError = snapshot.locationError;
      _loadingLocation = false;
      _loadingWeather = false;
    });
    if (_weather != null) {
      FirestoreService.instance.notifyRainIfNeeded(_weather!);
    }
  }

  Future<void> _predict() async {
    final reading = _ble.latestReading.value;
    if (reading == null) {
      setState(() {
        _message =
            'Connect the IoT soil sensor. Soil moisture is read automatically from the device.';
      });
      _connectSensorIfNeeded();
      return;
    }

    final soil = reading.moisture;

    setState(() {
      _predicting = true;
      _message = null;
      _result = null;
    });

    final result = await _predictionService.predict(
      soilMoisture: soil,
      soilTemperature: reading.temp,
      weather: _weather,
      latitude: _location?.latitude,
      longitude: _location?.longitude,
    );

    await IrrigationHistoryService.instance.save(result);

    if (!mounted) return;
    setState(() {
      _result = result;
      _predicting = false;
    });
  }

  @override
  void dispose() {
    _ble.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        title: Text(t('irrigationRecommendation')),
        backgroundColor: BrandColor.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Irrigation history',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const IrrigationHistoryScreen(),
                ),
              );
            },
            icon: const Icon(Icons.history),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.water_drop, size: 64, color: BrandColor.primary),
            const SizedBox(height: 8),
            Text(
              t('checkIrrigation'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              'Soil moisture comes from the IoT sensor. Weather is loaded automatically when the internet is available.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            _locationCard(),
            const SizedBox(height: 12),
            _weatherCard(),
            const SizedBox(height: 12),
            _sensorCard(),
            const SizedBox(height: 12),
            _liveSensorReadings(),
            const SizedBox(height: 16),
            AppPrimaryButton(
              label: t('checkIrrigation'),
              icon: Icons.search,
              isLoading: _predicting,
              onPressed: _predict,
            ),
            if (_message != null) ...[
              const SizedBox(height: 14),
              AppBanner(
                message: _message!,
                color: Colors.orange.shade800,
                icon: Icons.warning_amber_rounded,
              ),
            ],
            if (_result != null) ...[
              const SizedBox(height: 16),
              _resultCard(_result!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _locationCard() {
    return AppCard(
      child: Row(
        children: [
          const Icon(Icons.location_on, color: BrandColor.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t('farmLocation'), style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(
                  _loadingLocation
                      ? 'Getting current location...'
                      : _location == null
                          ? (_locationError ?? 'Location unavailable')
                          : '${_location!.latitude.toStringAsFixed(4)}, ${_location!.longitude.toStringAsFixed(4)} (${_location!.source})',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _prepareLocationAndWeather,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
    );
  }

  Widget _weatherCard() {
    String message;
    Color color = Colors.blueGrey;
    if (_loadingWeather) {
      message = 'Fetching live weather...';
    } else if (_weather == null) {
      message = _weatherService.lastError ??
          'No weather data. Irrigation will use soil moisture only.';
      color = Colors.orange.shade800;
    } else if (_weather!.isCached) {
      message =
          'Using saved weather from ${_formatTime(_weather!.fetchedAt)}. This is not live weather.';
      color = Colors.orange.shade800;
    } else {
      final hours = _weather!.rainExpectedInHours;
      final rain = hours == null
          ? t('noRainSoon')
          : t('waitRainReason').replaceAll('{hours}', '${hours < 1 ? 1 : hours}');
      message =
          '${t('currentWeather')}. ${t('rainForecast')}: ${_weather!.forecastRain24h} mm. $rain';
      color = _weather!.rainWithinTwoHours
          ? Colors.blue.shade800
          : Colors.green.shade800;
    }

    return AppBanner(message: message, color: color, icon: Icons.cloud_outlined);
  }

  Widget _sensorCard() {
    return ValueListenableBuilder<bool>(
      valueListenable: _ble.isConnected,
      builder: (context, connected, child) {
        return ValueListenableBuilder<bool>(
          valueListenable: _ble.isScanning,
          builder: (context, scanning, child) {
            return ValueListenableBuilder<String>(
              valueListenable: _ble.status,
              builder: (context, status, child) {
                return BluetoothStatusCard(
                  connected: connected,
                  scanning: scanning,
                  status: status,
                  connectLabel: t('connectSensor'),
                  onConnect: _ble.connect,
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _liveSensorReadings() {
    return ValueListenableBuilder<SoilSensorReading?>(
      valueListenable: _ble.latestReading,
      builder: (context, reading, _) {
        final live = reading != null;
        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'IoT Sensor Readings',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  Text(
                    live ? t('live') : t('waiting'),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: live ? Colors.green.shade700 : Colors.black38,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _sensorMetric(
                      t('soilMoisture'),
                      reading == null
                          ? '--'
                          : '${reading.moisture.toStringAsFixed(1)} %',
                      Icons.grass,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _sensorMetric(
                      t('soilTemperature'),
                      reading == null
                          ? '--'
                          : '${reading.temp.toStringAsFixed(1)} °C',
                      Icons.thermostat,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                live
                    ? 'Values are updating from the ESP32 soil sensor.'
                    : 'Turn on the ESP32 soil sensor. Moisture is filled automatically — no typing needed.',
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _sensorMetric(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: BrandColor.primary),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: Colors.black54),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }

  Widget _resultCard(IrrigationResult result) {
    final color = _statusColor(result.status);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Chip(
            label: Text(_modeLabel(result.mode)),
            backgroundColor: result.mode == 'live_weather'
                ? Colors.green.shade100
                : Colors.orange.shade100,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(_statusIcon(result.status), color: color, size: 32),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  result.status,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(result.reason, style: const TextStyle(fontSize: 15, height: 1.4)),
          if (result.modelPrediction != null) ...[
            const SizedBox(height: 8),
            Text('Model Prediction: ${result.modelPrediction}', style: const TextStyle(fontSize: 13)),
          ],
          if (result.finalPrediction != null)
            Text('Final Prediction: ${result.finalPrediction}', style: const TextStyle(fontSize: 13)),
          if (result.weatherUsed != null) ...[
            const Divider(height: 28),
            Text(
              result.weatherUsed!.isCached
                  ? 'Saved Weather Data (not live)'
                  : 'Live Weather Data Used',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _weatherRow('Temperature', result.weatherUsed!.tempMean, '°C'),
            _weatherRow('Apparent Temp', result.weatherUsed!.apparentTempMean, '°C'),
            _weatherRow('Rain Now', result.weatherUsed!.rainMm, 'mm'),
            _weatherRow('Rain Hours', result.weatherUsed!.rainHours, 'h'),
            _weatherRow('Forecast Rain 24h', result.weatherUsed!.forecastRain24h, 'mm'),
            _weatherRow('Wind Speed', result.weatherUsed!.windSpeedMax, 'km/h'),
            _weatherRow('ET0', result.weatherUsed!.et0, 'mm'),
          ],
        ],
      ),
    );
  }

  Widget _weatherRow(String label, dynamic value, String unit) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text('$value $unit', style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  String _modeLabel(String mode) {
    switch (mode) {
      case 'live_weather':
        return 'On-device + Live Weather';
      case 'cached_weather':
        return 'On-device + Saved Weather';
      case 'soil_only':
        return 'Offline Soil-Only Mode';
      default:
        return mode;
    }
  }

  Color _statusColor(String status) {
    if (status == t('waitForRain') || status.contains('RAIN')) {
      return Colors.blue.shade800;
    }
    if (status == t('suitableNow') ||
        status == 'Suitable Now' ||
        status == 'Suitable Based on Soil') {
      return Colors.green;
    }
    if (status == t('soilAlreadyWet') || status == 'Not Suitable Now') {
      return BrandColor.primary;
    }
    if (status == t('noUrgent') || status == 'No Urgent Irrigation Needed') {
      return Colors.orange;
    }
    return Colors.grey;
  }

  IconData _statusIcon(String status) {
    if (status == t('waitForRain') || status.contains('RAIN')) {
      return Icons.cloud;
    }
    if (status == t('suitableNow') ||
        status == 'Suitable Now' ||
        status == 'Suitable Based on Soil') {
      return Icons.check_circle;
    }
    if (status == t('soilAlreadyWet') || status == 'Not Suitable Now') {
      return Icons.cancel;
    }
    if (status == t('noUrgent') || status == 'No Urgent Irrigation Needed') {
      return Icons.info;
    }
    return Icons.warning;
  }

  String _formatTime(DateTime time) {
    return '${time.year}-${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')} '
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
