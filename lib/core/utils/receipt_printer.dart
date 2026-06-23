import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'currency_formatter.dart';
import '../../domain/entities/user.dart';

class ReceiptPrinter {
  /// Print receipt with 58mm thermal paper format
  static Future<void> printReceipt({
    required Map<String, dynamic> transaction,
    required List<Map<String, dynamic>> items,
    required User cashier,
    String storeName = 'SMESTA COFFEE',
    String storeAddress = 'Jalan Raya Smesta No. 123',
    String storePhone = '0812-3456-7890',
  }) async {
    final pdf = pw.Document();

    // 58mm roll paper is roughly 58mm * 2.83 pt/mm = 164 pt
    const double pageFormatWidth = 164.0;
    
    // We use a continuous page format
    final pageFormat = PdfPageFormat(pageFormatWidth, double.infinity, marginAll: 10.0);

    pdf.addPage(
      pw.Page(
        pageFormat: pageFormat,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              // Header
              pw.Text(storeName, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
              pw.SizedBox(height: 2),
              pw.Text(storeAddress, style: const pw.TextStyle(fontSize: 8), textAlign: pw.TextAlign.center),
              pw.Text(storePhone, style: const pw.TextStyle(fontSize: 8)),
              pw.Divider(thickness: 1, height: 10),

              // Transaction Info
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Waktu', style: const pw.TextStyle(fontSize: 8)),
                  pw.Text(
                    DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(transaction['created_at'] as String)),
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Kasir', style: const pw.TextStyle(fontSize: 8)),
                  pw.Text(cashier.name, style: const pw.TextStyle(fontSize: 8)),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('No. Trx', style: const pw.TextStyle(fontSize: 8)),
                  pw.Text(transaction['transaction_number'] as String, style: const pw.TextStyle(fontSize: 8)),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Antrian', style: const pw.TextStyle(fontSize: 8)),
                  pw.Text(transaction['queue_number'] as String, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Tipe', style: const pw.TextStyle(fontSize: 8)),
                  pw.Text(
                    (transaction['order_type'] as String).replaceAll('_', ' ').toUpperCase(),
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                ],
              ),
              pw.Divider(thickness: 1, height: 10, borderStyle: pw.BorderStyle.dashed),

              // Items
              ...items.map((item) {
                final name = item['product_name'] as String;
                final qty = item['quantity'] as int;
                final price = (item['unit_price'] as num).toDouble();
                final subtotal = (item['subtotal'] as num).toDouble();

                return pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(name, style: const pw.TextStyle(fontSize: 8)),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('$qty x ${CurrencyFormatter.format(price)}', style: const pw.TextStyle(fontSize: 8)),
                        pw.Text(CurrencyFormatter.format(subtotal), style: const pw.TextStyle(fontSize: 8)),
                      ],
                    ),
                    pw.SizedBox(height: 2),
                  ],
                );
              }),
              pw.Divider(thickness: 1, height: 10, borderStyle: pw.BorderStyle.dashed),

              // Totals
              _buildSummaryRow('Subtotal', (transaction['subtotal'] as num).toDouble()),
              if ((transaction['discount_amount'] as num).toDouble() > 0)
                _buildSummaryRow('Diskon', -(transaction['discount_amount'] as num).toDouble()),
              if ((transaction['service_charge_amount'] as num).toDouble() > 0)
                _buildSummaryRow('Service', (transaction['service_charge_amount'] as num).toDouble()),
              if ((transaction['tax_amount'] as num).toDouble() > 0)
                _buildSummaryRow('Pajak', (transaction['tax_amount'] as num).toDouble()),
              
              pw.SizedBox(height: 2),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('TOTAL', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  pw.Text(CurrencyFormatter.format((transaction['total'] as num).toDouble()), style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                ],
              ),
              
              pw.SizedBox(height: 2),
              _buildSummaryRow('Bayar (${transaction['payment_method']})', (transaction['cash_received'] as num).toDouble()),
              if ((transaction['cash_change'] as num).toDouble() > 0)
                _buildSummaryRow('Kembali', (transaction['cash_change'] as num).toDouble()),

