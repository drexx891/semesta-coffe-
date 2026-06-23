// Exception classes yang dilempar dari data layer
// dan ditangkap di repository untuk dikonversi ke Failure

class DatabaseException implements Exception {
  final String message;
  const DatabaseException([this.message = 'Database error']);

  @override
  String toString() => 'DatabaseException: $message';
}

class AuthException implements Exception {
  final String message;
  const AuthException([this.message = 'Auth error']);

  @override
  String toString() => 'AuthException: $message';
}

class NotFoundException implements Exception {
  final String message;
  const NotFoundException([this.message = 'Not found']);

  @override
  String toString() => 'NotFoundException: $message';
}

class ValidationException implements Exception {
  final String message;
  const ValidationException([this.message = 'Validation error']);

  @override
  String toString() => 'ValidationException: $message';
}

class PrinterException implements Exception {
  final String message;
  const PrinterException([this.message = 'Printer error']);

  @override
  String toString() => 'PrinterException: $message';
}

class BackupException implements Exception {
  final String message;
  const BackupException([this.message = 'Backup error']);

  @override
  String toString() => 'BackupException: $message';
}

class FileException implements Exception {
  final String message;
  const FileException([this.message = 'File error']);

  @override
  String toString() => 'FileException: $message';
}
