import 'package:equatable/equatable.dart';

/// Entity ActivityLog — log aktivitas pengguna (read-only)
class ActivityLog extends Equatable {
  final int? id;
  final int userId;
  final String actionType;
  final String description;
  final String? referenceId;
  final String? deviceInfo;
  final DateTime createdAt;

  // Relasi
  final String? userName;

  const ActivityLog({
    this.id,
    required this.userId,
    required this.actionType,
    required this.description,
    this.referenceId,
    this.deviceInfo,
    required this.createdAt,
    this.userName,
  });

  @override
  List<Object?> get props => [id, userId, actionType, createdAt];
}

/// Tipe aksi yang dicatat dalam log
class LogActionType {
  LogActionType._();

  static const String login = 'LOGIN';
  static const String logout = 'LOGOUT';
  static const String openShift = 'OPEN_SHIFT';
  static const String closeShift = 'CLOSE_SHIFT';
  static const String createTransaction = 'CREATE_TRANSACTION';
  static const String voidTransaction = 'VOID_TRANSACTION';
  static const String stockCorrection = 'STOCK_CORRECTION';
  static const String stockIn = 'STOCK_IN';
  static const String settingsChange = 'SETTINGS_CHANGE';
  static const String backup = 'BACKUP';
  static const String restore = 'RESTORE';
  static const String addUser = 'ADD_USER';
  static const String editUser = 'EDIT_USER';
  static const String deleteUser = 'DELETE_USER';
  static const String addProduct = 'ADD_PRODUCT';
  static const String editProduct = 'EDIT_PRODUCT';
  static const String deleteProduct = 'DELETE_PRODUCT';
  static const String discountApplied = 'DISCOUNT_APPLIED';
  static const String pinOverride = 'PIN_OVERRIDE';

  static String getDisplayName(String actionType) {
    switch (actionType) {
      case login: return 'Login';
      case logout: return 'Logout';
      case openShift: return 'Buka Shift';
      case closeShift: return 'Tutup Shift';
      case createTransaction: return 'Buat Transaksi';
      case voidTransaction: return 'Void Transaksi';
      case stockCorrection: return 'Koreksi Stok';
      case stockIn: return 'Tambah Stok';
      case settingsChange: return 'Ubah Pengaturan';
      case backup: return 'Backup Data';
      case restore: return 'Restore Data';
      case addUser: return 'Tambah Pengguna';
      case editUser: return 'Edit Pengguna';
      case deleteUser: return 'Hapus Pengguna';
      case addProduct: return 'Tambah Produk';
      case editProduct: return 'Edit Produk';
      case deleteProduct: return 'Hapus Produk';
      case discountApplied: return 'Diskon Diberikan';
      case pinOverride: return 'Override PIN';
      default: return actionType;
    }
  }
}