              pw.SizedBox(height: 10),
              // Footer
              pw.Text('Terima Kasih', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
              pw.Text('Silakan datang kembali', style: const pw.TextStyle(fontSize: 8)),
              pw.SizedBox(height: 10),
            ],
          );
        },
      ),
    );

    // Print
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Struk ${transaction['transaction_number']}',
      usePrinterSettings: true,
    );
  }

  static pw.Widget _buildSummaryRow(String label, double amount) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 8)),
        pw.Text(CurrencyFormatter.format(amount), style: const pw.TextStyle(fontSize: 8)),
      ],
    );
  }

  static Future<void> printKitchenTicket({
    required Map<String, dynamic> transaction,
    required List<Map<String, dynamic>> items,
    required User cashier,
  }) async {
    final pdf = pw.Document();
    const double pageFormatWidth = 164.0;
    final pageFormat = PdfPageFormat(pageFormatWidth, double.infinity, marginAll: 10.0);

    pdf.addPage(
      pw.Page(
        pageFormat: pageFormat,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              // Header Queue Number
              pw.Center(
                child: pw.Text('ANTREAN', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
              ),
              pw.Center(
                child: pw.Text(transaction['queue_number'] as String, style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              ),
              pw.Divider(thickness: 1, height: 10),

              // Transaction Info
              pw.Text('Waktu: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(transaction['created_at'] as String))}', style: const pw.TextStyle(fontSize: 8)),
              pw.Text('Kasir: ${cashier.name}', style: const pw.TextStyle(fontSize: 8)),
              if (transaction['table_number'] != null)
                pw.Text('Nama/Meja: ${transaction['table_number']}', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
              pw.Text(
                'Tipe: ${(transaction['order_type'] as String).replaceAll('_', ' ').toUpperCase()}',
                style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
              ),
              pw.Divider(thickness: 1, height: 10, borderStyle: pw.BorderStyle.dashed),

              // Items
              ...items.map((item) {
                final name = item['product_name'] as String;
                final qty = item['quantity'] as int;
                final notes = item['notes'] as String?;
                
                // Parse toppings/modifiers from DB if possible
                String modifierText = '';
                if (item['sugar_level'] != null && item['sugar_level'] != 'normal') {
                  modifierText += 'Sugar: ${item['sugar_level']} ';
                }
                if (item['ice_level'] != null && item['ice_level'] != 'normal') {
                  modifierText += 'Ice: ${item['ice_level']} ';
                }
                if (item['extra_shot'] == 1) {
                  modifierText += '+Extra Shot ';
                }

                return pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('$qty x $name', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                    if (modifierText.isNotEmpty)
                      pw.Text(modifierText, style: const pw.TextStyle(fontSize: 8)),
                    if (notes != null && notes.isNotEmpty)
                      pw.Text('Note: $notes', style: pw.TextStyle(fontSize: 8, fontStyle: pw.FontStyle.italic)),
                    pw.SizedBox(height: 4),
                  ],
                );
              }),
              
              pw.Divider(thickness: 1, height: 10),
              pw.Center(
                child: pw.Text('--- TIKET BARISTA ---', style: const pw.TextStyle(fontSize: 8)),
              ),
              pw.SizedBox(height: 10),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Tiket_Barista_${transaction['transaction_number']}',
      usePrinterSettings: true,
    );
  }

  /// Print simple report summary (thermal format)
  static Future<void> printReportSummary({
    required String reportTitle,
    required double totalSales,
    required List<Map<String, dynamic>> listData,
  }) async {
    final pdf = pw.Document();
    const double pageFormatWidth = 164.0;
    final pageFormat = PdfPageFormat(pageFormatWidth, double.infinity, marginAll: 10.0);

    pdf.addPage(
      pw.Page(
        pageFormat: pageFormat,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              pw.Center(
                child: pw.Text('LAPORAN S.COFFEE', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
              ),
              pw.Center(
                child: pw.Text(reportTitle, style: const pw.TextStyle(fontSize: 8)),
              ),
              pw.Center(
                child: pw.Text(DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now()), style: const pw.TextStyle(fontSize: 8)),
              ),
              pw.Divider(thickness: 1, height: 10, borderStyle: pw.BorderStyle.dashed),
              
              pw.Text('Total Pendapatan:', style: const pw.TextStyle(fontSize: 8)),
              pw.Text(CurrencyFormatter.format(totalSales), style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.Divider(thickness: 1, height: 10, borderStyle: pw.BorderStyle.dashed),

              pw.Text('RINCIAN', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 4),
              
              ...listData.take(15).map((item) {
                // Try to guess format
                String title = 'Item';
                String value = '';
                
                if (item.containsKey('category_name')) {
                  title = '${item['category_name']} (${item['total_qty']}x)';
                  value = CurrencyFormatter.format((item['total_sales'] as num).toDouble());
                } else if (item.containsKey('cashier_name')) {
                  title = '${item['cashier_name']}';
                  value = CurrencyFormatter.format((item['total_sales'] as num).toDouble());
                } else if (item.containsKey('payment_method')) {
                  title = '${item['payment_method']}';
                  value = CurrencyFormatter.format((item['total_sales'] as num).toDouble());
                } else if (item.containsKey('total_revenue') && item.containsKey('total_cogs')) {
                  title = '${item['product_name']}';
                  final margin = (item['total_revenue'] as num).toDouble() - (item['total_cogs'] as num).toDouble();
                  value = CurrencyFormatter.format(margin);
                } else {
                  return pw.SizedBox();
                }

                return pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 2),
                  child: _buildSummaryRow(title, (double.tryParse(value.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0) / 100), // Hacky parse back just to use buildSummaryRow, actually we just make a row
                );
              }),

              pw.Divider(thickness: 1, height: 10),
              pw.Center(
                child: pw.Text('--- AKHIR LAPORAN ---', style: const pw.TextStyle(fontSize: 8)),
              ),
              pw.SizedBox(height: 10),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Laporan_${reportTitle.replaceAll(' ', '_')}',
      usePrinterSettings: true,
    );
  }
}
