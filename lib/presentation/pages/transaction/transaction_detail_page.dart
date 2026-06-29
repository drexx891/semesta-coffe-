import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/receipt_printer.dart';
import '../../../core/di/injection_container.dart';
import '../../../data/database/dao/transaction_dao.dart';
import '../../../services/session_manager.dart';

import '../../../presentation/widgets/pin_verification_dialog.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

class TransactionDetailPage extends StatefulWidget {
  final int transactionId;

  const TransactionDetailPage({super.key, required this.transactionId});

  @override
  State<TransactionDetailPage> createState() => _TransactionDetailPageState();
}

class _TransactionDetailPageState extends State<TransactionDetailPage> {
  final TransactionDao _transactionDao = sl<TransactionDao>();
  final SessionManager _session = sl<SessionManager>();

  bool _isLoading = true;
  Map<String, dynamic>? _transaction;
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _loadTransaction();
  }

  Future<void> _loadTransaction() async {
    setState(() => _isLoading = true);
    try {
      final trx = await _transactionDao.getById(widget.transactionId);
      if (trx != null) {
        _transaction = trx;
        _items = List<Map<String, dynamic>>.from(trx['items'] as List);
      }
    } catch (e) {
      // ignore
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _printReceipt() async {
    if (_transaction == null) return;
    try {
      await ReceiptPrinter.printReceipt(
        transaction: _transaction!,
        items: _items,
        cashier: _session.currentUser!, // Assuming the person printing is the current user
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal mencetak struk: $e')));
      }
    }
  }

  Future<void> _printKitchenTicket() async {
    if (_transaction == null) return;
    try {
      await ReceiptPrinter.printKitchenTicket(
        transaction: _transaction!,
        items: _items,
        cashier: _session.currentUser!,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal mencetak tiket dapur: $e')));
      }
    }
  }

  Future<void> _voidTransaction() async {
    final user = _session.currentUser;
    if (user == null) return;

    int voidedByUserId = user.id ?? 1;

    // Check if the current user has permission to void. If not, ask for Supervisor PIN.
    if (!user.canVoidTransaction) {
      final overrideUser = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (ctx) => const PinVerificationDialog(actionDescription: 'Void Transaksi'),
      );

      if (overrideUser == null) {
        // Canceled
        return;
      }
      voidedByUserId = overrideUser['id'] as int;
    }

    if (!mounted) return;

    final reasonController = TextEditingController();
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Void Transaksi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Apakah Anda yakin ingin membatalkan transaksi ini? Stok bahan baku akan dikembalikan otomatis.'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Alasan Void',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Alasan harus diisi')));
                return;
              }
              Navigator.pop(ctx, true);
            },
            child: const Text('Void'),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    if (!mounted) return;

    setState(() => _isLoading = true);
    try {
      await _transactionDao.voidTransaction(
        transactionId: widget.transactionId,
        reason: reasonController.text.trim(),
        voidedBy: voidedByUserId,
      );
      await _loadTransaction();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal melakukan void: $e')));
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_transaction == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail Transaksi')),
        body: const Center(child: Text('Transaksi tidak ditemukan')),
      );
    }

    final trx = _transaction!;
    final isVoid = trx['status'] == 'void';
    
    // We allow everyone to see the button, but cashiers will be prompted for a PIN.
    final canInitiateVoid = !isVoid;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Detail ${trx['transaction_number']}', style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w600)),
        backgroundColor: AppColors.primaryDark,
        actions: [
          if (canInitiateVoid)
            IconButton(
              icon: const Icon(Icons.cancel_rounded, color: AppColors.error),
              tooltip: 'Void Transaksi',
              onPressed: _voidTransaction,
            ),
          IconButton(
            icon: const Icon(Icons.coffee_maker_rounded),
            tooltip: 'Cetak Tiket Barista',
            onPressed: _printKitchenTicket,
          ),
          IconButton(
            icon: const Icon(LucideIcons.printer),
            tooltip: 'Cetak Struk',
            onPressed: _printReceipt,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (isVoid) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: AppColors.errorLight, borderRadius: BorderRadius.circular(8)),
                        child: Column(
                          children: [
                            Text('TRANSAKSI DIBATALKAN (VOID)', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AppColors.error)),
                            const SizedBox(height: 4),
                            Text('Alasan: ${trx['void_reason']}', style: GoogleFonts.inter(fontSize: 12, color: AppColors.error)),
                            Text('Oleh: ${trx['voided_by_name'] ?? 'System'}', style: GoogleFonts.inter(fontSize: 12, color: AppColors.error)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    Text('Informasi Transaksi', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16)),
                    const Divider(),
                    _buildInfoRow('Waktu', trx['created_at'].toString().substring(0, 16).replaceAll('T', ' ')),
                    _buildInfoRow('Kasir', trx['user_name']?.toString() ?? '-'),
                    _buildInfoRow('Antrian', trx['queue_number']?.toString() ?? '-'),
                    _buildInfoRow('Tipe Pesanan', (trx['order_type'] as String).replaceAll('_', ' ').toUpperCase()),
                    _buildInfoRow('Metode Pembayaran', trx['payment_method'].toString().toUpperCase()),
                    const SizedBox(height: 24),

                    Text('Item Pesanan', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16)),
                    const Divider(),
                    ..._items.map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${item['quantity']}x ', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item['product_name'] as String, style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
                                    if (item['size'] != 'regular') Text('Ukuran: ${item['size']}', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
                                    if (item['sugar_level'] != 'normal') Text('Gula: ${item['sugar_level']}', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
                                    if (item['ice_level'] != 'normal') Text('Es: ${item['ice_level']}', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
                                    if (item['extra_shot'] == 1) Text('+ Extra Shot', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
                                    if (item['toppings_json'] != null) ...[
                                      ...((jsonDecode(item['toppings_json'] as String) as List).map(
                                        (t) => Text('+ ${t['name']}', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
                                      )),
                                    ],
                                  ],
                                ),
                              ),
                              Text(CurrencyFormatter.format((item['subtotal'] as num).toDouble()), style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
                            ],
                          ),
                        )),
                    const Divider(),
                    _buildInfoRow('Subtotal', CurrencyFormatter.format((trx['subtotal'] as num).toDouble())),
                    if ((trx['discount_amount'] as num).toDouble() > 0)
                      _buildInfoRow('Diskon', '-${CurrencyFormatter.format((trx['discount_amount'] as num).toDouble())}', color: AppColors.success),
                    if ((trx['service_charge_amount'] as num).toDouble() > 0)
                      _buildInfoRow('Service Charge', CurrencyFormatter.format((trx['service_charge_amount'] as num).toDouble())),
                    if ((trx['tax_amount'] as num).toDouble() > 0)
                      _buildInfoRow('Pajak (PPN)', CurrencyFormatter.format((trx['tax_amount'] as num).toDouble())),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total Bayar', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16)),
                        Text(
                          CurrencyFormatter.format((trx['total'] as num).toDouble()),
                          style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18, color: AppColors.accent),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow('Uang Diterima', CurrencyFormatter.format((trx['cash_received'] as num).toDouble())),
                    if ((trx['cash_change'] as num).toDouble() > 0)
                      _buildInfoRow('Kembalian', CurrencyFormatter.format((trx['cash_change'] as num).toDouble())),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 14)),
          Text(value, style: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 14, color: color)),
        ],
      ),
    );
  }
}
