// lib/database/daos/recommendation_dao.dart

import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../../models/recommendation_results.dart';
import '../../utils/id_generator.dart';

class RecommendationDao {
  final Future<Database> Function() _getDb;

  RecommendationDao(this._getDb);

  Future<String> saveRecommendationHistory(
    RecommendationResults results,
    String contextType, {
    DateTime? targetDate,
    String? mealType,
  }) async {
    final id = IdGenerator.generateId();
    final now = DateTime.now();
    final db = await _getDb();
    await db.insert('recommendation_history', {
      'id': id,
      'result_data': jsonEncode(results.toJson()),
      'created_at': now.toIso8601String(),
      'context_type': contextType,
      'target_date': targetDate?.toIso8601String(),
      'meal_type': mealType,
      'user_id': null,
    });
    return id;
  }

  Future<List<Map<String, dynamic>>> getRecommendationHistory({
    int limit = 10,
    String? contextType,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await _getDb();
    String query = 'SELECT * FROM recommendation_history';
    final args = <dynamic>[];
    final conditions = <String>[];

    if (contextType != null) {
      conditions.add('context_type = ?');
      args.add(contextType);
    }
    if (startDate != null) {
      conditions.add('created_at >= ?');
      args.add(startDate.toIso8601String());
    }
    if (endDate != null) {
      conditions.add('created_at <= ?');
      args.add(endDate.toIso8601String());
    }
    if (conditions.isNotEmpty) {
      query += ' WHERE ${conditions.join(' AND ')}';
    }
    query += ' ORDER BY created_at DESC LIMIT ?';
    args.add(limit);
    return await db.rawQuery(query, args);
  }

  Future<int> cleanupRecommendationHistory({int daysToKeep = 14}) async {
    final db = await _getDb();
    final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));
    return await db.delete(
      'recommendation_history',
      where: 'created_at < ?',
      whereArgs: [cutoffDate.toIso8601String()],
    );
  }

  // getRawRecommendationById returns the raw JSON string for a history entry.
  // DatabaseHelper.getRecommendationById uses this and then calls
  // RecommendationResults.fromJson(json, dbHelper) — which needs the full
  // DatabaseHelper to do recipe lookups, so that method stays in DatabaseHelper.
  Future<String?> getRawRecommendationById(String id) async {
    final db = await _getDb();
    final maps = await db.query(
      'recommendation_history',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return maps.first['result_data'] as String;
  }

  Future<void> updateRecommendationResultData(String historyId, String resultData) async {
    final db = await _getDb();
    await db.update(
      'recommendation_history',
      {'result_data': resultData},
      where: 'id = ?',
      whereArgs: [historyId],
    );
  }
}
