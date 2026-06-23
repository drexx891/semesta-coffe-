import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/di/injection_container.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/base64_image_helper.dart';

import '../../bloc/menu/menu_bloc.dart';
import '../../bloc/menu/menu_event.dart';
import '../../bloc/menu/menu_state.dart';
import '../../bloc/pos/pos_bloc.dart';
import '../../bloc/pos/pos_event.dart';
import '../../bloc/pos/pos_state.dart';

import 'widgets/modifier_bottom_sheet.dart';
import 'widgets/cart_panel.dart';
import 'widgets/cart_summary.dart';
import 'widgets/hold_order_dialog.dart';
import 'widgets/shift_warning_banner.dart';
import 'widgets/payment_success_dialog.dart';

class PosPage extends StatefulWidget {
  const PosPage({super.key});

  @override
  State<PosPage> createState() => _PosPageState();
}

class _PosPageState extends State<PosPage> {
  late PosBloc _posBloc;
  final ScrollController _cartScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _posBloc = sl<PosBloc>()..add(InitPos());
    Future.microtask(() {
      context.read<MenuBloc>().add(LoadMenu());
    });
  }

  @override
  void dispose() {
    _posBloc.close();
    _cartScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width >= AppDimensions.tabletBreakpoint;

    return BlocProvider.value(
      value: _posBloc,
      child: BlocListener<PosBloc, PosState>(
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
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (_) => BlocProvider.value(
                value: _posBloc,
                child: PaymentSuccessDialog(
                  transactionId: state.lastTransactionId!,
                  queueNumber: state.lastQueueNumber ?? '-',
                  trxNumber: state.lastTransactionNumber ?? '-',
                ),
              ),
            );
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
                      icon: const Icon(Icons.history_rounded, color: AppColors.textSecondary),
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
      ),
    );
  }

  void _showHoldOrdersDialog(BuildContext context) {
    // We could implement this dialog properly, but for now we'll keep it simple
    // or just show a message.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Daftar hold order akan diimplementasikan penuh di task berikutnya.')),
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
                          value: _posBloc,
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
                  prefixIcon: const Icon(Icons.search_rounded),
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
    final name = product['name'] as String;
    final price = (product['price_regular'] as num).toDouble();
    final isAvailable = stockAvailability[productId] ?? true;

    return GestureDetector(
      onTap: isAvailable ? () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          backgroundColor: Colors.transparent,
          builder: (ctx) => ModifierBottomSheet(
            product: product,
            onAddToCart: (item) {
              context.read<PosBloc>().add(AddToCart(item));
            },
          ),
        );
      } : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 3,
                    child: Container(
                      color: AppColors.surfaceVariant,
                      child: product['image_path'] != null && (product['image_path'] as String).isNotEmpty
                          ? Base64ImageHelper.buildImage(product['image_path'] as String, fit: BoxFit.cover)
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
              if (!isAvailable)
                Positioned.fill(
                  child: Container(
                    color: AppColors.surface.withValues(alpha: 0.7),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.textPrimary,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          'HABIS',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppColors.white,
                            letterSpacing: 0.5,
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
    );
  }
}
