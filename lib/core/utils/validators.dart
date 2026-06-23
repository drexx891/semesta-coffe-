/// Validators untuk input form
class Validators {
  Validators._();

  /// Validasi username: minimal 3 karakter, hanya alfanumerik dan underscore
  static String? validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'Username wajib diisi';
    }
    if (value.length < 3) {
      return 'Username minimal 3 karakter';
    }
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
      return 'Username hanya boleh huruf, angka, dan underscore';
    }
    return null;
  }

  /// Validasi password: minimal 6 karakter
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password wajib diisi';
    }
    if (value.length < 6) {
      return 'Password minimal 6 karakter';
    }
    return null;
  }

  /// Validasi PIN: harus 4-6 digit angka
  static String? validatePin(String? value) {
    if (value == null || value.isEmpty) {
      return 'PIN wajib diisi';
    }
    if (!RegExp(r'^\d{4,6}$').hasMatch(value)) {
      return 'PIN harus 4-6 digit angka';
    }
    return null;
  }

  /// Validasi field wajib
  static String? validateRequired(String? value, [String fieldName = 'Field']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName wajib diisi';
    }
    return null;
  }

  /// Validasi angka positif
  static String? validatePositiveNumber(String? value, [String fieldName = 'Nilai']) {
    if (value == null || value.isEmpty) {
      return '$fieldName wajib diisi';
    }
    final number = double.tryParse(value.replaceAll('.', '').replaceAll(',', '.'));
    if (number == null) {
      return '$fieldName harus berupa angka';
    }
    if (number < 0) {
      return '$fieldName tidak boleh negatif';
    }
    return null;
  }

  /// Validasi angka positif > 0
  static String? validatePositiveNonZero(String? value, [String fieldName = 'Nilai']) {
    final result = validatePositiveNumber(value, fieldName);
    if (result != null) return result;

    final number = double.tryParse(value!.replaceAll('.', '').replaceAll(',', '.'));
    if (number == 0) {
      return '$fieldName harus lebih dari 0';
    }
    return null;
  }

  /// Validasi harga
  static String? validatePrice(String? value) {
    return validatePositiveNonZero(value, 'Harga');
  }

  /// Validasi stok
  static String? validateStock(String? value) {
    return validatePositiveNumber(value, 'Stok');
  }

  /// Validasi persentase (0-100)
  static String? validatePercentage(String? value, [String fieldName = 'Persentase']) {
    if (value == null || value.isEmpty) {
      return '$fieldName wajib diisi';
    }
    final number = double.tryParse(value);
    if (number == null) {
      return '$fieldName harus berupa angka';
    }
    if (number < 0 || number > 100) {
      return '$fieldName harus antara 0 dan 100';
    }
    return null;
  }

  /// Validasi nomor telepon Indonesia
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Opsional
    }
    if (!RegExp(r'^(\+62|62|0)\d{8,13}$').hasMatch(value.replaceAll(RegExp(r'[\s-]'), ''))) {
      return 'Format nomor telepon tidak valid';
    }
    return null;
  }

  /// Validasi nama (minimal 2 karakter)
  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Nama wajib diisi';
    }
    if (value.trim().length < 2) {
      return 'Nama minimal 2 karakter';
    }
    return null;
  }
}
