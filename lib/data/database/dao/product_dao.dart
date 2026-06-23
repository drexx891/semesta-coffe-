import '../database_helper.dart';

/// Data Access Object untuk tabel products, categories, toppings
class ProductDao {
  final DatabaseHelper _db;

  ProductDao(this._db);

  // ============================================================
  // CATEGORIES
  // ============================================================

  Future<List<Map<String, dynamic>>> getAllCategories({bool activeOnly = true}) async {
    if (activeOnly) {
      return await _db.query('categories', where: 'is_active = 1', orderBy: 'sort_order ASC');
    }
    return await _db.query('categories', orderBy: 'sort_order ASC');
  }

  Future<int> insertCategory(Map<String, dynamic> category) async {
    return await _db.insert('categories', category);
  }

  Future<int> updateCategory(int id, Map<String, dynamic> data) async {
    return await _db.update('categories', data, where: 'id = ?', whereArgs: [id]);
  }

  Future<bool> hasProductsInCategory(int categoryId) async {
    return await _db.exists('products', where: 'category_id = ?', whereArgs: [categoryId]);
  }

  Future<int> deleteCategory(int id) async {
    return await _db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  // ============================================================
  // PRODUCTS
  // ============================================================

  /// Get semua produk aktif dengan nama kategori
  Future<List<Map<String, dynamic>>> getAllProducts({bool activeOnly = true}) async {
    final where = activeOnly ? 'AND p.is_active = 1' : '';
    return await _db.rawQuery('''
      SELECT p.*, c.name as category_name
      FROM products p
      LEFT JOIN categories c ON p.category_id = c.id
      WHERE 1=1 $where
      ORDER BY p.sort_order ASC, p.name ASC
    ''');
  }

  /// Get produk berdasarkan kategori
  Future<List<Map<String, dynamic>>> getByCategory(int categoryId) async {
    return await _db.rawQuery('''
      SELECT p.*, c.name as category_name
      FROM products p
      LEFT JOIN categories c ON p.category_id = c.id
      WHERE p.category_id = ? AND p.is_active = 1
      ORDER BY p.sort_order ASC, p.name ASC
    ''', [categoryId]);
  }

  /// Get produk by ID
  Future<Map<String, dynamic>?> getProductById(int id) async {
    final results = await _db.rawQuery('''
      SELECT p.*, c.name as category_name
      FROM products p
      LEFT JOIN categories c ON p.category_id = c.id
      WHERE p.id = ?
    ''', [id]);
    return results.isEmpty ? null : results.first;
  }

  /// Search produk berdasarkan nama
  Future<List<Map<String, dynamic>>> searchProducts(String query) async {
    return await _db.rawQuery('''
      SELECT p.*, c.name as category_name
      FROM products p
      LEFT JOIN categories c ON p.category_id = c.id
      WHERE p.name LIKE ? AND p.is_active = 1
      ORDER BY p.name ASC
    ''', ['%$query%']);
  }

  /// Insert produk baru
  Future<int> insertProduct(Map<String, dynamic> product) async {
    return await _db.insert('products', product);
  }

  /// Update produk
  Future<int> updateProduct(int id, Map<String, dynamic> data) async {
    data['updated_at'] = DateTime.now().toIso8601String();
    return await _db.update('products', data, where: 'id = ?', whereArgs: [id]);
  }

  /// Toggle produk aktif/nonaktif
  Future<void> toggleActive(int productId, bool isActive) async {
    await _db.update('products', {
      'is_active': isActive ? 1 : 0,
      'updated_at': DateTime.now().toIso8601String(),
    }, where: 'id = ?', whereArgs: [productId]);
  }

  /// Cek apakah produk pernah ada di transaksi
  Future<bool> hasTransactions(int productId) async {
    return await _db.exists('transaction_items',
      where: 'product_id = ?',
      whereArgs: [productId],
    );
  }

  /// Hapus produk (hanya jika belum pernah ada transaksi)
  Future<int> deleteProduct(int id) async {
    return await _db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  /// Update sort order produk
  Future<void> updateSortOrder(int productId, int sortOrder) async {
    await _db.update('products', {
      'sort_order': sortOrder,
      'updated_at': DateTime.now().toIso8601String(),
    }, where: 'id = ?', whereArgs: [productId]);
  }

  // ============================================================
  // TOPPINGS
  // ============================================================

  Future<List<Map<String, dynamic>>> getAllToppings({bool activeOnly = true}) async {
    if (activeOnly) {
      return await _db.query('toppings', where: 'is_active = 1', orderBy: 'name ASC');
    }
    return await _db.query('toppings', orderBy: 'name ASC');
  }

  Future<int> insertTopping(Map<String, dynamic> topping) async {
    return await _db.insert('toppings', topping);
  }

  Future<int> updateTopping(int id, Map<String, dynamic> data) async {
    return await _db.update('toppings', data, where: 'id = ?', whereArgs: [id]);
  }

  /// Get toppings untuk produk tertentu
  Future<List<Map<String, dynamic>>> getToppingsForProduct(int productId) async {
    return await _db.rawQuery('''
      SELECT t.*
      FROM toppings t
      INNER JOIN product_toppings pt ON t.id = pt.topping_id
      WHERE pt.product_id = ? AND t.is_active = 1
      ORDER BY t.name ASC
    ''', [productId]);
  }

  /// Set toppings untuk produk (replace all)
  Future<void> setProductToppings(int productId, List<int> toppingIds) async {
    await _db.transaction((txn) async {
      // Hapus semua existing
      await txn.delete('product_toppings', where: 'product_id = ?', whereArgs: [productId]);

      // Insert baru
      for (final toppingId in toppingIds) {
        await txn.insert('product_toppings', {
          'product_id': productId,
          'topping_id': toppingId,
        });
      }
    });
  }

  // ============================================================
  // STOCK AVAILABILITY CHECK
  // ============================================================

  /// Cek ketersediaan stok untuk produk berdasarkan resep
  Future<bool> checkStockAvailability(int productId, String size, {int quantity = 1}) async {
    final recipes = await _db.rawQuery('''
      SELECT r.ingredient_id, r.quantity as recipe_qty, i.current_stock
      FROM recipes r
      INNER JOIN ingredients i ON r.ingredient_id = i.id
      WHERE r.product_id = ? AND r.size = ?
    ''', [productId, size]);

    if (recipes.isEmpty) return true; // Tidak ada resep = stok selalu tersedia

    for (final recipe in recipes) {
      final required = (recipe['recipe_qty'] as num).toDouble() * quantity;
      final available = (recipe['current_stock'] as num).toDouble();
      if (available < required) return false;
    }

    return true;
  }

  /// Cek ketersediaan stok untuk semua produk aktif
  Future<Map<int, bool>> checkAllStockAvailability() async {
    final products = await getAllProducts();
    final result = <int, bool>{};

    for (final product in products) {
      final productId = product['id'] as int;
      result[productId] = await checkStockAvailability(productId, 'regular');
    }

    return result;
  }
}
