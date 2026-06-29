import '../database_helper.dart';

/// Data Access Object untuk ingredients, recipes, stock movements
class StockDao {
  final DatabaseHelper _db;

  StockDao(this._db);

  // ============================================================
  // INGREDIENTS
  // ============================================================

  Future<List<Map<String, dynamic>>> getAllIngredients({bool activeOnly = true}) async {
    if (activeOnly) {
      return await _db.query('ingredients', where: 'is_active = 1', orderBy: 'category ASC, name ASC');
    }
    return await _db.query('ingredients', orderBy: 'category ASC, name ASC');
  }

  Future<Map<String, dynamic>?> getIngredientById(int id) async {
    final results = await _db.query('ingredients', where: 'id = ?', whereArgs: [id]);
    return results.isEmpty ? null : results.first;
  }

  Future<int> insertIngredient(Map<String, dynamic> ingredient) async {
    return await _db.insert('ingredients', ingredient);
  }

  Future<int> updateIngredient(int id, Map<String, dynamic> data) async {
    data['updated_at'] = DateTime.now().toIso8601String();
    return await _db.update('ingredients', data, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteIngredient(int id) async {
    return await _db.update('ingredients', {'is_active': 0}, where: 'id = ?', whereArgs: [id]);
  }

  /// Get bahan baku dengan stok kritis (di bawah minimum)
  Future<List<Map<String, dynamic>>> getCriticalStock() async {
    return await _db.rawQuery('''
      SELECT * FROM ingredients
      WHERE current_stock <= min_stock AND is_active = 1
      ORDER BY (current_stock / CASE WHEN min_stock = 0 THEN 1 ELSE min_stock END) ASC
    ''');
  }

  /// Get bahan baku dengan stok warning (< 2× minimum)
  Future<List<Map<String, dynamic>>> getWarningStock() async {
    return await _db.rawQuery('''
      SELECT * FROM ingredients
      WHERE current_stock > min_stock AND current_stock <= (min_stock * 2) AND is_active = 1
      ORDER BY name ASC
    ''');
  }

  /// Hitung jumlah bahan baku kritis
  Future<int> countCriticalStock() async {
    return await _db.count('ingredients',
      where: 'current_stock <= min_stock AND is_active = 1',
    );
  }

  // ============================================================
  // STOCK OPERATIONS
  // ============================================================

  /// Tambah stok (Stock In)
  Future<void> addStock({
    required int ingredientId,
    required double quantity,
    required int userId,
    String? invoiceNumber,
    String? supplier,
  }) async {
    await _db.transaction((txn) async {
      // Ambil stok saat ini
      final result = await txn.query('ingredients',
        columns: ['current_stock'],
        where: 'id = ?',
        whereArgs: [ingredientId],
      );

      if (result.isNotEmpty) {
        final currentStock = (result.first['current_stock'] as num).toDouble();
        final newStock = currentStock + quantity;

        // Update stok
        await txn.update('ingredients', {
          'current_stock': newStock,
          'updated_at': DateTime.now().toIso8601String(),
        }, where: 'id = ?', whereArgs: [ingredientId]);

        // Log movement
        await txn.insert('stock_movements', {
          'ingredient_id': ingredientId,
          'movement_type': 'in',
          'quantity': quantity,
          'stock_before': currentStock,
          'stock_after': newStock,
          'reference': 'manual',
          'reason': 'Pembelian stok',
          'invoice_number': invoiceNumber,
          'supplier': supplier,
          'user_id': userId,
          'created_at': DateTime.now().toIso8601String(),
        });
      }
    });
  }

  /// Koreksi stok (Stock Opname / Kerusakan / dll)
  Future<void> correctStock({
    required int ingredientId,
    required double newQuantity,
    required String reason,
    required int userId,
  }) async {
    await _db.transaction((txn) async {
      final result = await txn.query('ingredients',
        columns: ['current_stock'],
        where: 'id = ?',
        whereArgs: [ingredientId],
      );

      if (result.isNotEmpty) {
        final currentStock = (result.first['current_stock'] as num).toDouble();
        final difference = newQuantity - currentStock;

        await txn.update('ingredients', {
          'current_stock': newQuantity,
          'updated_at': DateTime.now().toIso8601String(),
        }, where: 'id = ?', whereArgs: [ingredientId]);

        await txn.insert('stock_movements', {
          'ingredient_id': ingredientId,
          'movement_type': 'correction',
          'quantity': difference,
          'stock_before': currentStock,
          'stock_after': newQuantity,
          'reference': 'manual',
          'reason': reason,
          'user_id': userId,
          'created_at': DateTime.now().toIso8601String(),
        });
      }
    });
  }

  /// Get riwayat pergerakan stok
  Future<List<Map<String, dynamic>>> getStockMovements({
    int? ingredientId,
    DateTime? start,
    DateTime? end,
    int? limit,
  }) async {
    String where = '1=1';
    List<Object?> args = [];

    if (ingredientId != null) {
      where += ' AND sm.ingredient_id = ?';
      args.add(ingredientId);
    }
    if (start != null) {
      where += ' AND sm.created_at >= ?';
      args.add(start.toIso8601String());
    }
    if (end != null) {
      where += ' AND sm.created_at <= ?';
      args.add(end.toIso8601String());
    }

    final limitStr = limit != null ? 'LIMIT $limit' : '';

    return await _db.rawQuery('''
      SELECT sm.*, i.name as ingredient_name, i.unit, u.name as user_name
      FROM stock_movements sm
      LEFT JOIN ingredients i ON sm.ingredient_id = i.id
      LEFT JOIN users u ON sm.user_id = u.id
      WHERE $where
      ORDER BY sm.created_at DESC
      $limitStr
    ''', args);
  }

  // ============================================================
  // RECIPES
  // ============================================================

  /// Get resep untuk produk
  Future<List<Map<String, dynamic>>> getRecipesForProduct(int productId) async {
    return await _db.rawQuery('''
      SELECT r.*, i.name as ingredient_name, i.unit as ingredient_unit
      FROM recipes r
      LEFT JOIN ingredients i ON r.ingredient_id = i.id
      WHERE r.product_id = ?
      ORDER BY r.size ASC, i.name ASC
    ''', [productId]);
  }

  /// Set resep untuk produk (replace all)
  Future<void> setRecipes(int productId, List<Map<String, dynamic>> recipes) async {
    await _db.transaction((txn) async {
      await txn.delete('recipes', where: 'product_id = ?', whereArgs: [productId]);
      for (final recipe in recipes) {
        recipe['product_id'] = productId;
        await txn.insert('recipes', recipe);
      }
    });
  }

  /// Cek apakah produk memiliki resep
  Future<bool> hasRecipe(int productId) async {
    return await _db.exists('recipes', where: 'product_id = ?', whereArgs: [productId]);
  }

  /// Get modifier recipes (extra shot, topping)
  Future<List<Map<String, dynamic>>> getModifierRecipes(String modifierType, {int? modifierRefId}) async {
    String where = 'modifier_type = ?';
    List<Object?> args = [modifierType];

    if (modifierRefId != null) {
      where += ' AND modifier_ref_id = ?';
      args.add(modifierRefId);
    }

    return await _db.rawQuery('''
      SELECT mr.*, i.name as ingredient_name, i.unit as ingredient_unit
      FROM modifier_recipes mr
      LEFT JOIN ingredients i ON mr.ingredient_id = i.id
      WHERE $where
    ''', args);
  }

  /// Hitung pemotongan stok yang diperlukan untuk satu item transaksi
  /// Returns: list of {ingredient_id, quantity}
  Future<List<Map<String, dynamic>>> calculateStockDeduction({
    required int productId,
    required String size,
    required bool extraShot,
    required List<int> toppingIds,
    required int quantity,
  }) async {
    final deductions = <int, double>{}; // ingredient_id → total quantity

    // 1. Resep dasar produk
    final recipes = await _db.query('recipes',
      where: 'product_id = ? AND size = ?',
      whereArgs: [productId, size],
    );
    for (final r in recipes) {
      final ingId = r['ingredient_id'] as int;
      final qty = (r['quantity'] as num).toDouble() * quantity;
      deductions[ingId] = (deductions[ingId] ?? 0) + qty;
    }

    // 2. Extra shot
    if (extraShot) {
      final modifierRecipes = await _db.query('modifier_recipes',
        where: 'modifier_type = ?',
        whereArgs: ['extra_shot'],
      );
      for (final mr in modifierRecipes) {
        final ingId = mr['ingredient_id'] as int;
        final qty = (mr['quantity'] as num).toDouble() * quantity;
        deductions[ingId] = (deductions[ingId] ?? 0) + qty;
      }
    }

    // 3. Toppings
    for (final toppingId in toppingIds) {
      final modifierRecipes = await _db.query('modifier_recipes',
        where: 'modifier_type = ? AND modifier_ref_id = ?',
        whereArgs: ['topping', toppingId],
      );
      for (final mr in modifierRecipes) {
        final ingId = mr['ingredient_id'] as int;
        final qty = (mr['quantity'] as num).toDouble() * quantity;
        deductions[ingId] = (deductions[ingId] ?? 0) + qty;
      }
    }

    return deductions.entries.map((e) => {
      'ingredient_id': e.key,
      'quantity': e.value,
    }).toList();
  }
}
