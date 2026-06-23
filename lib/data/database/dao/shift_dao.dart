import 'dart:convert';
import '../database_helper.dart';

/// Data Access Object untuk shifts
class ShiftDao {
  final DatabaseHelper _db;

  ShiftDao(this._db);

  /// Buka shift baru
  Future<int> openShift(Map<String, dynamic> shift) async {
    return await _db.insert('shifts', shift);
  }

  /// Tutup shift
  Future<void> closeShift({
    required int shiftId,
    required double closingCash,
    required double expectedCash,
    required double cashDifference,
    required Map<String, dynamic> summary,
  }) async {
    await _db.update('shifts', {
      'closing_cash': closingCash,
      'expected_cash': expectedCash,
      'cash_difference': cashDifference,
      'status': 'closed',
      'closed_at': DateTime.now().toIso8601String(),
      'summary_json': jsonEncode(summary),
    }, where: 'id = ?', whereArgs: [shiftId]);
  }

  /// Get shift aktif (open) — hanya boleh ada satu
  Future<Map<String, dynamic>?> getActiveShift() async {
    final results = await _db.rawQuery('''
      SELECT s.*, u.name as user_name
      FROM shifts s
      LEFT JOIN users u ON s.user_id = u.id
      WHERE s.status = 'open'
      ORDER BY s.opened_at DESC
      LIMIT 1
    ''');
    return results.isEmpty ? null : results.first;
  }

  /// Get shift by ID
  Future<Map<String, dynamic>?> getById(int id) async {
    final results = await _db.rawQuery('''
      SELECT s.*, u.name as user_name
      FROM shifts s
      LEFT JOIN users u ON s.user_id = u.id
      WHERE s.id = ?
    ''', [id]);
    return results.isEmpty ? null : results.first;
  }

  /// Get semua shift hari ini
  Future<List<Map<String, dynamic>>> getTodayShifts() async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day).toIso8601String();
    return await _db.rawQuery('''
      SELECT s.*, u.name as user_name
      FROM shifts s
      LEFT JOIN users u ON s.user_id = u.id
      WHERE s.opened_at >= ?
      ORDER BY s.opened_at DESC
    ''', [startOfDay]);
  }

  /// Get shift berdasarkan range tanggal
  Future<List<Map<String, dynamic>>> getByDateRange(DateTime start, DateTime end) async {
    return await _db.rawQuery('''
      SELECT s.*, u.name as user_name
      FROM shifts s
      LEFT JOIN users u ON s.user_id = u.id
      WHERE s.opened_at BETWEEN ? AND ?
      ORDER BY s.opened_at DESC
    ''', [start.toIso8601String(), end.toIso8601String()]);
  }

  /// Hitung ringkasan shift saat penutupan
  Future<Map<String, dynamic>> calculateShiftSummary(int shiftId) async {
    // Total penjualan per metode pembayaran
    final salesByMethod = await _db.rawQuery('''
      SELECT 
        payment_method,
        COUNT(*) as count,
        COALESCE(SUM(total), 0) as total
      FROM transactions
      WHERE shift_id = ? AND status = 'completed'
      GROUP BY payment_method
    ''', [shiftId]);

    double totalCash = 0;
    double totalQris = 0;
    double totalTransfer = 0;
    double totalEdc = 0;
    double totalVoucher = 0;
    int totalTransactions = 0;

    for (final row in salesByMethod) {
      final method = row['payment_method'] as String;
      final total = (row['total'] as num).toDouble();
      final count = row['count'] as int;
      totalTransactions += count;

      switch (method) {
        case 'cash': totalCash = total;
        case 'qris': totalQris = total;
        case 'transfer': totalTransfer = total;
        case 'edc': totalEdc = total;
        case 'voucher': totalVoucher = total;
      }
    }

    // Total void
    final voidResult = await _db.rawQuery('''
      SELECT COUNT(*) as count FROM transactions
      WHERE shift_id = ? AND status = 'void'
    ''', [shiftId]);
    final totalVoid = voidResult.first['count'] as int;

    // Total diskon
    final discountResult = await _db.rawQuery('''
      SELECT COALESCE(SUM(discount_amount), 0) as total_discount
      FROM transactions
      WHERE shift_id = ? AND status = 'completed'
    ''', [shiftId]);
    final totalDiscount = (discountResult.first['total_discount'] as num).toDouble();

    // Total service charge
    final scResult = await _db.rawQuery('''
      SELECT COALESCE(SUM(service_charge_amount), 0) as total_sc
      FROM transactions
      WHERE shift_id = ? AND status = 'completed'
    ''', [shiftId]);
    final totalSC = (scResult.first['total_sc'] as num).toDouble();

    // Total pajak
    final taxResult = await _db.rawQuery('''
      SELECT COALESCE(SUM(tax_amount), 0) as total_tax
      FROM transactions
      WHERE shift_id = ? AND status = 'completed'
    ''', [shiftId]);
    final totalTax = (taxResult.first['total_tax'] as num).toDouble();

    final totalSales = totalCash + totalQris + totalTransfer + totalEdc + totalVoucher;

    return {
      'totalTransactions': totalTransactions,
      'totalVoidTransactions': totalVoid,
      'totalSales': totalSales,
      'totalCashSales': totalCash,
      'totalQrisSales': totalQris,
      'totalTransferSales': totalTransfer,
      'totalEdcSales': totalEdc,
      'totalVoucherSales': totalVoucher,
      'totalDiscount': totalDiscount,
      'totalServiceCharge': totalSC,
      'totalTax': totalTax,
    };
  }

  /// Cek apakah ada shift yang masih open
  Future<bool> hasOpenShift() async {
    return await _db.exists('shifts', where: 'status = ?', whereArgs: ['open']);
  }
}
