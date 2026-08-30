// lib/services/local_db_service.dart
import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/services.dart' show rootBundle;

class LocalDbService {
  Database? _db;

  Future<void> init() async {
    final documentsDir = await getApplicationDocumentsDirectory();
    final dbPath = join(documentsDir.path, "app_data.db");

    // Copy bundled recommendation rules DB on first run only
    if (!await File(dbPath).exists()) {
      final data = await rootBundle.load("assets/db/recommendation_rules.db");
      final bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );
      await File(dbPath).writeAsBytes(bytes, flush: true);
    }

    _db = await openDatabase(
      dbPath,
      version: 1,
      onOpen: (db) async {
        // Create the history table if it doesn't exist yet (app-generated data)
        await db.execute('''
          CREATE TABLE IF NOT EXISTS grading_history (
            id TEXT PRIMARY KEY,
            user_id TEXT NOT NULL,
            quality TEXT NOT NULL,
            confidence REAL NOT NULL,
            defect_type TEXT,
            severity_percent REAL,
            weight_grams INTEGER,
            recommendation TEXT NOT NULL,
            image_url TEXT,
            created_at TEXT NOT NULL
          )
        ''');
      },
    );
  }

  /// Look up the recommendation for a given quality/defect/severity/weight combination
  Future<Map<String, dynamic>?> getRecommendation({
    required String quality,
    String? defectType,
    double? severityPercent,
    int? weightGrams,
  }) async {
    if (_db == null) await init();

    List<Map<String, dynamic>> results;

    if (quality == "high_quality" || quality == "medium_quality") {
      final weight = weightGrams ?? 0;
      results = await _db!.query(
        "recommendation_rules",
        where: "quality_level = ? AND ? BETWEEN weight_min AND weight_max",
        whereArgs: [quality, weight],
      );
    } else {
      final severity = severityPercent ?? 0;
      final defect = defectType ?? "rot";
      results = await _db!.query(
        "recommendation_rules",
        where:
            "quality_level = ? AND defect_type = ? AND ? BETWEEN severity_min AND severity_max",
        whereArgs: [quality, defect, severity],
      );
    }

    return results.isNotEmpty ? results.first : null;
  }

  // ── History CRUD (fully local, offline) ──────────────────────────
  Future<void> saveHistory(Map<String, dynamic> record) async {
    if (_db == null) await init();
    await _db!.insert(
      "grading_history",
      record,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getHistory(String userId) async {
    if (_db == null) await init();
    return await _db!.query(
      "grading_history",
      where: "user_id = ?",
      whereArgs: [userId],
      orderBy: "created_at DESC",
    );
  }

  Future<void> deleteOne(String id) async {
    if (_db == null) await init();
    await _db!.delete("grading_history", where: "id = ?", whereArgs: [id]);
  }

  Future<void> deleteAll(String userId) async {
    if (_db == null) await init();
    await _db!.delete(
      "grading_history",
      where: "user_id = ?",
      whereArgs: [userId],
    );
  }
}
