import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/database/database_helper.dart';

class SupabaseSyncService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final DatabaseHelper _db;

  // Daftar tabel yang perlu disinkronisasi (Berurutan dari parent ke child)
  final List<String> _tables = [
    'users',
    'store_settings',
    'categories',
    'products',
    'toppings',
    'product_toppings',
    'ingredients',
    'recipes',
    'modifier_recipes',
    'customers',
    'shifts',
    'transactions',
    'transaction_payments',
    'transaction_items',
    'hold_orders',
    'stock_movements',
    'activity_logs',
    'vouchers',
    'attendance',
  ];

  SupabaseSyncService(this._db);

  /// Mendorong semua data lokal ke Supabase (Overwrite Cloud)
  Future<void> pushAllDataToCloud() async {
    try {
      for (final table in _tables) {
        // Ambil data lokal
        final localData = await _db.query(table);
        if (localData.isNotEmpty) {
          // Bersihkan tabel cloud (karena foreign keys, mungkin harus upsert)
          // Upsert data
          await _supabase.from(table).upsert(localData);
        }
      }
    } catch (e) {
      throw Exception('Gagal push data ke Cloud: $e');
    }
  }

  /// Menarik semua data dari Supabase ke lokal (Overwrite Local)
  Future<void> pullAllDataFromCloud() async {
    try {
      // Kita harus insert dalam urutan yang benar karena Foreign Key constraints
      await _db.transaction((txn) async {
        for (final table in _tables) {
          // Kosongkan tabel lokal
          await txn.delete(table);
          
          // Ambil data dari cloud
          final cloudData = await _supabase.from(table).select();
          
          if (cloudData.isNotEmpty) {
            final batch = txn.batch();
            for (final row in cloudData) {
              batch.insert(table, row);
            }
            await batch.commit();
          }
        }
      });
    } catch (e) {
      throw Exception('Gagal pull data dari Cloud: $e');
    }
  }
}
