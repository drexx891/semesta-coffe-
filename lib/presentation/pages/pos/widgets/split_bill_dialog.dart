import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';

class SplitBillDialog extends StatefulWidget {
  final double totalAmount;

  const SplitBillDialog({super.key, required this.totalAmount});

  @override
  State<SplitBillDialog> createState() => _SplitBillDialogState();
}

class _SplitBillDialogState extends State<SplitBillDialog> {
  final List<Map<String, dynamic>> _payments = [];
  double _remaining = 0;

  @override
  void initState() {
    super.initState();
    _remaining = widget.totalAmount;
    _addPaymentLine();
  }

  void _addPaymentLine() {
    if (_remaining <= 0) return;
    setState(() {
      _payments.add({
        'method': 'cash',
        'amount': _remaining,
        'controller': TextEditingController(text: _remaining.toStringAsFixed(0)),
      });
      _calculateRemaining();
    });
  }

  void _removePaymentLine(int index) {
    setState(() {
      _payments.removeAt(index);
      _calculateRemaining();
    });
  }

  void _calculateRemaining() {
    double paid = 0;
    for (var p in _payments) {
      paid += p['amount'] as double;
    }
    _remaining = widget.totalAmount - paid;
  }

  void _updatePaymentMethod(int index, String method) {
    setState(() {
      _payments[index]['method'] = method;
    });
  }

  void _updatePaymentAmount(int index, String value) {
    setState(() {
      _payments[index]['amount'] = double.tryParse(value) ?? 0;
      _calculateRemaining();
    });
  }

  Future<void> _processSplit() async {
    // Return all payments
    final result = _payments.map((p) => {
      'payment_method': p['method'],
      'amount': p['amount'],
    }).toList();
    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Split Bill', style: GoogleFonts.playfairDisplay(fontSize: 24, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('Total: ${CurrencyFormatter.format(widget.totalAmount)}', style: GoogleFonts.inter(fontSize: 16, color: AppColors.textSecondary)),
            const Divider(height: 32),
            
            ListView.builder(
              shrinkWrap: true,
              itemCount: _payments.length,
              itemBuilder: (ctx, index) {
                final payment = _payments[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<String>(
                          initialValue: payment['method'],
                          decoration: const InputDecoration(
                            isDense: true,
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'cash', child: Text('Cash')),
                            DropdownMenuItem(value: 'qris', child: Text('QRIS')),
                            DropdownMenuItem(value: 'transfer', child: Text('Transfer')),
                            DropdownMenuItem(value: 'edc', child: Text('EDC')),
                          ],
                          onChanged: (v) => _updatePaymentMethod(index, v!),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: payment['controller'],
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            prefixText: 'Rp ',
                            isDense: true,
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                          onChanged: (v) => _updatePaymentAmount(index, v),
                        ),
                      ),
                      if (_payments.length > 1)
                        IconButton(
                          icon: const Icon(Icons.remove_circle, color: AppColors.error),
                          onPressed: () => _removePaymentLine(index),
                        ),
                    ],
                  ),
                );
              },
            ),
            
            if (_remaining > 0)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _addPaymentLine,
                  icon: const Icon(Icons.add),
                  label: const Text('Tambah Pembayaran'),
                ),
              ),

            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _remaining == 0 ? AppColors.successLight : (_remaining < 0 ? AppColors.errorLight : AppColors.surfaceVariant),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_remaining < 0 ? 'Kembalian:' : 'Sisa:', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                  Text(CurrencyFormatter.format(_remaining.abs()), style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: _remaining == 0 ? AppColors.success : (_remaining < 0 ? AppColors.error : AppColors.textPrimary))),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _remaining <= 0 ? _processSplit : null,
                  child: const Text('Proses Pembayaran'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
