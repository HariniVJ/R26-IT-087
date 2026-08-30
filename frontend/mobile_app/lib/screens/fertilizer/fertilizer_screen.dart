import 'package:flutter/material.dart';

import '../../common/brand_color.dart';
import '../../common/common_widgets.dart';
import '../../l10n/app_strings.dart';
import '../../models/soil_sensor_reading.dart';
import '../../services/fertilizer/fertilizer_local_service.dart';
import '../../services/firebase/firestore_service.dart';
import '../../services/sensor/soil_bluetooth_service.dart';
import '../../widgets/weather_art.dart';
import 'fertilizer_history_screen.dart';
import 'fertilizer_result_screen.dart';

class FertilizerScreen extends StatefulWidget {
  const FertilizerScreen({super.key});

  @override
  State<FertilizerScreen> createState() => _FertilizerScreenState();
}

class _FertilizerScreenState extends State<FertilizerScreen> {
  final _ageController = TextEditingController();
  final _moistureController = TextEditingController();
  final _tempController = TextEditingController();
  final _phController = TextEditingController();
  final _nitrogenController = TextEditingController();
  final _phosphorusController = TextEditingController();
  final _potassiumController = TextEditingController();

  final _fertilizerService = FertilizerLocalService();
  final _ble = SoilBluetoothService.instance;

  bool _isLoading = false;
  String? _errorMessage;
  String? _ageError;

  @override
  void initState() {
    super.initState();
    _ble.latestReading.addListener(_fillFromSensor);
    _ageController.addListener(_onAgeChanged);
    _fillFromSensor();
    _connectSensorIfNeeded();
  }

  Future<void> _connectSensorIfNeeded() async {
    if (_ble.isConnected.value || _ble.isScanning.value) return;
    await _connectDevice();
  }

