import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../domain/entities/customer.dart';
import '../../../bloc/pos/pos_bloc.dart';
import '../../../bloc/pos/pos_event.dart';
import '../../../bloc/pos/pos_state.dart';
import '../../../../domain/entities/voucher.dart';
import 'customer_selection_dialog.dart';
import 'discount_dialog.dart';
import 'voucher_dialog.dart';
import 'payment_sheet.dart';

class CartSummary extends StatelessWidget {
  const CartSummary({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PosBloc, PosState>(
      builder: (context, state) {
        if (state.cartItems.isEmpty) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            boxShadow: [
              BoxShadow(color: AppColors.primaryDark.withValues(alpha: 0.05), blurRadius: 24, offset: const Offset(0, -8)),
            ],
          ),
          child: Column(
            children: [
              // Customer Name / Table Number Input
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: TextEditingController(text: state.customerNameInput)
                        ..selection = TextSelection.collapsed(offset: state.customerNameInput?.length ?? 0),
                      onChanged: (val) {
                        context.read<PosBloc>().add(SetCustomerName(val));
                      },
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: 'Nama / No Meja',
                        hintStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.textTertiary),
                        prefixIcon: const Icon(Icons.person_outline_rounded, size: 18, color: AppColors.textSecondary),
                        filled: true,
                        fillColor: AppColors.surfaceVariant,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.person_search_rounded, color: AppColors.primaryDark),
                      tooltip: 'Cari Member',
                      onPressed: () async {
                        final result = await showDialog<Customer>(
                          context: context,
                          builder: (ctx) => const CustomerSelectionDialog(),
                        );
                        if (result != null && context.mounted) {
                          context.read<PosBloc>().add(SetCustomer(result));
                        }
                      },
                    ),
                  ),
                ],
              ),
              if (state.selectedCustomer != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.verified_rounded, size: 14, color: AppColors.success),
                      const SizedBox(width: 4),
                      Text('Member: ${state.selectedCustomer!.name} (${state.selectedCustomer!.loyaltyPoints} Poin)', 
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.success)),
                    ],
                  ),
                ),
              const SizedBox(height: 20),

              _buildSummaryRow(AppStrings.subtotal, state.subtotal),
              if (state.selectedVoucher != null) ...[
                _buildSummaryRow('Voucher (${state.selectedVoucher!.code})', -state.selectedVoucher!.calculateDiscount(state.subtotal), isDiscount: true),
              ] else if (state.discountAmount > 0) ...[
                _buildSummaryRow(AppStrings.discount, -state.discountAmount, isDiscount: true),
              ],
              
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (state.selectedVoucher != null)
                    TextButton.icon(
                      onPressed: () {
                        context.read<PosBloc>().add(ClearVoucher());
                      },
                      icon: const Icon(Icons.close_rounded, size: 14, color: AppColors.error),
                      label: Text('Hapus Voucher', style: GoogleFonts.inter(fontSize: 12, color: AppColors.error, fontWeight: FontWeight.w600)),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    )
                  else
                    TextButton.icon(
                      onPressed: () async {
                        final result = await showDialog<Voucher>(
                          context: context,
                          builder: (ctx) => const VoucherDialog(),
                        );
                        if (result != null && context.mounted) {
                          context.read<PosBloc>().add(ApplyVoucher(result));
                        }
                      },
                      icon: const Icon(Icons.confirmation_number_outlined, size: 14, color: AppColors.success),
                      label: Text('Gunakan Voucher', style: GoogleFonts.inter(fontSize: 12, color: AppColors.success, fontWeight: FontWeight.w600)),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  const SizedBox(width: 8),
                  if (state.selectedVoucher == null)
                    TextButton.icon(
                      onPressed: () async {
                        final result = await showDialog<Map<String, dynamic>>(
                          context: context,
                          builder: (ctx) => DiscountDialog(
                            currentPercentage: state.discountPercentage,
                            currentNominal: state.discountNominal,
                            maxPercentage: state.maxCashierDiscount,
                          ),
                        );

                        if (result != null && context.mounted) {
                          context.read<PosBloc>().add(ApplyDiscount(
                                result['percentage'] as double,
                                result['nominal'] as double,
                              ));
                        }
                      },
                      icon: const Icon(Icons.local_offer_rounded, size: 14, color: AppColors.warning),
                      label: Text(state.discountAmount > 0 ? 'Ubah Diskon' : 'Terapkan Diskon', style: GoogleFonts.inter(fontSize: 12, color: AppColors.warning, fontWeight: FontWeight.w600)),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                ],
              ),
              if (state.serviceChargeEnabled)
                _buildSummaryRow('${AppStrings.serviceCharge} (${state.serviceChargePercentage.toStringAsFixed(0)}%)', state.serviceChargeAmount),
              if (state.taxEnabled)
                _buildSummaryRow('${AppStrings.tax} (${state.taxPercentage.toStringAsFixed(0)}%)', state.taxAmount),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Divider(color: AppColors.border.withValues(alpha: 0.5), height: 1),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Total', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                  Text(CurrencyFormatter.format(state.total),
                      style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.primaryDark, letterSpacing: -0.5)),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: state.cartItems.isEmpty ? LinearGradient(colors: [AppColors.border, AppColors.border]) : AppColors.accentGradient,
                    boxShadow: state.cartItems.isEmpty ? null : [
                      BoxShadow(color: AppColors.accent.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: state.cartItems.isNotEmpty && state.isShiftOpen ? () {
                       showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          useSafeArea: true,
                          builder: (ctx) => BlocProvider.value(
                            value: context.read<PosBloc>(),
                            child: const PaymentSheet(),
                          ),
                        );
                    } : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      disabledForegroundColor: AppColors.textSecondary,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.payment_rounded, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Text('Bayar Pesanan', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryRow(String label, double amount, {bool isDiscount = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
          Text(
            '${isDiscount ? '-' : ''}${CurrencyFormatter.format(amount.abs())}',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDiscount ? AppColors.error : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
