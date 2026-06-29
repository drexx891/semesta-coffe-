import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';
import '../../../domain/entities/customer.dart';

class CustomerDao {
  final DatabaseHelper _dbHelper;

  CustomerDao(this._dbHelper);

  Future<Database> get _db async => await _dbHelper.database;

  Future<int> insert(Customer customer) async {
    return await _dbHelper.insert('customers', customer.toMap());
  }

  Future<int> update(Customer customer) async {
    return await _dbHelper.update(
      'customers',
      customer.toMap(),
      where: 'id = ?',
      whereArgs: [customer.id],
    );
  }

  Future<int> delete(int id) async {
    return await _dbHelper.delete(
      'customers',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Customer>> getAll() async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      'customers',
      orderBy: 'name ASC',
    );
    return maps.map((e) => Customer.fromMap(e)).toList();
  }

  Future<List<Customer>> search(String query) async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      'customers',
      where: 'name LIKE ? OR phone LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'name ASC',
      limit: 20,
    );
    return maps.map((e) => Customer.fromMap(e)).toList();
  }

  Future<Customer?> getById(int id) async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      'customers',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return Customer.fromMap(maps.first);
    }
    return null;
  }

  Future<Customer?> getByPhone(String phone) async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      'customers',
      where: 'phone = ?',
      whereArgs: [phone],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return Customer.fromMap(maps.first);
    }
    return null;
  }

  Future<void> addPoints(int customerId, int points) async {
    final db = await _db;
    await db.rawUpdate('''
      UPDATE customers 
      SET loyalty_points = loyalty_points + ? 
      WHERE id = ?
    ''', [points, customerId]);
  }
}
