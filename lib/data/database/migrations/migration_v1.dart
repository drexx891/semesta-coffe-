/// Database migration v1 — schema DDL untuk semua tabel
/// Smesta Coffee POS Database
class MigrationV1 {
  MigrationV1._();

  static const int version = 3;

  /// Jalankan semua DDL untuk membuat tabel
  static List<String> get createStatements => [
    _createUsers,
    _createStoreSettings,
    _createCategories,
    _createProducts,
    _createToppings,
    _createProductToppings,
    _createIngredients,
    _createRecipes,
    _createModifierRecipes,
    _createShifts,
    _createCustomers,
    _createTransactions,
    _createTransactionPayments,
    _createTransactionItems,
    _createHoldOrders,
    _createStockMovements,
    _createActivityLogs,
    _createVouchers,
    // Indexes
    ..._createIndexes,
  ];

  /// Seed data awal (default owner account + store settings + categories)
  static List<String> get seedStatements => [
    _seedOwnerAccount,
    _seedStoreSettings,
    ..._seedCategories,
  ];

  // ============================================================
  // TABLE: users
  // ============================================================
  static const String _createUsers = '''
    CREATE TABLE users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      username TEXT NOT NULL UNIQUE,
      password_hash TEXT NOT NULL,
      name TEXT NOT NULL,
      pin TEXT,
      role TEXT NOT NULL CHECK(role IN ('owner', 'supervisor', 'cashier')),
      is_active INTEGER NOT NULL DEFAULT 1,
      failed_login_count INTEGER NOT NULL DEFAULT 0,
      locked_until TEXT,
      created_at TEXT NOT NULL DEFAULT (datetime('now', 'localtime')),
      updated_at TEXT NOT NULL DEFAULT (datetime('now', 'localtime'))
    )
  ''';

  // ============================================================
  // TABLE: store_settings
  // ============================================================
  static const String _createStoreSettings = '''
    CREATE TABLE store_settings (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      store_name TEXT NOT NULL DEFAULT 'Smesta Coffee',
      store_logo_path TEXT,
      store_address TEXT DEFAULT '',
      store_phone TEXT DEFAULT '',
      store_npwp TEXT DEFAULT '',
      receipt_footer TEXT DEFAULT 'Terima kasih telah berkunjung!',
      tax_percentage REAL NOT NULL DEFAULT 11.0,
      service_charge_percentage REAL NOT NULL DEFAULT 5.0,
      tax_enabled INTEGER NOT NULL DEFAULT 1,
      service_charge_enabled INTEGER NOT NULL DEFAULT 1,
      max_cashier_discount REAL NOT NULL DEFAULT 20.0,
      session_timeout_minutes INTEGER NOT NULL DEFAULT 15,
      hold_order_timeout_minutes INTEGER NOT NULL DEFAULT 120,
      qris_image_path TEXT,
      printer_paper_size TEXT NOT NULL DEFAULT '58mm' CHECK(printer_paper_size IN ('58mm', '80mm')),
      receipt_copies INTEGER NOT NULL DEFAULT 1,
      daily_backup_time TEXT NOT NULL DEFAULT '02:00',
      receipt_printer_address TEXT,
      barista_printer_address TEXT,
      updated_at TEXT NOT NULL DEFAULT (datetime('now', 'localtime'))
    )
  ''';

  // ============================================================
  // TABLE: categories
  // ============================================================
  static const String _createCategories = '''
    CREATE TABLE categories (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL UNIQUE,
      sort_order INTEGER NOT NULL DEFAULT 0,
      is_active INTEGER NOT NULL DEFAULT 1,
      created_at TEXT NOT NULL DEFAULT (datetime('now', 'localtime'))
    )
  ''';

  // ============================================================
  // TABLE: products
  // ============================================================
  static const String _createProducts = '''
    CREATE TABLE products (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      category_id INTEGER NOT NULL,
      name TEXT NOT NULL,
      description TEXT DEFAULT '',
      image_path TEXT,
      price_regular REAL NOT NULL DEFAULT 0,
      price_large REAL,
      has_large_size INTEGER NOT NULL DEFAULT 0,
      has_sugar_level INTEGER NOT NULL DEFAULT 0,
      has_ice_level INTEGER NOT NULL DEFAULT 0,
      has_extra_shot INTEGER NOT NULL DEFAULT 0,
      extra_shot_price REAL NOT NULL DEFAULT 0,
      is_active INTEGER NOT NULL DEFAULT 1,
      sort_order INTEGER NOT NULL DEFAULT 0,
      created_at TEXT NOT NULL DEFAULT (datetime('now', 'localtime')),
      updated_at TEXT NOT NULL DEFAULT (datetime('now', 'localtime')),
      FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE RESTRICT
    )
  ''';

