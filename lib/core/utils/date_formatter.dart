import 'package:intl/intl.dart';

/// Formatter untuk tanggal dan waktu dalam format Indonesia
class DateFormatter {
  DateFormatter._();

  static final DateFormat _fullDate = DateFormat('dd MMM yyyy', 'id_ID');
  static final DateFormat _fullDateTime = DateFormat('dd MMM yyyy HH:mm', 'id_ID');
  static final DateFormat _shortDate = DateFormat('dd/MM/yyyy', 'id_ID');
  static final DateFormat _timeOnly = DateFormat('HH:mm', 'id_ID');
  static final DateFormat _dayMonth = DateFormat('dd MMM', 'id_ID');
  static final DateFormat _monthYear = DateFormat('MMMM yyyy', 'id_ID');
  static final DateFormat _transactionDate = DateFormat('dd MMM yyyy HH:mm:ss', 'id_ID');
  static final DateFormat _receiptDate = DateFormat('dd MMM yyyy HH:mm', 'id_ID');
  static final DateFormat _fileDate = DateFormat('yyyyMMdd_HHmmss');
  static final DateFormat _dayName = DateFormat('EEEE', 'id_ID');

  /// "01 Jun 2024"
  static String fullDate(DateTime date) => _fullDate.format(date);

  /// "01 Jun 2024 10:30"
  static String fullDateTime(DateTime date) => _fullDateTime.format(date);

  /// "01/06/2024"
  static String shortDate(DateTime date) => _shortDate.format(date);

  /// "10:30"
  static String timeOnly(DateTime date) => _timeOnly.format(date);

  /// "01 Jun"
  static String dayMonth(DateTime date) => _dayMonth.format(date);

  /// "Juni 2024"
  static String monthYear(DateTime date) => _monthYear.format(date);

  /// "01 Jun 2024 10:30:45" — untuk detail transaksi
  static String transactionDate(DateTime date) => _transactionDate.format(date);

  /// "01 Jun 2024 10:30" — untuk struk
  static String receiptDate(DateTime date) => _receiptDate.format(date);

  /// "20240601_103045" — untuk nama file
  static String fileDate(DateTime date) => _fileDate.format(date);

  /// "Senin"
  static String dayName(DateTime date) => _dayName.format(date);

  /// Mendapatkan awal hari (00:00:00)
  static DateTime startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// Mendapatkan akhir hari (23:59:59)
  static DateTime endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59);
  }

  /// Mendapatkan awal bulan
  static DateTime startOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  /// Mendapatkan akhir bulan
  static DateTime endOfMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0, 23, 59, 59);
  }

  /// Format durasi relatif: "5 menit lalu", "2 jam lalu"
  static String timeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inSeconds < 60) {
      return 'Baru saja';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} menit lalu';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} jam lalu';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} hari lalu';
    } else {
      return fullDate(date);
    }
  }

  /// Generate nomor transaksi: TRX-20240601-001
  static String generateTransactionNumber(int sequenceToday) {
    final now = DateTime.now();
    final dateStr = DateFormat('yyyyMMdd').format(now);
    final seqStr = sequenceToday.toString().padLeft(3, '0');
    return 'TRX-$dateStr-$seqStr';
  }

  /// Generate nomor antrian: A001, A002, ...
  static String generateQueueNumber(int sequence) {
    return 'A${sequence.toString().padLeft(3, '0')}';
  }
}
