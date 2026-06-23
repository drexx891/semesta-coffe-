import '../database_helper.dart';

class HoldOrderDao {
  final DatabaseHelper _db;

  HoldOrderDao(this._db);

  /// Menyimpan hold order baru
  Future<int> insertHoldOrder(Map<String, dynamic> holdOrder) async {
    return await _db.insert('hold_orders', holdOrder);
  }

  /// Mengambil semua hold order yang belum expired
  Future<List<Map<String, dynamic>>> getActiveHoldOrders() async {
    return await _db.rawQuery('''
      SELECT ho.*, u.name as user_name
      FROM hold_orders ho
      LEFT JOIN users u ON ho.user_id = u.id
      WHERE ho.expires_at > datetime('now', 'localtime')
      ORDER BY ho.created_at ASC
    ''');
  }

  /// Mengambil hold order berdasarkan ID
  Future<Map<String, dynamic>?> getHoldOrderById(int id) async {
    final results = await _db.query('hold_orders', where: 'id = ?', whereArgs: [id]);
    return results.isEmpty ? null : results.first;
  }

  /// Menghapus hold order
  Future<int> deleteHoldOrder(int id) async {
    return await _db.delete('hold_orders', where: 'id = ?', whereArgs: [id]);
  }

  /// Menghitung jumlah hold order aktif (untuk badge notifikasi)
  Future<int> countActiveHoldOrders() async {
    final result = await _db.rawQuery('''
      SELECT COUNT(*) as count FROM hold_orders
      WHERE expires_at > datetime('now', 'localtime')
    ''');
    return result.first['count'] as int;
  }

  /// Membersihkan hold order yang sudah expired
  Future<int> cleanupExpiredHoldOrders() async {
    return await _db.delete('hold_orders',
      where: "expires_at <= datetime('now', 'localtime')",
    );
  }
}
