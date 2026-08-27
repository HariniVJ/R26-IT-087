/// Parsed 7-in-1 soil sensor CSV from the existing ESP32 BLE characteristic.
/// Format from `fertilizer_screen.dart`:
/// moisture,temp,ec,ph,nitrogen,phosphorus,potassium
class SoilSensorReading {
  final double moisture;
  final double temp;
  final double ec;
  final double ph;
  final double nitrogen;
  final double phosphorus;
  final double potassium;
  final String rawCsv;

  const SoilSensorReading({
    required this.moisture,
    required this.temp,
    required this.ec,
    required this.ph,
    required this.nitrogen,
    required this.phosphorus,
    required this.potassium,
    required this.rawCsv,
  });

  static SoilSensorReading? tryParse(String csv) {
    final parts = csv.trim().split(',');
    if (parts.length != 7) return null;

    final values = parts.map(double.tryParse).toList();
    if (values.any((v) => v == null)) return null;

    return SoilSensorReading(
      moisture: values[0]!,
      temp: values[1]!,
      ec: values[2]!,
      ph: values[3]!,
      nitrogen: values[4]!,
      phosphorus: values[5]!,
      potassium: values[6]!,
      rawCsv: csv.trim(),
    );
  }
}
