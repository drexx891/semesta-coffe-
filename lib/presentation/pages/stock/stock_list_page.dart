import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_dimensions.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/stock/stock_bloc.dart';
import '../../bloc/stock/stock_event.dart';
import '../../bloc/stock/stock_state.dart';
import 'widgets/ingredient_form_dialog.dart';
import 'widgets/stock_adjustment_dialog.dart';
import 'package:flutter_lucide/flutter_lucide.dart';


class StockListPage extends StatefulWidget {
  const StockListPage({super.key});

  @override
  State<StockListPage> createState() => _StockListPageState();
}

class _StockListPageState extends State<StockListPage> {
  @override
  void initState() {
    super.initState();
    // Dispatch event if not already loaded, but it's loaded in main.dart
    // For manual refresh, we will call add(LoadStock())
  }

  Color _getStockColor(double current, double min) {
    if (current <= min) return AppColors.stockCritical;
    if (current <= min * 2) return AppColors.stockWarning;
    return AppColors.stockSafe;
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<StockBloc, StockState>(
      listener: (context, state) {
        if (state is StockActionSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: AppColors.success),
          );
        } else if (state is StockError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: AppColors.error),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(AppStrings.stock, style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w600)),
          backgroundColor: AppColors.primaryDark,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () => context.read<StockBloc>().add(LoadStock()),
            ),
          ],
        ),
        body: BlocBuilder<StockBloc, StockState>(
          builder: (context, state) {
            if (state is StockLoading || state is StockInitial) {
              return const Center(child: CircularProgressIndicator(color: AppColors.accent));
            }
            if (state is StockLoaded) {
              final ingredients = state.ingredients;
              
              if (ingredients.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.package_search, size: 64, color: AppColors.textTertiary.withValues(alpha: 0.3)),
                      const SizedBox(height: 12),
                      Text('Belum ada bahan baku', style: GoogleFonts.inter(color: AppColors.textTertiary)),
                    ],
                  ),
                );
              }
              
              return RefreshIndicator(
                onRefresh: () async {
                  context.read<StockBloc>().add(LoadStock());
                },
                child: ListView.builder(
                  padding: const EdgeInsets.all(AppDimensions.spacing16),
                  itemCount: ingredients.length,
                  itemBuilder: (ctx, index) {
                    final ing = ingredients[index];
                    final currentStock = (ing['current_stock'] as num).toDouble();
                    final minStock = (ing['min_stock'] as num).toDouble();
                    final stockColor = _getStockColor(currentStock, minStock);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (_) => BlocProvider.value(
                              value: context.read<StockBloc>(),
                              child: StockAdjustmentDialog(ingredient: ing),
                            ),
                          );
                        },
                        onLongPress: () {
                          showDialog(
                            context: context,
                            builder: (_) => BlocProvider.value(
                              value: context.read<StockBloc>(),
                              child: IngredientFormDialog(ingredient: ing),
                            ),
                          );
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
              );
            }
            
            return const SizedBox.shrink();
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            showDialog(
              context: context,
              builder: (_) => BlocProvider.value(
                value: context.read<StockBloc>(),
                child: const IngredientFormDialog(),
              ),
            );
          },
          icon: const Icon(LucideIcons.plus),
          label: const Text('Tambah Bahan'),
          backgroundColor: AppColors.accent,
        ),
      ),
    );
  }
}
