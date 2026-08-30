import 'package:flutter/material.dart';

import '../../common/brand_color.dart';
import '../../common/common_widgets.dart';
import '../../l10n/app_strings.dart';
import '../../models/farm_location.dart';
import '../../models/irrigation_result.dart';
import '../../models/irrigation_weather.dart';
import '../../models/soil_sensor_reading.dart';
import '../../services/firebase/firestore_service.dart';
import '../../services/irrigation/irrigation_history_service.dart';
import '../../services/irrigation/irrigation_prediction_service.dart';
import '../../services/irrigation/irrigation_weather_service.dart';
import '../../services/irrigation/location_service.dart';
import '../../services/sensor/soil_bluetooth_service.dart';
import '../../widgets/weather_art.dart';
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
  final _scrollController = ScrollController();
  final _resultKey = GlobalKey();

  FarmLocation? _location;
  IrrigationWeather? _weather;
  IrrigationResult? _result;
  bool _predicting = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _prepareLocationAndWeather();
    _connectIfNeeded();
  }

  Future<void> _connectIfNeeded() async {
    if (_ble.isConnected.value || _ble.isScanning.value) return;
    await _connectDevice();
  }

  Future<void> _prepareLocationAndWeather() async {
    final snapshot = await _weatherService.loadForFarm(_locationService);
    if (!mounted) return;
    setState(() {
      _location = snapshot.location;
      _weather = snapshot.weather;
    });
    if (_weather != null) {
      FirestoreService.instance.notifyRainIfNeeded(_weather!);
    }
  }

  Future<void> _connectDevice() async {
    if (_ble.isScanning.value || _ble.isConnected.value) return;
    try {
      await _ble.connect();
    } catch (_) {
      if (!mounted) return;
      setState(() => _message = t('connectionFailed'));
    }
  }

  Future<void> _predict() async {
    if (_predicting) return;

    if (!_ble.isConnected.value) {
      setState(() => _message = t('errorSensorDisconnected'));
      return;
    }

    final reading = _ble.latestReading.value;
    if (reading == null || reading.moisture <= 0) {
      setState(() => _message = t('errorNoSoilMoisture'));
      return;
    }

    setState(() {
      _predicting = true;
      _message = null;
      _result = null;
    });

    try {
      if (_weather == null) {
        await _prepareLocationAndWeather();
      }

      final result = await _predictionService.predict(
        soilMoisture: reading.moisture,
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
      _scrollToResult();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _predicting = false;
        _message = t('errorPredictionFailed');
      });
    }
  }

  void _scrollToResult() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _resultKey.currentContext;
      if (ctx == null) return;
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
        alignment: 0.08,
      );
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LanguageController.instance,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(t('irrigation')),
            ),
            backgroundColor: BrandColor.primary,
            foregroundColor: Colors.white,
            iconTheme: const IconThemeData(color: Colors.white),
            automaticallyImplyLeading: false,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
              onPressed: () {
                if (Navigator.of(context).canPop()) Navigator.of(context).pop();
              },
            ),
            actions: [
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const IrrigationHistoryScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.history, color: Colors.white),
              ),
            ],
          ),
          body: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _grid(),
                const SizedBox(height: 16),
                AppPrimaryButton(
                  label: t('checkIrrigation'),
                  icon: Icons.water_drop_rounded,
                  isLoading: _predicting,
                  onPressed: _predicting ? null : _predict,
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
                  const SizedBox(height: 18),
                  KeyedSubtree(key: _resultKey, child: _resultCard(_result!)),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _grid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 12.0;
        final width = (constraints.maxWidth - gap) / 2;
        const height = 248.0;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            SizedBox(width: width, height: height, child: _sensorCard()),
            SizedBox(width: width, height: height, child: _readingCard(isMoisture: true)),
            SizedBox(width: width, height: height, child: _readingCard(isMoisture: false)),
            SizedBox(width: width, height: height, child: _weatherStatusCard()),
          ],
        );
      },
    );
  }

  Widget _sensorCard() {
    return ValueListenableBuilder<bool>(
      valueListenable: _ble.isConnected,
      builder: (context, connected, _) {
        return ValueListenableBuilder<bool>(
          valueListenable: _ble.isScanning,
          builder: (context, scanning, _) {
            final status = scanning
                ? t('connectingDevice')
                : connected
                    ? t('connected')
                    : t('disconnected');
            return _glassCard(
              headerIcon: Icons.bluetooth_rounded,
              title: t('sensorConnection'),
              value: status,
              subtitle: connected ? t('live') : t('waiting'),
              loading: scanning,
              art: _circleArt(
                icon: connected
                    ? Icons.bluetooth_connected_rounded
                    : Icons.bluetooth_disabled_rounded,
                color: connected ? const Color(0xFF16A34A) : BrandColor.primary,
              ),
              footer: connected || scanning
                  ? null
                  : _connectButton(scanning: scanning),
            );
          },
        );
      },
    );
  }

  Widget _connectButton({required bool scanning}) {
    return SizedBox(
      width: double.infinity,
      height: 32,
      child: ElevatedButton(
        onPressed: scanning ? null : _connectDevice,
        style: ElevatedButton.styleFrom(
          backgroundColor: BrandColor.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            t('connectDevice'),
            maxLines: 1,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
          ),
        ),
      ),
    );
  }

  Widget _readingCard({required bool isMoisture}) {
    return ValueListenableBuilder<SoilSensorReading?>(
      valueListenable: _ble.latestReading,
      builder: (context, reading, _) {
        return ValueListenableBuilder<bool>(
          valueListenable: _ble.isConnected,
          builder: (context, connected, _) {
            final ready = connected && reading != null;
            final value = !ready
                ? '--'
                : isMoisture
                    ? '${reading.moisture.toStringAsFixed(0)}%'
                    : '${reading.temp.toStringAsFixed(0)}°';
            return _glassCard(
              headerIcon: isMoisture
                  ? Icons.water_drop_outlined
                  : Icons.thermostat_outlined,
              title: isMoisture ? t('soilMoisture') : t('soilTemperature'),
              value: value,
              subtitle: ready ? t('live') : t('waiting'),
              art: WeatherArt(
                type: isMoisture
                    ? WeatherArtType.irrigate
                    : WeatherArtType.thermometer,
                size: 78,
              ),
            );
          },
        );
      },
    );
  }

  Widget _weatherStatusCard() {
    final weather = _weather;
    final conditionKey = weather == null
        ? 'loading'
        : weatherConditionLabel(weather.weatherCode);
    final details = <(String, String)>[];
    if (weather?.humidity != null) {
      details.add((t('humidity'), '${weather!.humidity!.toStringAsFixed(0)}%'));
    }
    if (weather?.rainProbability != null) {
      details.add((
        t('rainProbability'),
        '${weather!.rainProbability!.toStringAsFixed(0)}%',
      ));
    }
    return _glassCard(
      headerIcon: Icons.location_on_outlined,
      title: t('currentWeather'),
      value: weather == null ? '--' : '${weather.tempMean.toStringAsFixed(0)}°',
      subtitle: t(conditionKey),
      art: WeatherArt(
        type: weather == null
            ? WeatherArtType.cloudy
            : _artForWeather(weather.weatherCode),
        size: 78,
      ),
      details: details.take(2).toList(),
    );
  }

  WeatherArtType _artForWeather(double code) {
    switch (weatherConditionLabel(code)) {
      case 'sunny':
        return WeatherArtType.sunny;
      case 'partlyCloudy':
        return WeatherArtType.partlyCloudy;
      case 'rain':
        return WeatherArtType.rain;
      case 'rainShowers':
        return WeatherArtType.heavyRain;
      case 'thunderstorm':
        return WeatherArtType.thunderstorm;
      default:
        return WeatherArtType.cloudy;
    }
  }

  Widget _circleArt({required IconData icon, required Color color}) {
    return Container(
      width: 78,
      height: 78,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withValues(alpha: 0.18),
            color.withValues(alpha: 0.04),
          ],
        ),
      ),
      child: Icon(icon, color: color, size: 36),
    );
  }

  Widget _glassCard({
    required IconData headerIcon,
    required String title,
    required String value,
    required String subtitle,
    required Widget art,
    bool loading = false,
    Widget? footer,
    List<(String, String)> details = const [],
  }) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            const Color(0xFFF8F1F3),
          ],
        ),
        border: Border.all(color: const Color(0xFFE8D4D8)),
        boxShadow: [
          BoxShadow(
            color: BrandColor.primary.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(headerIcon, size: 14, color: BrandColor.primary.withValues(alpha: 0.75)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ),
              Icon(
                Icons.menu_rounded,
                size: 15,
                color: const Color(0xFF9CA3AF),
              ),
            ],
          ),
          const Spacer(),
          art,
          const Spacer(),
          if (loading)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                maxLines: 1,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w200,
                  color: Color(0xFF111827),
                  height: 1,
                ),
              ),
            ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: BrandColor.primary,
            ),
          ),
          if (details.isNotEmpty) ...[
            const SizedBox(height: 8),
            for (final row in details)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        row.$1,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF9CA3AF),
                        ),
                      ),
                    ),
                    Text(
                      row.$2,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF4B5563),
                      ),
                    ),
                  ],
                ),
              ),
          ],
          if (footer != null) ...[
            const SizedBox(height: 8),
            footer,
          ],
        ],
      ),
    );
  }

  Widget _resultCard(IrrigationResult result) {
    final view = _resultView(result);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 26, 20, 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE8D4D8)),
        boxShadow: [
          BoxShadow(
            color: BrandColor.primary.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          WeatherArt(type: view.art, size: 128),
          const SizedBox(height: 14),
          Text(
            view.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: view.tint,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            view.body,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              height: 1.45,
              color: Color(0xFF374151),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  _ResultView _resultView(IrrigationResult result) {
    final code = result.weatherUsed?.weatherCode ?? 0;
    final weatherKey = weatherConditionLabel(code);
    final prediction = result.finalPrediction ?? '';
    final thunder = weatherKey == 'thunderstorm';
    final heavy = weatherKey == 'rainShowers' ||
        (result.weatherUsed?.forecastRain24h ?? 0) >= 8;

    if (prediction == 'SKIP_RAIN_EXPECTED' && (thunder || heavy)) {
      return _ResultView(
        art: thunder ? WeatherArtType.thunderstorm : WeatherArtType.heavyRain,
        title: thunder ? t('doNotIrrigateTitle') : t('heavyRainExpected'),
        body: t('doNotIrrigateBody'),
        tint: const Color(0xFF1D4ED8),
      );
    }
    if (prediction == 'SKIP_RAIN_EXPECTED' ||
        result.status.contains('RAIN') ||
        result.status == t('waitForRain')) {
      return _ResultView(
        art: WeatherArtType.rain,
        title: t('waitBeforeIrrigatingTitle'),
        body: t('waitBeforeIrrigatingBody'),
        tint: const Color(0xFF2563EB),
      );
    }
    if (prediction == 'SUITABLE_TO_IRRIGATE' ||
        prediction == 'SUITABLE_BASED_ON_SOIL') {
      return _ResultView(
        art: WeatherArtType.irrigate,
        title: t('irrigateRecommendedTitle'),
        body: t('irrigateRecommendedBody'),
        tint: BrandColor.primary,
      );
    }
    if (weatherKey == 'cloudy' || weatherKey == 'partlyCloudy') {
      return _ResultView(
        art: weatherKey == 'partlyCloudy'
            ? WeatherArtType.partlyCloudy
            : WeatherArtType.cloudy,
        title: t('irrigateNotNeededTitle'),
        body: t('irrigateNotNeededBody'),
        tint: const Color(0xFF4B5563),
      );
    }
    if (weatherKey == 'sunny' &&
        (prediction == 'NO_URGENT_IRRIGATION' ||
            prediction == 'SKIP_SOIL_ALREADY_WET')) {
      return _ResultView(
        art: WeatherArtType.sunny,
        title: t('irrigateNotNeededTitle'),
        body: t('irrigateNotNeededBody'),
        tint: const Color(0xFFD97706),
      );
    }
    return _ResultView(
      art: WeatherArtType.plant,
      title: t('irrigateNotNeededTitle'),
      body: t('irrigateNotNeededBody'),
      tint: const Color(0xFF15803D),
    );
  }
}

class _ResultView {
  final WeatherArtType art;
  final String title;
  final String body;
  final Color tint;

  const _ResultView({
    required this.art,
    required this.title,
    required this.body,
    required this.tint,
  });
}
