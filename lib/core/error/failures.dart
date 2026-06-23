import 'package:equatable/equatable.dart';

/// Base class untuk semua failures di aplikasi
abstract class Failure extends Equatable {
  final String message;

  const Failure(this.message);

  @override
  List<Object> get props => [message];
}

/// Failure terkait database
class DatabaseFailure extends Failure {
  const DatabaseFailure([super.message = 'Terjadi kesalahan pada database']);
}

/// Failure terkait autentikasi
class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Autentikasi gagal']);
}

/// Failure terkait login
class LoginFailure extends Failure {
  final int remainingAttempts;

  const LoginFailure({
    String message = 'Username atau password salah',
    this.remainingAttempts = 0,
  }) : super(message);

  @override
  List<Object> get props => [message, remainingAttempts];
}

/// Failure akun terkunci
class AccountLockedFailure extends Failure {
  final DateTime lockedUntil;

  AccountLockedFailure({required this.lockedUntil})
      : super('Akun terkunci hingga ${lockedUntil.hour}:${lockedUntil.minute.toString().padLeft(2, '0')}');

  @override
  List<Object> get props => [message, lockedUntil];
}

/// Failure terkait izin akses
class PermissionFailure extends Failure {
  const PermissionFailure([super.message = 'Anda tidak memiliki izin untuk aksi ini']);
}

/// Failure terkait validasi PIN
class PinValidationFailure extends Failure {
  const PinValidationFailure([super.message = 'PIN tidak valid']);
}

/// Failure terkait stok
class StockFailure extends Failure {
  const StockFailure([super.message = 'Stok bahan baku tidak mencukupi']);
}

/// Failure terkait transaksi
class TransactionFailure extends Failure {
  const TransactionFailure([super.message = 'Gagal memproses transaksi']);
}

/// Failure terkait shift
class ShiftFailure extends Failure {
  const ShiftFailure([super.message = 'Gagal memproses shift']);
}

/// Failure terkait printer
class PrinterFailure extends Failure {
  const PrinterFailure([super.message = 'Printer tidak terhubung']);
}

/// Failure terkait backup
class BackupFailure extends Failure {
  const BackupFailure([super.message = 'Gagal melakukan backup']);
}

/// Failure terkait restore
class RestoreFailure extends Failure {
  const RestoreFailure([super.message = 'Gagal melakukan restore data']);
}

/// Failure terkait file
class FileFailure extends Failure {
  const FileFailure([super.message = 'Gagal mengakses file']);
}

/// Failure terkait export
class ExportFailure extends Failure {
  const ExportFailure([super.message = 'Gagal mengexport data']);
}

/// Failure void transaksi
class VoidFailure extends Failure {
  const VoidFailure([super.message = 'Gagal membatalkan transaksi']);
}

/// Failure tidak ditemukan
class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'Data tidak ditemukan']);
}

/// Failure validasi data
class ValidationFailure extends Failure {
  const ValidationFailure([super.message = 'Data tidak valid']);
}
