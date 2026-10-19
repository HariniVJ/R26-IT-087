import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../l10n/app_strings.dart';
import '../../config/firestore_schema.dart';
import '../../models/app_notification.dart';
import '../../models/farm.dart';
import '../../models/farmer_account.dart';
import '../../models/fertilizer_advice.dart';
import '../../models/irrigation_history_record.dart';
import '../../models/irrigation_result.dart';
import '../../models/irrigation_weather.dart';
import '../../models/soil_sensor_reading.dart';

class FirestoreService {
  FirestoreService._();

  static final FirestoreService instance = FirestoreService._();

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  String? get _uid =>
      Firebase.apps.isEmpty ? null : FirebaseAuth.instance.currentUser?.uid;

  DateTime? _lastSensorWriteAt;
  DateTime? _lastWeatherWriteAt;

  static const _sensorMinInterval = Duration(seconds: 20);

  static const _weatherMinInterval = Duration(minutes: 30);

  Future<void> saveUser(FarmerAccount farmer) async {
    if (Firebase.apps.isEmpty) return;

    await _db.collection(FirestoreSchema.users).doc(farmer.id).set({
      'fullName': farmer.fullName,
      'email': farmer.email,
      'phone': farmer.mobile,
      'mobile': farmer.mobile,
      'location': farmer.location,
      'role': farmer.role,
      if (farmer.defaultFarmId != null) 'defaultFarmId': farmer.defaultFarmId,
      'createdAt': farmer.createdAt ?? DateTime.now().toUtc(),
    }, SetOptions(merge: true));
  }

  Future<FarmerAccount?> getUser(String uid) async {
    if (Firebase.apps.isEmpty) {
      return null;
    }

    try {
      final doc = await _db.collection(FirestoreSchema.users).doc(uid).get();

      if (!doc.exists || doc.data() == null) {
        return null;
      }

      return FarmerAccount.fromJson(doc.id, doc.data()!);
    } catch (e) {
      debugPrint('getUser failed: $e');

      return null;
    }
  }

  Future<Farm?> ensureDefaultFarm({
    required String farmerId,
    String farmName = 'My Farm',
    double? latitude,
    double? longitude,
  }) async {
    if (Firebase.apps.isEmpty) {
      return null;
    }

    final ref = _db.collection(FirestoreSchema.farms).doc(farmerId);

    final existing = await ref.get();

    if (existing.exists && existing.data() != null) {
      await _db.collection(FirestoreSchema.users).doc(farmerId).set({
        'defaultFarmId': farmerId,
      }, SetOptions(merge: true));

      return Farm.fromFirestore(existing.id, existing.data()!);
    }

    final now = DateTime.now().toUtc();

    await ref.set({
      'farmerId': farmerId,
      'farmName': farmName,
      'district': '',
      'latitude': latitude,
      'longitude': longitude,
      'createdAt': now,
    });

    await _db.collection(FirestoreSchema.users).doc(farmerId).set({
      'defaultFarmId': farmerId,
    }, SetOptions(merge: true));

    return Farm(
      id: farmerId,
      farmerId: farmerId,
      farmName: farmName,
      latitude: latitude,
      longitude: longitude,
      createdAt: now,
    );
  }

  Future<Farm?> getDefaultFarm() async {
    final uid = _uid;

    if (uid == null) {
      return null;
    }

    try {
      final farmId = await _farmId();

      if (farmId == null) {
        return null;
      }

      final doc = await _db.collection(FirestoreSchema.farms).doc(farmId).get();

      if (!doc.exists || doc.data() == null) {
        return null;
      }

      return Farm.fromFirestore(doc.id, doc.data()!);
    } catch (e) {
      debugPrint('getDefaultFarm failed: $e');

      return null;
    }
  }

  Future<String?> _farmId() async {
    final uid = _uid;

    if (uid == null) {
      return null;
    }

    final user = await getUser(uid);

    if (user?.defaultFarmId != null && user!.defaultFarmId!.isNotEmpty) {
      return user.defaultFarmId;
    }

    final farm = await ensureDefaultFarm(farmerId: uid);

    return farm?.id;
  }

