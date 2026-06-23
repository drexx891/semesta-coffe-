import 'dart:convert';
import '../database_helper.dart';

/// Data Access Object untuk transaksi dan transaction_items
class TransactionDao {
  final DatabaseHelper _db;

  TransactionDao(this._db);

  /// Buat transaksi baru dengan items dalam satu transaksi database
  /// Returns: ID transaksi yang dibuat
  /// 
  /// KRITIS: Ini adalah fungsi utama POS. Pemotongan stok terjadi di sini.
  Future<int> createTransaction({
    required Map<String, dynamic> transaction,
    required List<Map<String, dynamic>> items,
    required List<Map<String, dynamic>> stockDeductions,
    List<Map<String, dynamic>>? payments,
  }) async {
    return await _db.transaction((txn) async {
      // 1. Insert transaksi
      final transactionId = await txn.insert('transactions', transaction);

      // 2. Insert semua items
      for (final item in items) {
        item['transaction_id'] = transactionId;
        await txn.insert('transaction_items', item);
      }

      // 3. Potong stok bahan baku
      for (final deduction in stockDeductions) {
        final ingredientId = deduction['ingredient_id'] as int;
        final quantity = deduction['quantity'] as double;

        // Ambil stok saat ini
        final currentStockResult = await txn.query('ingredients',
          columns: ['current_stock'],
          where: 'id = ?',
          whereArgs: [ingredientId],
        );

        if (currentStockResult.isNotEmpty) {
          final currentStock = (currentStockResult.first['current_stock'] as num).toDouble();
          final newStock = currentStock - quantity;

          // Update stok
          await txn.update('ingredients', {
            'current_stock': newStock < 0 ? 0 : newStock,
            'updated_at': DateTime.now().toIso8601String(),
          }, where: 'id = ?', whereArgs: [ingredientId]);

          // Log pergerakan stok
          await txn.insert('stock_movements', {
            'ingredient_id': ingredientId,
            'movement_type': 'out',
            'quantity': quantity,
            'stock_before': currentStock,
            'stock_after': newStock < 0 ? 0 : newStock,
            'reference': 'TRX-$transactionId',
            'reason': 'Penjualan',
            'user_id': transaction['user_id'],
            'created_at': DateTime.now().toIso8601String(),
          });
        }
      }

      // 4. Tambah poin loyalty pelanggan (Fase A)
      if (transaction['customer_id'] != null) {
        final totalTrx = transaction['total'] as double;
        // 1 poin tiap Rp 10.000
        final points = (totalTrx / 10000).floor();
        if (points > 0) {
          await txn.rawUpdate('''
            UPDATE customers 
            SET loyalty_points = loyalty_points + ? 
            WHERE id = ?
          ''', [points, transaction['customer_id']]);
        }
      }

      // 5. Simpan multi-payment (Fase B)
      if (payments != null && payments.isNotEmpty) {
        for (final payment in payments) {
          payment['transaction_id'] = transactionId;
          await txn.insert('transaction_payments', payment);
        }
      }

      return transactionId;
    });
  }

