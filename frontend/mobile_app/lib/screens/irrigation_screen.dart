import 'package:flutter/material.dart';

import '../logic/irrigation_logic.dart';
import '../services/irrigation_api_service.dart';

class IrrigationScreen extends StatefulWidget {
  const IrrigationScreen({super.key});

  @override
  State<IrrigationScreen> createState() => _IrrigationScreenState();
}

class _IrrigationScreenState extends State<IrrigationScreen> {
  static const Color mainRed = Color(0xFFBB2222);

  final TextEditingController soilMoistureController = TextEditingController(
    text: '38',
  );

  bool isLoading = false;
  Map<String, dynamic>? result;
  String? errorMessage;

  // Jaffna coordinates
  final double latitude = 9.6615;
  final double longitude = 80.0255;

  Future<void> checkIrrigation() async {
    final soilText = soilMoistureController.text.trim();

    if (soilText.isEmpty) {
      setState(() {
        errorMessage = 'Please enter soil moisture value.';
        result = null;
      });
      return;
    }

    final soilMoisture = double.tryParse(soilText);

    if (soilMoisture == null) {
      setState(() {
        errorMessage = 'Soil moisture must be a number.';
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
      final onlineResult = await IrrigationApiService.predictIrrigation(
        soilMoisture: soilMoisture,
        latitude: latitude,
        longitude: longitude,
      );

      setState(() {
        result = onlineResult;
      });
    } catch (e) {
      final offlineResult = IrrigationLogic.offlineDecision(
        soilMoisture: soilMoisture,
      );

      setState(() {
        result = offlineResult;
        errorMessage =
            'Online backend unavailable. Showing offline soil-based decision.';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Color statusColor(String status) {
    if (status == 'Suitable Now') return Colors.green;
    if (status == 'Suitable Based on Soil') return Colors.green;
    if (status == 'Not Suitable Now') return mainRed;
    if (status == 'No Urgent Irrigation Needed') return Colors.orange;
    if (status == 'Cannot Predict') return Colors.grey;
    return Colors.blueGrey;
  }

  IconData statusIcon(String status) {
    if (status == 'Suitable Now') return Icons.check_circle;
    if (status == 'Suitable Based on Soil') return Icons.check_circle;
    if (status == 'Not Suitable Now') return Icons.cancel;
    if (status == 'No Urgent Irrigation Needed') return Icons.info;
    return Icons.warning;
  }

  Widget weatherRow(String label, dynamic value, String unit) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            '$value $unit',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget resultCard() {
    final status = result?['status']?.toString() ?? 'Unknown';
    final reason = result?['reason'];
    final mode = result?['mode']?.toString() ?? 'unknown';
    final weather = result?['weather_used'];
    final finalPrediction = result?['final_prediction']?.toString();
    final modelPrediction = result?['model_prediction']?.toString();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Chip(
              label: Text(
                mode == 'online'
                    ? 'Online Weather-Aware Mode'
                    : 'Offline Rural Mode',
              ),
              backgroundColor: mode == 'online'
                  ? Colors.green.shade100
                  : Colors.orange.shade100,
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Icon(statusIcon(status), color: statusColor(status), size: 34),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    status,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: statusColor(status),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            if (reason is List)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: reason
                    .map<Widget>(
                      (item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          '• $item',
                          style: const TextStyle(fontSize: 15),
                        ),
                      ),
                    )
                    .toList(),
              )
            else
              Text(
                reason?.toString() ?? 'No reason provided.',
                style: const TextStyle(fontSize: 16),
              ),

            const SizedBox(height: 12),

            if (modelPrediction != null)
              Text(
                'Model Prediction: $modelPrediction',
                style: const TextStyle(fontSize: 13),
              ),

            if (finalPrediction != null)
              Text(
                'Final Prediction: $finalPrediction',
                style: const TextStyle(fontSize: 13),
              ),

            if (weather != null) ...[
              const Divider(height: 30),
              const Text(
                'Weather Data Used',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              weatherRow('Temperature', weather['temp_mean'], '°C'),
              weatherRow('Apparent Temp', weather['apparent_temp_mean'], '°C'),
              weatherRow('Rain Now', weather['rain_mm'], 'mm'),
              weatherRow('Rain Hours', weather['rain_hours'], 'h'),
              weatherRow(
                'Forecast Rain 24h',
                weather['forecast_rain_24h'],
                'mm',
              ),
              weatherRow('Wind Speed', weather['wind_speed_max'], 'km/h'),
              weatherRow('ET0', weather['et0'], 'mm'),
              weatherRow('Weather Code', weather['weather_code'], ''),
            ],

            if (mode == 'offline') ...[
              const Divider(height: 30),
              const Text(
                'Weather forecast is unavailable in offline mode.',
                style: TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    soilMoistureController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        title: const Text('Irrigation Advice'),
        centerTitle: true,
        backgroundColor: mainRed,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.water_drop, size: 70, color: mainRed),

            const SizedBox(height: 12),

            const Text(
              'Check Irrigation Suitability',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            const Text(
              'Online mode uses weather forecast. Offline mode uses soil moisture only.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 24),

            TextField(
              controller: soilMoistureController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Soil Moisture (%)',
                hintText: 'Example: 38',
                prefixIcon: const Icon(Icons.grass, color: mainRed),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: mainRed, width: 1.6),
                ),
              ),
            ),

            const SizedBox(height: 16),

            ElevatedButton.icon(
              onPressed: isLoading ? null : checkIrrigation,
              icon: isLoading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.search),
              label: Text(
                isLoading ? 'Checking...' : 'Check Irrigation',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: mainRed,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),

            const SizedBox(height: 22),

            if (errorMessage != null)
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

            if (result != null) resultCard(),
          ],
        ),
      ),
    );
  }
}
