// lib/services/reports/farm_dataset_report_service.dart
//
// FARM DATASET REPORT (read-only — does not change any other component)
//
// For the logged-in farmer:
//   • Farm location  → farms/{farmId} latitude/longitude, else the latest
//                      irrigation record's GPS (irrigation already saves
//                      latitude / longitude), else latest weather record.
//   • Location name  → reverse geocoding of that GPS → farm district →
//                      profile location → coordinates.
//   • How many tests each component has:
//       disease_predictions · quality_results · growth_predictions ·
//       irrigation_predictions · fertilizer_predictions
//
// Every login only sees its own farm (filtered by user id).
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';

/// The 5 app components, in chart order.
enum FarmComponent { disease, grading, growth, irrigation, fertilizer }

class FarmInfo {
  final String farmName;
  final String locationName;
  final double? latitude;
  final double? longitude;

  /// 'farm' | 'irrigation' | 'weather' | 'profile' | 'none'
  final String locationSource;

  const FarmInfo({
    required this.farmName,
    required this.locationName,
    required this.locationSource,
    this.latitude,
    this.longitude,
  });

  bool get hasGps => latitude != null && longitude != null;
}

/// One record = one test (one image / one check), with its time.
class FarmTest {
  final FarmComponent component;
  final DateTime time;
  const FarmTest(this.component, this.time);
}

class FarmDatasetReport {
  final FarmInfo farm;
  final List<FarmTest> tests;
  const FarmDatasetReport({required this.farm, required this.tests});
}

class FarmDatasetReportService {
  FarmDatasetReportService._();
  static final FarmDatasetReportService instance = FarmDatasetReportService._();

  // Collection names (same as config/firestore_schema.dart).
  static const _users = 'users';
  static const _farms = 'farms';
  static const _weather = 'weather';
  static const _disease = 'disease_predictions';
  static const _quality = 'quality_results';
  static const _growth = 'growth_predictions';
  static const _irrigation = 'irrigation_predictions';
  static const _irrigationLegacy = 'irrigation';
  static const _fertilizer = 'fertilizer_predictions';
  static const _fertilizerLegacy = 'fertilizer';

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  String? get uid =>
      Firebase.apps.isEmpty ? null : FirebaseAuth.instance.currentUser?.uid;

  final Map<String, String?> _placeCache = {};

  // ═══════════════════════════════════════════════════════════════════
  //  LOAD
  // ═══════════════════════════════════════════════════════════════════
  Future<FarmDatasetReport?> load() async {
    final id = uid;
    if (id == null) return null;

    // Read the 5 components in parallel.
    final results = await Future.wait([
      _docs(_disease, 'user_id', id),
      _docs(_quality, 'user_id', id),
      _docs(_growth, 'farmerId', id),
      _docs(_irrigation, 'farmerId', id, legacy: _irrigationLegacy),
      _docs(_fertilizer, 'farmerId', id, legacy: _fertilizerLegacy),
    ]);

    final tests = <FarmTest>[
      ..._toTests(results[0], FarmComponent.disease, const [
        'created_at_local',
        'created_at',
      ]),
      ..._toTests(results[1], FarmComponent.grading, const ['created_at']),
      ..._toTests(results[2], FarmComponent.growth, const ['captureDate']),
      ..._toTests(results[3], FarmComponent.irrigation, const [
        'predictedAt',
        'createdAt',
        'timestamp',
      ]),
      ..._toTests(results[4], FarmComponent.fertilizer, const [
        'predictedAt',
        'createdAt',
        'timestamp',
      ]),
    ];

    final farm = await _farmInfo(id, irrigationDocs: results[3]);
    return FarmDatasetReport(farm: farm, tests: tests);
  }

  /// Reads one collection for this farmer. If empty, tries the older
  /// collection (same fallback the existing history screens use).
  Future<List<Map<String, dynamic>>> _docs(
    String collection,
    String userField,
    String id, {
    String? legacy,
  }) async {
    try {
      var snap = await _db
          .collection(collection)
          .where(userField, isEqualTo: id)
          .get();
      if (snap.docs.isEmpty && legacy != null) {
        snap = await _db
            .collection(legacy)
            .where('userId', isEqualTo: id)
            .get();
      }
      return snap.docs.map((d) => d.data()).toList();
    } catch (e) {
      debugPrint('📊 Farm report: cannot read $collection ($e)');
      return [];
    }
  }

  List<FarmTest> _toTests(
    List<Map<String, dynamic>> docs,
    FarmComponent component,
    List<String> timeFields,
  ) {
    return docs.map((d) {
      DateTime? time;
      for (final f in timeFields) {
        time = _toDate(d[f]);
        if (time != null) break;
      }
      return FarmTest(
        component,
        time ?? DateTime.fromMillisecondsSinceEpoch(0),
      );
    }).toList();
  }

