import '../database_helper.dart';

class AttendanceDao {
  final DatabaseHelper _db;

  AttendanceDao(this._db);

  /// Clock in
  Future<int> clockIn(int userId) async {
    return await _db.insert('attendance', {
      'user_id': userId,
      'clock_in_time': DateTime.now().toIso8601String(),
    });
  }

  /// Clock out
  Future<int> clockOut(int userId, String notes) async {
    final activeAttendance = await getActiveAttendance(userId);
    if (activeAttendance == null) return 0;

    return await _db.update('attendance', {
      'clock_out_time': DateTime.now().toIso8601String(),
      'notes': notes,
    }, where: 'id = ?', whereArgs: [activeAttendance['id']]);
  }

  /// Get active attendance (clocked in but not clocked out)
  Future<Map<String, dynamic>?> getActiveAttendance(int userId) async {
    final results = await _db.query('attendance',
      where: 'user_id = ? AND clock_out_time IS NULL',
      whereArgs: [userId],
    );
    return results.isEmpty ? null : results.first;
  }

  /// Get attendance history for a user
  Future<List<Map<String, dynamic>>> getHistory(int userId) async {
    return await _db.query('attendance',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'clock_in_time DESC',
    );
  }
}