  Future<void> _connectDevice() async {
    if (_ble.isScanning.value || _ble.isConnected.value) return;
    try {
      await _ble.connect();
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorMessage = t('connectionFailed'));
    }
  }

  void _fillFromSensor() {
    final reading = _ble.latestReading.value;
    if (reading == null || !mounted) return;
    setState(() {
      _moistureController.text = reading.moisture.toString();
      _tempController.text = reading.temp.toString();
      _phController.text = reading.ph.toString();
      _nitrogenController.text = reading.nitrogen.toString();
      _phosphorusController.text = reading.phosphorus.toString();
      _potassiumController.text = reading.potassium.toString();
      _errorMessage = null;
    });
  }

  void _onAgeChanged() {
    if (_ageError == null) return;
    setState(() => _ageError = _validatePlantAge(_ageController.text));
  }

  String? _validatePlantAge(String raw) {
    final value = double.tryParse(raw.trim());
    if (value == null || value < 0 || value > 10) {
      return t('plantAgeInvalid');
    }
    return null;
  }

  Future<void> _checkFertilizer() async {
    final ageError = _validatePlantAge(_ageController.text);
    if (ageError != null) {
      setState(() {
        _ageError = ageError;
        _errorMessage = ageError;
      });
      return;
    }

    final treeAge = double.tryParse(_ageController.text.trim());
    if (treeAge == null) {
      setState(() {
        _ageError = t('plantAgeInvalid');
        _errorMessage = t('plantAgeInvalid');
      });
      return;
    }

    final reading = _ble.latestReading.value;
    final moisture =
        reading?.moisture ?? double.tryParse(_moistureController.text.trim());
    final temp = reading?.temp ?? double.tryParse(_tempController.text.trim());
    final ph = reading?.ph ?? double.tryParse(_phController.text.trim());
    final nitrogen =
        reading?.nitrogen ?? double.tryParse(_nitrogenController.text.trim());
    final phosphorus =
        reading?.phosphorus ??
        double.tryParse(_phosphorusController.text.trim());
    final potassium =
        reading?.potassium ?? double.tryParse(_potassiumController.text.trim());

    if (moisture == null ||
        temp == null ||
        ph == null ||
        nitrogen == null ||
        phosphorus == null ||
        potassium == null) {
      setState(() => _errorMessage = t('errorSensorReadings'));
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _ageError = null;
    });

    try {
      final advice = await _fertilizerService.predict(
        moisture: moisture,
        temp: temp,
        ph: ph,
        nitrogen: nitrogen,
        phosphorus: phosphorus,
        potassium: potassium,
        treeAge: treeAge,
      );

      try {
        await FirestoreService.instance.saveFertilizer(advice);
      } catch (_) {}

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FertilizerResultScreen(advice: advice),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorMessage = t('errorFertilizerFailed'));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _ageController.removeListener(_onAgeChanged);
    _ble.latestReading.removeListener(_fillFromSensor);
    _ageController.dispose();
    _moistureController.dispose();
    _tempController.dispose();
    _phController.dispose();
    _nitrogenController.dispose();
    _phosphorusController.dispose();
    _potassiumController.dispose();
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
              child: Text(t('fertilizer')),
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
                      builder: (_) => const FertilizerHistoryScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.history, color: Colors.white),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _sensorBar(),
                const SizedBox(height: 10),
                _npkRow(),
                const SizedBox(height: 10),
                _soilRow(),
                const SizedBox(height: 10),
                _ageBar(),
                const SizedBox(height: 12),
                AppPrimaryButton(
                  label: t('checkFertilizer'),
                  icon: Icons.spa_rounded,
                  isLoading: _isLoading,
                  onPressed: _isLoading ? null : _checkFertilizer,
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 14),
                  AppBanner(
                    message: _errorMessage!,
                    color: Colors.orange.shade800,
                    icon: Icons.warning_amber_rounded,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _npkRow() {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 8.0;
        final width = (constraints.maxWidth - gap * 2) / 3;
        return Row(
          children: [
            SizedBox(
              width: width,
              height: 96,
              child: _readingCard(_ReadingKind.nitrogen, compact: true),
            ),
            const SizedBox(width: gap),
            SizedBox(
              width: width,
              height: 96,
              child: _readingCard(_ReadingKind.phosphorus, compact: true),
            ),
            const SizedBox(width: gap),
            SizedBox(
              width: width,
              height: 96,
              child: _readingCard(_ReadingKind.potassium, compact: true),
            ),
          ],
        );
      },
    );
  }

  Widget _soilRow() {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 8.0;
        final width = (constraints.maxWidth - gap * 2) / 3;
        return Row(
          children: [
            SizedBox(
              width: width,
              height: 118,
              child: _readingCard(_ReadingKind.moisture, compact: true),
            ),
            const SizedBox(width: gap),
            SizedBox(
              width: width,
              height: 118,
              child: _readingCard(_ReadingKind.temp, compact: true),
            ),
            const SizedBox(width: gap),
            SizedBox(
              width: width,
              height: 118,
              child: _readingCard(_ReadingKind.ph, compact: true),
            ),
          ],
        );
      },
    );
  }

  Widget _sensorBar() {
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
            final color = connected ? const Color(0xFF16A34A) : BrandColor.primary;
            return _panel(
              height: 56,
              child: Row(
                children: [
                  _circleArt(
                    icon: connected
                        ? Icons.bluetooth_connected_rounded
                        : Icons.bluetooth_disabled_rounded,
                    color: color,
                    size: 34,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          t('sensorConnection'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF111827),
                          ),
                        ),
                        Text(
                          scanning
                              ? t('connectingDevice')
                              : connected
                                  ? t('live')
                                  : t('waiting'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (scanning)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else if (!connected)
                    SizedBox(
                      height: 32,
                      child: ElevatedButton(
                        onPressed: _connectDevice,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: BrandColor.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          t('connectDevice'),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    )
                  else
                    Text(
                      status,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _readingCard(_ReadingKind kind, {bool compact = false}) {
    return ValueListenableBuilder<SoilSensorReading?>(
      valueListenable: _ble.latestReading,
      builder: (context, reading, _) {
        return ValueListenableBuilder<bool>(
          valueListenable: _ble.isConnected,
          builder: (context, connected, _) {
            final ready = connected && reading != null;
            return _glassCard(
              title: t(kind.titleKey),
              value: ready ? kind.format(reading) : '--',
              art: kind.art(compact: compact),
              compact: compact,
            );
          },
        );
      },
    );
  }

  Widget _ageBar() {
    return _panel(
      height: 58,
      child: Row(
        children: [
          _circleArt(
            icon: Icons.calendar_month_rounded,
            color: const Color(0xFF15803D),
            size: 34,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              t('treeAge'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827),
              ),
            ),
          ),
          SizedBox(
            width: 86,
            child: TextField(
              controller: _ageController,
              textAlign: TextAlign.center,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w300,
                color: Color(0xFF111827),
                height: 1,
              ),
              decoration: InputDecoration(
                isDense: true,
                hintText: t('plantAgeHint'),
                hintStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w300,
                  color: Color(0xFFD1D5DB),
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          Flexible(
            child: Text(
              _ageError ?? t('years'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _ageError != null ? Colors.orange.shade800 : BrandColor.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _panel({required Widget child, double? height}) {
    return Container(
      width: double.infinity,
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE8D4D8)),
        boxShadow: [
          BoxShadow(
            color: BrandColor.primary.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _circleArt({
    required IconData icon,
    required Color color,
    double size = 44,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withValues(alpha: 0.18),
            color.withValues(alpha: 0.04),
          ],
        ),
      ),
      child: Icon(icon, color: color, size: size * 0.48),
    );
  }

  Widget _glassCard({
    required String title,
    required String value,
    required Widget art,
    bool loading = false,
    Widget? valueSlot,
    bool compact = false,
  }) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: EdgeInsets.fromLTRB(compact ? 6 : 8, 8, compact ? 6 : 8, 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Color(0xFFF8F1F3)],
        ),
        border: Border.all(color: const Color(0xFFE8D4D8)),
        boxShadow: [
          BoxShadow(
            color: BrandColor.primary.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B7280),
            ),
          ),
          const Spacer(),
          art,
          const Spacer(),
          if (loading)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else if (valueSlot != null)
            valueSlot
          else
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                maxLines: 1,
                style: TextStyle(
                  fontSize: compact ? 18 : 22,
                  fontWeight: FontWeight.w200,
                  color: const Color(0xFF111827),
                  height: 1,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

enum _ReadingKind { moisture, temp, ph, nitrogen, phosphorus, potassium }

extension on _ReadingKind {
  String get titleKey {
    switch (this) {
      case _ReadingKind.moisture:
        return 'soilMoisture';
      case _ReadingKind.temp:
        return 'soilTemperature';
      case _ReadingKind.ph:
        return 'soilPh';
      case _ReadingKind.nitrogen:
        return 'nitrogen';
      case _ReadingKind.phosphorus:
        return 'phosphorus';
      case _ReadingKind.potassium:
        return 'potassium';
    }
  }

  String format(SoilSensorReading reading) {
    switch (this) {
      case _ReadingKind.moisture:
        return '${reading.moisture.toStringAsFixed(0)}%';
      case _ReadingKind.temp:
        return '${reading.temp.toStringAsFixed(0)}°';
      case _ReadingKind.ph:
        return reading.ph.toStringAsFixed(1);
      case _ReadingKind.nitrogen:
        return reading.nitrogen.toStringAsFixed(0);
      case _ReadingKind.phosphorus:
        return reading.phosphorus.toStringAsFixed(0);
      case _ReadingKind.potassium:
        return reading.potassium.toStringAsFixed(0);
    }
  }

  Widget art({required bool compact}) {
    final size = compact ? 36.0 : 44.0;
    switch (this) {
      case _ReadingKind.moisture:
        return WeatherArt(type: WeatherArtType.irrigate, size: size);
      case _ReadingKind.temp:
        return WeatherArt(type: WeatherArtType.thermometer, size: size);
      case _ReadingKind.ph:
        return _NutrientMark(letter: 'pH', color: const Color(0xFF0D9488), size: size);
      case _ReadingKind.nitrogen:
        return _NutrientMark(letter: 'N', color: const Color(0xFF2563EB), size: size);
      case _ReadingKind.phosphorus:
        return _NutrientMark(letter: 'P', color: const Color(0xFFEA580C), size: size);
      case _ReadingKind.potassium:
        return _NutrientMark(letter: 'K', color: const Color(0xFF7C3AED), size: size);
    }
  }
}

class _NutrientMark extends StatelessWidget {
  final String letter;
  final Color color;
  final double size;

  const _NutrientMark({
    required this.letter,
    required this.color,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withValues(alpha: 0.18),
            color.withValues(alpha: 0.04),
          ],
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: TextStyle(
          fontSize: size * 0.38,
          fontWeight: FontWeight.w300,
          color: color,
        ),
      ),
    );
  }
}
