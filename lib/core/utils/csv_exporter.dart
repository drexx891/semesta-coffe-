import 'dart:typed_data';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

class CsvExporter {
  /// Mengekspor daftar transaksi ke format CSV
  static Future<void> exportTransactions(List<Map<String, dynamic>> transactions) async {
    List<List<dynamic>> rows = [];
    
    // Header
    rows.add([
      'ID Transaksi',
      'No. Antrean',
      'Tipe Pesanan',
      'No. Meja',
      'Pelanggan',
      'Subtotal',
      'Diskon',
      'Pajak',
      'Total',
      'Metode Pembayaran',
      'Status',
      'Tanggal',
    ]);
    
    // Data
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
    for (var tx in transactions) {
      rows.add([
        tx['transaction_number'] ?? '',
        tx['queue_number'] ?? '',
        tx['order_type'] ?? '',
        tx['table_number'] ?? '',
        tx['customer_name'] ?? '',
        tx['subtotal'] ?? 0,
        (tx['discount_amount'] ?? 0) + (tx['discount_nominal'] ?? 0),
        tx['tax_amount'] ?? 0,
        tx['total'] ?? 0,
        tx['payment_method'] ?? '',
        tx['status'] ?? '',
        tx['created_at'] != null ? dateFormat.format(DateTime.parse(tx['created_at'])) : '',
      ]);
    }
    
    String csvData = _convertToCsv(rows);
    await _downloadCsv(csvData, 'laporan_transaksi_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}');
  }

  /// Mengekspor laporan shift ke format CSV
  static Future<void> exportShifts(List<Map<String, dynamic>> shifts) async {
    List<List<dynamic>> rows = [];
    
    // Header
    rows.add([
      'ID Shift',
      'Kasir',
      'Waktu Buka',
      'Waktu Tutup',
      'Saldo Awal',
      'Total Penjualan',
      'Total Kas Diterima',
      'Selisih Kas',
      'Status',
    ]);
    
    // Data
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
    for (var shift in shifts) {
      rows.add([
        shift['id'] ?? '',
        shift['user_id'] ?? '',
        shift['start_time'] != null ? dateFormat.format(DateTime.parse(shift['start_time'])) : '',
        shift['end_time'] != null ? dateFormat.format(DateTime.parse(shift['end_time'])) : '',
        shift['opening_cash'] ?? 0,
        shift['total_sales'] ?? 0,
        shift['total_cash_received'] ?? 0,
        (shift['closing_cash'] ?? 0) - ((shift['opening_cash'] ?? 0) + (shift['total_cash_received'] ?? 0)),
        shift['status'] ?? '',
      ]);
    }
    
    String csvData = _convertToCsv(rows);
    await _downloadCsv(csvData, 'laporan_shift_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}');
  }

  static String _convertToCsv(List<List<dynamic>> rows) {
    return rows.map((row) {
      return row.map((cell) {
        String cellStr = cell.toString();
        if (cellStr.contains(',') || cellStr.contains('"') || cellStr.contains('\n')) {
          return '"${cellStr.replaceAll('"', '""')}"';
        }
        return cellStr;
      }).join(',');
    }).join('\n');
  }

  static Future<void> _downloadCsv(String csvData, String fileName) async {
    final bytes = Uint8List.fromList(csvData.codeUnits);
    final xFile = XFile.fromData(
      bytes, 
      mimeType: 'text/csv', 
      name: '$fileName.csv',
    );
    
    await Share.shareXFiles([xFile], text: 'Laporan CSV');
  }
}
