import '../database_helper.dart';

/// Data Access Object untuk store_settings, activity_logs, hold_orders
class SettingsDao {
  final DatabaseHelper _db;

  SettingsDao(this._db);

  // ============================================================
  // STORE SETTINGS
  // ============================================================

  Future<Map<String, dynamic>?> getSettings() async {
    final results = await _db.query('store_settings', limit: 1);
    return results.isEmpty ? null : results.first;
  }

  Future<void> updateSettings(Map<String, dynamic> data) async {
    data['updated_at'] = DateTime.now().toIso8601String();
    final exists = await _db.count('store_settings');
    if (exists > 0) {
      await _db.update('store_settings', data, where: 'id = 1');
    } else {
      await _db.insert('store_settings', data);
    }
  }

  // ============================================================
  // ACTIVITY LOGS (read-only, tidak bisa dihapus)
  // ============================================================

  Future<int> insertLog(Map<String, dynamic> log) async {
    return await _db.insert('activity_logs', log);
  }

  Future<List<Map<String, dynamic>>> getLogs({
    String? actionType,
    int? userId,
    DateTime? start,
    DateTime? end,
    int limit = 100,
    int offset = 0,
  }) async {
    String where = '1=1';
    List<Object?> args = [];

    if (actionType != null) {
      where += ' AND al.action_type = ?';
      args.add(actionType);
    }
    if (userId != null) {
      where += ' AND al.user_id = ?';
      args.add(userId);
    }
    if (start != null) {
      where += ' AND al.created_at >= ?';
      args.add(start.toIso8601String());
    }
    if (end != null) {
      where += ' AND al.created_at <= ?';
      args.add(end.toIso8601String());
    }

    return await _db.rawQuery('''
      SELECT al.*, u.name as user_name
      FROM activity_logs al
      LEFT JOIN users u ON al.user_id = u.id
      WHERE $where
      ORDER BY al.created_at DESC
      LIMIT $limit OFFSET $offset
    ''', args);
  }

}

