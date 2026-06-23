import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../data/database/dao/stock_dao.dart';
import '../../../../services/session_manager.dart';

class StockAdjustmentDialog extends StatefulWidget {
  final Map<String, dynamic> ingredient;

  const StockAdjustmentDialog({super.key, required this.ingredient});

  @override
  State<StockAdjustmentDialog> createState() => _StockAdjustmentDialogState();
}

class _StockAdjustmentDialogState extends State<StockAdjustmentDialog> {
  final StockDao _stockDao = sl<StockDao>();
  final SessionManager _session = sl<SessionManager>();
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _qtyController;
  late TextEditingController _reasonController;
  
  String _adjustmentType = 'add'; // 'add', 'correct'
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _qtyController = TextEditingController();
    _reasonController = TextEditingController();
  }

  @override
  void dispose() {
    _qtyController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    
    try {
      final qty = double.tryParse(_qtyController.text) ?? 0.0;
      final userId = _session.currentUser?.id ?? 1;

      if (_adjustmentType == 'add') {
        await _stockDao.addStock(
          ingredientId: widget.ingredient['id'] as int,
          quantity: qty,
          userId: userId,
          invoiceNumber: _reasonController.text.trim().isNotEmpty ? _reasonController.text.trim() : null,
        );
      } else {
        await _stockDao.correctStock(
          ingredientId: widget.ingredient['id'] as int,
          newQuantity: qty,
          reason: _reasonController.text.trim(),
          userId: userId,
        );
      }
      
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e')));
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentStock = (widget.ingredient['current_stock'] as num).toDouble();
    final unit = widget.ingredient['unit'] as String;

    return AlertDialog(
      title: Text(
        'Penyesuaian Stok',
        style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w600),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.ingredient['name'] as String,
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                'Stok saat ini: ${currentStock.toStringAsFixed(0)} $unit',
                style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'add', label: Text('Tambah (In)')),
                  ButtonSegment(value: 'correct', label: Text('Koreksi (Opname)')),
                ],
                selected: {_adjustmentType},
                onSelectionChanged: (Set<String> newSelection) {
                  setState(() => _adjustmentType = newSelection.first);
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _qtyController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: _adjustmentType == 'add' ? 'Jumlah Ditambah' : 'Stok Aktual Baru',
                  suffixText: unit,
                  border: const OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Harus diisi' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _reasonController,
                decoration: InputDecoration(
                  labelText: _adjustmentType == 'add' ? 'No. Invoice / Keterangan (Opsional)' : 'Alasan Koreksi',
                  border: const OutlineInputBorder(),
                ),
                validator: (v) {
                  if (_adjustmentType == 'correct' && (v == null || v.isEmpty)) {
                    return 'Alasan koreksi harus diisi';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Simpan'),
        ),
      ],
    );
  }
}
