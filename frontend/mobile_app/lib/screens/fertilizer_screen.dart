import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import '../services/fertilizer_api_service.dart';
import 'fertilizer_result_screen.dart';

class FertilizerScreen extends StatefulWidget {
  const FertilizerScreen({super.key});

  @override
  State<FertilizerScreen> createState() => _FertilizerScreenState();
}

class _FertilizerScreenState extends State<FertilizerScreen> {
  static const Color mainRed = Color(0xFFBB2222);

  final TextEditingController ageController = TextEditingController();

  final TextEditingController moistureController = TextEditingController();
  final TextEditingController tempController = TextEditingController();
  final TextEditingController ecController = TextEditingController();
  final TextEditingController phController = TextEditingController();
  final TextEditingController nitrogenController = TextEditingController();
  final TextEditingController phosphorusController = TextEditingController();
  final TextEditingController potassiumController = TextEditingController();

  final Guid serviceUuid = Guid("12345678-1234-1234-1234-1234567890ab");
  final Guid characteristicUuid = Guid("abcd1234-5678-90ab-cdef-1234567890ab");

  BluetoothDevice? connectedDevice;
  BluetoothCharacteristic? sensorCharacteristic;
  StreamSubscription<List<int>>? sensorSubscription;

  bool isLoading = false;
  bool isScanning = false;
  bool isBleConnected = false;

  String? errorMessage;
  String bleStatus = "Sensor not connected";

  Future<void> requestBlePermissions() async {
    await Permission.bluetoothScan.request();
    await Permission.bluetoothConnect.request();
    await Permission.location.request();
  }

  Future<void> connectToEsp32() async {
    await requestBlePermissions();

    setState(() {
      isScanning = true;
      isBleConnected = false;
      bleStatus = "Scanning for ESP32 sensor...";
      errorMessage = null;
    });

    try {
      await FlutterBluePlus.stopScan();

      BluetoothDevice? targetDevice;
      StreamSubscription<List<ScanResult>>? scanSub;

      scanSub = FlutterBluePlus.scanResults.listen((results) async {
        for (final r in results) {
          final name = r.device.platformName;
          final advName = r.advertisementData.advName;

          debugPrint("Found BLE: name=$name advName=$advName");

          if (name == "Soil Sensor BLE" || advName == "Soil Sensor BLE") {
            targetDevice = r.device;

            await FlutterBluePlus.stopScan();
            await scanSub?.cancel();

            if (!mounted) return;

            setState(() {
              bleStatus = "Connecting to ESP32...";
            });

            try {
              await targetDevice!.connect(
                timeout: const Duration(seconds: 10),
                autoConnect: false,
              );
            } catch (e) {
              debugPrint("Connect warning: $e");
            }

            connectedDevice = targetDevice;

            final services = await connectedDevice!.discoverServices();

            for (final service in services) {
              debugPrint("Service found: ${service.uuid}");

              if (service.uuid.toString().toLowerCase() ==
                  serviceUuid.toString().toLowerCase()) {
                for (final c in service.characteristics) {
                  debugPrint("Characteristic found: ${c.uuid}");

                  if (c.uuid.toString().toLowerCase() ==
                      characteristicUuid.toString().toLowerCase()) {
                    sensorCharacteristic = c;

                    await sensorCharacteristic!.setNotifyValue(true);

                    sensorSubscription =
                        sensorCharacteristic!.onValueReceived.listen((value) {
                      final csv = utf8.decode(value);
                      debugPrint("BLE CSV received: $csv");
                      parseSensorCsv(csv);
                    });

                    if (!mounted) return;

                    setState(() {
                      isScanning = false;
                      isBleConnected = true;
                      bleStatus = "ESP32 connected and receiving data";
                    });

                    return;
                  }
                }
              }
            }

            if (!mounted) return;

            setState(() {
              isScanning = false;
              isBleConnected = false;
              bleStatus = "Connected, but sensor characteristic not found";
            });

            return;
          }
        }
      });

      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));
      await Future.delayed(const Duration(seconds: 11));