  Future<void> saveSensorReading(SoilSensorReading reading) async {
    final uid = _uid;

    if (uid == null) {
      return;
    }

    final now = DateTime.now().toUtc();

    if (_lastSensorWriteAt != null &&
        now.difference(_lastSensorWriteAt!) < _sensorMinInterval) {
      return;
    }

    _lastSensorWriteAt = now;

    final farmId = await _farmId();

    await _db.collection(FirestoreSchema.sensorReadings).add({
      'farmerId': uid,
      'farmId': farmId,
      'treeId': null,
      'soilMoisture': reading.moisture,
      'soilTemperature': reading.temp,
      'soilEc': reading.ec,
      'soilPh': reading.ph,
      'nitrogen': reading.nitrogen,
      'phosphorus': reading.phosphorus,
      'potassium': reading.potassium,
      'timestamp': now,
      'source': 'esp32_ble',
    });
  }

  Future<List<Map<String, dynamic>>> getSensorHistory({int limit = 50}) async {
    final uid = _uid;

    if (uid == null) {
      return [];
    }

    final snapshot = await _db
        .collection(FirestoreSchema.sensorReadings)
        .where('farmerId', isEqualTo: uid)
        .get();

    final docs = snapshot.docs.toList()
      ..sort((a, b) {
        final aTime = a.data()['timestamp'];

        final bTime = b.data()['timestamp'];

        return _toDate(bTime).compareTo(_toDate(aTime));
      });

    return docs
        .take(limit)
        .map((doc) => {'id': doc.id, ...doc.data()})
        .toList();
  }

  Future<void> saveIrrigation(IrrigationResult result) async {
    final uid = _uid;

    if (uid == null) {
      throw StateError(
        'Cannot save irrigation history without a signed-in user.',
      );
    }

    String? farmId;
    try {
      farmId = await _farmId();
    } catch (error) {
      debugPrint('Farm lookup skipped for irrigation history: $error');
    }

    final predicted = result.finalPrediction ?? result.modelPrediction;

    await _db.collection(FirestoreSchema.irrigationPredictions).add({
      'user_id': uid,
      'farmerId': uid,
      'farmId': farmId,
      'treeId': null,
      'soilMoisture': result.soilMoisture,
      'soilTemperature': result.soilTemperature,
      'airTemperature': result.weatherUsed?.tempMean,
      'humidity': result.weatherUsed?.humidity,
      'rainfallForecast': result.weatherUsed?.forecastRain24h,
      'rainExpectedInHours': result.weatherUsed?.rainExpectedInHours,
      'rainProbability': result.weatherUsed?.rainProbability,
      'modelPrediction': result.modelPrediction,
      'finalPrediction': result.finalPrediction,
      'modelConfidence': result.modelConfidence,
      'pumpStatus': 'off',
      'status': result.status,
      'reason': result.reason,
      'mode': result.mode,
      'weatherSource': result.weatherSource,
      'latitude': result.latitude,
      'longitude': result.longitude,
      'predictedAt': result.createdAt.toUtc(),
    });

    if (result.weatherUsed != null && result.weatherSource == 'live') {
      await saveWeather(
        weather: result.weatherUsed!,
        latitude: result.latitude,
        longitude: result.longitude,
      );
    }

    await _notifyIrrigation(uid, predicted, result);
  }

