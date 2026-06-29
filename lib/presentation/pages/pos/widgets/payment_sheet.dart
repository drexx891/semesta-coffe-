import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../bloc/pos/pos_bloc.dart';
import '../../../bloc/pos/pos_event.dart';
import '../../../bloc/pos/pos_state.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../data/database/dao/settings_dao.dart';
import 'dart:convert';

class PaymentSheet extends StatefulWidget {
  const PaymentSheet({super.key});

  @override
  State<PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends State<PaymentSheet> {
  String selectedMethod = 'cash';
  final cashController = TextEditingController();
  double cashReceived = 0;
  String? _qrisBase64;

  @override
  void initState() {
    super.initState();
    context.read<PosBloc>().add(SyncCartState(status: 'payment', paymentMethod: selectedMethod));
    _loadQrisSettings();
  }

  Future<void> _loadQrisSettings() async {
    final settingsDao = sl<SettingsDao>();
    final settings = await settingsDao.getSettings();
    if (settings != null && settings['qris_image_path'] != null) {
      if (mounted) {
        setState(() {
          _qrisBase64 = settings['qris_image_path'] as String?;
        });
      }
    }
  }

  @override
  void dispose() {
    cashController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PosBloc, PosState>(
      builder: (context, state) {
        final change = cashReceived - state.total;
        final canConfirm = selectedMethod != 'cash' || change >= 0;

        return Container(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title
              Text(AppStrings.paymentMethod,
                  style: GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),

              // Payment methods
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _paymentMethodChip('cash', AppStrings.cash, Icons.money_rounded, AppColors.paymentCash, selectedMethod),
                  _paymentMethodChip('qris', AppStrings.qris, Icons.qr_code_rounded, AppColors.paymentQris, selectedMethod),
                  _paymentMethodChip('transfer', AppStrings.bankTransfer, Icons.account_balance_rounded, AppColors.paymentTransfer, selectedMethod),
                  _paymentMethodChip('edc', AppStrings.edc, Icons.credit_card_rounded, AppColors.paymentEdc, selectedMethod),
                ],
              ),
              const SizedBox(height: 20),

              // Total
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(AppStrings.total, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
                    Text(CurrencyFormatter.format(state.total),
                        style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.accent)),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // QRIS Image
              if (selectedMethod == 'qris' && _qrisBase64 != null) ...[
                Center(
                  child: Column(
                    children: [
                      Text('Silakan Scan QRIS Berikut', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Container(
                        height: 250,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(base64Decode(_qrisBase64!), fit: BoxFit.contain),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Cash input
              if (selectedMethod == 'cash') ...[
                TextField(
                  controller: cashController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: AppStrings.cashReceived,
                    prefixText: 'Rp ',
                    filled: true,
                  ),
                  style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600),
                  onChanged: (v) {
                    setState(() {
                      cashReceived = double.tryParse(v.replaceAll('.', '').replaceAll(',', '')) ?? 0;
                    });
                  },
                ),
                const SizedBox(height: 12),
                if (cashReceived > 0)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: change >= 0 ? AppColors.successLight : AppColors.errorLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(AppStrings.change, style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
                        Text(
                          change >= 0 ? CurrencyFormatter.format(change) : AppStrings.cashNotEnough,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: change >= 0 ? AppColors.success : AppColors.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                // Quick cash buttons
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [state.total, 50000, 100000, 150000, 200000].map((amount) {
                    return ActionChip(
                      label: Text(CurrencyFormatter.format(amount.toDouble())),
                      onPressed: () {
                        cashController.text = amount.toStringAsFixed(0);
                        setState(() => cashReceived = amount.toDouble());
                      },
                      backgroundColor: AppColors.surfaceVariant,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
              ],

              // Confirm button
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: canConfirm && state.paymentStatus != PaymentStatus.processing ? () {
                    context.read<PosBloc>().add(ProcessPayment(selectedMethod, cashReceived));
                  } : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryDark,
                    disabledBackgroundColor: AppColors.border,
                  ),
                  child: state.paymentStatus == PaymentStatus.processing 
                    ? const CircularProgressIndicator(color: AppColors.white)
                    : Text(AppStrings.confirmPayment,
                      style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.white)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _paymentMethodChip(String value, String label, IconData icon, Color color, String selected) {
    final isSelected = value == selected;
    return GestureDetector(
      onTap: () {
        setState(() => selectedMethod = value);
        context.read<PosBloc>().add(SyncCartState(status: 'payment', paymentMethod: selectedMethod));
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? color : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: isSelected ? color : AppColors.textSecondary),
            const SizedBox(width: 6),
            Text(label, style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected ? color : AppColors.textSecondary,
            )),
          ],
        ),
      ),
    );
  }
}
