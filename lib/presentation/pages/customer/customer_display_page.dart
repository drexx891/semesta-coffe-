import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/base64_image_helper.dart';
import '../../../core/di/injection_container.dart';
import '../../../data/database/dao/hold_order_dao.dart';
import '../../../domain/entities/hold_order.dart';
import '../../bloc/menu/menu_bloc.dart';
import '../../bloc/menu/menu_event.dart';
import '../../bloc/menu/menu_state.dart';
import '../pos/widgets/modifier_bottom_sheet.dart';
import 'package:lucide_icons/lucide_icons.dart';

class CustomerDisplayPage extends StatefulWidget {
  const CustomerDisplayPage({super.key});

  @override
  State<CustomerDisplayPage> createState() => _CustomerDisplayPageState();
}

class _CustomerDisplayPageState extends State<CustomerDisplayPage> {
  final List<CartItem> _cartItems = [];
  bool _isProcessing = false;
  int? _selectedCategoryId;
  String _searchQuery = '';

  double get _total => _cartItems.fold(0.0, (sum, item) => sum + item.subtotal);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bloc = context.read<MenuBloc>();
      if (bloc.state is! MenuLoaded) {
        bloc.add(LoadMenu());
      }
    });
  }

  void _addToCart(Map<String, dynamic> product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ModifierBottomSheet(
        product: product,
        onAddToCart: (item) {
          setState(() {
            _cartItems.add(item);
          });
        },
      ),
    );
  }

  void _updateQuantity(int index, int delta) {
    setState(() {
      final newQty = _cartItems[index].quantity + delta;
      if (newQty <= 0) {
        _cartItems.removeAt(index);
      } else {
        final item = _cartItems[index];
        _cartItems[index] = item.copyWith(quantity: newQty);
      }
    });
  }

  void _clearCart() {
    if (_cartItems.isEmpty) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Kosongkan Keranjang?', style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold)),
        content: Text('Semua item di keranjang akan dihapus.', style: GoogleFonts.inter()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _cartItems.clear());
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Hapus Semua'),
          ),
        ],
      ),
    );
  }

  Future<void> _checkout() async {
    if (_cartItems.isEmpty) return;

    String orderType = 'dine_in';
    final TextEditingController tableController = TextEditingController();
    
    final bool? proceed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text('Detail Pesanan', style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildOrderTypeOption(
                        label: 'Dine In',
                        icon: Icons.restaurant_rounded,
                        isSelected: orderType == 'dine_in',
                        onTap: () => setDialogState(() => orderType = 'dine_in'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildOrderTypeOption(
                        label: 'Takeaway',
                        icon: Icons.takeout_dining_rounded,
                        isSelected: orderType == 'take_away',
                        onTap: () => setDialogState(() => orderType = 'take_away'),
                      ),
                    ),
                  ],
                ),
                if (orderType == 'dine_in')
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: TextField(
                      controller: tableController,
                      decoration: InputDecoration(
                        labelText: 'Nomor Meja',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.table_restaurant),
                        filled: true,
                        fillColor: AppColors.surfaceVariant,
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Batal', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: () {
                  if (orderType == 'dine_in' && tableController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Isi nomor meja!')));
                    return;
                  }
                  Navigator.pop(ctx, true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Kirim Tagihan'),
              ),
            ],
          );
        }
      ),
    );

    if (proceed != true) return;

    setState(() => _isProcessing = true);

    try {
      final dao = sl<HoldOrderDao>();
      final label = orderType == 'dine_in' ? 'Kiosk - Meja ${tableController.text}' : 'Kiosk - Takeaway';
      
      final holdOrder = {
        'label': label,
        'order_type': orderType,
        'table_number': tableController.text.isEmpty ? null : tableController.text,
        'items_json': jsonEncode(_cartItems.map((i) => i.toJson()).toList()),
        'subtotal': _total,
        'user_id': 1,
        'created_at': DateTime.now().toIso8601String(),
        'expires_at': DateTime.now().add(const Duration(hours: 2)).toIso8601String(),
      };

      await dao.insertHoldOrder(holdOrder);

      setState(() {
        _cartItems.clear();
      });

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.successLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.checkCircle, color: AppColors.success, size: 56),
                ),
                const SizedBox(height: 20),
                Text('Pesanan Terkirim!', style: GoogleFonts.playfairDisplay(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Text(
                  'Silakan lakukan pembayaran di Kasir.\nSebutkan tagihan "$label".',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(color: AppColors.textSecondary, height: 1.5),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Tutup', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          )
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Widget _buildOrderTypeOption({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? AppColors.primary : AppColors.textSecondary, size: 28),
            const SizedBox(height: 8),
            Text(label, style: GoogleFonts.inter(
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            )),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _filterProducts(MenuLoaded state) {
    var products = state.allProducts.where((p) => (p['is_active'] ?? 1) == 1).toList();

    if (_selectedCategoryId != null) {
      products = products.where((p) => p['category_id'] == _selectedCategoryId).toList();
    }

    if (_searchQuery.isNotEmpty) {
      products = products.where((p) =>
        ((p['name'] as String?) ?? '').toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }

    return products;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          // === KIRI: Menu & Hero ===
          Expanded(
            flex: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Premium Hero Header
                Container(
                  padding: const EdgeInsets.fromLTRB(32, 40, 32, 24),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: const BorderRadius.only(bottomRight: Radius.circular(32)),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryDark.withValues(alpha: 0.03),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.wb_sunny_rounded, color: AppColors.accent, size: 28),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Selamat Datang,',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textTertiary,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Text(
                                'Mau pesan apa hari ini?',
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Search Bar Premium
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
                        ),
                        child: TextField(
                          onChanged: (v) => setState(() => _searchQuery = v),
                          decoration: InputDecoration(
                            hintText: 'Cari minuman favoritmu...',
                            hintStyle: GoogleFonts.inter(color: AppColors.textTertiary, fontSize: 15),
                            prefixIcon: const Icon(LucideIcons.search, color: AppColors.primaryLight),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                          ),
                          style: GoogleFonts.inter(fontSize: 16, color: AppColors.textPrimary),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Premium Category Pills
                BlocBuilder<MenuBloc, MenuState>(
                  builder: (context, state) {
                    if (state is! MenuLoaded) return const SizedBox.shrink();
                    return SizedBox(
                      height: 50,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        physics: const BouncingScrollPhysics(),
                        children: [
                          _buildCategoryPill(null, 'Semua Menu', state),
                          ...state.categories.map((c) =>
                            _buildCategoryPill(c['id'] as int, c['name'] as String, state),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 8),

                // Product Grid
                Expanded(
                  child: BlocBuilder<MenuBloc, MenuState>(
                    builder: (context, state) {
                      if (state is MenuLoading) {
                        return const Center(child: CircularProgressIndicator(color: AppColors.accent));
                      }
                      if (state is MenuLoaded) {
                        final products = _filterProducts(state);
                        
                        if (products.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(LucideIcons.coffee, size: 80, color: AppColors.textTertiary.withValues(alpha: 0.3)),
                                const SizedBox(height: 16),
                                Text(
                                  _searchQuery.isNotEmpty ? 'Menu tidak ditemukan' : 'Belum ada menu',
                                  style: GoogleFonts.inter(fontSize: 18, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          );
                        }
                        return GridView.builder(
                          padding: const EdgeInsets.fromLTRB(32, 16, 32, 40),
                          physics: const BouncingScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            childAspectRatio: 0.72,
                            crossAxisSpacing: 20,
                            mainAxisSpacing: 24,
                          ),
                          itemCount: products.length,
                          itemBuilder: (context, index) {
                            final product = products[index];
                            return _buildProductCard(product, state.stockAvailability);
                          },
                        );
                      }
                      return const Center(child: CircularProgressIndicator());
                    },
                  ),
                ),
              ],
            ),
          ),
          
          // === KANAN: Floating Premium Cart ===
          Container(
            width: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.border.withValues(alpha: 0.1),
                  AppColors.border,
                  AppColors.border.withValues(alpha: 0.1),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Container(
              color: AppColors.surface,
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Cart Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(28, 40, 28, 24),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pesanan Saya',
                                style: GoogleFonts.playfairDisplay(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_cartItems.fold<int>(0, (s, i) => s + i.quantity)} Items',
                                style: GoogleFonts.inter(fontSize: 14, color: AppColors.textTertiary, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                          const Spacer(),
                          if (_cartItems.isNotEmpty)
                            TextButton.icon(
                              onPressed: _clearCart,
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.error,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              icon: const Icon(LucideIcons.trash2, size: 20),
                              label: Text('Reset', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                            ),
                        ],
                      ),
                    ),
                    
                    // Cart Items
                    if (_cartItems.isEmpty)
                      Expanded(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.surfaceVariant.withValues(alpha: 0.5),
                                ),
                                child: Icon(Icons.shopping_bag_outlined, size: 64, color: AppColors.primaryLight.withValues(alpha: 0.5)),
                              ),
                              const SizedBox(height: 24),
                              Text('Keranjang masih kosong', style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 16, fontWeight: FontWeight.w500)),
                              const SizedBox(height: 8),
                              Text('Silakan pilih menu di samping', style: GoogleFonts.inter(color: AppColors.textTertiary, fontSize: 14)),
                            ],
                          ),
                        ),
                      )
                    else
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          physics: const BouncingScrollPhysics(),
                          itemCount: _cartItems.length,
                          separatorBuilder: (ctx, i) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Divider(color: AppColors.border.withValues(alpha: 0.5), height: 1),
                          ),
                          itemBuilder: (ctx, i) {
                            final item = _cartItems[i];
                            return _buildCartItemTile(item, i);
                          },
                        ),
                      ),

                    // Bottom: Premium Total + Pay Button
                    Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: const BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
                        boxShadow: [
                          BoxShadow(color: AppColors.primaryDark.withValues(alpha: 0.05), blurRadius: 24, offset: const Offset(0, -8)),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Total Pembayaran', style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary)),
                                  const SizedBox(height: 4),
                                  Text('Termasuk PPN', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textTertiary)),
                                ],
                              ),
                              Text(
                                CurrencyFormatter.format(_total),
                                style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.primaryDark, letterSpacing: -1),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 60,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                gradient: _cartItems.isEmpty || _isProcessing
                                    ? LinearGradient(colors: [AppColors.border, AppColors.border])
                                    : AppColors.accentGradient,
                                boxShadow: _cartItems.isEmpty || _isProcessing ? null : [
                                  BoxShadow(color: AppColors.accent.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 8))
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: _cartItems.isEmpty || _isProcessing ? null : _checkout,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                ),
                                child: _isProcessing
                                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                                    : Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text('Kirim ke Kasir', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
                                          const SizedBox(width: 12),
                                          const Icon(Icons.arrow_forward_rounded, color: Colors.white),
                                        ],
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItemTile(CartItem item, int index) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Quantity Adjuster (Pill style)
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(LucideIcons.minus, size: 16),
                  color: AppColors.textSecondary,
                  onPressed: () => _updateQuantity(index, -1),
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  padding: EdgeInsets.zero,
                  splashRadius: 16,
                ),
                SizedBox(
                  width: 20,
                  child: Text('${item.quantity}', textAlign: TextAlign.center, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14)),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.plus, size: 16),
                  color: AppColors.primary,
                  onPressed: () => _updateQuantity(index, 1),
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  padding: EdgeInsets.zero,
                  splashRadius: 16,
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Item Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.productName, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.textPrimary)),
                if (item.modifierDisplay.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(item.modifierDisplay, style: GoogleFonts.inter(color: AppColors.textTertiary, fontSize: 12, fontWeight: FontWeight.w500)),
                  ),
              ],
            ),
          ),
          // Price
          Text(CurrencyFormatter.format(item.subtotal), style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AppColors.textPrimary, fontSize: 15)),
        ],
      ),
    );
  }

  Widget _buildCategoryPill(int? id, String name, MenuLoaded state) {
    final isSelected = _selectedCategoryId == id;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategoryId = id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryDark : AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? AppColors.primaryDark : AppColors.border.withValues(alpha: 0.5),
          ),
          boxShadow: isSelected ? [
            BoxShadow(color: AppColors.primaryDark.withValues(alpha: 0.2), blurRadius: 12, offset: const Offset(0, 4))
          ] : null,
        ),
        child: Center(
          child: Text(
            name,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? Colors.white : AppColors.textSecondary,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product, Map<int, bool> stockAvailability) {
    final productId = product['id'] as int? ?? 0;
    final productName = (product['name'] as String?) ?? 'Tanpa Nama';
    final price = (product['price_regular'] as num?)?.toDouble() ?? 0;
    final isAvailable = stockAvailability[productId] ?? true;
    final isOutOfStock = !isAvailable;
    final imagePath = product['image_path'] as String?;

    return GestureDetector(
      onTap: isOutOfStock ? null : () => _addToCart(product),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 16, offset: const Offset(0, 8)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Edge-to-edge Image
                  Expanded(
                    flex: 3,
                    child: imagePath != null && imagePath.isNotEmpty
                        ? Base64ImageHelper.buildImage(imagePath, fit: BoxFit.cover)
                        : Container(
                            color: AppColors.surfaceVariant,
                            child: const Icon(Icons.coffee_rounded, size: 64, color: AppColors.border),
                          ),
                  ),
                  // Content details
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            productName,
                            style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.textPrimary, height: 1.3),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            CurrencyFormatter.format(price),
                            style: GoogleFonts.inter(color: AppColors.accentDark, fontWeight: FontWeight.w800, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              
              // Out of Stock Overlay (Glassmorphism)
              if (isOutOfStock)
                Positioned.fill(
                  child: Container(
                    color: AppColors.surface.withValues(alpha: 0.7),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.textPrimary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text('HABIS', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14, letterSpacing: 1)),
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
