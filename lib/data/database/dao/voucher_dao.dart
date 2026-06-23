import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';
import '../../../domain/entities/voucher.dart';

class VoucherDao {
  final DatabaseHelper _db;

  VoucherDao(this._db);

  Future<int> insertVoucher(Voucher voucher) async {
    return await _db.insert('vouchers', voucher.toJson());
  }

  Future<int> updateVoucher(Voucher voucher) async {
    return await _db.update(
      'vouchers',
      voucher.toJson(),
      where: 'id = ?',
      whereArgs: [voucher.id],
    );
  }

  Future<int> deleteVoucher(int id) async {
    return await _db.delete(
      'vouchers',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<Voucher?> getVoucherByCode(String code) async {
    final results = await _db.query(
      'vouchers',
      where: 'code = ? COLLATE NOCASE',
      whereArgs: [code],
    );
    if (results.isEmpty) return null;
    return Voucher.fromJson(results.first);
  }

  Future<List<Voucher>> getAllVouchers() async {
    final results = await _db.query('vouchers', orderBy: 'created_at DESC');
    return results.map((e) => Voucher.fromJson(e)).toList();
  }

  Future<List<Voucher>> getActiveVouchers() async {
    final results = await _db.query(
      'vouchers',
      where: "is_active = 1 AND used_count < usage_limit AND valid_from <= datetime('now', 'localtime') AND valid_until >= datetime('now', 'localtime')",
      orderBy: 'valid_until ASC',
    );
    return results.map((e) => Voucher.fromJson(e)).toList();
  }

  Future<void> incrementUsedCount(int id) async {
    final db = await _db.database;
    await db.rawUpdate(
      'UPDATE vouchers SET used_count = used_count + 1 WHERE id = ?',
      [id],
    );
  }
}
