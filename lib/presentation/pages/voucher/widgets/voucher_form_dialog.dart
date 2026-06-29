import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../domain/entities/voucher.dart';
import '../../../bloc/voucher/voucher_bloc.dart';
import '../../../bloc/voucher/voucher_event.dart';
import 'package:lucide_icons/lucide_icons.dart';

class VoucherFormDialog extends StatefulWidget {
  final Voucher? voucher;

  const VoucherFormDialog({super.key, this.voucher});

  @override
  State<VoucherFormDialog> createState() => _VoucherFormDialogState();
}

class _VoucherFormDialogState extends State<VoucherFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _codeController;
  late TextEditingController _discountPercController;
  late TextEditingController _discountNominalController;
  late TextEditingController _minPurchaseController;
  late TextEditingController _maxDiscountController;
  late TextEditingController _usageLimitController;
  
  DateTime? _validFrom;
  DateTime? _validUntil;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController(text: widget.voucher?.code ?? '');
    _discountPercController = TextEditingController(text: (widget.voucher?.discountPercentage ?? 0).toString());
    _discountNominalController = TextEditingController(text: (widget.voucher?.discountNominal ?? 0).toString());
    _minPurchaseController = TextEditingController(text: (widget.voucher?.minPurchase ?? 0).toString());
    _maxDiscountController = TextEditingController(text: (widget.voucher?.maxDiscount ?? 0).toString());
    _usageLimitController = TextEditingController(text: (widget.voucher?.usageLimit ?? 9999).toString());
    
    _validFrom = widget.voucher?.validFrom ?? DateTime.now();
    _validUntil = widget.voucher?.validUntil ?? DateTime.now().add(const Duration(days: 30));
    _isActive = widget.voucher?.isActive ?? true;
  }

  @override
  void dispose() {
    _codeController.dispose();
    _discountPercController.dispose();
    _discountNominalController.dispose();
    _minPurchaseController.dispose();
    _maxDiscountController.dispose();
    _usageLimitController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isFrom) async {
    final initialDate = isFrom ? _validFrom! : _validUntil!;
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null) {
      setState(() {
        if (isFrom) {
          _validFrom = pickedDate;
        } else {
          _validUntil = pickedDate;
        }
      });
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final voucher = Voucher(
      id: widget.voucher?.id,
      code: _codeController.text.trim().toUpperCase(),
      discountPercentage: double.tryParse(_discountPercController.text) ?? 0.0,
      discountNominal: double.tryParse(_discountNominalController.text) ?? 0.0,
      minPurchase: double.tryParse(_minPurchaseController.text) ?? 0.0,
      maxDiscount: double.tryParse(_maxDiscountController.text) ?? 0.0,
      validFrom: _validFrom!,
      validUntil: _validUntil!,
      usageLimit: int.tryParse(_usageLimitController.text) ?? 9999,
      usedCount: widget.voucher?.usedCount ?? 0,
      isActive: _isActive,
      createdAt: widget.voucher?.createdAt ?? DateTime.now(),
    );

    if (widget.voucher == null) {
      context.read<VoucherBloc>().add(AddVoucher(voucher));
    } else {
      context.read<VoucherBloc>().add(UpdateVoucher(voucher));
    }
    
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: AlertDialog(
        backgroundColor: AppColors.surface.withValues(alpha: 0.95),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          widget.voucher == null ? 'Buat Voucher Baru' : 'Edit Voucher',
          style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w700),
        ),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _codeController,
                    decoration: const InputDecoration(
                      labelText: 'Kode Voucher (Unik)',
                      prefixIcon: Icon(LucideIcons.ticket),
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'Kode wajib diisi' : null,
                  ),
                  const SizedBox(height: AppDimensions.spacing16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _discountPercController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Diskon (%)',
                            prefixIcon: Icon(LucideIcons.percent),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppDimensions.spacing16),
                      Expanded(
                        child: TextFormField(
                          controller: _discountNominalController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Diskon (Rp)',
                            prefixIcon: Icon(LucideIcons.banknote),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.spacing16),
                  TextFormField(
                    controller: _minPurchaseController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Min. Pembelian (Rp)',
                      prefixIcon: Icon(LucideIcons.shoppingCart),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spacing16),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _selectDate(context, true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.border),
                              borderRadius: BorderRadius.circular(100), // pill shape
                            ),
                            child: Row(
                              children: [
                                const Icon(LucideIcons.calendarDays, color: AppColors.textSecondary, size: 20),
                                const SizedBox(width: 8),
                                Expanded(child: Text(DateFormat('dd MMM yyyy').format(_validFrom!), style: const TextStyle(fontSize: 14))),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppDimensions.spacing16),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _selectDate(context, false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.border),
                              borderRadius: BorderRadius.circular(100), // pill shape
                            ),
                            child: Row(
                              children: [
                                const Icon(LucideIcons.calendarCheck, color: AppColors.textSecondary, size: 20),
                                const SizedBox(width: 8),
                                Expanded(child: Text(DateFormat('dd MMM yyyy').format(_validUntil!), style: const TextStyle(fontSize: 14))),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.spacing16),
                  SwitchListTile(
                    title: Text('Voucher Aktif', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                    value: _isActive,
                    onChanged: (val) => setState(() => _isActive = val),
                    activeColor: AppColors.accent,
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: _save,
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }
}
