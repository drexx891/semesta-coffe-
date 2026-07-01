import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sqflite/sqflite.dart';
import '../data/database/database_helper.dart';

class SupabaseSyncService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final DatabaseHelper _db;
  
  final _syncCompleteController = StreamController<void>.broadcast();
  Stream<void> get onSyncComplete => _syncCompleteController.stream;

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

  /// Menarik semua data dari Supabase ke lokal secara aman (Upsert / Sinkronisasi 2 arah)
  Future<void> pullAllDataFromCloud() async {
    try {
      _db.suspendSyncTriggers = true;
      // Kita harus insert dalam urutan yang benar karena Foreign Key constraints
      await _db.transaction((txn) async {
        for (final table in _tables) {
          // Ambil data dari cloud
          final cloudData = await _supabase.from(table).select();
          
          if (cloudData.isNotEmpty) {
            for (final row in cloudData) {
              final id = row['id'];
              if (id != null) {
                final exists = await txn.query(table, where: 'id = ?', whereArgs: [id]);
                if (exists.isNotEmpty) {
                  await txn.update(table, row, where: 'id = ?', whereArgs: [id]);
                } else {
                  await txn.insert(table, row);
                }
              } else {
                await txn.insert(table, row);
              }
            }
          }
        }
      });
    } catch (e) {
      throw Exception('Gagal pull data dari Cloud: $e');
    } finally {
      _db.suspendSyncTriggers = false;
      // Beritahu UI bahwa sinkronisasi selesai dan data baru tersedia
      _syncCompleteController.add(null);
    }
  }

  void dispose() {
    _syncCompleteController.close();
  }
}
