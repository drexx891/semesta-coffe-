import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/di/injection_container.dart';
import '../../../data/database/dao/stock_dao.dart';
import 'widgets/ingredient_form_dialog.dart';
import 'widgets/stock_adjustment_dialog.dart';


class StockListPage extends StatefulWidget {
  const StockListPage({super.key});

  @override
  State<StockListPage> createState() => _StockListPageState();
}

class _StockListPageState extends State<StockListPage> {
  final StockDao _stockDao = sl<StockDao>();
  List<Map<String, dynamic>> _ingredients = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadIngredients();
  }

  Future<void> _loadIngredients() async {
    setState(() => _isLoading = true);
    try {
      _ingredients = await _stockDao.getAllIngredients();
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Color _getStockColor(double current, double min) {
    if (current <= min) return AppColors.stockCritical;
    if (current <= min * 2) return AppColors.stockWarning;
    return AppColors.stockSafe;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(AppStrings.stock, style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w600)),
        backgroundColor: AppColors.primaryDark,
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _loadIngredients),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
          : _ingredients.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.inventory_2_rounded, size: 64, color: AppColors.textTertiary.withValues(alpha: 0.3)),
                      const SizedBox(height: 12),
                      Text('Belum ada bahan baku', style: GoogleFonts.inter(color: AppColors.textTertiary)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadIngredients,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(AppDimensions.spacing16),
                    itemCount: _ingredients.length,
                    itemBuilder: (ctx, index) {
                      final ing = _ingredients[index];
                      final currentStock = (ing['current_stock'] as num).toDouble();
                      final minStock = (ing['min_stock'] as num).toDouble();
                      final stockColor = _getStockColor(currentStock, minStock);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          onTap: () async {
                            final result = await showDialog<bool>(
                              context: context,
                              builder: (_) => StockAdjustmentDialog(ingredient: ing),
                            );
                            if (result == true) _loadIngredients();
                          },
                          onLongPress: () async {
                            final result = await showDialog<bool>(
                              context: context,
                              builder: (_) => IngredientFormDialog(ingredient: ing),
                            );
                            if (result == true) _loadIngredients();
                          },
                          leading: Container(
                            width: 12,
                            height: 44,
                            decoration: BoxDecoration(
                              color: stockColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          title: Text(
                            ing['name'] as String,
                            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            '${ing['category']} · Min: ${minStock.toStringAsFixed(0)} ${ing['unit']}',
                            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                          ),
                          trailing: Text(
                            '${currentStock.toStringAsFixed(0)} ${ing['unit']}',
                            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: stockColor),
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await showDialog<bool>(
            context: context,
            builder: (_) => const IngredientFormDialog(),
          );
          if (result == true) _loadIngredients();
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah Bahan'),
        backgroundColor: AppColors.accent,
      ),
    );
  }
}
