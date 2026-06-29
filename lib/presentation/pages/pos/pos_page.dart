import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/di/injection_container.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/base64_image_helper.dart';
import '../../../data/database/dao/hold_order_dao.dart';
import '../../../domain/entities/hold_order.dart';

import '../../bloc/menu/menu_bloc.dart';
import '../../bloc/menu/menu_event.dart';
import '../../bloc/menu/menu_state.dart';
import '../../bloc/pos/pos_bloc.dart';
import '../../bloc/pos/pos_event.dart';
import '../../bloc/pos/pos_state.dart';

import 'widgets/modifier_bottom_sheet.dart';
import 'widgets/cart_panel.dart';
import 'widgets/cart_summary.dart';
import 'widgets/shift_warning_banner.dart';
import 'widgets/payment_success_dialog.dart';
import 'package:lucide_icons/lucide_icons.dart';

class PosPage extends StatefulWidget {
  const PosPage({super.key});

  @override
  State<PosPage> createState() => _PosPageState();
}

class _PosPageState extends State<PosPage> {
  final ScrollController _cartScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      context.read<MenuBloc>().add(LoadMenu());
    });
  }

  @override
  void dispose() {
    _cartScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width >= AppDimensions.tabletBreakpoint;

    return BlocListener<PosBloc, PosState>(
        listenWhen: (previous, current) =>
            previous.paymentStatus != current.paymentStatus ||
            previous.errorMessage != current.errorMessage,
        listener: (context, state) {
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage!), backgroundColor: AppColors.error),
            );
          }

          if (state.paymentStatus == PaymentStatus.success && state.lastTransactionId != null) {
            // Close PaymentSheet
            Navigator.of(context).pop();
            
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (_) => BlocProvider.value(
                value: context.read<PosBloc>(),
                child: PaymentSuccessDialog(
                  transactionId: state.lastTransactionId!,
                  queueNumber: state.lastQueueNumber ?? '-',
                  trxNumber: state.lastTransactionNumber ?? '-',
                ),
              ),
            );
            // Reset payment status after showing dialog (BUG 7/10 fix)
            context.read<PosBloc>().add(ResetPos());
          }
        },
        child: Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: Text(AppStrings.pos, style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            backgroundColor: AppColors.surface,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            shadowColor: AppColors.primaryDark.withValues(alpha: 0.05),
            actions: [
              BlocBuilder<PosBloc, PosState>(
                builder: (context, state) {
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildOrderTypeButton(context, AppStrings.dineIn, 'dine_in', Icons.restaurant_rounded, state.orderType),
                        _buildOrderTypeButton(context, AppStrings.takeAway, 'take_away', Icons.takeout_dining_rounded, state.orderType),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
              BlocBuilder<PosBloc, PosState>(
                builder: (context, state) {
                  return Badge(
                    isLabelVisible: state.activeHoldOrders > 0,
                    label: Text('${state.activeHoldOrders}', style: const TextStyle(fontSize: 12)),
                    backgroundColor: AppColors.error,
                    alignment: const Alignment(0.4, -0.4),
                    child: IconButton(
                      icon: const Icon(LucideLucideIcons.history, color: AppColors.textSecondary),
                      tooltip: 'Hold Orders',
                      onPressed: () => _showHoldOrdersDialog(context),
                    ),
                  );
                },
              ),
              const SizedBox(width: 16),
            ],
          ),
          body: Column(
            children: [
              const ShiftWarningBanner(),
              Expanded(
                child: isTablet ? _buildTabletLayout() : _buildPhoneLayout(),
              ),
            ],
          ),
        ),
    );
  }

  void _showHoldOrdersDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return FutureBuilder<List<Map<String, dynamic>>>(
          future: sl<HoldOrderDao>().getActiveHoldOrders(),
          builder: (context, snapshot) {
            final orders = snapshot.data ?? [];
            return AlertDialog(
              title: Text('Hold Orders', style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w600)),
              content: SizedBox(
                width: 360,
                child: orders.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text('Tidak ada pesanan ditahan', style: GoogleFonts.inter(color: AppColors.textTertiary)),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: orders.length,
                        separatorBuilder: (_, _) => const Divider(),
                        itemBuilder: (ctx, index) {
                          final order = orders[index];
                          final label = order['label'] as String? ?? 'Pesanan';
                          final createdAt = order['created_at'] as String? ?? '';
                          final itemsJson = order['items_json'] as String? ?? '[]';
                          List<CartItem> items = [];
                          try {
                            items = CartItem.decodeList(itemsJson);
                          } catch (_) {}
                          final totalItems = items.fold<int>(0, (s, i) => s + i.quantity);
                          final orderType = order['order_type'] as String? ?? 'dine_in';

                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Container(
                              width: 40, height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.warning.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.pause_circle_rounded, color: AppColors.warning),
                            ),
                            title: Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
                            subtitle: Text('$totalItems item · ${orderType == 'dine_in' ? 'Dine In' : 'Takeaway'}',
                                style: GoogleFonts.inter(fontSize: 12, color: AppColors.textTertiary)),
                            trailing: IconButton(
                              icon: const Icon(Icons.play_circle_rounded, color: AppColors.success, size: 28),
                              tooltip: 'Muat pesanan',
                              onPressed: () {
                                Navigator.pop(context);
                                final holdOrder = HoldOrder(
                                  id: order['id'] as int?,
                                  label: label,
                                  orderType: orderType,
                                  tableNumber: order['table_number'] as String?,
                                  items: items,
                                  userId: order['user_id'] as int? ?? 1,
                                  createdAt: DateTime.tryParse(createdAt) ?? DateTime.now(),
                                  expiresAt: DateTime.tryParse(order['expires_at'] as String? ?? '') ?? DateTime.now(),
                                );
                                ctx.read<PosBloc>().add(LoadHoldOrder(holdOrder));
                              },
                            ),
                          );
                        },
                      ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Tutup'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildOrderTypeButton(BuildContext context, String label, String type, IconData icon, String currentType) {
    final isSelected = currentType == type;
    return GestureDetector(
      onTap: () => context.read<PosBloc>().add(SetOrderType(type)),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryDark : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          boxShadow: isSelected ? [
            BoxShadow(color: AppColors.primaryDark.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 2))
          ] : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isSelected ? AppColors.white : AppColors.textSecondary),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? AppColors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabletLayout() {
    return Row(
      children: [
        // Menu panel
        Expanded(
          flex: 6,
          child: _buildMenuPanel(),
        ),
        // Cart panel
        Container(
          width: 360,
          decoration: BoxDecoration(
            color: AppColors.white,
            boxShadow: [
              BoxShadow(
                color: AppColors.cardShadow.withValues(alpha: 0.15),
                blurRadius: 10,
                offset: const Offset(-2, 0),
              ),
            ],
          ),
          child: Column(
            children: [
              Expanded(child: CartPanel(scrollController: _cartScrollController)),
              const CartSummary(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneLayout() {
    return Stack(
      children: [
        _buildMenuPanel(),
        // Cart button overlay for phone
        BlocBuilder<PosBloc, PosState>(
          builder: (context, state) {
            if (state.cartItems.isEmpty) return const SizedBox.shrink();
            
            return Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    useSafeArea: true,
                    builder: (ctx) => DraggableScrollableSheet(
                      initialChildSize: 0.85,
                      minChildSize: 0.5,
                      maxChildSize: 0.95,
                      expand: false,
                      builder: (ctx, scrollController) => Container(
                        decoration: const BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                        ),
                        child: BlocProvider.value(
                          value: context.read<PosBloc>(),
                          child: Column(
                            children: [
                              Expanded(child: CartPanel(scrollController: scrollController)),
                              const CartSummary(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primaryDark, AppColors.primary],
                    ),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryDark.withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${state.cartItems.fold<int>(0, (sum, item) => sum + item.quantity)}',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        AppStrings.cart,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.white,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        CurrencyFormatter.format(state.total),
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildMenuPanel() {
    return BlocBuilder<MenuBloc, MenuState>(
      builder: (context, state) {
        if (state is MenuLoading || state is MenuInitial) {
          return const Center(child: CircularProgressIndicator(color: AppColors.accent));
        }

        if (state is MenuError) {
          return Center(child: Text(state.message));
        }

        final menuState = state as MenuLoaded;

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppDimensions.spacing12),
              child: TextField(
                decoration: InputDecoration(
                  hintText: AppStrings.searchProduct,
                  prefixIcon: const Icon(LucideLucideIcons.search),
                  filled: true,
                  fillColor: AppColors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (v) => context.read<MenuBloc>().add(SearchMenu(v)),
              ),
            ),
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacing12),
                children: [
                  _buildCategoryChip(context, null, AppStrings.allCategory, menuState.selectedCategoryId),
                  ...menuState.categories.map((c) => _buildCategoryChip(context, c['id'] as int, c['name'] as String, menuState.selectedCategoryId)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: menuState.filteredProducts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.coffee_rounded, size: 64, color: AppColors.textTertiary.withValues(alpha: 0.3)),
                          const SizedBox(height: 12),
                          Text(AppStrings.noData, style: GoogleFonts.inter(color: AppColors.textTertiary)),
                        ],
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(AppDimensions.spacing12),
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 170,
                        childAspectRatio: 0.78,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: menuState.filteredProducts.length,
                      itemBuilder: (ctx, index) {
                        final product = menuState.filteredProducts[index];
                        return _buildProductCard(context, product, menuState.stockAvailability);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCategoryChip(BuildContext context, int? id, String name, int? selectedId) {
    final isSelected = selectedId == id;
    return GestureDetector(
      onTap: () => context.read<MenuBloc>().add(SelectCategory(id)),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryDark : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primaryDark : AppColors.border.withValues(alpha: 0.5),
          ),
          boxShadow: isSelected ? [
            BoxShadow(color: AppColors.primaryDark.withValues(alpha: 0.15), blurRadius: 8, offset: const Offset(0, 2))
          ] : null,
        ),
        child: Center(
          child: Text(
            name,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, Map<String, dynamic> product, Map<int, bool> stockAvailability) {
    final productId = product['id'] as int;
    final isAvailable = stockAvailability[productId] ?? true;

    return _ProductCard(
      product: product,
      isAvailable: isAvailable,
    );
  }
}

class _ProductCard extends StatefulWidget {
  final Map<String, dynamic> product;
  final bool isAvailable;

  const _ProductCard({required this.product, required this.isAvailable});

  @override
  State<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<_ProductCard> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final name = widget.product['name'] as String;
    final price = (widget.product['price_regular'] as num).toDouble();

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: widget.isAvailable ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTapDown: widget.isAvailable ? (_) => setState(() => _isPressed = true) : null,
        onTapUp: widget.isAvailable ? (_) => setState(() => _isPressed = false) : null,
        onTapCancel: widget.isAvailable ? () => setState(() => _isPressed = false) : null,
        onTap: widget.isAvailable ? () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            useSafeArea: true,
            backgroundColor: Colors.transparent,
            builder: (ctx) => ModifierBottomSheet(
              product: widget.product,
              onAddToCart: (item) {
                context.read<PosBloc>().add(AddToCart(item));
              },
            ),
          );
        } : null,
        child: AnimatedScale(
          scale: _isPressed ? 0.95 : (_isHovered ? 1.03 : 1.0),
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium * 1.5),
              border: Border.all(
                color: _isHovered && widget.isAvailable ? AppColors.primary : AppColors.border.withValues(alpha: 0.3),
                width: _isHovered && widget.isAvailable ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryDark.withValues(alpha: _isHovered ? 0.15 : 0.05),
                  blurRadius: _isHovered ? 20 : 12,
                  offset: Offset(0, _isHovered ? 8 : 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium * 1.5),
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        flex: 3,
                        child: Container(
                          color: AppColors.surfaceVariant,
                          child: widget.product['image_path'] != null && (widget.product['image_path'] as String).isNotEmpty
                              ? Base64ImageHelper.buildImage(widget.product['image_path'] as String, fit: BoxFit.cover)
                              : const Icon(Icons.coffee_rounded, size: 48, color: AppColors.border),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                name,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                  height: 1.2,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                CurrencyFormatter.format(price),
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.accentDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (!widget.isAvailable)
                    Positioned.fill(
                      child: ClipRect(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                          child: Container(
                            color: AppColors.surface.withValues(alpha: 0.3),
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.textPrimary.withValues(alpha: 0.8),
                                  borderRadius: BorderRadius.circular(100),
                                ),
                                child: Text(
                                  'HABIS',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.white,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