  // ============================================================
  // TABLE: toppings
  // ============================================================
  static const String _createToppings = '''
    CREATE TABLE toppings (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      price REAL NOT NULL DEFAULT 0,
      is_active INTEGER NOT NULL DEFAULT 1,
      created_at TEXT NOT NULL DEFAULT (datetime('now', 'localtime'))
    )
  ''';

  // ============================================================
  // TABLE: product_toppings (many-to-many)
  // ============================================================
  static const String _createProductToppings = '''
    CREATE TABLE product_toppings (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      product_id INTEGER NOT NULL,
      topping_id INTEGER NOT NULL,
      FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE,
      FOREIGN KEY (topping_id) REFERENCES toppings(id) ON DELETE CASCADE,
      UNIQUE(product_id, topping_id)
    )
  ''';

  // ============================================================
  // TABLE: ingredients (bahan baku)
  // ============================================================
  static const String _createIngredients = '''
    CREATE TABLE ingredients (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      category TEXT NOT NULL DEFAULT 'Lainnya',
      unit TEXT NOT NULL DEFAULT 'gram' CHECK(unit IN ('gram', 'ml', 'pcs', 'liter', 'kg')),
      current_stock REAL NOT NULL DEFAULT 0,
      min_stock REAL NOT NULL DEFAULT 0,
      cost_per_unit REAL NOT NULL DEFAULT 0,
      is_active INTEGER NOT NULL DEFAULT 1,
      created_at TEXT NOT NULL DEFAULT (datetime('now', 'localtime')),
      updated_at TEXT NOT NULL DEFAULT (datetime('now', 'localtime'))
    )
  ''';

  // ============================================================
  // TABLE: recipes (resep produk → bahan baku)
  // ============================================================
  static const String _createRecipes = '''
    CREATE TABLE recipes (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      product_id INTEGER NOT NULL,
      ingredient_id INTEGER NOT NULL,
      size TEXT NOT NULL DEFAULT 'regular' CHECK(size IN ('regular', 'large')),
      quantity REAL NOT NULL DEFAULT 0,
      FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE,
      FOREIGN KEY (ingredient_id) REFERENCES ingredients(id) ON DELETE RESTRICT,
      UNIQUE(product_id, ingredient_id, size)
    )
  ''';

  // ============================================================
  // TABLE: modifier_recipes (resep modifier → bahan baku)
  // ============================================================
  static const String _createModifierRecipes = '''
    CREATE TABLE modifier_recipes (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      modifier_type TEXT NOT NULL CHECK(modifier_type IN ('extra_shot', 'topping')),
      modifier_ref_id INTEGER,
      ingredient_id INTEGER NOT NULL,
      quantity REAL NOT NULL DEFAULT 0,
      FOREIGN KEY (ingredient_id) REFERENCES ingredients(id) ON DELETE RESTRICT
    )
  ''';

  // ============================================================
  // TABLE: shifts
  // ============================================================
  static const String _createShifts = '''
    CREATE TABLE shifts (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL,
      opening_cash REAL NOT NULL DEFAULT 0,
      closing_cash REAL,
      expected_cash REAL,
      cash_difference REAL,
      status TEXT NOT NULL DEFAULT 'open' CHECK(status IN ('open', 'closed')),
      opened_at TEXT NOT NULL DEFAULT (datetime('now', 'localtime')),
      closed_at TEXT,
      summary_json TEXT,
      FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE RESTRICT
    )
  ''';

  // ============================================================
  // TABLE: customers
  // ============================================================
  static const String _createCustomers = '''
    CREATE TABLE customers (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      phone TEXT,
      loyalty_points INTEGER NOT NULL DEFAULT 0,
      created_at TEXT NOT NULL DEFAULT (datetime('now', 'localtime'))
    )
  ''';