  Future<void> saveWeather({
    required IrrigationWeather weather,
    double? latitude,
    double? longitude,
  }) async {
    final uid = _uid;

    if (uid == null) {
      return;
    }

    final now = DateTime.now().toUtc();

    if (_lastWeatherWriteAt != null &&
        now.difference(_lastWeatherWriteAt!) < _weatherMinInterval) {
      return;
    }

    _lastWeatherWriteAt = now;

    final farmId = await _farmId();

    await _db.collection(FirestoreSchema.weather).add({
      'farmerId': uid,
      'farmId': farmId,
      'temperature': weather.tempMean,
      'humidity': weather.humidity,
      'rainfallForecast': weather.forecastRain24h,
      'rainExpectedInHours': weather.rainExpectedInHours,
      'rainProbability': weather.rainProbability,
      'rainfall': weather.rainMm,
      'rainHours': weather.rainHours,
      'forecastTime': weather.fetchedAt.toUtc(),
      'latitude': latitude,
      'longitude': longitude,
      'apparentTemperature': weather.apparentTempMean,
      'solarRadiation': weather.solarRadiation,
      'windSpeedMax': weather.windSpeedMax,
      'windGustMax': weather.windGustMax,
      'et0': weather.et0,
      'weatherCode': weather.weatherCode,
      'dailyWeatherCode': weather.dailyWeatherCode,
      'source': weather.isCached ? 'cached' : 'live',
      'timestamp': weather.fetchedAt.toUtc(),
    });
  }

  Future<void> saveFertilizer(FertilizerAdvice advice) async {
    final uid = _uid;

    if (uid == null) {
      throw StateError(
        'Cannot save fertilizer history without a signed-in user.',
      );
    }

    String? farmId;
    try {
      farmId = await _farmId();
    } catch (error) {
      debugPrint('Farm lookup skipped for fertilizer history: $error');
    }

    await _db.collection(FirestoreSchema.fertilizerPredictions).add({
      'user_id': uid,
      'userId': uid,
      'farmerId': uid,
      'farmId': farmId,
      'treeId': advice.treeId,
      'soilMoisture': advice.moisture,
      'soilTemperature': advice.temp,
      'soilPh': advice.ph,
      'nitrogen': advice.nitrogen,
      'phosphorus': advice.phosphorus,
      'potassium': advice.potassium,
      'treeAge': advice.treeAge,
      'predictedLevel': advice.fertilizerClass,
      'ureaG': advice.ureaG,
      'tspG': advice.tspG,
      'mopG': advice.mopG,
      'deficiencyScore': advice.deficiencyScore,
      'growthStage': advice.stage,
      'stageName': advice.stageName,
      'modelConfidence': advice.modelConfidence,
      'predictedAt': (advice.createdAt ?? DateTime.now()).toUtc(),
    });

    if (advice.nitrogen < 70) {
      await addNotification(
        type: FirestoreSchema.notifyNLow,
        title: t('nLowTitle'),
        message: '${t('nitrogen')}: ${advice.nitrogen}',
      );
    }

    if (advice.phosphorus < 50) {
      await addNotification(
        type: FirestoreSchema.notifyPLow,
        title: t('pLowTitle'),
        message: '${t('phosphorus')}: ${advice.phosphorus}',
      );
    }

    if (advice.potassium < 225) {
      await addNotification(
        type: FirestoreSchema.notifyKLow,
        title: t('kLowTitle'),
        message: '${t('potassium')}: ${advice.potassium}',
      );
    }

    await addNotification(
      type: FirestoreSchema.notifyNewFertilizer,
      title: t('newFertilizer'),
      message:
          '${t('recommendedFertilizer')}: ${advice.fertilizerClass}. '
          '${t('urea')} ${advice.ureaG} g, '
          '${t('tsp')} ${advice.tspG} g, '
          '${t('mop')} ${advice.mopG} g',
      treeId: advice.treeId,
      skipDedupe: true,
    );

    if (advice.fertilizerClass == 'HIGH' ||
        advice.fertilizerClass == 'MEDIUM') {
      await addNotification(
        type: advice.fertilizerClass == 'HIGH'
            ? FirestoreSchema.notifyNpkDeficiency
            : FirestoreSchema.notifyFertilizerRequired,
        title: advice.fertilizerClass == 'HIGH'
            ? t('nLowTitle')
            : t('fertilizerRequired'),
        message:
            '${t('recommendedFertilizer')} '
            '${advice.fertilizerClass}. '
            '${t('urea')} ${advice.ureaG} g, '
            '${t('tsp')} ${advice.tspG} g, '
            '${t('mop')} ${advice.mopG} g',
      );
    }
  }

