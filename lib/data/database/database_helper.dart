import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';
import 'migrations/migration_v1.dart';

/// Singleton database helper untuk SQLite
/// Mengelola koneksi, migrasi, dan operasi database
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  /// Mendapatkan instance database (lazy initialization)
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    if (kIsWeb) {
      // Menggunakan databaseFactoryFfiWeb dengan absolute URI agar tidak crash saat routing SPA di Vercel
      databaseFactory = createDatabaseFactoryFfiWeb(
        options: SqfliteFfiWebOptions(
          sharedWorkerUri: Uri.parse('/sqflite_sw.js'),
          sqlite3WasmUri: Uri.parse('/sqlite3.wasm'),
        ),
      );
      return await databaseFactory.openDatabase(
        'smesta_coffee.db',
        options: OpenDatabaseOptions(
          version: MigrationV1.version,
          onCreate: _onCreate,
          onUpgrade: _onUpgrade,
          onConfigure: _onConfigure,
        ),
      );
    } else if (defaultTargetPlatform == TargetPlatform.windows || 
               defaultTargetPlatform == TargetPlatform.linux || 
               defaultTargetPlatform == TargetPlatform.macOS) {
      // Use desktop factory
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      final databasesPath = await getDatabasesPath();
      final path = join(databasesPath, 'smesta_coffee.db');
      return await databaseFactory.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: MigrationV1.version,
          onCreate: _onCreate,
          onUpgrade: _onUpgrade,
          onConfigure: _onConfigure,
        ),
      );
    } else {
      // Default mobile factory (Android/iOS)
      final databasesPath = await getDatabasesPath();
      final path = join(databasesPath, 'smesta_coffee.db');

      return await openDatabase(
        path,
        version: MigrationV1.version,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
        onConfigure: _onConfigure,
      );
    }
  }

  /// Konfigurasi database — enable foreign keys
  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  /// Buat semua tabel saat database pertama kali dibuat
  Future<void> _onCreate(Database db, int version) async {
    final batch = db.batch();

    // Buat semua tabel
    for (final statement in MigrationV1.createStatements) {
      batch.execute(statement);
    }

    // Seed data awal
    for (final statement in MigrationV1.seedStatements) {
      batch.execute(statement);
    }

    await batch.commit(noResult: true);
  }

  /// Upgrade database jika versi berubah
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Fix owner password hash
      await db.execute('''
        UPDATE users 
        SET password_hash = '43a0d17178a9d26c9e0fe9a74b0b45e38d32f27aed887a008a54bf6e033bf7b9' 
        WHERE username = 'owner'
      ''');
    }

    if (oldVersion < 3) {
      // Phase A: Customers
      await db.execute('''
        CREATE TABLE customers (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          phone TEXT,
          loyalty_points INTEGER NOT NULL DEFAULT 0,
          created_at TEXT NOT NULL DEFAULT (datetime('now', 'localtime'))
        )
      ''');
      await db.execute('ALTER TABLE transactions ADD COLUMN customer_id INTEGER REFERENCES customers(id) ON DELETE SET NULL');

      // Phase B: Split Payments
      await db.execute('''
        CREATE TABLE transaction_payments (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          transaction_id INTEGER NOT NULL,
          payment_method TEXT NOT NULL,
          amount REAL NOT NULL,
          FOREIGN KEY (transaction_id) REFERENCES transactions(id) ON DELETE CASCADE
        )
      ''');

      // Phase C: Order Status
      await db.execute("ALTER TABLE transactions ADD COLUMN order_status TEXT NOT NULL DEFAULT 'completed'");
    }

    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE attendance (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          clock_in_time TEXT NOT NULL,
          clock_out_time TEXT,
          notes TEXT,
          FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
        )
      ''');
    }
  }

  /// Tutup database
  Future<void> close() async {
    final db = await database;
    db.close();
    _database = null;
  }

  /// Hapus database (untuk testing/reset)
  Future<void> deleteDb() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'smesta_coffee.db');
    await deleteDatabase(path);
    _database = null;
  }

  /// Dapatkan path database untuk backup
  Future<String> getDatabasePath() async {
    final databasesPath = await getDatabasesPath();
    return join(databasesPath, 'smesta_coffee.db');
  }

  // ============================================================
  // HELPER METHODS
  // ============================================================

  /// Insert dan return ID
  Future<int> insert(String table, Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert(table, data);
  }

  /// Update dan return jumlah rows yang terpengaruh
  Future<int> update(String table, Map<String, dynamic> data, {
    String? where,
    List<Object?>? whereArgs,
  }) async {
    final db = await database;
    return await db.update(table, data, where: where, whereArgs: whereArgs);
  }

  /// Delete dan return jumlah rows yang terhapus
  Future<int> delete(String table, {
    String? where,
    List<Object?>? whereArgs,
  }) async {
    final db = await database;
    return await db.delete(table, where: where, whereArgs: whereArgs);
  }

  /// Query dengan semua opsi
  Future<List<Map<String, dynamic>>> query(String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    final db = await database;
    return await db.query(
      table,
      distinct: distinct,
      columns: columns,
      where: where,
      whereArgs: whereArgs,
      groupBy: groupBy,
      having: having,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );
  }

  /// Raw query
  Future<List<Map<String, dynamic>>> rawQuery(String sql, [List<Object?>? arguments]) async {
    final db = await database;
    return await db.rawQuery(sql, arguments);
  }

  /// Raw execute
  Future<void> rawExecute(String sql, [List<Object?>? arguments]) async {
    final db = await database;
    await db.execute(sql, arguments);
  }

  /// Transaksi database
  Future<T> transaction<T>(Future<T> Function(Transaction txn) action) async {
    final db = await database;
    return await db.transaction(action);
  }

  /// Batch operation
  Future<List<Object?>> batch(void Function(Batch batch) operations) async {
    final db = await database;
    final batch = db.batch();
    operations(batch);
    return await batch.commit();
  }

  /// Hitung jumlah rows
  Future<int> count(String table, {String? where, List<Object?>? whereArgs}) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $table${where != null ? ' WHERE $where' : ''}',
      whereArgs,
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Check apakah row exists
  Future<bool> exists(String table, {required String where, required List<Object?> whereArgs}) async {
    final count = await this.count(table, where: where, whereArgs: whereArgs);
    return count > 0;
  }
}
