import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../l10n/app_strings.dart';
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
    if (_connecting || isConnected.value) return;
    _connecting = true;
    _shouldReconnect = true;
    errorMessage.value = null;

    try {
      await _prepareAdapter();
      await FlutterBluePlus.stopScan();

      isScanning.value = true;
      status.value = t('connectingDevice');
      isConnected.value = false;

      final already = _findKnownDevice(FlutterBluePlus.connectedDevices);
      if (already != null) {
        await _completeConnection(already);
        return;
      }

      try {
        final bonded = await FlutterBluePlus.bondedDevices;
        final known = _findKnownDevice(bonded);
        if (known != null) {
          await _completeConnection(known);
          return;
        }
      } catch (_) {}

      final found = Completer<BluetoothDevice>();
      await _scanSub?.cancel();
      _scanSub = FlutterBluePlus.scanResults.listen((results) {
        if (found.isCompleted) return;
        for (final result in results) {
          if (_isSensor(result.device.platformName) ||
              _isSensor(result.advertisementData.advName)) {
            found.complete(result.device);
            return;
          }
        }
      });

      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 15),
        androidUsesFineLocation: true,
        androidScanMode: AndroidScanMode.lowLatency,
      );

      BluetoothDevice? target;
      try {
        target = await found.future.timeout(const Duration(seconds: 15));
      } on TimeoutException {
        target = null;
      }

      await FlutterBluePlus.stopScan();
      await _scanSub?.cancel();

      if (target != null) {
        await _completeConnection(target);
        return;
      }

      if (!isConnected.value) {
        isScanning.value = false;
        status.value = t('bleNotFound');
        errorMessage.value = t('bleBusyOtherPhone');
      }
    } catch (e) {
      isScanning.value = false;
      isConnected.value = false;
      status.value = e.toString().replaceFirst('Exception: ', '');
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

  bool _isSensor(String? name) {
    final n = (name ?? '').trim().toLowerCase();
    if (n.isEmpty) return false;
    return n == deviceName.toLowerCase() || n.contains('soil sensor');
  }

  BluetoothDevice? _findKnownDevice(Iterable<BluetoothDevice> devices) {
    for (final device in devices) {
      if (_isSensor(device.platformName) || _isSensor(device.advName)) {
        return device;
      }
    }
    return null;
  }

  Future<void> _prepareAdapter() async {
    if (!await FlutterBluePlus.isSupported) {
      throw Exception(t('bleNotSupported'));
    }

    await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.bluetooth,
      Permission.locationWhenInUse,
    ].request();

    final scanOk = await Permission.bluetoothScan.isGranted ||
        await Permission.locationWhenInUse.isGranted ||
        await Permission.bluetooth.isGranted;
    final connectOk = await Permission.bluetoothConnect.isGranted ||
        await Permission.bluetooth.isGranted ||
        await Permission.locationWhenInUse.isGranted;
    if (!scanOk && !connectOk) {
      throw Exception(t('blePermissionDenied'));
    }

    var adapter = await FlutterBluePlus.adapterState.first;
    if (adapter != BluetoothAdapterState.on) {
      try {
        await FlutterBluePlus.turnOn();
        adapter = await FlutterBluePlus.adapterState
            .firstWhere((state) => state == BluetoothAdapterState.on)
            .timeout(const Duration(seconds: 8));
      } catch (_) {
        throw Exception(t('bleOff'));
      }
    }
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