      if (targetDevice == null) {
        await scanSub.cancel();

        if (!mounted) return;

        setState(() {
          isScanning = false;
          isBleConnected = false;
          bleStatus = "ESP32 not found. Restart ESP32 and try again.";
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isScanning = false;
        isBleConnected = false;
        bleStatus = "BLE error: $e";
      });
    }
  }

  void parseSensorCsv(String csv) {
    try {
      final parts = csv.trim().split(',');

      if (parts.length != 7) {
        setState(() {
          errorMessage = "Invalid sensor data: $csv";
        });
        return;
      }

      setState(() {
        moistureController.text = parts[0];
        tempController.text = parts[1];
        ecController.text = parts[2];
        phController.text = parts[3];
        nitrogenController.text = parts[4];
        phosphorusController.text = parts[5];
        potassiumController.text = parts[6];

        errorMessage = null;
      });
    } catch (e) {
      setState(() {
        errorMessage = "Sensor parse error: $e";
      });
    }
  }

  Future<void> checkFertilizer() async {
    final treeAge = double.tryParse(ageController.text.trim());
    final moisture = double.tryParse(moistureController.text.trim());
    final temp = double.tryParse(tempController.text.trim());
    final ec = double.tryParse(ecController.text.trim());
    final ph = double.tryParse(phController.text.trim());
    final nitrogen = double.tryParse(nitrogenController.text.trim());
    final phosphorus = double.tryParse(phosphorusController.text.trim());
    final potassium = double.tryParse(potassiumController.text.trim());

    if (treeAge == null || treeAge <= 0) {
      setState(() {
        errorMessage = 'Please enter valid tree age.';
      });
      return;
    }

    if (moisture == null ||
        temp == null ||
        ec == null ||
        ph == null ||
        nitrogen == null ||
        phosphorus == null ||
        potassium == null) {
      setState(() {
        errorMessage = 'Please connect sensor or enter all sensor readings.';
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final onlineResult = await FertilizerApiService.predictFertilizer(
        moisture: moisture,
        temp: temp,
        ec: ec,
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
          builder: (_) => FertilizerResultScreen(
            result: onlineResult,
            treeAge: ageController.text.trim(),
            nitrogen: nitrogenController.text.trim(),
            phosphorus: phosphorusController.text.trim(),
            potassium: potassiumController.text.trim(),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage = 'Backend unavailable: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Widget bleConnectCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor:
                    isBleConnected ? Colors.green.shade50 : Colors.red.shade50,
                child: Icon(
                  isBleConnected
                      ? Icons.bluetooth_connected
                      : Icons.bluetooth_disabled,
                  color: isBleConnected ? Colors.green : mainRed,
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
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      bleStatus,
                      style: TextStyle(
                        color: isBleConnected ? Colors.green : mainRed,
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
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isScanning ? null : connectToEsp32,
              icon: isScanning
                  ? const SizedBox(
                      width: 17,
                      height: 17,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.add, size: 19),
              label: Text(
                isScanning ? "Scanning..." : "Connect the Sensor",
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: mainRed,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget inputField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    bool readOnly = false,
  }) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        suffixIcon: Icon(icon, size: 17, color: Colors.grey.shade500),
        filled: true,
        fillColor: const Color(0xFFF6F7F9),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 13,
        ),
        labelStyle: const TextStyle(
          fontSize: 11,
          color: Colors.black54,
        ),
        hintStyle: const TextStyle(
          fontSize: 12,
          color: Colors.black38,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE4E6EA)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE4E6EA)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: mainRed, width: 1.4),
        ),
      ),
    );
  }

  Widget sensorInputSection() {
    return Container(
      margin: const EdgeInsets.only(top: 18),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          inputField(
            label: 'Tree Age (Years)',
            hint: 'Example: 5',
            controller: ageController,
            icon: Icons.calendar_month,
          ),
        ],
      ),
    );
  }

  Widget sensorReadingsCard() {
    return Container(
      margin: const EdgeInsets.only(top: 18),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: const [
              Expanded(
                child: Text(
                  'Sensor Readings',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
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
                child: inputField(
                  label: 'Soil Moisture (%)',
                  hint: '--',
                  controller: moistureController,
                  icon: Icons.water_drop,
                  readOnly: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: inputField(
                  label: 'Temperature (°C)',
                  hint: '--',
                  controller: tempController,
                  icon: Icons.thermostat,
                  readOnly: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: inputField(
                  label: 'EC (mS/cm)',
                  hint: '--',
                  controller: ecController,
                  icon: Icons.bolt,
                  readOnly: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: inputField(
                  label: 'pH',
                  hint: '--',
                  controller: phController,
                  icon: Icons.science,
                  readOnly: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: inputField(
                  label: 'Nitrogen (N)',
                  hint: '--',
                  controller: nitrogenController,
                  icon: Icons.grass,
                  readOnly: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: inputField(
                  label: 'Phosphorus (P)',
                  hint: '--',
                  controller: phosphorusController,
                  icon: Icons.eco,
                  readOnly: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: inputField(
                  label: 'Potassium (K)',
                  hint: '--',
                  controller: potassiumController,
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

  @override
  void dispose() {
    sensorSubscription?.cancel();
    connectedDevice?.disconnect();

    ageController.dispose();
    moistureController.dispose();
    tempController.dispose();
    ecController.dispose();
    phController.dispose();
    nitrogenController.dispose();
    phosphorusController.dispose();
    potassiumController.dispose();

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
                'Connect your 7-in-1 soil sensor and enter tree age to get a precise per-tree fertilizer recommendation.',
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 22),
              bleConnectCard(),
              sensorInputSection(),
              sensorReadingsCard(),
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: isLoading ? null : checkFertilizer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: mainRed,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                        height: 19,
                        width: 19,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'CHECK FERTILIZER',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
              ),
              if (errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.red.shade100),
                  ),
                  child: Text(
                    errorMessage!,
                    style: const TextStyle(
                      color: mainRed,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}