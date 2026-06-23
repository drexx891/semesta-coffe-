import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../domain/entities/voucher.dart';
import '../../../../../data/database/dao/voucher_dao.dart';

class VoucherFormDialog extends StatefulWidget {
  final Voucher? voucher;

  const VoucherFormDialog({super.key, this.voucher});

  @override
  State<VoucherFormDialog> createState() => _VoucherFormDialogState();
}

class _VoucherFormDialogState extends State<VoucherFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _discountPctController = TextEditingController(text: '0');
  final _discountNominalController = TextEditingController(text: '0');
  final _minPurchaseController = TextEditingController(text: '0');
  final _maxDiscountController = TextEditingController(text: '0');
  final _usageLimitController = TextEditingController(text: '999999');
  
  DateTime _validFrom = DateTime.now();
  DateTime _validUntil = DateTime.now().add(const Duration(days: 30));
  bool _isActive = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.voucher != null) {
      final v = widget.voucher!;
      _codeController.text = v.code;
      _discountPctController.text = v.discountPercentage.toStringAsFixed(0);
      _discountNominalController.text = v.discountNominal.toStringAsFixed(0);
      _minPurchaseController.text = v.minPurchase.toStringAsFixed(0);
      _maxDiscountController.text = v.maxDiscount.toStringAsFixed(0);
      _usageLimitController.text = v.usageLimit.toString();
      _validFrom = v.validFrom;
      _validUntil = v.validUntil;
      _isActive = v.isActive;
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _discountPctController.dispose();
    _discountNominalController.dispose();
    _minPurchaseController.dispose();
    _maxDiscountController.dispose();
    _usageLimitController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isFrom) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isFrom ? _validFrom : _validUntil,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _validFrom = picked;
          if (_validUntil.isBefore(_validFrom)) _validUntil = _validFrom.add(const Duration(days: 1));
        } else {
          _validUntil = picked;
          if (_validFrom.isAfter(_validUntil)) _validFrom = _validUntil.subtract(const Duration(days: 1));
        }
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final code = _codeController.text.trim().toUpperCase();
      final pct = double.tryParse(_discountPctController.text) ?? 0;
      final nom = double.tryParse(_discountNominalController.text) ?? 0;
      final minP = double.tryParse(_minPurchaseController.text) ?? 0;
      final maxD = double.tryParse(_maxDiscountController.text) ?? 0;
      final limit = int.tryParse(_usageLimitController.text) ?? 999999;

      final dao = GetIt.I<VoucherDao>();
      
      // Validate unique code
      if (widget.voucher == null || widget.voucher!.code != code) {
        final existing = await dao.getVoucherByCode(code);
        if (existing != null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kode voucher sudah digunakan')));
            setState(() => _isLoading = false);
          }
          return;
        }
      }

      final voucher = Voucher(
        id: widget.voucher?.id,
        code: code,
        discountPercentage: pct,
        discountNominal: nom,
        minPurchase: minP,
        maxDiscount: maxD,
        usageLimit: limit,
        usedCount: widget.voucher?.usedCount ?? 0,
        validFrom: _validFrom,
        validUntil: _validUntil,
        isActive: _isActive,
        createdAt: widget.voucher?.createdAt ?? DateTime.now(),
      );

      if (widget.voucher == null) {
        await dao.insertVoucher(voucher);
      } else {
        await dao.updateVoucher(voucher);
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy');
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        padding: const EdgeInsets.all(24),
        width: 500,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.voucher == null ? 'Tambah Voucher' : 'Edit Voucher',
                  style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _codeController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    labelText: 'Kode Voucher',
                    hintText: 'Contoh: DISKON10',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (val) => val == null || val.isEmpty ? 'Kode harus diisi' : null,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _discountPctController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Diskon (%)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _discountNominalController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Diskon Nominal (Rp)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _minPurchaseController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Min. Pembelian (Rp)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _maxDiscountController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Maks. Diskon (Rp)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _usageLimitController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Limit Kuota Penggunaan',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectDate(context, true),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Berlaku Dari',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(dateFormat.format(_validFrom)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectDate(context, false),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Berlaku Sampai',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(dateFormat.format(_validUntil)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Aktif'),
                  value: _isActive,
                  onChanged: (val) => setState(() => _isActive = val),
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Batal'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryDark,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isLoading 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Simpan'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