  Future<void> saveIrrigationLog({
    required DateTime startedAt,
    DateTime? endedAt,
    String pumpStatus = 'on',
    String activation = 'manual',
    double? waterAmountLiters,
    String? treeId,
  }) async {
    final uid = _uid;

    if (uid == null) {
      return;
    }

    final farmId = await _farmId();

    final durationMinutes = endedAt == null
        ? null
        : endedAt.difference(startedAt).inMinutes;

    await _db.collection(FirestoreSchema.irrigationLogs).add({
      'farmerId': uid,
      'farmId': farmId,
      'treeId': treeId,
      'startedAt': startedAt.toUtc(),
      'endedAt': endedAt?.toUtc(),
      'durationMinutes': durationMinutes,
      'pumpStatus': pumpStatus,
      'waterAmountLiters': waterAmountLiters,
      'activation': activation,
    });
  }

  Future<void> saveFertilizerLog({
    required String fertilizerType,
    required double recommendedAmount,
    required double actualAmount,
    required DateTime appliedAt,
    String? treeId,
  }) async {
    final uid = _uid;

    if (uid == null) {
      return;
    }

    final farmId = await _farmId();

    await _db.collection(FirestoreSchema.fertilizerLogs).add({
      'farmerId': uid,
      'farmId': farmId,
      'treeId': treeId,
      'fertilizerType': fertilizerType,
      'recommendedAmount': recommendedAmount,
      'actualAmount': actualAmount,
      'appliedAt': appliedAt.toUtc(),
    });
  }

  Future<void> addNotification({
    required String type,
    required String title,
    required String message,
    String? treeId,
    bool skipDedupe = false,
  }) async {
    final uid = _uid;

    if (uid == null) {
      return;
    }

    if (!skipDedupe && await _hasRecent(type)) {
      return;
    }

    final farmId = await _farmId();

    await _db.collection(FirestoreSchema.notifications).add({
      'userId': uid,
      'farmerId': uid,
      'farmId': farmId,
      'treeId': treeId,
      'type': type,
      'title': title,
      'message': message,
      'isRead': false,
      'createdAt': DateTime.now().toUtc(),
    });
  }

  Future<bool> _hasRecent(String type) async {
    final existing = await getNotifications(limit: 20);

    final cutoff = DateTime.now().toUtc().subtract(const Duration(hours: 6));

    return existing.any((n) => n.type == type && n.createdAt.isAfter(cutoff));
  }

  Future<int> unreadCount() async {
    final items = await getNotifications(limit: 80);

    return items.where((n) => !n.isRead).length;
  }

  Future<void> notifyRainIfNeeded(IrrigationWeather weather) async {
    if (!weather.rainWithinTwoHours) {
      return;
    }

    await notifyRainFromHours(weather.rainExpectedInHours ?? 2);
  }

  Future<void> notifyRainFromHours(int? hours) async {
    if (hours == null || hours < 0 || hours > 2) {
      return;
    }

    final shown = hours < 1 ? 1 : hours;

    await addNotification(
      type: FirestoreSchema.notifyRainExpected,
      title: t('rainAlertTitle'),
      message: t('rainAlertBody').replaceAll('{hours}', '$shown'),
    );
  }

  Future<List<AppNotification>> getNotifications({int limit = 40}) async {
    final uid = _uid;

    if (uid == null) {
      return [];
    }

    final snapshot = await _db
        .collection(FirestoreSchema.notifications)
        .where('farmerId', isEqualTo: uid)
        .get();

    final records = snapshot.docs
        .map((doc) => AppNotification.fromFirestore(doc.id, doc.data()))
        .toList();

    records.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return records.take(limit).toList();
  }

  Future<void> markNotificationRead(String id) async {
    final uid = _uid;

    if (uid == null) {
      return;
    }

    await _db.collection(FirestoreSchema.notifications).doc(id).update({
      'isRead': true,
    });
  }

