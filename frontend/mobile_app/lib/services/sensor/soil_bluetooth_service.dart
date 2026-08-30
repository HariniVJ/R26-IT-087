import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../models/soil_sensor_reading.dart';
import '../firebase/firestore_service.dart';

/// Bluetooth service for the existing ESP32 soil sensor.
/// Device name, service UUID, characteristic UUID, and CSV layout are taken
/// from the current fertilizer screen — they are not invented.
class SoilBluetoothService {
  static final SoilBluetoothService instance = SoilBluetoothService._();
  SoilBluetoothService._();

  static const deviceName = 'Soil Sensor BLE';
  static final serviceUuid = Guid('12345678-1234-1234-1234-1234567890ab');
  static final characteristicUuid =
      Guid('abcd1234-5678-90ab-cdef-1234567890ab');

  BluetoothDevice? _device;
  StreamSubscription<List<int>>? _notifySub;
  StreamSubscription<BluetoothConnectionState>? _stateSub;
  StreamSubscription<List<ScanResult>>? _scanSub;

  bool _connecting = false;
  bool _shouldReconnect = false;

  final ValueNotifier<String> status =
      ValueNotifier<String>('Sensor not connected');
  final ValueNotifier<bool> isConnected = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isScanning = ValueNotifier<bool>(false);
  final ValueNotifier<SoilSensorReading?> latestReading =
      ValueNotifier<SoilSensorReading?>(null);
  final ValueNotifier<String?> errorMessage = ValueNotifier<String?>(null);

  Future<void> connect() async {
    if (_connecting) return;
    _connecting = true;
    _shouldReconnect = true;
    errorMessage.value = null;

    try {
      await _requestPermissions();
      await FlutterBluePlus.stopScan();

      isScanning.value = true;
      status.value = 'Scanning for ESP32 sensor...';
      isConnected.value = false;

      BluetoothDevice? target;

      await _scanSub?.cancel();
      _scanSub = FlutterBluePlus.scanResults.listen((results) async {
        for (final result in results) {
          final name = result.device.platformName;
          final advName = result.advertisementData.advName;
          if (name == deviceName || advName == deviceName) {
            target = result.device;
            await FlutterBluePlus.stopScan();
            await _scanSub?.cancel();
            await _completeConnection(target!);
            return;
          }
        }
      });

      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));
      await Future.delayed(const Duration(seconds: 11));

      if (target == null && !isConnected.value) {
        await _scanSub?.cancel();
        isScanning.value = false;
        status.value = 'ESP32 not found. Restart the sensor and try again.';
      }
    } catch (e) {
      isScanning.value = false;
      isConnected.value = false;
      status.value = 'Bluetooth error: $e';
      errorMessage.value = status.value;
    } finally {
      _connecting = false;
    }
  }

  Future<void> disconnect() async {
    _shouldReconnect = false;
    await _notifySub?.cancel();
    await _stateSub?.cancel();
    await _scanSub?.cancel();
    await FlutterBluePlus.stopScan();
    await _device?.disconnect();
    _device = null;
    isConnected.value = false;
    isScanning.value = false;
    status.value = 'Sensor disconnected';
  }

  Future<void> _completeConnection(BluetoothDevice device) async {
    status.value = 'Connecting to ESP32...';
    _device = device;

    try {
      await device.connect(
        timeout: const Duration(seconds: 10),
        autoConnect: false,
      );
    } catch (e) {
      debugPrint('Connect warning: $e');
    }

    await _stateSub?.cancel();
    _stateSub = device.connectionState.listen((state) {
      if (state == BluetoothConnectionState.disconnected) {
        isConnected.value = false;
        status.value = 'Sensor disconnected';
        if (_shouldReconnect) {
          status.value = 'Sensor disconnected. Reconnecting...';
          Future.delayed(const Duration(seconds: 2), () {
            if (_shouldReconnect && !isConnected.value) {
              connect();
            }
          });
        }
      }
    });

    final services = await device.discoverServices();
    for (final service in services) {
      if (service.uuid.toString().toLowerCase() !=
          serviceUuid.toString().toLowerCase()) {
        continue;
      }

      for (final characteristic in service.characteristics) {
        if (characteristic.uuid.toString().toLowerCase() !=
            characteristicUuid.toString().toLowerCase()) {
          continue;
        }

        await characteristic.setNotifyValue(true);
        await _notifySub?.cancel();
        _notifySub = characteristic.onValueReceived.listen(_onBytes);

        isScanning.value = false;
        isConnected.value = true;
        status.value = 'ESP32 connected and receiving data';
        return;
      }
    }

    isScanning.value = false;
    isConnected.value = false;
    status.value = 'Connected, but sensor characteristic not found';
  }

  void _onBytes(List<int> value) {
    try {
      final csv = utf8.decode(value);
      final reading = SoilSensorReading.tryParse(csv);
      if (reading == null) {
        errorMessage.value = 'Invalid sensor data: $csv';
        return;
      }

      if (reading.moisture <= 0 || reading.moisture > 100) {
        errorMessage.value =
            'Invalid soil moisture reading (${reading.moisture}). Please check the sensor.';
        return;
      }

      latestReading.value = reading;
      errorMessage.value = null;
      FirestoreService.instance.saveSensorReading(reading);
    } catch (e) {
      errorMessage.value = 'Sensor parse error: $e';
    }
  }

  Future<void> _requestPermissions() async {
    await Permission.bluetoothScan.request();
    await Permission.bluetoothConnect.request();
    await Permission.location.request();
  }

  Future<void> dispose() async {
    await disconnect();
    status.dispose();
    isConnected.dispose();
    isScanning.dispose();
    latestReading.dispose();
    errorMessage.dispose();
  }
}