  // ============================================================
  // TABLE: transactions
  // ============================================================
  static const String _createTransactions = '''
    CREATE TABLE transactions (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      transaction_number TEXT NOT NULL UNIQUE,
      shift_id INTEGER NOT NULL,
      user_id INTEGER NOT NULL,
      order_type TEXT NOT NULL DEFAULT 'dine_in' CHECK(order_type IN ('dine_in', 'take_away')),
      table_number TEXT,
      queue_number TEXT,
      subtotal REAL NOT NULL DEFAULT 0,
      discount_amount REAL NOT NULL DEFAULT 0,
      discount_percentage REAL NOT NULL DEFAULT 0,
      discount_reason TEXT,
      service_charge_amount REAL NOT NULL DEFAULT 0,
      tax_amount REAL NOT NULL DEFAULT 0,
      total REAL NOT NULL DEFAULT 0,
      payment_method TEXT NOT NULL DEFAULT 'cash' CHECK(payment_method IN ('cash', 'qris', 'transfer', 'edc', 'voucher')),
      cash_received REAL NOT NULL DEFAULT 0,
      cash_change REAL NOT NULL DEFAULT 0,
      voucher_code TEXT,
      status TEXT NOT NULL DEFAULT 'completed' CHECK(status IN ('completed', 'void')),
      void_reason TEXT,
      voided_by INTEGER,
      voided_at TEXT,
      customer_id INTEGER,
      order_status TEXT NOT NULL DEFAULT 'completed' CHECK(order_status IN ('queued', 'preparing', 'ready', 'served', 'completed')),
      created_at TEXT NOT NULL DEFAULT (datetime('now', 'localtime')),
      FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE SET NULL,
      FOREIGN KEY (shift_id) REFERENCES shifts(id) ON DELETE RESTRICT,
      FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE RESTRICT,
      FOREIGN KEY (voided_by) REFERENCES users(id) ON DELETE RESTRICT
    )
  ''';

  // ============================================================
  // TABLE: transaction_payments (For Split Bill)
  // ============================================================
  static const String _createTransactionPayments = '''
    CREATE TABLE transaction_payments (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      transaction_id INTEGER NOT NULL,
      payment_method TEXT NOT NULL,
      amount REAL NOT NULL,
      FOREIGN KEY (transaction_id) REFERENCES transactions(id) ON DELETE CASCADE
    )
  ''';

  // ============================================================
  // TABLE: transaction_items
  // ============================================================
  static const String _createTransactionItems = '''
    CREATE TABLE transaction_items (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      transaction_id INTEGER NOT NULL,
      product_id INTEGER NOT NULL,
      product_name TEXT NOT NULL,
      size TEXT NOT NULL DEFAULT 'regular' CHECK(size IN ('regular', 'large')),
      sugar_level TEXT NOT NULL DEFAULT 'normal' CHECK(sugar_level IN ('normal', 'less', 'none')),
      ice_level TEXT NOT NULL DEFAULT 'normal' CHECK(ice_level IN ('normal', 'less', 'none')),
      extra_shot INTEGER NOT NULL DEFAULT 0,
      toppings_json TEXT,
      notes TEXT,
      unit_price REAL NOT NULL DEFAULT 0,
      modifier_price REAL NOT NULL DEFAULT 0,
      quantity INTEGER NOT NULL DEFAULT 1,
      subtotal REAL NOT NULL DEFAULT 0,
      FOREIGN KEY (transaction_id) REFERENCES transactions(id) ON DELETE CASCADE,
      FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE RESTRICT
    )
  ''';

  // ============================================================
  // TABLE: hold_orders
  // ============================================================
  static const String _createHoldOrders = '''
    CREATE TABLE hold_orders (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      label TEXT NOT NULL,
      order_type TEXT NOT NULL DEFAULT 'dine_in' CHECK(order_type IN ('dine_in', 'take_away')),
      table_number TEXT,
      items_json TEXT NOT NULL,
      user_id INTEGER NOT NULL,
      created_at TEXT NOT NULL DEFAULT (datetime('now', 'localtime')),
      expires_at TEXT NOT NULL,
      FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE RESTRICT
    )
  ''';

  // ============================================================
  // TABLE: stock_movements
  // ============================================================
  static const String _createStockMovements = '''
    CREATE TABLE stock_movements (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      ingredient_id INTEGER NOT NULL,
      movement_type TEXT NOT NULL CHECK(movement_type IN ('in', 'out', 'correction')),
      quantity REAL NOT NULL DEFAULT 0,
      stock_before REAL NOT NULL DEFAULT 0,
      stock_after REAL NOT NULL DEFAULT 0,
      reference TEXT,
      reason TEXT,
      invoice_number TEXT,
      supplier TEXT,
      user_id INTEGER NOT NULL,
      created_at TEXT NOT NULL DEFAULT (datetime('now', 'localtime')),
      FOREIGN KEY (ingredient_id) REFERENCES ingredients(id) ON DELETE RESTRICT,
      FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE RESTRICT
    )
  ''';

