import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../config/firestore_schema.dart';
import '../models/farmer_account.dart';
import '../models/fertilizer_advice.dart';
import '../models/irrigation_history_record.dart';
import '../models/irrigation_result.dart';
import '../models/irrigation_weather.dart';

/// Cloud Firestore access for farmer-owned records.
/// Prediction still runs on the phone. This service only stores history.
class FirestoreService {
  FirestoreService._();
  static final FirestoreService instance = FirestoreService._();

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  String? get _uid =>
      Firebase.apps.isEmpty ? null : FirebaseAuth.instance.currentUser?.uid;

  Future<void> saveUser(FarmerAccount farmer) async {
    if (Firebase.apps.isEmpty) return;
    await _db.collection(FirestoreSchema.users).doc(farmer.id).set({
      'fullName': farmer.fullName,
      'email': farmer.email,
      'mobile': farmer.mobile,
      'createdAt': farmer.createdAt ?? DateTime.now().toUtc(),
    }, SetOptions(merge: true));
  }

  Future<FarmerAccount?> getUser(String uid) async {
    if (Firebase.apps.isEmpty) return null;
    try {
      final doc = await _db.collection(FirestoreSchema.users).doc(uid).get();
      if (!doc.exists || doc.data() == null) return null;
      return FarmerAccount.fromJson(doc.id, doc.data()!);
    } catch (e) {
      debugPrint('getUser failed: $e');
      return null;
    }
  }

  Future<void> saveIrrigation(IrrigationResult result) async {
    final uid = _uid;
    if (uid == null) return;

    await _db.collection(FirestoreSchema.irrigation).add({
      'userId': uid,
      'createdAt': result.createdAt.toUtc(),
      'latitude': result.latitude,
      'longitude': result.longitude,
      'soilMoisture': result.soilMoisture,
      'temperature': result.weatherUsed?.tempMean,
      'apparentTemperature': result.weatherUsed?.apparentTempMean,
      'solarRadiation': result.weatherUsed?.solarRadiation,
      'rainfall': result.weatherUsed?.rainMm,
      'rainHours': result.weatherUsed?.rainHours,
      'forecastRainfall': result.weatherUsed?.forecastRain24h,
      'windSpeedMax': result.weatherUsed?.windSpeedMax,
      'et0': result.weatherUsed?.et0,
      'weatherCode': result.weatherUsed?.weatherCode,
      'modelPrediction': result.modelPrediction,
      'prediction': result.finalPrediction,
      'status': result.status,
      'reason': result.reason,
      'weatherSource': result.weatherSource,
      'mode': result.mode,
    });

    if (result.weatherUsed != null && result.weatherSource == 'live') {
      await saveWeather(
        weather: result.weatherUsed!,
        latitude: result.latitude,
        longitude: result.longitude,
      );
    }
  }

  Future<void> saveWeather({
    required IrrigationWeather weather,
    double? latitude,
    double? longitude,
  }) async {
    final uid = _uid;
    if (uid == null) return;

    await _db.collection(FirestoreSchema.weather).add({
      'userId': uid,
      'timestamp': weather.fetchedAt.toUtc(),
      'latitude': latitude,
      'longitude': longitude,
      'temperature': weather.tempMean,
      'apparentTemperature': weather.apparentTempMean,
      'solarRadiation': weather.solarRadiation,
      'rainfall': weather.rainMm,
      'rainHours': weather.rainHours,
      'forecastRainfall': weather.forecastRain24h,
      'windSpeedMax': weather.windSpeedMax,
      'windGustMax': weather.windGustMax,
      'et0': weather.et0,
      'weatherCode': weather.weatherCode,
      'dailyWeatherCode': weather.dailyWeatherCode,
      'source': weather.isCached ? 'cached' : 'live',
    });
  }

  Future<void> saveFertilizer(FertilizerAdvice advice) async {
    final uid = _uid;
    if (uid == null) return;

    await _db.collection(FirestoreSchema.fertilizer).add({
      'userId': uid,
      'timestamp': DateTime.now().toUtc(),
      'soilData': {
        'moisture': advice.moisture,
        'temperature': advice.temp,
        'ph': advice.ph,
        'nitrogen': advice.nitrogen,
        'phosphorus': advice.phosphorus,
        'potassium': advice.potassium,
      },
      'treeAge': advice.treeAge,
      'growthStage': advice.stage,
      'stageName': advice.stageName,
      'fertilizerClass': advice.fertilizerClass,
      'deficiencyScore': advice.deficiencyScore,
      'recommendation': {
        'ureaG': advice.ureaG,
        'tspG': advice.tspG,
        'mopG': advice.mopG,
      },
    });
  }

  Future<List<IrrigationHistoryRecord>> getIrrigationHistory() async {
    final uid = _uid;
    if (uid == null) return [];

    final snapshot = await _db
        .collection(FirestoreSchema.irrigation)
        .where('userId', isEqualTo: uid)
        .get();

    final records = snapshot.docs
        .map((doc) => IrrigationHistoryRecord.fromFirestore(doc.id, doc.data()))
        .toList();
    records.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return records;
  }

  Future<List<FertilizerAdvice>> getFertilizerHistory() async {
    final uid = _uid;
    if (uid == null) return [];

    final snapshot = await _db
        .collection(FirestoreSchema.fertilizer)
        .where('userId', isEqualTo: uid)
        .get();

    final records = snapshot.docs
        .map((doc) => FertilizerAdvice.fromFirestore(doc.id, doc.data()))
        .toList();
    records.sort((a, b) => (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
    return records;
  }
}
