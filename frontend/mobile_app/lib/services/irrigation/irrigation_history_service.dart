import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../../models/irrigation_history_record.dart';
import '../../models/irrigation_result.dart';
import '../firebase/firestore_service.dart';

/// Local SQLite store for irrigation predictions. Works fully offline.
/// When a farmer is signed in, the same record is also written to Firestore.
class IrrigationHistoryService {
  IrrigationHistoryService._();
  static final IrrigationHistoryService instance = IrrigationHistoryService._();

  Database? _db;

  Future<Database> get _database async {
    if (_db != null) return _db!;

    final dbPath = await getDatabasesPath();
    _db = await openDatabase(
      p.join(dbPath, 'irrigation_history.db'),
      version: 1,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE irrigation_history (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            created_at TEXT NOT NULL,
            latitude REAL,
            longitude REAL,
            soil_moisture REAL NOT NULL,
            temp_mean REAL,
            apparent_temp_mean REAL,
            solar_radiation REAL,
            rain_mm REAL,
            rain_hours REAL,
            forecast_rain_24h REAL,
            wind_speed_max REAL,
            et0 REAL,
            weather_code REAL,
            model_prediction TEXT,
            final_prediction TEXT,
            status TEXT NOT NULL,
            reason TEXT NOT NULL,
            weather_source TEXT NOT NULL,
            mode TEXT NOT NULL
          )
        ''');
      },
    );
    return _db!;
  }

  Future<void> save(IrrigationResult result) async {
    final db = await _database;
    await db.insert('irrigation_history', result.toHistoryMap());

    try {
      await FirestoreService.instance.saveIrrigation(result);
    } catch (e) {
      debugPrint('Firestore irrigation save deferred/failed: $e');
    }
  }

  Future<List<IrrigationHistoryRecord>> getAll() async {
    try {
      final cloud = await FirestoreService.instance.getIrrigationHistory();
      if (cloud.isNotEmpty) return cloud;
    } catch (e) {
      debugPrint('Firestore irrigation history fallback to local: $e');
    }

    final db = await _database;
    final rows = await db.query(
      'irrigation_history',
      orderBy: 'created_at DESC',
    );
    return rows.map(IrrigationHistoryRecord.fromMap).toList();
  }
}