  // ============================================================
  // TABLE: activity_logs
  // ============================================================
  static const String _createActivityLogs = '''
    CREATE TABLE activity_logs (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL,
      action_type TEXT NOT NULL,
      description TEXT NOT NULL,
      reference_id TEXT,
      device_info TEXT,
      created_at TEXT NOT NULL DEFAULT (datetime('now', 'localtime')),
      FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE RESTRICT
    )
  ''';

  // ============================================================
  // TABLE: vouchers
  // ============================================================
  static const String _createVouchers = '''
    CREATE TABLE vouchers (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      code TEXT NOT NULL UNIQUE,
      type TEXT NOT NULL CHECK(type IN ('percentage', 'nominal')),
      value REAL NOT NULL DEFAULT 0,
      min_transaction REAL NOT NULL DEFAULT 0,
      is_active INTEGER NOT NULL DEFAULT 1,
      valid_from TEXT,
      valid_until TEXT,
      usage_count INTEGER NOT NULL DEFAULT 0,
      max_usage INTEGER NOT NULL DEFAULT 0,
      created_at TEXT NOT NULL DEFAULT (datetime('now', 'localtime'))
    )
  ''';

  // ============================================================
  // INDEXES
  // ============================================================
  static const List<String> _createIndexes = [
    'CREATE INDEX idx_products_category ON products(category_id)',
    'CREATE INDEX idx_products_active ON products(is_active)',
    'CREATE INDEX idx_recipes_product ON recipes(product_id)',
    'CREATE INDEX idx_recipes_ingredient ON recipes(ingredient_id)',
    'CREATE INDEX idx_transactions_shift ON transactions(shift_id)',
    'CREATE INDEX idx_transactions_user ON transactions(user_id)',
    'CREATE INDEX idx_transactions_date ON transactions(created_at)',
    'CREATE INDEX idx_transactions_status ON transactions(status)',
    'CREATE INDEX idx_transaction_items_transaction ON transaction_items(transaction_id)',
    'CREATE INDEX idx_shifts_user ON shifts(user_id)',
    'CREATE INDEX idx_shifts_status ON shifts(status)',
    'CREATE INDEX idx_stock_movements_ingredient ON stock_movements(ingredient_id)',
    'CREATE INDEX idx_stock_movements_date ON stock_movements(created_at)',
    'CREATE INDEX idx_activity_logs_user ON activity_logs(user_id)',
    'CREATE INDEX idx_activity_logs_date ON activity_logs(created_at)',
    'CREATE INDEX idx_activity_logs_action ON activity_logs(action_type)',
    'CREATE INDEX idx_hold_orders_expires ON hold_orders(expires_at)',
    'CREATE INDEX idx_vouchers_code ON vouchers(code)',
  ];

  // ============================================================
  // SEED DATA
  // ============================================================

  /// Default owner: username=owner, password=owner123 (SHA-256 hashed)
  /// PIN: 1234
  static const String _seedOwnerAccount = '''
    INSERT INTO users (username, password_hash, name, pin, role, is_active)
    VALUES (
      'owner',
      '43a0d17178a9d26c9e0fe9a74b0b45e38d32f27aed887a008a54bf6e033bf7b9',
      'Owner',
      '1234',
      'owner',
      1
    )
  ''';

  static const String _seedStoreSettings = '''
    INSERT INTO store_settings (store_name, store_address, receipt_footer)
    VALUES (
      'Smesta Coffee',
      'Jl. Contoh No. 1, Kota',
      'Terima kasih telah berkunjung!\nSelamat menikmati kopi Anda'
    )
  ''';

  static final List<String> _seedCategories = [
    "INSERT INTO categories (name, sort_order) VALUES ('Coffee', 1)",
    "INSERT INTO categories (name, sort_order) VALUES ('Non Coffee', 2)",
    "INSERT INTO categories (name, sort_order) VALUES ('Tea', 3)",
    "INSERT INTO categories (name, sort_order) VALUES ('Snack', 4)",
    "INSERT INTO categories (name, sort_order) VALUES ('Dessert', 5)",
  ];
}
