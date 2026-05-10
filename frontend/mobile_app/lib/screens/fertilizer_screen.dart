import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import '../services/fertilizer_api_service.dart';

class FertilizerScreen extends StatefulWidget {
  const FertilizerScreen({super.key});

  @override
  State<FertilizerScreen> createState() => _FertilizerScreenState();
}

class _FertilizerScreenState extends State<FertilizerScreen> {
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

  Map<String, dynamic>? result;
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

                    sensorSubscription = sensorCharacteristic!.onValueReceived
                        .listen((value) {
                          final csv = utf8.decode(value);
                          debugPrint("BLE CSV received: $csv");
                          parseSensorCsv(csv);
                        });

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

        setState(() {
          isScanning = false;
          isBleConnected = false;
          bleStatus = "ESP32 not found. Restart ESP32 and try again.";
        });
      }
    } catch (e) {
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
        result = null;
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
        result = null;
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
      result = null;
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

      setState(() {
        result = onlineResult;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Backend unavailable: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget bleConnectCard() {
    return Card(
      color: isBleConnected ? Colors.green.shade50 : Colors.orange.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              bleStatus,
              style: TextStyle(
                color: isBleConnected
                    ? Colors.green.shade800
                    : Colors.orange.shade800,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: isScanning ? null : connectToEsp32,
              icon: isScanning
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.bluetooth),
              label: Text(isScanning ? "Scanning..." : "Connect ESP32 Sensor"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget inputField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: Colors.green.shade700),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.green.shade100),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.green.shade700, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget sensorInputSection() {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.green.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Farmer Input',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          inputField(
            label: 'Tree Age',
            hint: 'Example: 4',
            controller: ageController,
            icon: Icons.calendar_month,
          ),
          const SizedBox(height: 10),
          const Text(
            'Sensor Readings',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          inputField(
            label: 'Soil Moisture (%)',
            hint: 'Auto-filled from ESP32',
            controller: moistureController,
            icon: Icons.water_drop,
          ),
          inputField(
            label: 'Temperature (°C)',
            hint: 'Auto-filled from ESP32',
            controller: tempController,
            icon: Icons.thermostat,
          ),
          inputField(
            label: 'EC',
            hint: 'Auto-filled from ESP32',
            controller: ecController,
            icon: Icons.bolt,
          ),
          inputField(
            label: 'pH',
            hint: 'Auto-filled from ESP32',
            controller: phController,
            icon: Icons.science,
          ),
          inputField(
            label: 'Nitrogen',
            hint: 'Auto-filled from ESP32',
            controller: nitrogenController,
            icon: Icons.grass,
          ),
          inputField(
            label: 'Phosphorus',
            hint: 'Auto-filled from ESP32',
            controller: phosphorusController,
            icon: Icons.grass,
          ),
          inputField(
            label: 'Potassium',
            hint: 'Auto-filled from ESP32',
            controller: potassiumController,
            icon: Icons.grass,
          ),
        ],
      ),
    );
  }

  Widget topSummaryCard() {
    final fertilizerClass = result?['fertilizer_class']?.toString() ?? '-';
    final stageName = result?['stage_name']?.toString() ?? '-';
    final treeAge =
        result?['tree_age']?.toString() ?? ageController.text.trim();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F8EE),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                height: 42,
                width: 42,
                decoration: const BoxDecoration(
                  color: Color(0xFFE53935),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 14),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Crop',
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  Text(
                    'Pomegranate',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              summaryItem('Age', treeAge.isEmpty ? '-' : '$treeAge years'),
              summaryItem('Stage', cleanStageName(stageName)),
              summaryItem('Class', fertilizerClass),
            ],
          ),
        ],
      ),
    );
  }

  String cleanStageName(String value) {
    if (value == '-') return '-';
    return value.replaceAll('_', ' ');
  }

  Widget summaryItem(String title, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget nutrientCard({
    required String title,
    required String symbol,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        height: 126,
        padding: const EdgeInsets.all(14),
        margin: const EdgeInsets.symmetric(horizontal: 5),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withOpacity(0.82)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              blurRadius: 8,
              color: color.withOpacity(0.35),
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              symbol,
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
            const Spacer(),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget fertilizerAmountCard() {
    if (result == null) return const SizedBox();

    final amount = result!['fertilizer_amount'];
    final ecWarning = result!['ec_warning']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(top: 22),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F8EE),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recommended Fertilizer Amount',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
          ),
          const SizedBox(height: 4),
          const Text(
            'Per plant / per application',
            style: TextStyle(color: Colors.black54, fontSize: 12),
          ),
          const SizedBox(height: 20),
          fertilizerRow(
            letter: 'U',
            name: 'Urea',
            amount: '${amount['urea_g']} g / plant',
            color: Colors.cyan,
          ),
          fertilizerRow(
            letter: 'T',
            name: 'TSP',
            amount: '${amount['tsp_g']} g / plant',
            color: Colors.orange,
          ),
          fertilizerRow(
            letter: 'M',
            name: 'MOP',
            amount: '${amount['mop_g']} g / plant',
            color: Colors.red,
          ),
          if (ecWarning.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              ecWarning,
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget fertilizerRow({
    required String letter,
    required String name,
    required String amount,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        children: [
          CircleAvatar(
            radius: 17,
            backgroundColor: color,
            child: Text(
              letter,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(child: Text(name, style: const TextStyle(fontSize: 15))),
          Text(amount, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget resultSection() {
    if (result == null) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 24),
        topSummaryCard(),
        const SizedBox(height: 24),
        const Text(
          'Nutrient Quantity',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            nutrientCard(
              title: 'Nitrogen',
              symbol: 'N',
              value: '${nitrogenController.text.trim()} raw',
              color: const Color(0xFF2196F3),
            ),
            nutrientCard(
              title: 'Phosphorus',
              symbol: 'P',
              value: '${phosphorusController.text.trim()} raw',
              color: const Color(0xFFFF5722),
            ),
            nutrientCard(
              title: 'Potassium',
              symbol: 'K',
              value: '${potassiumController.text.trim()} raw',
              color: const Color(0xFF9C27B0),
            ),
          ],
        ),
        fertilizerAmountCard(),
      ],
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
      backgroundColor: const Color(0xFFEAF5E6),
      appBar: AppBar(
        title: const Text('Fertilizer Recommendation'),
        centerTitle: true,
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFEAF5E6), Color(0xFFFFFFFF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              const Text(
                'Pomegranate Fertilizer Advisor',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              const Text(
                'Connect ESP32 sensor, enter tree age, and get per-plant recommendation.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 18),

              bleConnectCard(),

              sensorInputSection(),

              const SizedBox(height: 18),

              ElevatedButton.icon(
                onPressed: isLoading ? null : checkFertilizer,
                icon: isLoading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.eco),
                label: Text(
                  isLoading ? 'Checking...' : 'Get Recommendation',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),

              if (errorMessage != null) ...[
                const SizedBox(height: 18),
                Card(
                  color: Colors.orange.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      errorMessage!,
                      style: const TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],

              resultSection(),
            ],
          ),
        ),
      ),
    );
  }
}
