import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../data/database/dao/product_dao.dart';
import '../../../../domain/entities/hold_order.dart';
import '../../../../domain/entities/transaction.dart';

class ModifierBottomSheet extends StatefulWidget {
  final Map<String, dynamic> product;
  final Function(CartItem) onAddToCart;

  const ModifierBottomSheet({
    super.key,
    required this.product,
    required this.onAddToCart,
  });

  @override
  State<ModifierBottomSheet> createState() => _ModifierBottomSheetState();
}

class _ModifierBottomSheetState extends State<ModifierBottomSheet> {
  final ProductDao _productDao = sl<ProductDao>();
  
  List<Map<String, dynamic>> _availableToppings = [];
  bool _isLoading = true;

  // Selected state
  String _selectedSize = 'regular';
  int _extraShot = 0;
  final List<Map<String, dynamic>> _selectedToppings = [];
  final TextEditingController _notesController = TextEditingController();

  double get _basePrice => (widget.product['price_regular'] as num).toDouble();
  double get _largePrice => (widget.product['price_large'] as num?)?.toDouble() ?? _basePrice;
  double get _currentBasePrice => _selectedSize == 'regular' ? _basePrice : _largePrice;
  
  double get _totalPrice {
    double total = _currentBasePrice;
    // Add extra shot
    total += _extraShot * 5000; // Hardcode extra shot price for now
    // Add toppings
    for (final t in _selectedToppings) {
      total += (t['price'] as num).toDouble();
    }
    return total;
  }

  @override
  void initState() {
    super.initState();
    _loadToppings();
  }

  Future<void> _loadToppings() async {
    try {
      final productId = widget.product['id'] as int;
      _availableToppings = await _productDao.getToppingsForProduct(productId);
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  void _addToCart() {
    final item = CartItem(
      cartItemId: const Uuid().v4(),
      productId: widget.product['id'] as int,
      productName: widget.product['name'] as String,
      basePrice: _currentBasePrice,
      quantity: 1,
      size: _selectedSize,
      extraShot: _extraShot > 0,
      selectedToppings: _selectedToppings.map((t) => ToppingInfo(
        id: t['id'] as int,
        name: t['name'] as String,
        price: (t['price'] as num).toDouble(),
      )).toList(),
      notes: _notesController.text.trim(),
    );
    
    widget.onAddToCart(item);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final hasLargeSize = widget.product['price_large'] != null && (widget.product['price_large'] as num) > 0;
    
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
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  widget.product['name'] as String,
                  style: GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.w600),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(height: 24),
          
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Size Selection
                  if (hasLargeSize) ...[
                    Text('Pilih Ukuran', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _buildSizeOption('regular', 'Regular', _basePrice)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildSizeOption('large', 'Large', _largePrice)),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Extra Shot
                  Text('Extra Shot (Espresso)', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildQuantityButton(Icons.remove, () {
                        if (_extraShot > 0) setState(() => _extraShot--);
                      }),
                      Container(
                        width: 48,
                        alignment: Alignment.center,
                        child: Text('$_extraShot', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600)),
                      ),
                      _buildQuantityButton(Icons.add, () {
                        if (_extraShot < 5) setState(() => _extraShot++);
                      }),
                      const Spacer(),
                      Text('+ ${CurrencyFormatter.format(5000)}/shot', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Toppings
                  if (_isLoading)
                    const Center(child: CircularProgressIndicator(color: AppColors.accent))
                  else if (_availableToppings.isNotEmpty) ...[
                    Text('Topping Tambahan', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    ..._availableToppings.map((t) => _buildToppingOption(t)),
                    const SizedBox(height: 24),
                  ],

                  // Notes
                  Text('Catatan', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _notesController,
                    decoration: InputDecoration(
                      hintText: 'Cth: Less sugar, no ice...',
                      filled: true,
                      fillColor: AppColors.surfaceVariant,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Add Button
          SizedBox(
            height: 54,
            child: ElevatedButton(
              onPressed: _addToCart,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryDark,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Tambah ke Keranjang', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.white)),
                  Text(CurrencyFormatter.format(_totalPrice), style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.white)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSizeOption(String id, String label, double price) {
    final isSelected = _selectedSize == id;
    return GestureDetector(
      onTap: () => setState(() => _selectedSize = id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent.withValues(alpha: 0.1) : AppColors.surfaceVariant,
          border: Border.all(color: isSelected ? AppColors.accent : AppColors.border, width: isSelected ? 2 : 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(label, style: GoogleFonts.inter(fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400, color: isSelected ? AppColors.accent : AppColors.textPrimary)),
            const SizedBox(height: 4),
            Text(CurrencyFormatter.format(price), style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildQuantityButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 20, color: AppColors.primaryDark),
      ),
    );
  }

  Widget _buildToppingOption(Map<String, dynamic> topping) {
    final isSelected = _selectedToppings.any((t) => t['id'] == topping['id']);
    return CheckboxListTile(
      value: isSelected,
      onChanged: (val) {
        setState(() {
          if (val == true) {
            _selectedToppings.add(topping);
          } else {
            _selectedToppings.removeWhere((t) => t['id'] == topping['id']);
          }
        });
      },
      title: Text(topping['name'] as String, style: GoogleFonts.inter(fontSize: 14)),
      subtitle: Text('+ ${CurrencyFormatter.format((topping['price'] as num).toDouble())}', style: GoogleFonts.inter(fontSize: 12, color: AppColors.accent)),
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
      activeColor: AppColors.accent,
      dense: true,
    );
  }
}