  // ═══════════════════════════════════════════════════════════════════
  //  FARM LOCATION
  // ═══════════════════════════════════════════════════════════════════
  Future<FarmInfo> _farmInfo(
    String id, {
    required List<Map<String, dynamic>> irrigationDocs,
  }) async {
    String farmName = '';
    String district = '';
    String profileLocation = '';
    double? lat;
    double? lng;
    String source = 'none';

    // 1. Profile + farm document.
    try {
      final user = await _db.collection(_users).doc(id).get();
      final u = user.data() ?? {};
      profileLocation = (u['location'] ?? '').toString();
      final farmId = (u['defaultFarmId'] ?? id).toString();
      final farm = await _db.collection(_farms).doc(farmId).get();
      final f = farm.data() ?? {};
      farmName = (f['farmName'] ?? '').toString();
      district = (f['district'] ?? '').toString();
      lat = (f['latitude'] as num?)?.toDouble();
      lng = (f['longitude'] as num?)?.toDouble();
      if (lat != null && lng != null) source = 'farm';
    } catch (e) {
      debugPrint('📊 Farm report: farm read failed ($e)');
    }

    // 2. Latest irrigation GPS (irrigation saves latitude / longitude).
    if (lat == null || lng == null) {
      final gps = _latestGps(irrigationDocs, const [
        'predictedAt',
        'createdAt',
        'timestamp',
      ]);
      if (gps != null) {
        lat = gps.$1;
        lng = gps.$2;
        source = 'irrigation';
      }
    }

    // 3. Latest weather GPS.
    if (lat == null || lng == null) {
      try {
        final w = await _db
            .collection(_weather)
            .where('farmerId', isEqualTo: id)
            .get();
        final gps = _latestGps(w.docs.map((d) => d.data()).toList(), const [
          'timestamp',
          'forecastTime',
        ]);
        if (gps != null) {
          lat = gps.$1;
          lng = gps.$2;
          source = 'weather';
        }
      } catch (_) {}
    }

    // Location name.
    String? name;
    if (lat != null && lng != null) name = await _placeName(lat, lng);
    name ??= district.isNotEmpty ? district : null;
    if (name == null && profileLocation.isNotEmpty) {
      name = profileLocation;
      if (source == 'none') source = 'profile';
    }
    name ??= (lat != null && lng != null)
        ? '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}'
        : '';

    return FarmInfo(
      farmName: farmName,
      locationName: name,
      latitude: lat,
      longitude: lng,
      locationSource: source,
    );
  }

  /// (lat, lng) of the newest record that has GPS.
  (double, double)? _latestGps(
    List<Map<String, dynamic>> docs,
    List<String> timeFields,
  ) {
    (double, double)? best;
    DateTime? bestTime;
    for (final d in docs) {
      final lat = (d['latitude'] as num?)?.toDouble();
      final lng = (d['longitude'] as num?)?.toDouble();
      if (lat == null || lng == null) continue;
      DateTime? t;
      for (final f in timeFields) {
        t = _toDate(d[f]);
        if (t != null) break;
      }
      t ??= DateTime.fromMillisecondsSinceEpoch(0);
      if (bestTime == null || t.isAfter(bestTime)) {
        bestTime = t;
        best = (lat, lng);
      }
    }
    return best;
  }

  /// On-device reverse geocoding, e.g. "Kokuvil, Jaffna".
  Future<String?> _placeName(double lat, double lng) async {
    final key = '${lat.toStringAsFixed(3)},${lng.toStringAsFixed(3)}';
    if (_placeCache.containsKey(key)) return _placeCache[key];
    String? name;
    try {
      final marks = await placemarkFromCoordinates(
        lat,
        lng,
      ).timeout(const Duration(seconds: 6));
      if (marks.isNotEmpty) {
        final p = marks.first;
        final parts = <String>[
          if ((p.subLocality ?? '').isNotEmpty) p.subLocality!,
          if ((p.locality ?? '').isNotEmpty) p.locality!,
          if ((p.subAdministrativeArea ?? '').isNotEmpty)
            p.subAdministrativeArea!,
        ];
        if (parts.isNotEmpty) name = parts.toSet().take(2).join(', ');
      }
    } catch (e) {
      debugPrint('📍 Reverse geocoding failed: $e');
    }
    _placeCache[key] = name;
    return name;
  }

  DateTime? _toDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is Timestamp) return v.toDate();
    if (v is String) return DateTime.tryParse(v);
    try {
      return (v as dynamic).toDate() as DateTime;
    } catch (_) {
      return null;
    }
  }
}
