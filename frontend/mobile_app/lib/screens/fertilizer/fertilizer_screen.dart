import 'package:flutter/material.dart';

import '../../common/brand_color.dart';
import '../../common/common_widgets.dart';
import '../../services/fertilizer_local_service.dart';
import '../../services/soil_bluetooth_service.dart';
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

  @override
  void initState() {
    super.initState();
    _ble.latestReading.addListener(_fillFromSensor);
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

  Future<void> _checkFertilizer() async {
    final treeAge = double.tryParse(_ageController.text.trim());
    final moisture = double.tryParse(_moistureController.text.trim());
    final temp = double.tryParse(_tempController.text.trim());
    final ph = double.tryParse(_phController.text.trim());
    final nitrogen = double.tryParse(_nitrogenController.text.trim());
    final phosphorus = double.tryParse(_phosphorusController.text.trim());
    final potassium = double.tryParse(_potassiumController.text.trim());

    if (treeAge == null || treeAge <= 0) {
      setState(() => _errorMessage = 'Please enter valid tree age.');
      return;
    }

    if (moisture == null ||
        temp == null ||
        ph == null ||
        nitrogen == null ||
        phosphorus == null ||
        potassium == null) {
      setState(() {
        _errorMessage = 'Please connect the sensor or enter all sensor readings.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final advice = _fertilizerService.predict(
        moisture: moisture,
        temp: temp,
        ph: ph,
        nitrogen: nitrogen,
        phosphorus: phosphorus,
        potassium: potassium,
        treeAge: treeAge,
      );

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
              const Text(
                'Pomegranate Fertilizer\nAdvisor',
                style: TextStyle(
                  color: Color(0xFF176B2C),
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Connect your 7-in-1 soil sensor and enter tree age to get a per-tree fertilizer recommendation on this phone.',
                style: TextStyle(color: Colors.black54, fontSize: 13, height: 1.45),
              ),
              const SizedBox(height: 22),
              _bleCard(),
              const SizedBox(height: 18),
              AppCard(
                child: AppTextField(
                  label: 'Tree Age (Years)',
                  hint: 'Example: 5',
                  controller: _ageController,
                  icon: Icons.calendar_month,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
              const SizedBox(height: 18),
              _readingsCard(),
              const SizedBox(height: 18),
              AppPrimaryButton(
                label: 'CHECK FERTILIZER',
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
                return AppCard(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: connected
                                ? Colors.green.shade50
                                : Colors.red.shade50,
                            child: Icon(
                              connected
                                  ? Icons.bluetooth_connected
                                  : Icons.bluetooth_disabled,
                              color: connected ? Colors.green : BrandColor.primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Sensor Status',
                                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  status,
                                  style: TextStyle(
                                    color: connected ? Colors.green : BrandColor.primary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      AppPrimaryButton(
                        label: scanning ? 'Scanning...' : 'Connect the Sensor',
                        icon: Icons.add,
                        isLoading: scanning,
                        onPressed: scanning ? null : _ble.connect,
                      ),
                    ],
                  ),
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
          const Row(
            children: [
              Expanded(
                child: Text(
                  'Sensor Readings',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
                ),
              ),
              Text(
                'READ-ONLY',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.black38,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  label: 'Soil Moisture (%)',
                  hint: '--',
                  controller: _moistureController,
                  icon: Icons.water_drop,
                  readOnly: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AppTextField(
                  label: 'Temperature (°C)',
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
            label: 'pH',
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
                  label: 'Nitrogen (N)',
                  hint: '--',
                  controller: _nitrogenController,
                  icon: Icons.grass,
                  readOnly: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AppTextField(
                  label: 'Phosphorus (P)',
                  hint: '--',
                  controller: _phosphorusController,
                  icon: Icons.eco,
                  readOnly: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AppTextField(
                  label: 'Potassium (K)',
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