  /// Void transaksi — kembalikan stok, tandai sebagai void
  Future<void> voidTransaction({
    required int transactionId,
    required String reason,
    required int voidedBy,
  }) async {
    await _db.transaction((txn) async {
      // 1. Ambil detail transaksi dan items
      final transactionData = await txn.query('transactions',
        where: 'id = ?',
        whereArgs: [transactionId],
      );
      if (transactionData.isEmpty) return;

      final transactionItems = await txn.query('transaction_items',
        where: 'transaction_id = ?',
        whereArgs: [transactionId],
      );

      // 2. Kembalikan stok untuk setiap item
      for (final item in transactionItems) {
        final productId = item['product_id'] as int;
        final size = item['size'] as String;
        final quantity = item['quantity'] as int;
        final hasExtraShot = item['extra_shot'] == 1;

        // Ambil resep produk
        final recipes = await txn.query('recipes',
          where: 'product_id = ? AND size = ?',
          whereArgs: [productId, size],
        );

        for (final recipe in recipes) {
          final ingredientId = recipe['ingredient_id'] as int;
          final recipeQty = (recipe['quantity'] as num).toDouble() * quantity;

          // Ambil stok saat ini
          final currentStockResult = await txn.query('ingredients',
            columns: ['current_stock'],
            where: 'id = ?',
            whereArgs: [ingredientId],
          );

          if (currentStockResult.isNotEmpty) {
            final currentStock = (currentStockResult.first['current_stock'] as num).toDouble();
            final newStock = currentStock + recipeQty;

            await txn.update('ingredients', {
              'current_stock': newStock,
              'updated_at': DateTime.now().toIso8601String(),
            }, where: 'id = ?', whereArgs: [ingredientId]);

            await txn.insert('stock_movements', {
              'ingredient_id': ingredientId,
              'movement_type': 'in',
              'quantity': recipeQty,
              'stock_before': currentStock,
              'stock_after': newStock,
              'reference': 'VOID-$transactionId',
              'reason': 'Void transaksi: $reason',
              'user_id': voidedBy,
              'created_at': DateTime.now().toIso8601String(),
            });
          }
        }

        // Kembalikan stok extra shot jika ada
        if (hasExtraShot) {
          final modifierRecipes = await txn.query('modifier_recipes',
            where: 'modifier_type = ?',
            whereArgs: ['extra_shot'],
          );
          for (final mr in modifierRecipes) {
            final ingredientId = mr['ingredient_id'] as int;
            final mrQty = (mr['quantity'] as num).toDouble() * quantity;

            final currentStockResult = await txn.query('ingredients',
              columns: ['current_stock'],
              where: 'id = ?',
              whereArgs: [ingredientId],
            );

            if (currentStockResult.isNotEmpty) {
              final currentStock = (currentStockResult.first['current_stock'] as num).toDouble();
              final newStock = currentStock + mrQty;

              await txn.update('ingredients', {
                'current_stock': newStock,
                'updated_at': DateTime.now().toIso8601String(),
              }, where: 'id = ?', whereArgs: [ingredientId]);
            }
          }
        }

        // Kembalikan stok topping jika ada
        final toppingsJson = item['toppings_json'] as String?;
        if (toppingsJson != null && toppingsJson.isNotEmpty) {
          final toppings = jsonDecode(toppingsJson) as List;
          for (final topping in toppings) {
            final toppingId = topping['id'] as int;
            final modifierRecipes = await txn.query('modifier_recipes',
              where: 'modifier_type = ? AND modifier_ref_id = ?',
              whereArgs: ['topping', toppingId],
            );
            for (final mr in modifierRecipes) {
              final ingredientId = mr['ingredient_id'] as int;
              final mrQty = (mr['quantity'] as num).toDouble() * quantity;

              final currentStockResult = await txn.query('ingredients',
                columns: ['current_stock'],
                where: 'id = ?',
                whereArgs: [ingredientId],
              );

              if (currentStockResult.isNotEmpty) {
                final currentStock = (currentStockResult.first['current_stock'] as num).toDouble();
                final newStock = currentStock + mrQty;

                await txn.update('ingredients', {
                  'current_stock': newStock,
                  'updated_at': DateTime.now().toIso8601String(),
                }, where: 'id = ?', whereArgs: [ingredientId]);
              }
            }
          }
        }
      }

      // 3. Tandai transaksi sebagai VOID
      await txn.update('transactions', {
        'status': 'void',
        'void_reason': reason,
        'voided_by': voidedBy,
        'voided_at': DateTime.now().toIso8601String(),
      }, where: 'id = ?', whereArgs: [transactionId]);
    });
  }

  /// Get transaksi by ID dengan items
  Future<Map<String, dynamic>?> getById(int id) async {
    final results = await _db.rawQuery('''
      SELECT t.*, u.name as user_name, v.name as voided_by_name, c.name as customer_name
      FROM transactions t
      LEFT JOIN users u ON t.user_id = u.id
      LEFT JOIN users v ON t.voided_by = v.id
      LEFT JOIN customers c ON t.customer_id = c.id
      WHERE t.id = ?
    ''', [id]);

    if (results.isEmpty) return null;

    final transaction = Map<String, dynamic>.from(results.first);

    // Ambil items
    final items = await _db.query('transaction_items',
      where: 'transaction_id = ?',
      whereArgs: [id],
    );
    transaction['items'] = items;

    return transaction;
  }

  /// Update order status for KDS
  Future<void> updateOrderStatus(int transactionId, String newStatus) async {
    await _db.update('transactions', {
      'order_status': newStatus,
    }, where: 'id = ?', whereArgs: [transactionId]);
  }

