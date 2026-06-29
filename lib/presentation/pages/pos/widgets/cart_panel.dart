import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../bloc/pos/pos_bloc.dart';
import '../../../bloc/pos/pos_event.dart';
import '../../../bloc/pos/pos_state.dart';
import 'hold_order_dialog.dart';
import 'package:lucide_icons/lucide_icons.dart';

class CartPanel extends StatelessWidget {
  final ScrollController scrollController;

  const CartPanel({super.key, required this.scrollController});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PosBloc, PosState>(
      builder: (context, state) {
        return Column(
          children: [
            // Cart header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border(bottom: BorderSide(color: AppColors.border.withValues(alpha: 0.5))),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.shoppingCart, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '${AppStrings.cart} (${state.cartItems.fold<int>(0, (s, i) => s + i.quantity)})',
                    style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  if (state.cartItems.isNotEmpty) ...[
                    TextButton.icon(
                      onPressed: () => _showSaveHoldOrder(context),
                      icon: const Icon(Icons.pause_circle_outline_rounded, size: 16, color: AppColors.warning),
                      label: Text('Hold', style: GoogleFonts.inter(fontSize: 12, color: AppColors.warning)),
                    ),
                    const SizedBox(width: 4),
                    TextButton.icon(
                      onPressed: () => context.read<PosBloc>().add(ClearCart()),
                      icon: const Icon(LucideIcons.trash2, size: 16, color: AppColors.error),
                      label: Text(AppStrings.clearCart,
                          style: GoogleFonts.inter(fontSize: 12, color: AppColors.error)),
                    ),
                  ],
                ],
              ),
            ),

            // Cart items
            Expanded(
              child: state.cartItems.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.shoppingCart_outlined, size: 48, color: AppColors.textTertiary.withValues(alpha: 0.3)),
                          const SizedBox(height: 8),
                          Text(AppStrings.emptyCart, style: GoogleFonts.inter(color: AppColors.textTertiary, fontSize: 14)),
                          const SizedBox(height: 4),
                          Text(AppStrings.emptyCartMessage,
                              style: GoogleFonts.inter(color: AppColors.textTertiary, fontSize: 12)),
                        ],
                      ),
                    )
                  : ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.all(12),
                      itemCount: state.cartItems.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (ctx, index) {
                        final item = state.cartItems[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.productName,
                                        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                                    if (item.hasModifiers)
                                      Text(item.modifierDisplay,
                                          style: GoogleFonts.inter(fontSize: 11, color: AppColors.textTertiary)),
                                    if (item.notes != null && item.notes!.isNotEmpty)
                                      Text('📝 ${item.notes}',
                                          style: GoogleFonts.inter(fontSize: 11, color: AppColors.textTertiary)),
                                    const SizedBox(height: 4),
                                    Text(CurrencyFormatter.format(item.unitPrice),
                                        style: GoogleFonts.inter(fontSize: 12, color: AppColors.accent, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                              // Quantity controls
                              Container(
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceVariant,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(LucideIcons.minus, size: 16),
                                      onPressed: () => context.read<PosBloc>().add(UpdateCartItemQuantity(index, -1)),
                                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                      padding: EdgeInsets.zero,
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 4),
                                      child: Text('${item.quantity}',
                                          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
                                    ),
                                    IconButton(
                                      icon: const Icon(LucideIcons.plus, size: 16),
                                      onPressed: () => context.read<PosBloc>().add(UpdateCartItemQuantity(index, 1)),
                                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                      padding: EdgeInsets.zero,
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Item subtotal
                              SizedBox(
                                width: 75,
                                child: Text(
                                  CurrencyFormatter.format(item.subtotal),
                                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  void _showSaveHoldOrder(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => SaveHoldOrderDialog(
        onSave: (label) {
          context.read<PosBloc>().add(SaveHoldOrder(label));
        },
      ),
    );
  }
}
