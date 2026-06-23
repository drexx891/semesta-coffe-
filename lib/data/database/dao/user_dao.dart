import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../database_helper.dart';

/// Data Access Object untuk tabel users
class UserDao {
  final DatabaseHelper _db;

  UserDao(this._db);

  /// Hash password menggunakan SHA-256
  static String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Insert user baru
  Future<int> insert(Map<String, dynamic> user) async {
    return await _db.insert('users', user);
  }

  /// Update user
  Future<int> update(int id, Map<String, dynamic> data) async {
    data['updated_at'] = DateTime.now().toIso8601String();
    return await _db.update('users', data, where: 'id = ?', whereArgs: [id]);
  }

  /// Get user by ID
  Future<Map<String, dynamic>?> getById(int id) async {
    final results = await _db.query('users', where: 'id = ?', whereArgs: [id]);
    return results.isEmpty ? null : results.first;
  }

  /// Get user by username
  Future<Map<String, dynamic>?> getByUsername(String username) async {
    final results = await _db.query('users',
      where: 'username = ?',
      whereArgs: [username],
    );
    return results.isEmpty ? null : results.first;
  }

  /// Authenticate user
  Future<Map<String, dynamic>?> authenticate(String username, String password) async {
    final passwordHash = hashPassword(password);
    final results = await _db.query('users',
      where: 'username = ? AND password_hash = ? AND is_active = 1',
      whereArgs: [username, passwordHash],
    );
    return results.isEmpty ? null : results.first;
  }

  /// Validate PIN for supervisor/owner actions
  Future<Map<String, dynamic>?> validatePin(String pin) async {
    final results = await _db.query('users',
      where: 'pin = ? AND role IN (?, ?) AND is_active = 1',
      whereArgs: [pin, 'owner', 'supervisor'],
    );
    return results.isEmpty ? null : results.first;
  }

  /// Increment failed login count
  Future<void> incrementFailedLogin(int userId) async {
    await _db.rawExecute(
      'UPDATE users SET failed_login_count = failed_login_count + 1, updated_at = datetime(\'now\', \'localtime\') WHERE id = ?',
      [userId],
    );
  }

  /// Lock account for specified duration
  Future<void> lockAccount(int userId, DateTime lockUntil) async {
    await _db.update('users', {
      'locked_until': lockUntil.toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    }, where: 'id = ?', whereArgs: [userId]);
  }

  /// Reset failed login count
  Future<void> resetFailedLogin(int userId) async {
    await _db.update('users', {
      'failed_login_count': 0,
      'locked_until': null,
      'updated_at': DateTime.now().toIso8601String(),
    }, where: 'id = ?', whereArgs: [userId]);
  }

  /// Get all active users
  Future<List<Map<String, dynamic>>> getAll({bool activeOnly = true}) async {
    if (activeOnly) {
      return await _db.query('users', where: 'is_active = 1', orderBy: 'name ASC');
    }
    return await _db.query('users', orderBy: 'name ASC');
  }

  /// Get users by role
  Future<List<Map<String, dynamic>>> getByRole(String role) async {
    return await _db.query('users',
      where: 'role = ? AND is_active = 1',
      whereArgs: [role],
      orderBy: 'name ASC',
    );
  }

  /// Check if username exists
  Future<bool> usernameExists(String username, {int? excludeId}) async {
    String where = 'username = ?';
    List<Object?> whereArgs = [username];

    if (excludeId != null) {
      where += ' AND id != ?';
      whereArgs.add(excludeId);
    }

    return await _db.exists('users', where: where, whereArgs: whereArgs);
  }

  /// Update password
  Future<void> updatePassword(int userId, String newPassword) async {
    await _db.update('users', {
      'password_hash': hashPassword(newPassword),
      'updated_at': DateTime.now().toIso8601String(),
    }, where: 'id = ?', whereArgs: [userId]);
  }

  /// Toggle active status
  Future<void> toggleActive(int userId, bool isActive) async {
    await _db.update('users', {
      'is_active': isActive ? 1 : 0,
      'updated_at': DateTime.now().toIso8601String(),
    }, where: 'id = ?', whereArgs: [userId]);
  }
}