  /// Get transaksi hari ini
  Future<List<Map<String, dynamic>>> getTodayTransactions() async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day).toIso8601String();
    final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59).toIso8601String();

    return await _db.rawQuery('''
      SELECT t.*, u.name as user_name, c.name as customer_name
      FROM transactions t
      LEFT JOIN users u ON t.user_id = u.id
      LEFT JOIN customers c ON t.customer_id = c.id
      WHERE t.created_at BETWEEN ? AND ?
      ORDER BY t.created_at DESC
    ''', [startOfDay, endOfDay]);
  }

  /// Get transaksi berdasarkan shift
  Future<List<Map<String, dynamic>>> getByShift(int shiftId) async {
    return await _db.rawQuery('''
      SELECT t.*, u.name as user_name, c.name as customer_name
      FROM transactions t
      LEFT JOIN users u ON t.user_id = u.id
      LEFT JOIN customers c ON t.customer_id = c.id
      WHERE t.shift_id = ?
      ORDER BY t.created_at DESC
    ''', [shiftId]);
  }

  /// Get transaksi berdasarkan range tanggal
  Future<List<Map<String, dynamic>>> getByDateRange(DateTime start, DateTime end) async {
    return await _db.rawQuery('''
      SELECT t.*, u.name as user_name, c.name as customer_name
      FROM transactions t
      LEFT JOIN users u ON t.user_id = u.id
      LEFT JOIN customers c ON t.customer_id = c.id
      WHERE t.created_at BETWEEN ? AND ?
      ORDER BY t.created_at DESC
    ''', [start.toIso8601String(), end.toIso8601String()]);
  }

  /// Hitung jumlah transaksi hari ini (untuk generate nomor transaksi)
  Future<int> countTodayTransactions() async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day).toIso8601String();
    return await _db.count('transactions', where: 'created_at >= ?', whereArgs: [startOfDay]);
  }

  /// Hitung jumlah antrian hari ini (untuk generate nomor antrian)
  Future<int> countTodayQueue() async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day).toIso8601String();
    return await _db.count('transactions',
      where: 'created_at >= ? AND status = ?',
      whereArgs: [startOfDay, 'completed'],
    );
  }

  /// Get total penjualan hari ini
  Future<double> getTodayTotalSales() async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day).toIso8601String();
    final result = await _db.rawQuery('''
      SELECT COALESCE(SUM(total), 0) as total_sales
      FROM transactions
      WHERE created_at >= ? AND status = 'completed'
    ''', [startOfDay]);
    return (result.first['total_sales'] as num).toDouble();
  }

  /// Get produk terlaris hari ini
  Future<Map<String, dynamic>?> getTodayBestSeller() async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day).toIso8601String();
    final result = await _db.rawQuery('''
      SELECT ti.product_name, SUM(ti.quantity) as total_qty
      FROM transaction_items ti
      INNER JOIN transactions t ON ti.transaction_id = t.id
      WHERE t.created_at >= ? AND t.status = 'completed'
      GROUP BY ti.product_id
      ORDER BY total_qty DESC
      LIMIT 1
    ''', [startOfDay]);
    return result.isEmpty ? null : result.first;
  }

  /// Get ringkasan penjualan per hari (7 hari terakhir)
  Future<List<Map<String, dynamic>>> getLast7DaysSales() async {
    return await _db.rawQuery('''
      SELECT DATE(created_at) as date,
             COUNT(*) as transaction_count,
             COALESCE(SUM(total), 0) as total_sales
      FROM transactions
      WHERE created_at >= datetime('now', '-7 days', 'localtime')
            AND status = 'completed'
      GROUP BY DATE(created_at)
      ORDER BY date ASC
    ''');
  }

  /// Get penjualan per kategori
  Future<List<Map<String, dynamic>>> getSalesByCategory({DateTime? start, DateTime? end}) async {
    String dateFilter = '';
    List<Object?> args = [];

    if (start != null && end != null) {
      dateFilter = 'AND t.created_at BETWEEN ? AND ?';
      args = [start.toIso8601String(), end.toIso8601String()];
    }

    return await _db.rawQuery('''
      SELECT c.name as category_name,
             SUM(ti.subtotal) as total_sales,
             SUM(ti.quantity) as total_qty
      FROM transaction_items ti
      INNER JOIN transactions t ON ti.transaction_id = t.id
      INNER JOIN products p ON ti.product_id = p.id
      INNER JOIN categories c ON p.category_id = c.id
      WHERE t.status = 'completed' $dateFilter
      GROUP BY c.id
      ORDER BY total_sales DESC
    ''', args);
  }

  /// Get penjualan per kasir
  Future<List<Map<String, dynamic>>> getSalesByCashier({DateTime? start, DateTime? end}) async {
    String dateFilter = '';
    List<Object?> args = [];

    if (start != null && end != null) {
      dateFilter = 'AND created_at BETWEEN ? AND ?';
      args = [start.toIso8601String(), end.toIso8601String()];
    }

    return await _db.rawQuery('''
      SELECT u.name as cashier_name,
             COUNT(t.id) as total_transactions,
             SUM(t.total) as total_sales
      FROM transactions t
      INNER JOIN users u ON t.user_id = u.id
      WHERE t.status = 'completed' $dateFilter
      GROUP BY u.id
      ORDER BY total_sales DESC
    ''', args);
  }

  /// Get penjualan per metode pembayaran
  Future<List<Map<String, dynamic>>> getSalesByPaymentMethod({DateTime? start, DateTime? end}) async {
    String dateFilter = '';
    List<Object?> args = [];

    if (start != null && end != null) {
      dateFilter = 'AND created_at BETWEEN ? AND ?';
      args = [start.toIso8601String(), end.toIso8601String()];
    }

    return await _db.rawQuery('''
      SELECT payment_method,
             COUNT(id) as total_transactions,
             SUM(total) as total_sales
      FROM transactions
      WHERE status = 'completed' $dateFilter
      GROUP BY payment_method
      ORDER BY total_sales DESC
    ''', args);
  }

  /// Get transaksi void
  Future<List<Map<String, dynamic>>> getVoidTransactions({DateTime? start, DateTime? end}) async {
    String dateFilter = '';
    List<Object?> args = [];

    if (start != null && end != null) {
      dateFilter = 'AND t.created_at BETWEEN ? AND ?';
      args = [start.toIso8601String(), end.toIso8601String()];
    }

    return await _db.rawQuery('''
      SELECT t.*, u.name as user_name, v.name as voided_by_name
      FROM transactions t
      LEFT JOIN users u ON t.user_id = u.id
      LEFT JOIN users v ON t.voided_by = v.id
      WHERE t.status = 'void' $dateFilter
      ORDER BY t.created_at DESC
    ''', args);
  }

  /// Get Laporan Diskon
  Future<List<Map<String, dynamic>>> getDiscountReport({DateTime? start, DateTime? end}) async {
    String dateFilter = '';
    List<Object?> args = [];

    if (start != null && end != null) {
      dateFilter = 'AND created_at BETWEEN ? AND ?';
      args = [start.toIso8601String(), end.toIso8601String()];
    }

    return await _db.rawQuery('''
      SELECT discount_reason,
             COUNT(id) as total_transactions,
             SUM(discount_amount) as total_discount
      FROM transactions
      WHERE status = 'completed' AND discount_amount > 0 $dateFilter
      GROUP BY discount_reason
      ORDER BY total_discount DESC
    ''', args);
  }

  /// Get Laporan Pajak & Service Charge
  Future<List<Map<String, dynamic>>> getTaxReport({DateTime? start, DateTime? end}) async {
    String dateFilter = '';
    List<Object?> args = [];

    if (start != null && end != null) {
      dateFilter = 'AND created_at BETWEEN ? AND ?';
      args = [start.toIso8601String(), end.toIso8601String()];
    }

    return await _db.rawQuery('''
      SELECT DATE(created_at) as date,
             SUM(tax_amount) as total_tax,
             SUM(service_charge_amount) as total_service_charge,
             SUM(total) as total_sales
      FROM transactions
      WHERE status = 'completed' $dateFilter
      GROUP BY DATE(created_at)
      ORDER BY date DESC
    ''', args);
  }

  /// Get Laporan HPP & Laba (Simulasi)
  Future<List<Map<String, dynamic>>> getHppReport({DateTime? start, DateTime? end}) async {
    String dateFilter = '';
    List<Object?> args = [];

    if (start != null && end != null) {
      dateFilter = 'AND t.created_at BETWEEN ? AND ?';
      args = [start.toIso8601String(), end.toIso8601String()];
    }

    return await _db.rawQuery('''
      SELECT ti.product_name,
             SUM(ti.quantity) as total_qty,
             SUM(ti.subtotal) as total_revenue,
             SUM(ti.quantity * (
                SELECT COALESCE(SUM(r.quantity * i.cost_per_unit), 0)
                FROM recipes r
                JOIN ingredients i ON r.ingredient_id = i.id
                WHERE r.product_id = ti.product_id AND r.size = ti.size
             )) as total_cogs
      FROM transaction_items ti
      JOIN transactions t ON ti.transaction_id = t.id
      WHERE t.status = 'completed' $dateFilter
      GROUP BY ti.product_id, ti.product_name
      ORDER BY total_revenue DESC
    ''', args);
  }

  /// Menghapus semua riwayat transaksi, berguna untuk reset data / factory reset
  Future<void> deleteAllTransactions() async {
    await _db.transaction((txn) async {
      await txn.delete('transaction_items');
      await txn.delete('transactions');
      await txn.delete('stock_movements');
    });
  }
}
