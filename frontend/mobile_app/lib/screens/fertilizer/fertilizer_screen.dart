import 'package:flutter/material.dart';

import '../../common/brand_color.dart';
import '../../common/common_widgets.dart';
import '../../l10n/app_strings.dart';
import '../../services/fertilizer/fertilizer_local_service.dart';
import '../../services/firebase/firestore_service.dart';
import '../../services/sensor/soil_bluetooth_service.dart';
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
    if (!_ble.isConnected.value && !_ble.isScanning.value) {
      await _ble.connect();
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
    final reading = _ble.latestReading.value;
    final moisture = reading?.moisture ??
        double.tryParse(_moistureController.text.trim());
    final temp =
        reading?.temp ?? double.tryParse(_tempController.text.trim());
    final ph = reading?.ph ?? double.tryParse(_phController.text.trim());
    final nitrogen = reading?.nitrogen ??
        double.tryParse(_nitrogenController.text.trim());
    final phosphorus = reading?.phosphorus ??
        double.tryParse(_phosphorusController.text.trim());
    final potassium = reading?.potassium ??
        double.tryParse(_potassiumController.text.trim());

    if (moisture == null ||
        temp == null ||
        ph == null ||
        nitrogen == null ||
        phosphorus == null ||
        potassium == null) {
      setState(() {
        _errorMessage =
            'Connect the IoT soil sensor. N, P, K, pH and moisture are read automatically.';
      });
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
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _ageController.removeListener(_onAgeChanged);
    _ble.latestReading.removeListener(_fillFromSensor);
    _ble.disconnect();
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
    return Scaffold(
      backgroundColor: const Color(0xFFEFF8F0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  IconButton(
                    tooltip: 'Back',
                    onPressed: () {
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      }
                    },
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Color(0xFF176B2C),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      t('fertilizerRecommendation'),
                      style: const TextStyle(
                        color: Color(0xFF176B2C),
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        height: 1.15,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Fertilizer history',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const FertilizerHistoryScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.history),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                'Connect the 7-in-1 soil sensor. The app reads N, P, K, pH and moisture from the IoT device, then runs the fertilizer model on this phone.',
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 22),
              _bleCard(),
              const SizedBox(height: 18),
              AppCard(
                child: Column(
                  children: [
                    AppTextField(
                      label: t('treeAge'),
                      hint: '0 - 10',
                      controller: _ageController,
                      icon: Icons.calendar_month,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      errorText: _ageError,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _readingsCard(),
              const SizedBox(height: 18),
              AppPrimaryButton(
                label: t('fertilizerRecommendation'),
                isLoading: _isLoading,
                onPressed: _checkFertilizer,
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                AppBanner(
                  message: _errorMessage!,
                  color: BrandColor.primary,
                  icon: Icons.error_outline,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _bleCard() {
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

  Widget _readingsCard() {
    return AppCard(
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'IoT Sensor Readings',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
                ),
              ),
              ValueListenableBuilder(
                valueListenable: _ble.latestReading,
                builder: (context, reading, _) {
                  final live = reading != null;
                  return Text(
                    live ? t('live') : t('waiting'),
                    style: TextStyle(
                      fontSize: 10,
                      color: live ? Colors.green.shade700 : Colors.black38,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  label: t('soilMoisture'),
                  hint: '--',
                  controller: _moistureController,
                  icon: Icons.water_drop,
                  readOnly: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AppTextField(
                  label: t('soilTemperature'),
                  hint: '--',
                  controller: _tempController,
                  icon: Icons.thermostat,
                  readOnly: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          AppTextField(
            label: t('soilPh'),
            hint: '--',
            controller: _phController,
            icon: Icons.science,
            readOnly: true,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  label: t('nitrogen'),
                  hint: '--',
                  controller: _nitrogenController,
                  icon: Icons.grass,
                  readOnly: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AppTextField(
                  label: t('phosphorus'),
                  hint: '--',
                  controller: _phosphorusController,
                  icon: Icons.eco,
                  readOnly: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AppTextField(
                  label: t('potassium'),
                  hint: '--',
                  controller: _potassiumController,
                  icon: Icons.spa,
                  readOnly: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