  Future<List<Map<String, dynamic>>> getIrrigationLogs({
    int limit = 200,
  }) async {
    final uid = _uid;

    if (uid == null) {
      return [];
    }

    final snapshot = await _db
        .collection(FirestoreSchema.irrigationLogs)
        .where('farmerId', isEqualTo: uid)
        .get();

    final docs = snapshot.docs.toList()
      ..sort((a, b) {
        return _toDate(
          b.data()['startedAt'],
        ).compareTo(_toDate(a.data()['startedAt']));
      });

    return docs
        .take(limit)
        .map((doc) => {'id': doc.id, ...doc.data()})
        .toList();
  }

  Future<List<IrrigationHistoryRecord>> getIrrigationHistory() async {
    final uid = _uid;

    if (uid == null) {
      return [];
    }

    final predictionByFarmerSnapshot = await _db
        .collection(FirestoreSchema.irrigationPredictions)
        .where('farmerId', isEqualTo: uid)
        .get();

    final predictionByUserSnapshot = await _db
        .collection(FirestoreSchema.irrigationPredictions)
        .where('user_id', isEqualTo: uid)
        .get();

    final legacySnapshot = await _db
        .collection(FirestoreSchema.irrigationLegacy)
        .where('userId', isEqualTo: uid)
        .get();

    final documentsByPath = <String, DocumentSnapshot<Map<String, dynamic>>>{};
    for (final doc in [
      ...predictionByFarmerSnapshot.docs,
      ...predictionByUserSnapshot.docs,
      ...legacySnapshot.docs,
    ]) {
      documentsByPath[doc.reference.path] = doc;
    }

    final records = documentsByPath.values
        .map(
          (doc) => IrrigationHistoryRecord.fromFirestore(
            doc.id,
            doc.data() ?? const <String, dynamic>{},
          ),
        )
        .toList();

    records.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return records;
  }

  Future<List<FertilizerAdvice>> getFertilizerHistory() async {
    final uid = _uid;

    if (uid == null) {
      return [];
    }

    final predictionByFarmerSnapshot = await _db
        .collection(FirestoreSchema.fertilizerPredictions)
        .where('farmerId', isEqualTo: uid)
        .get();

    final predictionByUserSnapshot = await _db
        .collection(FirestoreSchema.fertilizerPredictions)
        .where('userId', isEqualTo: uid)
        .get();

    final predictionBySnakeCaseUserSnapshot = await _db
        .collection(FirestoreSchema.fertilizerPredictions)
        .where('user_id', isEqualTo: uid)
        .get();

    final legacySnapshot = await _db
        .collection(FirestoreSchema.fertilizerLegacy)
        .where('userId', isEqualTo: uid)
        .get();

    final documentsByPath = <String, DocumentSnapshot<Map<String, dynamic>>>{};
    for (final doc in [
      ...predictionByFarmerSnapshot.docs,
      ...predictionByUserSnapshot.docs,
      ...predictionBySnakeCaseUserSnapshot.docs,
      ...legacySnapshot.docs,
    ]) {
      documentsByPath[doc.reference.path] = doc;
    }

    final records = documentsByPath.values
        .map(
          (doc) => FertilizerAdvice.fromFirestore(
            doc.id,
            doc.data() ?? const <String, dynamic>{},
          ),
        )
        .toList();

    records.sort(
      (a, b) =>
          (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)),
    );

    return records;
  }

  Future<void> _notifyIrrigation(
    String uid,
    String? predicted,
    IrrigationResult result,
  ) async {
    if (predicted == 'SKIP_SOIL_ALREADY_WET' || result.soilMoisture >= 70) {
      await addNotification(
        type: FirestoreSchema.notifySoilWet,
        title: t('soilWetTitle'),
        message:
            '${t('soilMoisture')} '
            '${result.soilMoisture.toStringAsFixed(1)}%. '
            '${t('soilAlreadyWet')}',
      );

      return;
    }

    if (predicted == 'SKIP_RAIN_EXPECTED') {
      final hours = result.weatherUsed?.rainExpectedInHours ?? 2;

      final shown = hours < 1 ? 1 : hours;

      await addNotification(
        type: FirestoreSchema.notifySkippedRain,
        title: t('skippedRainTitle'),
        message: t('waitRainReason').replaceAll('{hours}', '$shown'),
      );

      return;
    }

    if (predicted == 'SUITABLE_TO_IRRIGATE' ||
        predicted == 'SUITABLE_BASED_ON_SOIL' ||
        result.soilMoisture < 45) {
      await addNotification(
        type: result.soilMoisture < 45
            ? FirestoreSchema.notifySoilTooLow
            : FirestoreSchema.notifyIrrigationRecommended,
        title: result.soilMoisture < 45
            ? t('soilTooLowTitle')
            : t('irrigateTitle'),
        message: result.reason,
      );
    }
  }

  Future<void> saveGrowthDetectionResult({
    required Map<String, dynamic> resultData,
    required String imagePath,
    required DateTime captureTime,
  }) async {
    final uid = _uid;

    if (uid == null) {
      debugPrint('Growth save skipped: Firebase user is not logged in.');

      return;
    }

    final growthStage = Map<String, dynamic>.from(
      resultData['growth_stage'] ?? {},
    );

    final transition = Map<String, dynamic>.from(
      resultData['transition_prediction'] ?? {},
    );

    final harvest = Map<String, dynamic>.from(
      resultData['harvest_prediction'] ?? {},
    );

    final weather = Map<String, dynamic>.from(resultData['weather'] ?? {});

    final soil = Map<String, dynamic>.from(resultData['soil'] ?? {});

    final environment = Map<String, dynamic>.from(
      resultData['environment'] ?? {},
    );

    final recommendations = Map<String, dynamic>.from(
      resultData['recommendations'] ?? {},
    );

    String? farmId;
    try {
      farmId = await _farmId();
    } catch (e, stackTrace) {
      debugPrint('Growth farm/tree lookup skipped: $e');
      debugPrint('$stackTrace');
    }

    final treeId = resultData['tree_id'] ?? resultData['treeId'];

    try {
      final doc = await _db.collection(FirestoreSchema.growthPredictions).add({
        'farmerId': uid,

        'farmId': farmId,

        'treeId': treeId,

        'capturedAt': captureTime.toUtc(),

        // Firebase Storage is unavailable for growth predictions.
        'imageUrl': null,

        'localImagePath': imagePath,

        'detectedStage': growthStage['detected'] ?? 'Unknown',

        'confidencePercent': growthStage['confidence_percent'],

        'nextStage': resultData['next_stage'],

        'estimatedDaysRange': transition['range'] ?? '',

        'estimatedStartDate': transition['estimated_start_date'] ?? '',

        'estimatedEndDate': transition['estimated_end_date'] ?? '',

        'estimatedDateRange': transition['estimated_date_range'] ?? '',

        'remainingDaysRange': harvest['range'] ?? '',

        'harvestStatus': harvest['message'] ?? '',

        'soilTemperatureCelsius': soil['temperature_celsius'],

        'weatherTemperatureCelsius': weather['temperature_celsius'],

        'weatherCondition': weather['condition'] ?? 'Unavailable',

        'humidityPercent': weather['humidity_percent'],

        'environmentLevel': environment['level'] ?? 'Unknown',

        'environmentStatus':
            environment['status'] ?? 'Environmental data unavailable',

        'developmentCondition':
            environment['status'] ?? 'Environmental data unavailable',

        'developmentConditionLevel': environment['level'] ?? 'Unknown',

        'developmentConditionReason': environment['reason'] ?? '',

        'developmentConditionMessage': environment['farmer_message'] ?? '',

        'recommendations': recommendations,

        'careTip': recommendations['care_tip'] ?? '',

        'careAction': recommendations['care_action'] ?? '',

        'riskWarning': recommendations['risk_warning'] ?? '',

        'recordedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('Growth prediction saved successfully: ${doc.id}');
    } catch (e, stackTrace) {
      debugPrint('Growth prediction save failed: $e');

      debugPrint('$stackTrace');

      rethrow;
    }
  }

  DateTime _toDate(dynamic value) {
    if (value is DateTime) {
      return value;
    }

    try {
      return (value as dynamic).toDate() as DateTime;
    } catch (_) {
      return DateTime.tryParse(value?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
    }
  }
}
